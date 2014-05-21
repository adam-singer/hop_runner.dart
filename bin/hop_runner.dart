import 'dart:io';
import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:hop_runner/hop_runner.dart';

final parser = new ArgParser();
final taskParser = new ArgParser();
final log = new Logger("hop");
bool offline;
var taskList = [];

void main(List<String> args) {

  hierarchicalLoggingEnabled = true;

  log.level = Level.INFO;

  parser.addOption("loglevel", defaultsTo:'info', allowed:['info','fine'], abbr:'l');
  parser.addFlag("offline", abbr:'o', help: "Use cached packages instead of accessing the network.");
  parser.addFlag("help", help: "Displays this message.");

  taskParser.addOption("type", defaultsTo:'pub', allowed:['pub','path','git','hosted'], abbr:'t');
  taskParser.addOption("name", abbr: 'n');


  log.onRecord.listen((LogRecord record){
    print("${record.loggerName}: ${record.message}");
  });

  if(_parseArgs(args)) _hop();

}

void _hop() {
  var hop_runner = new HopRunner(taskList);
  hop_runner.log = log;
  hop_runner.offline = offline;
  hop_runner.run();
}

bool _parseArgs(List<String> args) {
  bool parseResult = true;
  var hopargs = [];
  var taskargs = new List.from(args);

  if(args.isEmpty) {
    print(_getUsage());
  } else {
    parser.options.forEach((name, option){
      
      var abbr = option.abbreviation;
      var isFlag = option.isFlag;
      int index = [args.indexOf("--$name"), args.indexOf("-$abbr")].firstWhere((item) => item!= -1, orElse:() => -1);
      if(index != -1) {
        hopargs.add(args[index]);
        if(!isFlag) hopargs.add(args[index+1]);
      }
      
    });

    taskargs.removeWhere((item) => hopargs.contains(item));

    var results = parser.parse(hopargs);

    if(results["help"]) print(_getUsage());
    else {
      log.level = results["loglevel"] == "fine" ? Level.FINE : Level.INFO;
      offline = results["offline"];
      log.fine("offline: $offline");
      var taskargsets = taskargs.join(" ").split(',');
      log.fine("taskargs: $taskargsets");
      taskargsets.forEach((String taskarg){
        taskarg = taskarg.trim();
        log.fine("taskarg: $taskarg");
        var taskResults = taskParser.parse(taskarg.split(' '));
        var type = taskResults["type"];
        var name = taskResults["name"];
        var source = taskResults.rest.first;
        log.fine("type: $type");
        log.fine("name: $name");
        log.fine("source: $source");

        // TODO parse task arguments.
        var task = new Task.from(name, type, source, "");
        log.fine(task.toJson());

        taskList.add(task);
      });
    }

  }

  return parseResult;
}



String _getUsage() {
  return "Usage: hop [<options>] <pub-task> [<pub-task>, ...]\n\n<pub-task>: [<pub-task-options>] [<name>, <url>, <path>]\n   -t, --type: [pub (default), hosted, git, path]\n   -n, --name: Repository name.\n\n${parser.getUsage()}";
}