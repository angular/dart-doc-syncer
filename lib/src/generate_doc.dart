import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

final String basePath = p.dirname(Platform.script.path);
final String defaultAssetsPath = p.join(basePath, "../default_assets");

/// Generates a clean documentation application folder based on the raw content
/// at [snaphsot].
Future assembleDocumentationExample(Directory snapshot, Directory out) async {
  out.createSync(recursive: false);

  // Add default assets first.
  await Process.run('cp', ['-a', p.join(defaultAssetsPath, '.'), out.path]);

  // Add all files from snapshot folder.
  await Process.run('cp', ['-a', p.join(snapshot.path, '.'), out.path]);
}

main() {
  assembleDocumentationExample(
      new Directory(p.join(basePath, '../examples/1/new')),
      new Directory(p.join(basePath, '../examples/1/out')));
}
