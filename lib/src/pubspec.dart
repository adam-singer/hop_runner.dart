part of hop_runner;

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
   * [Logger.FINE] and [Logger.INFO] currently supported.
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

class PubProcessor {
  /// Directory where pubspec.yaml is built from which `pub get` is called.
  Directory dir;
  
  /// Hop Pub Package url.
  final String hopUrl = "http://pub.dartlang.org/api/packages/hop";
  
  /// Hop Pub Cache Base Uri.
  final String hopCacheUriBase = "${Platform.environment['HOME']}/.pub-cache/hosted/pub.dartlang.org/hop-";
  
  /**
   * Logger whose level is set by the commandline --loglevel option.
   * [Logger.FINE] and [Logger.INFO] currently supported.
   */
  Logger log;
  
  PubProcessor(this.dir);

  /// Processes `pub get`
  Future<ProcessResult> get({bool offline:false}) {
    var completer = new Completer();
    var args = ['get'];
    if(offline) {
      args.add('--offline');
      log.fine("pub args: $args");
      Process.run('pub',args,workingDirectory:dir.path).then((ProcessResult result) => completer.complete(result));
    } else {
      _hopUptodate().then((bool hopUptodate){
        log.fine("hopUptodate: $hopUptodate");
        if(hopUptodate) args.add('--offline');
        log.fine("pub args: $args");
        Process.run('pub',args,workingDirectory:dir.path).then((ProcessResult result) => completer.complete(result));
      });
    }

    return completer.future;
  }
  
  Future<bool> _hopUptodate() {
    var completer = new Completer();
    
    var client = new HttpClient();
    try {
      client.getUrl(Uri.parse(hopUrl))
        .then((HttpClientRequest request) {
          request.headers.contentType = new ContentType("application", "json", charset: "utf-8");
          return request.close();
        })
        .then((HttpClientResponse response){
          if(response.statusCode == 200) {
            UTF8.decodeStream(response).then((String responseText){
              var pubMap = JSON.decode(responseText);
              String version = pubMap["latest"]["version"];
              log.fine("Latest Hop version: $version");
              var hopPubDir = new Directory(hopCacheUriBase+version).absolute;
              bool hopPubDirExists = hopPubDir.existsSync();
              log.fine("hopPubDir: $hopPubDir, exists: $hopPubDirExists");
              completer.complete(hopPubDirExists);
            });
          }
        });
     } catch(e) {
       log.fine("Failed to call hop package api.");
       completer.complete(false);
     }
    
    return completer.future;
  }
}