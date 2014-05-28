part of hop_runner;

class Dependency {
  final String TAB = "   ";
  // Name of the dependency
  String name;
  // Type of dependency (path, hosted, pub, git)
  String type;
  // Data:
  Map<String, dynamic> data;


  Dependency(this.name, this.type, this.data);

  // Named constructors?
  Dependency.path() {}
  Dependency.git() {}
  Dependency.hosted() {}

  String toString() {
    String _pubEntry;
    switch(type) {
      case "path":
        /*
         *   transmogrify:
         *     path: /Users/me/transmogrify
         */
        _pubEntry =
            TAB + name + ":\n" +
            TAB + TAB + "path: " + data["path"] + "\n";
        break;
      case "hosted":
        /*
         *   transmogrify:
         *     hosted:
         *       name: transmogrify
         *       url: http://your-package-server.com
         *     version: '>=0.4.0 <1.0.0'
         */
        _pubEntry =
          TAB + name + ":\n";
    }
    return _pubEntry;
  }
}