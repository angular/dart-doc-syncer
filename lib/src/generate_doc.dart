import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import 'package:dart_doc_syncer/src/generate_readme.dart';
import 'package:dart_doc_syncer/src/remove_doc_tags.dart';

import 'runner.dart' as Process; // TODO(chalin) tmp name to avoid code changes

final Logger _logger = new Logger('update_doc_repo');

final String _basePath = p.dirname(Platform.script.path);
final String _defaultAssetsPath = p.join(_basePath, "../default_assets");

const whitelist = const ['.css', '.dart', '.html', '.yaml'];

/// Generates a clean documentation application folder based on the raw content
/// at [snaphsot].
Future assembleDocumentationExample(Directory snapshot, Directory out,
    {Directory angularDirectory, String webdevNgPath}) async {
  out.createSync(recursive: false);

  // Add default assets first.
  await Process.run('cp', ['-a', p.join(_defaultAssetsPath, '.'), out.path]);

  // Add all files from snapshot folder.
  await Process.run('cp', ['-a', p.join(snapshot.path, '.'), out.path]);

  // Remove unimportant files that would distract the user.
  await Process.run('rm', [
    '-f',
    p.join(out.path, '.analysis_options'),
    p.join(out.path, 'example-config.json')
  ]);

  // Remove source files used solely in support of the prose.
  final targetFiles =
      whitelist.map((ext) => '-name *_[0-9]$ext').join(' -o ');
  await Process.run('find',
      [out.path]..addAll('( $targetFiles ) -exec rm -f {} +'.split(' ')));

  // Add the common styles file.
  await Process.run('cp', [
    p.join(angularDirectory.path, 'public/docs/_examples/_boilerplate/styles.css'),
    p.join(out.path, 'web/styles.css')
  ]);

  // Clean the application code
  _logger.fine('Removing doc tags in ${out.path}.');
  await _removeDocTagsFromApplication(out.path);

  // Generate a README file
  await generateReadme(out.path, webdevNgPath: webdevNgPath);

  // Format the Dart code
  _logger.fine('Running dartfmt in ${out.path}.');
  await Process.run('dartfmt', ['-w', p.absolute(out.path)]);
}

/// Rewrites all files under the [path] directory by filtering out the
/// documentation tags.
Future _removeDocTagsFromApplication(String path) async {
  if (Process.options.dryRun) return new Future.value(null);

  final files = await new Directory(path)
      .list(recursive: true)
      .where((e) => e is File)
      .toList();
  return Future.wait(files.map(_removeDocTagsFromFile));
}

/// Rewrites the [file] by filtering out the documentation tags.
Future _removeDocTagsFromFile(File file) async {
  if (whitelist.every((String e) => !file.path.endsWith(e))) return null;

  final content = await file.readAsString();
  final cleanedContent = removeDocTags(content);

  if (content == cleanedContent) return null;

  return file.writeAsString(cleanedContent);
}
