import 'package:path/path.dart' as p;

const docExampleDirRoot = 'examples/ng/doc';

class Example2Uri {
  final String _exampleName;

  Example2Uri(this._exampleName);

  String get path => p.join(docExampleDirRoot, _exampleName);

  String get repositoryUri =>
      'git@github.com:angular-examples/$_exampleName.git';
}

/// [path] is assumed to be of the form '$docExampleDirRoot/$_exampleName';
/// returns <exampleName>.
String getExampleName(String path) {
  assert (path.startsWith(docExampleDirRoot));
  var name = p.basename(path);
  assert (name.isNotEmpty);
  return name;
}
