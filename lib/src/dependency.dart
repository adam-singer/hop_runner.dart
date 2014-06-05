part of hop_runner;

class Dependency {

  /// Name of the dependency.
  String name;
  
  /// Type of dependency (path, hosted, pub, git).
  String type;
  
  /// Data defining the dependency.
  Map<String, dynamic> data;
  
  /// The version of the dependency.
  String version;

  final String TAB = "   ";

  Dependency(this.name, this.type, this.data, {this.version:"any"});

  String toString() {
    String _pubEntry;
    switch(type) {
    
      case "pub":
        _pubEntry = TAB + name + ": $version\n";
      break;
      
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
          TAB + name + ":\n" + 
          TAB + TAB + "hosted:\n" +
          TAB + TAB + TAB + "name: " + "$name\n" +
          TAB + TAB + TAB + "url: " + data["url"] + "\n" +
          TAB + TAB + "version: $version";
      break;
      
      case "git":
        /*
         *   kittens:
         *      git: git://github.com/munificent/kittens.git
         *
         *   kittens:
         *      url:
         *         url: git://github.com/munificent/kittens.git
         *         ref: some-branch
         */
         _pubEntry = TAB + name + ":\n";
         if(data.containsKey("ref")) {
           _pubEntry = _pubEntry +
           TAB + TAB + "git: \n" +
           TAB + TAB + TAB + "url: " + data["url"] + "\n" +
           TAB + TAB + TAB + "ref: " + data["ref"] + "\n";           
         } else {
           _pubEntry = _pubEntry +
           TAB + TAB + "git: " + data["url"] + "\n";
         }
           
      break;      

    }
    return _pubEntry;
  }
}