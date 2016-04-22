import 'dart:async';
import 'dart:io';

import 'package:dart_doc_syncer/documentation_updater.dart';
import 'package:dart_doc_syncer/src/generate_gh_pages.dart';
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

      // Only clone into the repository if the directory is not already there.
      if (!new Directory(angularRepository.directory).existsSync()) {
        await angularRepository.cloneFrom(_angularRepositoryUri);
      }

      // Clone [outRepository] into tmp folder.
      final exampleName = p.basename(p.dirname(examplePath));
      final outPath = p.join(_basePath, '.tmp/${exampleName}');
      final outRepository = _gitFactory.create(outPath);
      await outRepository.cloneFrom(outRepositoryUri);

      // Remove existing content as we will generate an updated version.
      await outRepository.deleteAll();

      _logger.fine('Generating updated example application into $outPath.');
      final exampleFolder = p.join(angularRepository.directory, examplePath);
      await assembleDocumentationExample(
          new Directory(exampleFolder), new Directory(outRepository.directory),
          angularDirectory: new Directory(angularRepository.directory),
          angularIoPath: examplePath);

      await _updateMaster(outRepository, commitMessage, push);
      await _updateGhPages(outRepository, exampleName, push);
    } on GitException catch (e) {
      _logger.severe(e.message);
    } finally {
      if (clean) {
        // Clean up .tmp folder
        await new Directory(p.join(_basePath, '.tmp')).delete(recursive: true);
      }
    }
  }

  /// Updates the master branch with the latest cleaned example application
  /// code.
  Future _updateMaster(GitRepository repo, String message, bool push) async {
    repo.updateMaster(message: message);

    if (push) {
      // Push the new content to [outRepository].
      _logger.fine('Pushing to master branch.');
      await repo.pushCurrent();
    }
  }

  /// Updates the gh-pages branch with the latest compiled code.
  Future _updateGhPages(GitRepository repo, String name, bool push) async {
    // Generate the application assets into the gh-pages branch.
    String applicationAssetsPath =
        await generateApplication(new Directory(repo.directory), name);
    await repo.updateGhPages(applicationAssetsPath);

    if (push) {
      // Push the new content to [outRepository].
      _logger.fine('Pushing to gh-pages branch for example "$name".');
      await repo.pushGhPages();
    }
  }
}
