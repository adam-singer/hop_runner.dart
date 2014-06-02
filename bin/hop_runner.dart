import 'dart:io';
import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:hop_runner/hop_runner.dart';

/// The main commandline arguments parser.
final parser = new ArgParser();

/// The commandline arguments parser for [Task] specific arguments.
final taskParser = new ArgParser();

final logLevelMap = {
  "info":  Level.INFO,
  "fine":  Level.FINE,
  "finer": Level.FINER,
  "finest": Level.FINEST
};

/**
 * Logger whose level is set by the commandline --loglevel option.
 */
final log = new Logger("hop");

/**
 * Set by the commandline --offline flag.
 * If `true`, cached packages are used.
 * If `false`, packages pulled from the network.
*/
bool offline;

/**
 * Set by the commandline --debug flag.
 * If `true`, the temporary directory is not deleted after running.
 * If `false`, the temporary directory is deleted after running.
*/
bool debug;

/**
 * The [List] of [Task]s as a result of parsing through the commandline arguments.
 * Forms the basis for subsequent building and running.
 */
var taskList = [];

void main(List<String> args) {

  hierarchicalLoggingEnabled = true;

  // Set default Logger.level to Level.INFO.
  log.level = Level.INFO;

  // Allow setting the Logger.level to FINE or INFO.
  parser.addOption("loglevel", defaultsTo:'info', allowed:logLevelMap.keys, abbr:'l');
  
  // Determines whether task and hop packages are pulled from local cache or from accessing the network.
  parser.addFlag("offline", abbr:'o', help: "Use cached packages instead of accessing the network.");
  
  // Determines whether to delete the temporary directory after all tasks are processed.
  parser.addFlag("debug", abbr:'d', help: "Does not delete temporary directory.");
  
  parser.addFlag("help", help: "Displays this message.");

  // Task specific option to define the pub package type that defines the task.  Follows pubspec.yaml convention.
  taskParser.addOption("type", defaultsTo:'pub', allowed:['pub','path','git','hosted'], abbr:'t');
  
  // Task specific option that defines the name of the package if needed.
  taskParser.addOption("name", abbr: 'n');

  log.onRecord.listen((LogRecord record){
    print("${record.loggerName}: ${record.message}");
  });

  // If arguments parse successfully without error, then kick off the process.
  if(_parseArgs(args)) _hop();

}

/// Main method for building and running each [Task] in [taskList] using [HopRunner].
void _hop() {
  var hop_runner = new HopRunner(taskList);
  hop_runner.log = log;
  hop_runner.offline = offline;
  hop_runner.debug = debug;
  hop_runner.run();
}

/// Parses main and [Task] specific arguments from the commandline.
bool _parseArgs(List<String> args) {
  
  // Default the parsing result success to `true`.
  bool parseResult = true;
  
  /* 
    Allocate two Lists for the main and Task specific arguments, respectively.
    By default we fill taskargs with all the arguments. We will later remove 
    the main hop arguments from taskargs as they are found.
  */
  var hopargs = [];
  var taskargs = new List.from(args);

  // Print usage information if there are no provided arguments at the commandline.
  if(args.isEmpty) {
    print(_getUsage());
    parseResult = false;
  } else {
    // The following allocates arguments into main or Task specific.
    // First iterate through each main parser options/flags.
    parser.options.forEach((name, option){
      
      var abbr = option.abbreviation;
      var isFlag = option.isFlag;
      
      // Acquire index of the main option/flag within the args List.
      int index = [args.indexOf("--$name"), args.indexOf("-$abbr")].firstWhere((item) => item!= -1, orElse:() => -1);
      
      // Allocate the args element into hopargs if main option/flag found.
      if(index != -1) {
        hopargs.add(args[index]);
        if(!isFlag) hopargs.add(args[index+1]);
      }
      
    });

    // Remove any args that are main arguments.
    taskargs.removeWhere((item) => hopargs.contains(item));

    // Parse the main hop arguments.
    var results = parser.parse(hopargs);

    if(results["help"]){ 
      print(_getUsage());
      parseResult = false;
    } else {
    
      // Handle the main arguments.
      log.level = logLevelMap[results["loglevel"]];
      offline = results["offline"];
      debug = results["debug"];
      log.fine("offline: $offline");
      
      /*
        The algorithm then parses the sets of task specific arguments.
        Each set is separated by comma.
      */
      var taskargsets = taskargs.join(" ").split(',');
      log.fine("taskargs: $taskargsets");
      
      // Iterate through each set and parse the task specific arguments.
      taskargsets.forEach((String taskarg){
        
        // Remove trailing spaces from a task argument set.
        taskarg = taskarg.trim();
        log.fine("taskarg: $taskarg");
        
        // Parse task specific arguments.
        var taskResults = taskParser.parse(taskarg.split(' '));
        var rest = taskResults.rest;
        log.fine("rest: $rest");
        
        var type = taskResults["type"];
        var name = taskResults["name"];
        var source = rest.first;
        var args = rest.length > 1 ? rest.sublist(1).join(" ") : "";
        
        log.fine("type: $type");
        log.fine("name: $name");
        log.fine("source: $source");
        
        // Build [Task] from parsed task specific arguments.
        var task = new Task.from(name, type, source, args);
        if(task==null) {
          print("Task was not properly parsed.\n");
        } else {
          log.fine(task.toJson());
          taskList.add(task);
        }
  
      });

      if(taskList.isEmpty) {
        print(_getUsage());
        parseResult = false;
      }
    }

  }

  return parseResult;
}

/// Get usage information.
String _getUsage() {
  return "Usage: hop [<options>] <pub-task> [<pub-task>, ...]\n\n<pub-task>: [<pub-task-options>] [<name>, <url>, <path>]\n   -t, --type: [pub (default), hosted, git, path]\n   -n, --name: Repository name.\n\n${parser.getUsage()}";
}