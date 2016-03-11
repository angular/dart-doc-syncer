import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:logging/logging.dart';
import 'package:dart_doc_syncer/src/generate_doc.dart';

final logger = new Logger('update_doc_repo');

final String basePath = p.dirname(Platform.script.path);
const String angularRepository = 'https://github.com/angular/angular.io';

/// Updates [outRepository] based on the content of the example under
/// [examplePath] in the angular.io repository.
Future updateDocRepo(String examplePath, String outRepository) async {
  try {
    // Clone content of angular repo into tmp folder.
    final tmpAngularPath = p.join(basePath, '.tmp/angular_io');
    await cloneInto(angularRepository, tmpAngularPath);

    // Clone [outRepository] into tmp folder.
    final outPath = p.join(basePath, '.tmp/example_out');
    await cloneInto(outRepository, outPath);

    // Remove existing content as we will generate an updated version.
    await Process.run('git', ['rm', '*'], workingDirectory: outPath);

    logger.fine('Generating updated example application into $outPath.');
    final exampleFolder = p.join(tmpAngularPath, examplePath);
    await assembleDocumentationExample(
        new Directory(exampleFolder), new Directory(outPath));

    // --
    // TODO: Everything is in place, rm angular.io doc comments + generate README.
    // --

    // Push the new content to [outRepository].
    logger.fine('Pushing generated example to $outRepository');
    await pushContent(outPath);
  } finally {
    // Clean up .tmp folder
    await new Directory(p.join(basePath, '.tmp')).delete(recursive: true);
  }
}

/// Clones the [repository] into the [directory].
Future cloneInto(String repository, String directory) async {
  logger.fine('Cloning $repository into $directory');
  await assertSuccess(
      () => Process.run('git', ['clone', repository, directory]));
}

/// Stages, commits and pushes local changes to origin for [repositoryPath].
pushContent(String repositoryPath) async {
  logger.fine('Staging local changes for $repositoryPath');
  await assertSuccess(
      () => Process.run('git', ['add', '.'], workingDirectory: repositoryPath));

  logger.fine('Comitting changes for $repositoryPath');
  await assertSuccess(() => Process.run('git', ['commit', '-m' '"Update..."'],
      workingDirectory: repositoryPath));

  logger.fine('Pushing changes for $repositoryPath');
  await assertSuccess(
      () => Process.run('git', ['push'], workingDirectory: repositoryPath));
}

/// Throws if the exitCode returned by [gitCommand] is not 0.
Future assertSuccess(Future gitCommand()) async {
  final r = await gitCommand();
  if (r.exitCode != 0) throw r.stderr;
}

main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });

  await updateDocRepo('public/docs/_examples/template-syntax/dart',
      'https://github.com/thso/dart-doc-syncer-test');

  print('Done!');
}
