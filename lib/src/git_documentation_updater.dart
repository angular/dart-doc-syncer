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
  final String _webdevRepoUri =
      'https://github.com/${options.user}/site-webdev';
  GitRepository webdevRepo;

  GitDocumentationUpdater(this._gitFactory);

  @override
  Future<int> updateMatchingRepo(RegExp re, {bool push, bool clean}) async {
    int updateCount = 0;
    try {
      final angularRepository = await _cloneWebdevRepoIntoWorkDir();
      final files = await new Directory(angularRepository.dirPath)
          .list(recursive: true)
          .where(
              (e) => e is File && p.basename(e.path) == exampleConfigFileName)
          .toList();
      for (var e in files) {
        var dartDir =
            p.dirname(e.path).substring(angularRepository.dirPath.length);
        if (dartDir.startsWith('/')) dartDir = dartDir.substring(1);
        final e2u = new Example2Uri(dartDir);
        if (re.hasMatch(dartDir)) {
          var updated = await updateRepository(e2u.path, e2u.repositoryUri,
              clean: clean, push: push);
          if (updated) updateCount++;
        } else if (options.verbose) {
          print('Skipping ${e2u.path}');
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

  /// [rrrExamplePath] is a repo-root-relative example path, e.g.,
  /// 'examples/ng/doc/quickstart'
  @override
  Future<bool> updateRepository(String rrrExamplePath, String outRepositoryUri,
      {String exampleName: '', bool push: true, bool clean: true}) async {
    // final examplePath = getExamplePath(rrrExamplePath);
    if (exampleName.isEmpty) exampleName = getExampleName(rrrExamplePath);
    print('Processing $rrrExamplePath');

    var updated = false;
    String commitMessage;

    try {
      var angularRepository = await _cloneWebdevRepoIntoWorkDir();

      // Clone [outRepository] into working directory.
      final outPath = p.join(workDir.path, exampleName);
      final outRepo = _gitFactory.create(outPath, options.branch);
      if (outRepo.dir.existsSync()) {
        _logger.fine(
            '  > repo exists; assuming source files have already been updated ($outPath)');
        outRepo.checkout();
      } else {
        await outRepo.cloneFrom(outRepositoryUri);

        // Remove existing content as we will generate an updated version.
        await outRepo.delete();

        _logger.fine('Generating updated example app(s) into $outPath.');
        final exampleFolder = p.join(angularRepository.dirPath, rrrExamplePath);
        await assembleDocumentationExample(
            new Directory(exampleFolder), new Directory(outRepo.dirPath),
            angularDirectory: new Directory(angularRepository.dirPath),
            webdevNgPath: rrrExamplePath);

        commitMessage =
            await _createCommitMessage(angularRepository, rrrExamplePath);

        updated = await __handleUpdate(
            () => _update(outRepo, commitMessage, push),
            'Example source changed',
            exampleName,
            outRepo.branch);
      }

      if (updated || options.forceBuild) {
        print(updated
            ? '  Changes to sources detected'
            : '  Force build requested');

        if (commitMessage == null)
          commitMessage =
              await _createCommitMessage(angularRepository, rrrExamplePath);

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
    } catch (e, st) {
      var es = e.toString();
      if (es.contains(_errorOrFatal)) {
        throw e; // propagate serious errors
      } else if (!es.contains('nothing to commit')) {
        print(es);
        _logger.finest(st);
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

  /// Clone webdev repo into working directory, if it is not already present.
  Future<GitRepository> _cloneWebdevRepoIntoWorkDir() async {
    if (webdevRepo == null) {
      final webdevRepoPath = p.join(workDir.path, 'site_webdev_ng');
      webdevRepo = _gitFactory.create(webdevRepoPath, options.branch);
      await webdevRepo.cloneFrom(_webdevRepoUri);
    }
    return webdevRepo;
  }

  /// Generates a commit message containing the commit hash of the Angular docs
  /// snapshot used to generate the content of the example repository.
  Future<String> _createCommitMessage(
      GitRepository repo, String webdevNgPath) async {
    final short = await repo.getCommitHash(short: true);
    final long = await repo.getCommitHash();

    return 'Sync with $short\n\n'
        'Synced with dart-lang/site-webdev ${repo.branch} branch, commit $short:\n'
        '$_webdevRepoUri/tree/$long/$webdevNgPath';
  }

  /// Updates the branch with the latest cleaned example application code.
  Future _update(GitRepository repo, String message, bool push) async {
    await repo.update(commitMessage: message);
    if (push) {
      await repo.push();
    } else {
      _logger.fine('NOT Pushing changes for ${repo.dirPath}.');
    }
  }

  /// Updates the gh-pages branch with the latest built app(s).
  Future _updateGhPages(GitRepository exampleRepo, String exampleName,
      String commitMessage, bool push) async {
    final Iterable<Directory> appRoots = _getAppRoots(exampleRepo.dir);

    if (appRoots.length == 0)
      throw new Exception('No pubspecs found under ${exampleRepo.dirPath}');

    final relativeAppRoots =
        appRoots.map((d) => stripPathPrefix(exampleRepo.dirPath, d.path));
    excludeTmpBuildFiles(exampleRepo.dir, relativeAppRoots);

    for (var appRoot in appRoots) {
      if (appRoots.length > 1)
        print('  Building app ${stripPathPrefix(workDir.path, appRoot.path)}');
      await _buildApp(appRoot, exampleName);
    }

    await exampleRepo.updateGhPages(relativeAppRoots, commitMessage);
    if (push) {
      await exampleRepo.push('gh-pages');
    } else {
      _logger
          .info('NOT Pushing changes to gh-pages for ${exampleRepo.dirPath}.');
    }
  }

  Future<String> _buildApp(Directory dir, String exampleName) async {
    await buildApp(dir);
    var href = '/$exampleName/' +
        (options.ghPagesAppDir.isEmpty ? '' : '${options.ghPagesAppDir}/');
    if (!dir.path.endsWith(exampleName)) {
      href += p.basename(dir.path) + '/';
    }
    await adjustBaseHref(p.join(dir.path, 'build/web'), href);
  }

  /// Return list of directories containing pubspec files. If [dir] contains
  /// a pubspec, return `[dir]`, otherwise look one level down in the
  /// subdirectories of [dir], for pubspecs.
  List<Directory> _getAppRoots(Directory dir) {
    final List<Directory> appRoots = [];
    if (_containsPubspec(dir)) {
      appRoots.add(dir);
    } else {
      for (var fsEntity in dir.listSync(followLinks: false)) {
        if (p.basename(fsEntity.path).startsWith('.')) continue;
        if (fsEntity is Directory) {
          if (!_containsPubspec(fsEntity)) continue;
          _logger.finer('  >> pubspec found under ${fsEntity.path}');
          appRoots.add(fsEntity);
        }
      }
    }
    return appRoots;
  }

  bool _containsPubspec(Directory dir) =>
      new File(p.join(dir.path, 'pubspec.yaml')).existsSync();
}
