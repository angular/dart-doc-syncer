import 'dart:async';
import 'dart:io';

import 'package:dart_doc_syncer/documentation_updater.dart';
import 'package:dart_doc_syncer/example2uri.dart';
import 'package:dart_doc_syncer/src/generate_gh_pages.dart';
import 'package:path/path.dart' as p;
import 'package:logging/logging.dart';

import 'git_repository.dart';
import 'generate_doc.dart';
import 'options.dart';
import 'util.dart';

final Logger _logger = new Logger('update_doc_repo');

class GitDocumentationUpdater implements DocumentationUpdater {
  final GitRepositoryFactory _gitFactory;
  final String _angularRepositoryUri =
      'https://github.com/${options.user}/site-webdev';

  GitDocumentationUpdater(this._gitFactory);

  @override
  Future<int> updateMatchingRepo(RegExp re, {bool push, bool clean}) async {
    int updateCount = 0;
    try {
      var angularRepository = await _cloneAngularRepoIntoTmp();
      final files = await new Directory(angularRepository.directory)
          .list(recursive: true)
          .where(
              (e) => e is File && p.basename(e.path) == exampleConfigFileName)
          .toList();
      for (var e in files) {
        var dartDir = p.dirname(e.path);
        var exampleName = getExampleName(dartDir);
        if (re.hasMatch(e.path)) {
          var e2u = new Example2Uri(exampleName);
          var updated = await updateRepository(e2u.path, e2u.repositoryUri,
              clean: clean, push: push);
          if (updated) updateCount++;
        } else if (options.verbose) {
          print('Skipping $exampleName');
        }
      }
    } on GitException catch (e) {
      _logger.severe(e.message);
    } finally {
      await _deleteWorkDir(clean);
    }

    print("Example repo(s) updated: $updateCount");
    return updateCount;
  }

  @override
  Future<bool> updateRepository(String examplePath, String outRepositoryUri,
      {String exampleName: '', bool push: true, bool clean: true}) async {
    if (exampleName.isEmpty) exampleName = getExampleName(examplePath);
    print('Processing $exampleName');

    var updated = false;
    try {
      var angularRepository = await _cloneAngularRepoIntoTmp();

      // Clone [outRepository] into tmp folder.
      final outPath = p.join(workDir.path, exampleName);
      final outRepo = _gitFactory.create(outPath);
      await outRepo.cloneFrom(outRepositoryUri);

      // Remove existing content as we will generate an updated version.
      await outRepo.deleteAll();

      _logger.fine('Generating updated example application into $outPath.');
      final exampleFolder = p.join(angularRepository.directory, examplePath);
      await assembleDocumentationExample(
          new Directory(exampleFolder), new Directory(outRepo.directory),
          angularDirectory: new Directory(angularRepository.directory),
          webdevNgPath: examplePath);

      final commitMessage =
          await _createCommitMessage(angularRepository, examplePath);

      updated = await __handleUpdate(
          () => _update(outRepo, commitMessage, push),
          'Example source changed',
          exampleName,
          outRepo.branch);

      if (updated || options.forceBuild) {
        print('  Building app' + (options.forceBuild ? ' (force build)' : ''));
        updated = await __handleUpdate(
                () => _updateGhPages(outRepo, exampleName, commitMessage, push),
                'App files have changed',
                exampleName,
                'gh-pages') ||
            updated;
      } else {
        final msg = 'not built (to force use `--force-build`)';
        print("  $exampleName (gh-pages): $msg");
      }
    } on GitException catch (e) {
      _logger.severe(e.message);
    } finally {
      await _deleteWorkDir(clean);
    }
    return updated;
  }

  final _errorOrFatal = new RegExp(r'error|fatal', caseSensitive: false);
  Future __handleUpdate(Future update(), String infoMsg, String exampleName,
      String branch) async {
    var updated = false;
    try {
      await update();
      print("  $infoMsg: updated $exampleName ($branch)");
      updated = true;
    } catch (e) {
      var es = e.toString();
      if (es.contains(_errorOrFatal)) {
        throw e; // propagate serious errors
      } else if (!es.contains('nothing to commit')) {
        print("** $es");
      } else {
        print("  $exampleName ($branch): nothing to commit");
      }
    }
    return updated;
  }

  Future _deleteWorkDir(bool clean) async {
    if (!clean) {
      _logger.fine('Keeping ${workDir.path}.');
    } else if (await workDir.exists()) {
      _logger.fine('Deleting ${workDir.path}.');
      await workDir.delete(recursive: true);
    }
  }

  /// Clone angular repo into tmp folder if it is not already present.
  Future _cloneAngularRepoIntoTmp() async {
    dryRunMkDir(workDir.path);

    // Clone content of Angular docs repo into tmp folder.
    final tmpAngularDocsRepoPath = p.join(workDir.path, 'site_webdev_ng');
    final angularRepository =
        _gitFactory.create(tmpAngularDocsRepoPath, options.branch);

    // Only clone into the repository if the directory is not already there.
    if (!new Directory(angularRepository.directory).existsSync()) {
      await angularRepository.cloneFrom(_angularRepositoryUri);
    }
    return angularRepository;
  }

  /// Generates a commit message containing the commit hash of the Angular docs
  /// snapshot used to generate the content of the example repository.
  Future<String> _createCommitMessage(
      GitRepository repo, String webdevNgPath) async {
    final short = await repo.getCommitHash(short: true);
    final long = await repo.getCommitHash();

    return 'Sync with $short\n\n'
        'Synced with dart-lang/site-webdev ${repo.branch} branch, commit $short:\n'
        '$_angularRepositoryUri/tree/$long/$webdevNgPath';
  }

  /// Updates the branch with the latest cleaned example application code.
  Future _update(GitRepository repo, String message, bool push) async {
    await repo.update(message: message);
    if (push) {
      await repo.pushCurrent();
    } else {
      _logger.fine('NOT Pushing changes for ${repo.directory}.');
    }
  }

  /// Updates the gh-pages branch with the latest compiled code.
  Future _updateGhPages(
      GitRepository repo, String name, String commitMessage, bool push) async {
    // Generate the application assets into the gh-pages branch.
    String applicationAssetsPath =
        await generateApplication(new Directory(repo.directory), name);
    await repo.updateGhPages(applicationAssetsPath, commitMessage);
    if (push) {
      await repo.pushGhPages();
    } else {
      _logger.fine('NOT Pushing changes to gh-pages for ${repo.directory}.');
    }
  }
}
