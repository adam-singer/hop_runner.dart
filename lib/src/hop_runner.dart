part of hop_runner;

class HopRunner {
  /// [List] of [Task] items to run.
  List<Task> taskList;
  
  /**
   * Logger whose level is set by the commandline --loglevel option.
   * [Logger.FINE] and [Logger.INFO] currently supported.
   */
  Logger log;
  
  /**
   * Set by the commandline --offline flag.
   * If `true`, cached packages are used.
   * If `false`, packages pulled from the network.
   */
  bool offline = false;
  
  /**
   * Set by the commandline --debug flag.
   * If `true`, the temporary directory is not deleted after running.
   * If `false`, the temporary directory is deleted after running.
   */
  bool debug = false;
  
  HopRunner(this.taskList);

  /**
   * Main entry method for [HopRunner].
   * 1. Creates the temporary directory.
   * 2. Using [PubspecBuilder], creates the pubspec.yaml file in the temp directory.
   * 3. Using [HopBuilder], creates a `tool/hop_runner.dart` file in the temp directory.
   * 4. Runs `pub get` to acquire pub task packages.
   * 5. For each [Task] in [taskList], it runs `tool/hop_runner.dart`.
   * 6. Deletes the temperatory directory if [debug] is `false`.
   */
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
            
            // Run each Task.
            hb.run(taskList).then((_){
              if(!debug){
              
                // Delete the temporary directory.
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

  /// The directory in which the [HopRunner] builds and runs each [Task].
  Directory root;
  
  HopBuilder(this.root);
  
  /**
   * Logger whose level is set by the commandline --loglevel option.
   * [Logger.FINE] and [Logger.INFO] currently supported.
   */
  Logger log;
  
  /// Needed to pipe [Process.stdin] for each [Task].
  final stdinHandler = new StdinHandler();
  
  /// Needed to pipe [Process.stdin] for each [Task].
  StreamSubscription streamSubscription;
  
  /// Builds the `tool/hop_runner.dart` file.
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
  
  // Builds the import section of the `tool/hop_runner.dart` file.
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
  
  // Builds the body section of the `tool/hop_runner.dart` file.
  String _body(List taskList) {
    var sb = new StringBuffer();
    taskList.forEach((Task task) => sb.write(task.call));
    
    return sb.toString();
  }
  
  // Builds the ending section of the `tool/hop_runner.dart` file.
  String _end() {
    var sb = new StringBuffer();
    sb.write("runHop(args);\n");
    sb.write("}");
    return sb.toString();
  }
  
  /**
   * Handles the process for the running [Task].
   * Assigns [Process.stdin] to [stdinHandler] and writes [Process.stdout] to [Stdout].
   */
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
  
  /**
   * Iterates through each [Task] in [taskList].
   * Assigns output of previous task to input of a subsequent task, if exists.
   * The subsequent task does not start until its previous task completes.
   */
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
  
  /// Processes each [Task] in [taskList].
  Future run(List taskList) {
    var completer = new Completer();
    
    // Set the stdin listener for use in _runTaskList.
    streamSubscription = stdin.listen(stdinHandler.handleInput);
    
    // Acquire first task's arguments to provide as input.
    Task firstTask = taskList.first;
    String firstTaskArgs = firstTask.args;
    
    // Iterate through taskList to process each Task.
    var iterator = taskList.iterator;
    _runTaskList(iterator, previousOutput:firstTaskArgs)
    .then((_){
      log.fine("Completed from _runTaskList.");
      completer.complete(true);
    });
    
    return completer.future;
  }
}

/// [Process.stdin] handler to capture input from [Task].
class StdinHandler {

  /// [Process.stdin] returns an [IOSink].
  IOSink stdin;
  
  /// Function for handling [Stdin.listen].
  void handleInput(List<int> data) {
    stdin.add(data);
  }
}