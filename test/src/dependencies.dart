import 'package:unittest/unittest.dart';
import 'package:hop_runner/hop_runner.dart';

main() {
  Dependency pathDependency = new Dependency("awesomeDep", "path",
      {"path":"/path/to/my/dependency"});
  String okPathDependency =
"""  awesomeDep:
    path: /path/to/my/dependency
""";

  Dependency hostedDependency = new Dependency("awesomeDep", "hosted",
      {"hosted":});
  test('Path dependency', () {
    expect(pathDependency.toString(), equals(okPathDependency));
  });
}