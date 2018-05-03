import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import 'generate_readme.dart';
import 'options.dart';
import 'remove_doc_tags.dart';
import 'runner.dart' as Process; // TODO(chalin) tmp name to avoid code changes
import 'util.dart';

final Logger _logger = new Logger('update_doc_repo');

const whitelist = const ['.css', '.dart', '.html', '.yaml'];

/// Clears the [out] example repo root and creates fresh content from [webdev].
Future refreshExampleRepo(Directory webdev, Directory out,
    {final /*out*/ List<Directory> appRoots, String webdevNgPath}) async {
  out.createSync(recursive: false);

  // Add all files from webdev folder.
  await Process.run('cp', ['-a', p.join(webdev.path, '.'), out.path]);

  assert(appRoots.isEmpty);
  appRoots.addAll(getAppRoots(out));

  for (var appRoot in appRoots) {
    await _refreshExample(webdev, appRoot, webdevNgPath: webdevNgPath);
  }
  await generateReadme(out.path, webdevNgPath: webdevNgPath);
}

Future _refreshExample(Directory snapshot, Directory out,
    {String webdevNgPath}) async {
  // Remove unimportant files that would distract the user.
  await Process.run('rm', [
    '-f',
    p.join(out.path, 'example-config.json'),
    p.join(out.path, 'e2e-spec.ts')
  ]);

  // Remove source files used solely in support of the prose.
  final targetFiles = whitelist.map((ext) => '-name *_[0-9]$ext').join(' -o ');
  await Process.run('find',
      [out.path]..addAll('( $targetFiles ) -exec rm -f {} +'.split(' ')));

  await _addBoilerplateFiles(snapshot.parent, out);

  // Clean the application code
  _logger.fine('Removing doc tags in ${out.path}.');
  await _removeDocTagsFromApplication(out.path);

  // Format the Dart code
  _logger.fine('Running dartfmt in ${out.path}.');
  await Process.run('dartfmt', ['-w', p.absolute(out.path)]);
}

Future<void> _addBoilerplateFiles(Directory exDir, Directory target) async {
  for (final boilerPlateDir in _findBoilerPlateDir(exDir)) {
    await Process.run('cp', ['-a', '${boilerPlateDir.path}/', target.path]);
  }
}

Iterable<Directory> _findBoilerPlateDir(Directory dir,
    {bool searchParentDir = true}) sync* {
  final entities = dir.listSync(followLinks: false);
  for (var fsEntity in entities) {
    if (fsEntity is! Directory) continue;
    if (p.basename(fsEntity.path) == '_boilerplate') yield fsEntity;
  }
  if (!searchParentDir) return;
  final parent = dir.parent;
  if (parent == null) return;
  yield* _findBoilerPlateDir(parent,
      searchParentDir: p.basename(parent.path) != docExampleDirRoot);
}

/// Rewrites all files under the [path] directory by filtering out the
/// documentation tags.
Future _removeDocTagsFromApplication(String path) async {
  if (Process.options.dryRun) return new Future.value(null);

  final files = await new Directory(path)
      .list(recursive: true, followLinks: false)
      .where((e) => e is File && !e.path.contains('/.'))
      .toList();
  _logger.finer('>> Files to be stripped of doctags: ${files.join('\n  ')}');
  return Future.wait(files.map(_removeDocTagsFromFile));
}

/// Rewrites the [file] by filtering out the documentation tags.
Future _removeDocTagsFromFile(FileSystemEntity file) async {
  if (file is File) {
    if (whitelist.every((String e) => !file.path.endsWith(e))) return null;

    final content = await file.readAsString();
    final cleanedContent = removeDocTags(content);

    if (content == cleanedContent) return null;

    return file.writeAsString(cleanedContent);
  }
  return null;
}
