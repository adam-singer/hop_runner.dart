part of hop_runner;

class PubspecBuilder {
  String name;
  List taskList;
  Directory dir;
  PubspecBuilder(this.name, this.taskList, this.dir);

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

  String _base(){
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
  Directory dir;
  PubProcessor(this.dir);

  Future<ProcessResult> get({bool offline:false}) {
    var args = ['get'];
    if(offline) args.add('--offline');
    return Process.run('pub',args,workingDirectory:dir.path);
  }

}