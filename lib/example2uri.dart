import 'package:path/path.dart' as p;

class Example2Uri {
  final String _exampleName;

  Example2Uri(this._exampleName);

  String get path => 'public/docs/_examples/$_exampleName/dart';

  String get repositoryUri =>
      'git@github.com:angular-examples/$_exampleName.git';
}

/// [path] is assumed to be of the form
/// 'public/docs/_examples/<exampleName>/dart';
/// returns <exampleName>.
String getExampleName(String path) {
  assert (p.basename(path) == 'dart');
  var name = p.basename(p.dirname(path));
  assert (name.isNotEmpty);
  return name;
}
