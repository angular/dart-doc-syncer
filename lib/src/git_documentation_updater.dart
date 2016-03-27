import 'dart:async';
import 'dart:io';

import 'package:dart_doc_syncer/documentation_updater.dart';
import 'package:path/path.dart' as p;
import 'package:logging/logging.dart';

import 'git_repository.dart';
import 'generate_doc.dart';

final Logger _logger = new Logger('update_doc_repo');

final String _basePath = p.dirname(Platform.script.path);
const String _angularRepositoryUri = 'https://github.com/angular/angular.io';

class GitDocumentationUpdater implements DocumentationUpdater {
  final GitRepositoryFactory _gitFactory;

  GitDocumentationUpdater(this._gitFactory);

  @override
  Future updateRepository(String examplePath, String outRepositoryUri,
      {bool push: true, bool clean: true, String commitMessage: "Sync"}) async {
    try {
      // Clone content of angular repo into tmp folder.
      final tmpAngularPath = p.join(_basePath, '.tmp/angular_io');
      final angularRepository = _gitFactory.create(tmpAngularPath);
      await angularRepository.cloneFrom(_angularRepositoryUri);

      // Clone [outRepository] into tmp folder.
      final outPath = p.join(_basePath, '.tmp/example_out');
      final outRepository = _gitFactory.create(outPath);
      await outRepository.cloneFrom(outRepositoryUri);

      // Remove existing content as we will generate an updated version.
      await outRepository.deleteAll();

      _logger.fine('Generating updated example application into $outPath.');
      final exampleFolder = p.join(angularRepository.directory, examplePath);
      await assembleDocumentationExample(
          new Directory(exampleFolder), new Directory(outRepository.directory),
          angularIoPath: examplePath);

      if (push) {
        // Push the new content to [outRepository].
        _logger.fine('Pushing generated example to $outRepositoryUri.');
        await outRepository.pushContent(message: commitMessage);
      }
    } on GitException catch (e) {
      _logger.severe(e.message);
    } finally {
      if (clean) {
        // Clean up .tmp folder
        await new Directory(p.join(_basePath, '.tmp')).delete(recursive: true);
      }
    }
  }
}
