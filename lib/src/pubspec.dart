part of hop_runner;

/// Pubspec.yaml file builder.
class PubspecBuilder {
  /// The name of the pub package, typically the name of the temporary directory.
  String name;
  
  /// List of [Task]s parsed from the commandline.
  List taskList;
  
  /// The directory that serves as the root for the pubspec.yaml file.
  Directory dir;
  
  PubspecBuilder(this.name, this.taskList, this.dir);

  /**
   * Logger whose level is set by the commandline --loglevel option.
   */
  Logger log;

  /// Build the pubspec.yaml file.
  Future<File> build(){
    return dir.exists()
    .then((bool exists){
      var path = dir.path;
      return new File('$path/pubspec.yaml')
      ..create()
      .then((File pubspec){
        var sb = new StringBuffer();
        sb.write(_base());
        sb.write(_generateDependencies());

        return pubspec.writeAsString(sb.toString());
      });
    });
  }

  /// Write the first part of the pubspec.yaml file.
  String _base(){
    /*
      name: [name]
      dependencies:
         hop: any
    */
    return "name: $name\ndependencies:\n   hop: any\n";
  }

  /// Generate dependencies for each parsed task.
  String _generateDependencies() {
    var sb = new StringBuffer();

    // Track built tasks to make sure there are no duplicate dependencies.
    var builtTasks = [];
    taskList.forEach((Task task) {
      if (!builtTasks.contains(task.name)) {
        // Processing each dependency
        task.dependencies.forEach((Dependency dependency) {
          // Calling here Dependency.toString() method
          sb.write(dependency);
        });
        builtTasks.add(task.name);
      }
    });

    return sb.toString();
  }
  
}

/// Pub dependency handler.
class PubProcessor {
  /// The name of the pub package, typically the name of the temporary directory.
  String name;
  
  /// Directory where pubspec.yaml is built from which `pub get` is called.
  Directory dir;
  
  /// List of [Task]s parsed from the commandline.
  List taskList;

  /// Hop Pub Package url.
  final String pubUrl = "http://pub.dartlang.org/api/packages/";
  
  /// Pub Cache Base Uri.
  final String pubCacheUriBase = "${Platform.environment['HOME']}/.pub-cache/hosted/pub.dartlang.org/";

  /**
   * Logger whose level is set by the commandline --loglevel option.
   */
  Logger log;
  
  /// Getter for git/hosted packages.
  List<Task> get nonPub => _nonPub();
  List<Task> _nonPub() {
    return taskList.where((Task task) => ['hosted','git'].contains(task.type)).toList();
  }
  
  /// Getter for pub packages.
  List<String> get pub => _pub();
  List<String> _pub() {
    return ['hop']..addAll(taskList.where((Task task) => task.type == "pub").map((Task task) => task.name));
  }
  
  PubProcessor(this.name, this.taskList, this.dir);

  /// Prepares pub package dependencies.
  Future prepare({bool offline:false}) {
    
    var completer = new Completer();
    
    log.finer("PubProcessor.prepare name: $name");
    log.finer("PubProcessor.prepare dir: $dir");
    log.finer("PubProcessor.prepare taskList: ${taskList.map((task) => task.name).toList()}");
    var prepareFutureList = [];
    
    // If offline is `false`, verify latest version of packages and dependencies in pub_cache.
    if(!offline) {
      
      log.finer("PubProcessor.prepare: $offline");
      
      // Confirm two lists, one for pub and one for git/hosted packages, respectively.
      log.finer("PubProcessor.prepare nonPub: ${nonPub.map((Task task) => task.name).toList()}");
      log.finer("PubProcessor.prepare pub: $pub");
      
      Future.wait([
        _prepareNonPubList(),
        _preparePubList()
      ]).then((_){
        log.finer("PubProcessor.prepare: completed _prepareNonPubList, _preparePubList");
        completer.complete(true);
      });      
    } else {
      completer.complete(true);
    }
    
    return completer.future;
  }

  /// Prepares package dependencies for packages hosted outside pub.dartlang.org.
  Future _prepareNonPubList() {
    var completer = new Completer();
    if (!nonPub.isEmpty) {
        // Prepare git/hosted packages and dependencies.
        dir.createTemp().then((Directory temp){
          var pubspecBuilder = new PubspecBuilder('githosted', nonPub, temp);
          pubspecBuilder.log = log;
          
          // Build pubspec.yaml of types git and hosted.
          pubspecBuilder.build().then((File pubspecFile){
            log.fine("Built 'githosted' pubspecFile: $pubspecFile");

            // Run `pub get` to download dependencies.
            return Process.run('pub',['get'], workingDirectory:temp.path).then((ProcessResult result){
              log.fine(result.stdout);
              stderr.write(result.stderr);

              // Clean files/directories.
              temp.delete(recursive:true).then((_) => completer.complete(true));
            });
          });
        });
    } else completer.complete(true);
    return completer.future;
  }

  /// Prepares pub package dependencies packages hosted on pub.dartlang.org.
  Future _preparePubList() {
    return Future.wait(pub.map((String pubName) => _preparePub(pubName)));
  }

  /// Prepares pub package dependencies for given [pubName].
  Future _preparePub(String pubName) {
    log.fine("PubProcessor._preparePub, pubName: $pubName");
    var completer = new Completer();
    
    // Acquire latest version of pubName.
    _version(pubName).then((String version){
      log.fine("PubProcessor._preparePub, version: $version");

      if(version!="") {
      
        // Determine if latest pub cache folder exists.
        _pubFolderExists(pubName, version).then((bool pubFolderExists){

          log.fine("PubProcessor._preparePub, pubFolderExists: $pubFolderExists");
          if(!pubFolderExists) {

            // `pub cache add [pubName]`
            ProcessResult result = Process.runSync('pub', ['cache', 'add', pubName]);
            log.fine(result.stdout);
            stderr.write(result.stderr);
          }

          // Update pub dependencies.
          _update(pubName, version).then((ProcessResult result) {
            log.fine(result.stdout);
            stderr.write(result.stderr);
            completer.complete(true);
          });
        });
      }
    });
        
    return completer.future;
  }

  /// Acquires latest version of pub package.
  Future<String> _version(String pubName) {
    var completer = new Completer();
    
    var client = new HttpClient();
    try {
      client.getUrl(Uri.parse(pubUrl+pubName))
        .then((HttpClientRequest request) {
          request.headers.contentType = new ContentType("application", "json", charset: "utf-8");
          return request.close();
        })
        .then((HttpClientResponse response){
          if(response.statusCode == 200) {
            UTF8.decodeStream(response).then((String responseText){
              var pubMap = JSON.decode(responseText);
              String version = pubMap["latest"]["version"];
              log.fine("Latest $pubName version: $version");
              completer.complete(version);
            });
          }
        });
     } catch(e) {
       log.fine("Failed to call $pubName package api.");
       completer.complete("");
     }
    
    return completer.future;
  }
  
  /// Determines existence of pub package version folder in .pub_cache.
  Future<bool> _pubFolderExists(String pubName, String version) {
    var dir = new Directory(pubCacheUriBase+pubName+"-$version");
    return dir.exists();
  }
  
  /// Updates pub dependencies
  Future<ProcessResult> _update(String pubName, String version) {
    // Assumes dir exists.
    var dir = new Directory(pubCacheUriBase+pubName+"-$version");
    return Process.run('pub',['get'],workingDirectory:dir.path);
  }
}