part of hop_runner;

abstract class Task {
  String name;
  var source;
  String args;

  Task(this.name, this.source, this.args);

  factory Task.from(String name, String type, var source, String args) {
    args = args.trim();
    switch (type) {
      case 'pub':
        break;

      case 'path':

        // Remove '/' at the end of the source path.
        source = source.endsWith('/') ? source.substring(0, source.length - 1) :
            source;

        // Derive name from source if name is null
        if (name == null) name = source.split('/').last;

        var dir = new Directory(source);

        bool exists = dir.existsSync();
        if (exists) return new DirectoryTask(name, dir, args); else throw
            new Exception("${dir.path} does not exist.");
        break;

      case 'git':
        break;

      case 'hosted':
        break;
    }
  }


  List<Dependency> get dependencies => _deriveDependencies();
  List<Dependency> _deriveDependencies();

  String get call => _deriveCall();

  String _deriveCall() {
    return "addTask('$name', $name.createDefaultTask());\n";
  }

  String get import => _deriveImport();

  String _deriveImport() {
    return "import 'package:$name/$name.dart' as $name;\n";
  }

  Future<Process> run(Directory dir) {
    
    var processArgs = ['tool/hop_runner.dart', name];
    if(args.length > 0) processArgs.add(args);
    return Process.start('dart', processArgs, workingDirectory:dir.absolute.path);
  }

  Map toJson() {
    return {
      "name": name,
      "source": source,
      "args": args
    };
  }
}

class DirectoryTask extends Task {

  DirectoryTask(String name, Directory source, String args) : super(name, source,
      args);


  List<Dependency> _deriveDependencies() {
    return [new Dependency(name, "path", {
        "path": source.absolute.path
      })];
  }
}
