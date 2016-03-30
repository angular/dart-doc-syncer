import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import 'package:dart_doc_syncer/src/generate_readme.dart';
import 'package:dart_doc_syncer/src/remove_doc_tags.dart';

final Logger _logger = new Logger('update_doc_repo');

final String _basePath = p.dirname(Platform.script.path);
final String _defaultAssetsPath = p.join(_basePath, "../default_assets");

/// Generates a clean documentation application folder based on the raw content
/// at [snaphsot].
Future assembleDocumentationExample(Directory snapshot, Directory out,
    {Directory angularDirectory, String angularIoPath}) async {
  out.createSync(recursive: false);

  // Add default assets first.
  await Process.run('cp', ['-a', p.join(_defaultAssetsPath, '.'), out.path]);

  // Add all files from snapshot folder.
  await Process.run('cp', ['-a', p.join(snapshot.path, '.'), out.path]);

  // Add the common styles file.
  await Process.run('cp', [
    p.join(angularDirectory.path, 'public/docs/_examples/styles.css'),
    p.join(out.path, 'web/styles.css')
  ]);

  // Clean the application code
  _logger.fine('Removing doc tags in $out.path.');
  await _removeDocTagsFromApplication(out.path);

  // Generate a README file
  generateReadme(out.path, angularIoPath: angularIoPath);
}

/// Rewrites all files under the [path] directory by filtering out the
/// documentation tags.
Future _removeDocTagsFromApplication(String path) async {
  final files = await new Directory(path)
      .list(recursive: true)
      .where((e) => e is File)
      .toList();
  return Future.wait(files.map(_removeDocTagsFromFile));
}

/// Rewrites the [file] by filtering out the documentation tags.
Future _removeDocTagsFromFile(File file) async {
  const whitelist = const ['.html', '.dart', '.yaml'];
  if (whitelist.every((String e) => !file.path.endsWith(e))) return null;

  final content = await file.readAsString();
  final cleanedContent = removeDocTags(content);

  if (content == cleanedContent) return null;

  return file.writeAsString(cleanedContent);
}
