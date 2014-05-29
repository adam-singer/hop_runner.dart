part of hop_runner;

class PubspecBuilder {
  /// The name of the pub package, typically the name of the temporary directory.
  String name;
  
  /// List of [Task]s parsed from the commandline.
  List taskList;
  
  /// The directory that serves as the root for the pubspec.yaml file.
  Directory dir;
  PubspecBuilder(this.name, this.taskList, this.dir);

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

    taskList.forEach((Task task) {
      // Processing each dependency
      task.dependencies.forEach((Dependency dependency) {
        // Calling here Dependency.toString() method
        sb.write(dependency);
      });
    });

    return sb.toString();
  }
  
}

class PubProcessor {
  /// Directory where pubspec.yaml is built from which `pub get` is called.
  Directory dir;
  PubProcessor(this.dir);

  /// Processes `pub get`
  Future<ProcessResult> get({bool offline:false}) {
    var args = ['get'];
    if(offline) args.add('--offline');
    return Process.run('pub',args,workingDirectory:dir.path);
  }

}