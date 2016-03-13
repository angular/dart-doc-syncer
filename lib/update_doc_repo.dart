import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:logging/logging.dart';

import 'package:dart_doc_syncer/src/generate_doc.dart';
import 'package:dart_doc_syncer/src/git_repository.dart';
import 'package:dart_doc_syncer/src/remove_doc_tags.dart';

final logger = new Logger('update_doc_repo');

final String basePath = p.dirname(Platform.script.path);
const String angularRepositoryUri = 'https://github.com/angular/angular.io';

/// Updates [outRepository] based on the content of the example under
/// [examplePath] in the angular.io repository.
Future updateDocRepo(String examplePath, String outRepositoryUri) async {
  try {
    // Clone content of angular repo into tmp folder.
    final tmpAngularPath = p.join(basePath, '.tmp/angular_io');
    final angularRepository = new GitRepository(tmpAngularPath);
    await angularRepository.cloneFrom(angularRepositoryUri);

    // Clone [outRepository] into tmp folder.
    final outPath = p.join(basePath, '.tmp/example_out');
    final outRepository = new GitRepository(outPath);
    await outRepository.cloneFrom(outRepositoryUri);

    // Remove existing content as we will generate an updated version.
    await outRepository.deleteAll();

    logger.fine('Generating updated example application into $outPath.');
    final exampleFolder = p.join(tmpAngularPath, examplePath);
    await assembleDocumentationExample(
        new Directory(exampleFolder), new Directory(outPath));

    // Clean the application code
    logger.fine('Cleaning files in $outRepository');
    await removeDocTagsFromApplication(outPath);

    // Push the new content to [outRepository].
    logger.fine('Pushing generated example to $outRepositoryUri');
    await outRepository.pushContent(message: "Update...");
  } finally {
    // Clean up .tmp folder
    await new Directory(p.join(basePath, '.tmp')).delete(recursive: true);
  }
}

/// Rewrites all files under the [path] directory by filtering out the
/// documentation tags.
Future removeDocTagsFromApplication(String path) async {
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

main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });

  await updateDocRepo('public/docs/_examples/template-syntax/dart',
      'https://github.com/thso/dart-doc-syncer-test');

  print('Done!');
}
