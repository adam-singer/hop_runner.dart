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
  final stdinHandler = new StdinHandler();
  StreamSubscription streamSubscription;
  
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
  
  Future _handle(Process process) {
    var completer = new Completer();
    var sb = new StringBuffer();
    process.exitCode.then((exitCode){
      log.fine("Task exitCode: $exitCode");
      completer.complete(sb.toString());
    });
    
    stdinHandler.stdin = process.stdin;
    
    process.stdout.listen((data){
      var output = new String.fromCharCodes(data);
      sb.write(output);
      stdout.write(output);
    });
        
    process.stderr.listen((data){
      stdout.write(new String.fromCharCodes(data));
    });
    
    return completer.future;
  }
  
  Future _runTaskList(Iterator iterator, {String previousOutput:""}) {
    var completer = new Completer();
    if(iterator.moveNext()) {
      Task task = iterator.current;
      log.fine("Running task: ${task.name}");
      task.args = previousOutput;
      return task.run(root)
      .then(_handle)
      .then((String output){
        log.fine("Completed task: ${task.name}");
        var nextInput = output.trim();
        return _runTaskList(iterator, previousOutput:nextInput);
      });
    } else {
      log.fine("Commpleted all tasks.");
      log.fine("Remove subscription to stdin.");
      var ftr = streamSubscription.cancel();
      if(ftr!=null) {
        ftr.whenComplete(() => completer.complete(true));
      } else completer.complete(true);
    }
    return completer.future;
  }
  
  Future run(List taskList) {
    var completer = new Completer();
    streamSubscription = stdin.listen(stdinHandler.handleInput);
    Task firstTask = taskList.first;
    String firstTaskArgs = firstTask.args;
    var iterator = taskList.iterator;
    _runTaskList(iterator, previousOutput:firstTaskArgs)
    .then((_){
      log.fine("Completed from _runTaskList.");
      completer.complete(true);
    });
    
    return completer.future;
  }
}



class StdinHandler {
  IOSink stdin;
  void handleInput(List<int> data) {
    stdin.add(data);
  }
}