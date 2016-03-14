import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import 'package:dart_doc_syncer/src/remove_doc_tags.dart';

final Logger _logger = new Logger('update_doc_repo');

final String _basePath = p.dirname(Platform.script.path);
final String _defaultAssetsPath = p.join(_basePath, "../default_assets");

/// Generates a clean documentation application folder based on the raw content
/// at [snaphsot].
Future assembleDocumentationExample(Directory snapshot, Directory out) async {
  out.createSync(recursive: false);

  // Add default assets first.
  await Process.run('cp', ['-a', p.join(_defaultAssetsPath, '.'), out.path]);

  // Add all files from snapshot folder.
  await Process.run('cp', ['-a', p.join(snapshot.path, '.'), out.path]);

  // Clean the application code
  _logger.fine('Removing doc tags in $out.path.');
  await _removeDocTagsFromApplication(out.path);
}

/// Rewrites all files under the [path] directory by filtering out the
/// documentation tags.
Future _removeDocTagsFromApplication(String path) async {
  final files =
      new Directory(path).list(recursive: true).where((e) => e is File);
  await for (File file in files) {
    if (!file.path.endsWith('.html') && !file.path.endsWith('.dart')) continue;

    final content = await file.readAsString();
    final cleanedContent = removeDocTags(content);

    if (content == cleanedContent) continue;

    await file.writeAsString(cleanedContent);
  }
}
