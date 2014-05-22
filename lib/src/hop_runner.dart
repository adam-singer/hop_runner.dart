part of hop_runner;

class HopRunner {
  List taskList;
  Logger log;
  bool offline = false;
  bool debug = false;
  
  HopRunner(this.taskList);

  void run(){
    log.fine("offline: $offline");

    var dir = new Directory('.');

    // Run task in temporary directory.
    dir.createTemp().then((Directory temp){

      // Use name of temporary directory as project name.
      String name = temp.path.split('/').toList().last;
      log.fine("Created $temp $name");

      // Build pubspec in temporary directory.
      var pubspecBuilder = new PubspecBuilder(name, taskList, temp);
      
      pubspecBuilder.build().then((File pubspec){

        log.fine("Built $pubspec");
      
        // Build hop_runner.dart file.
        var hb = new HopBuilder(temp);
        hb.log = log;

        hb.build(taskList)
        .then((File hop_runnerfile){

          log.fine("Built $hop_runnerfile");
          
          var processor = new PubProcessor(temp);

          log.fine("Pulling dependencies...");
          
          // Call pub get to get repositories.
          processor.get(offline:offline)
          .then((ProcessResult result){
            stderr.write(result.stderr);
            hb.run(taskList).then((_){
              if(!debug){
                temp.delete(recursive:true)
                .then((_) => log.fine("done."));
              } else log.fine("done.");
              
            });
          });
        });
      });
    });
  }
}

class HopBuilder {
  Directory root;
  HopBuilder(this.root);
  Logger log;
  
  Future<File> build(List taskList) {
    var sb = new StringBuffer();
    sb.write(_base(taskList));
    sb.write(_body(taskList));
    sb.write(_end());
    var tool = new Directory("${root.path}/tool");
    return tool.create()
    .then((Directory tool){
      var path = tool.path;
      var hr = new File("$path/hop_runner.dart");
      return hr.create()
      .then((File hr){
        return hr.writeAsString(sb.toString());
      });
    });
  }
  
  String _base(List taskList) {
    var sb = new StringBuffer();
    sb.write("library hop_runner;\n");
    sb.write("import 'dart:io';\n");
    sb.write("import 'package:hop/hop.dart';\n");
    sb.write("import 'package:args/args.dart';\n");
    taskList.forEach((Task task) => sb.write(task.import));
    sb.write("void main(List<String> args) {\n");
    return sb.toString();
  }
  
  String _body(List taskList) {
    var sb = new StringBuffer();
    taskList.forEach((Task task) => sb.write(task.call));
    
    return sb.toString();
  }
  
  String _end() {
    var sb = new StringBuffer();
    sb.write("runHop(args);\n");
    sb.write("}");
    return sb.toString();
  }
  
  Future run(List taskList) {
    /*
      This is hacky but needed because Future.forEach completes before process.exitCode.
    */
    var length = taskList.length;
    var completer = new Completer();
    var i = 0;
    Future.forEach(taskList, (Task task){
      task.run(root)
      .then((Process process){
        process.exitCode.then((exitCode){
          log.fine("${task.name} exitCode: $exitCode");
          i = i + 1;
          if(i == length) completer.complete(true);
        });
        
        stdin.pipe(process.stdin);
        process.stdout.listen((data){
          stdout.write(new String.fromCharCodes(data));
        });
        
        process.stderr.listen((data){
          stdout.write(new String.fromCharCodes(data));
        });
      });
    });
    
    return completer.future;
  }
}