part of hop_runner;

abstract class Task {
  /// The name of the pub package cooresponding to the task. Must match the name in its pubspec.yaml.
  String name;
  
  /// Variably typed and depends on the Task type: path, git, hosted.
  var source;
  
  /// Arguments parsed and passed from the commandline when the Task is built.
  String args;
  
  /// The task type parsed from the commandline: [pub (default), hosted, git, path].
  String type;
  
  /// The version of the pub package cooresponding to the task.
  String version;

  Task(this.name, this.source, this.args, this.type, {this.version:"any"});

  /// Factory constructor to return a [Task] based on the type.
  factory Task.from(String name, String type, var source, String args, String version) {
    args = args.trim();
    switch (type) {
    
      // Build a [Task] from a pub package published on pub.dartlang.org.
      case 'pub':
        return new PubTask(name, args, version:version);
        break;

      // Build a [Task] from in a directory pub package.
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

      // Build a [Task] from a pub package from a git repo.
      case 'git':
        return new GitTask(name, source, args);
        break;

      // Build a [Task] from a hosted pub package.
      case 'hosted':
        return new HostedTask(name, source, args, version);
        break;
    }
  }

  /// The dependencies specific to the Task type definition.
  List<Dependency> get dependencies => _deriveDependencies();
  List<Dependency> _deriveDependencies();

  /// The call to the [Task] written to the `tool/hop_runner.dart` file by [HopBuilder].
  String get call => _deriveCall();

  String _deriveCall() {
    return "addTask('$name', $name.createDefaultTask());\n";
  }

  /// The import to write to `tool/hop_runner.dart` file by [HopBuilder].
  String get import => _deriveImport();

  String _deriveImport() {
    return "import 'package:$name/$name.dart' as $name;\n";
  }

  /// Runs the built [Task] from [HopRunner].
  Future<Process> run(Directory dir) {
    
    var processArgs = ['tool/hop_runner.dart', name];
    if(args.length > 0) processArgs.add(args);
    return Process.start('dart', processArgs, workingDirectory:dir.absolute.path);
  }

  /// Used for debugging purposes, currently written to log.
  Map toJson() {
    return {
      "name": name,
      "source": source,
      "args": args
    };
  }
}

/// Implementation of the directory type pub package [Task].
class DirectoryTask extends Task {

  DirectoryTask(String name, Directory source, String args) : super(name, source, args, 'path');

  /// Implementation of [Task.dependencies]
  List<Dependency> _deriveDependencies() {
    return [new Dependency(name, "path", {
        "path": source.absolute.path
      })];
  }
}

/// Implementation of the pub type [Task].
class PubTask extends Task {
  
  PubTask(String name, String args, {String version:"any"}) : super(name, '', args, 'pub', version:version);
  
  /// Implementation of [Task.dependencies]
  List<Dependency> _deriveDependencies() {
    return [new Dependency(name, "pub", {}, version:version)];
  }
}

/// Implementation of the git type [Task].
class GitTask extends Task {
  
  GitTask(String name, Map source, String args) : super(name, source, args, 'git');
  
  /// Implementation of [Task.dependencies]
  List<Dependency> _deriveDependencies() {
    return [new Dependency(name, "git", source)];
  }
}

/// Implementation of the hosted type [Task].
class HostedTask extends Task {
  
  HostedTask(String name, Map source, String args, {String version:"any"}) : super(name, source, args, 'hosted', version:version);
  
  /// Implementation of [Task.dependencies]
  List<Dependency> _deriveDependencies() {
    return [new Dependency(name, "hosted", source)];
  }
}