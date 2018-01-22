import 'package:path/path.dart' as p;

import 'options.dart';

class Example2Uri {
  final String _relativePath;
  final String exampleName;

  Example2Uri(String path)
      : _relativePath = getExamplePath(path),
        exampleName = getExampleName(path);

  // Path of example relative to [docExampleDirRoot].
  String get path => p.join(docExampleDirRoot, _relativePath);

  String get repositoryUri =>
      'https://github.com/angular-examples/$exampleName.git';
}

/// [path] is assumed to be of the form '[docExampleDirRoot]/.../exampleName';
/// returns exampleName.
String getExampleName(String path) {
  assert(path.startsWith(docExampleDirRoot), 'path is $path');
  var name = p.basename(path);
  assert(name.isNotEmpty);
  return name;
}

/// [path] is assumed to start with [docExampleDirRoot].
/// returns the part of the path after [docExampleDirRoot].
String getExamplePath(String path) {
  assert(path.startsWith(docExampleDirRoot));
  var result = path.substring(docExampleDirRoot.length);
  if (result.startsWith('/')) result = result.substring(1);
  return result;
}
