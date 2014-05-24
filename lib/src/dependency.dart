part of hop_runner;

class Dependency {
  final String TAB = "  ";
  // Name of the dependency
  final String name;
  // Type of dependency (path, hosted, pub, git)
  final String type;
  // Data:
  Map<String, dynamic> data;

  Dependency(this.name, this.type, this.data);

  String toString() {
    String _pubEntry;
    switch(type) {
      case "path":
        _pubEntry =
            TAB + name + ":\n" +
            TAB + TAB + "path: " + data["path"] + "\n";
        break;
    }
    return _pubEntry;
  }
}