import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import 'runner.dart' as Process; // TODO(chalin) tmp name to avoid code changes
import 'options.dart';
import 'util.dart';

class GitRepositoryFactory {
  GitRepository create(String directory, [String branch = defaultGitBranch]) =>
      new GitRepository(directory, branch);
}

class GitRepository {
  final _logger = new Logger('GitRepository');
  final String branch;

  /// Local path to directory where this repo will reside.
  final String dirPath;
  final Directory dir;

  GitRepository(this.dirPath, this.branch) : dir = new Directory(dirPath);

  /// Clones the git [repository]'s [branch] into this [dirPath].
  Future cloneFrom(String repository) async {
    _logger.fine('Cloning $repository ($branch) into $dirPath.');
    dryRunMkDir(dirPath);
    if (dir.existsSync()) {
      _logger.fine('  > clone already exists for $dirPath');
      await checkout();
      return;
    }
    try {
      await _git(['clone', '-b', branch, repository, dirPath]);
      return;
    } catch (e) {
      // if (!e.toString().contains('Remote branch $branch not found'))
      throw e;
    }
    // Disable example repo branch creation for now. Handle it outside the dds.
    // _logger.info('Branch $branch does not exist, creating it from master');
    // await _git(['clone', '-b', defaultGitBranch, repository, directory]);
    // await _git(['checkout', '-b', branch], workingDirectory: directory);
  }

  Future checkout() async {
    _logger.fine('Checkout $branch.');
    await _git(['checkout', branch], workingDirectory: dirPath);
  }

  /// Delete all files under [dirPath]/subdir.
  Future delete([String subdir = '']) async {
    final dir = p.join(dirPath, subdir);
    _logger.fine('Git rm * under $dir.');
    if (new Directory(dir).existsSync()) {
      try {
        await _git(['rm', '-rf', '*'], workingDirectory: dir);
        return;
      } catch (e) {
        if (!e.toString().contains('did not match any files')) throw e;
      }
    }
    _logger.fine('  > No matching files; probably already removed ($dir)');
  }

  /// Push given branch, or [branch] to origin from [dirPath].
  Future push([String _branch]) async {
    final branch = _branch ?? this.branch;
    _logger.fine('Pushing $branch from $dirPath.');
    await _git(['push', '--set-upstream', 'origin', branch],
        workingDirectory: dirPath);
  }

  Future update({String commitMessage}) async {
    await checkout();

    _logger.fine('Staging local changes for $dirPath.');
    await _git(['add', '.'], workingDirectory: dirPath);

    _logger.fine('Committing changes for $dirPath.');
    await _git(['commit', '-m', commitMessage], workingDirectory: dirPath);
  }

  /// Clones the git [repository] into this [dirPath].
  Future updateGhPages(Iterable<String> appRoots, String message) async {
    await checkoutGhPages();

    // Remove all previous content of branch
    await delete(options.ghPagesAppDir);

    // Copy newly built app files
    final baseDest = p.join(dirPath, options.ghPagesAppDir);
    for (var appRoot in appRoots) {
      final web = pathToBuiltApp(appRoot);
      _logger.fine('Copy from $web to $dirPath.');
      final dest = appRoot.isEmpty ? baseDest : p.join(baseDest, appRoot);
      await Process.run('mkdir', ['-p', dest]);
      await Process.run('cp', ['-a', p.join(web, '.'), dest],
          workingDirectory: dirPath);
      // Deploy pubspec.lock so we know what the app was built with.
      await Process.run('cp', [p.join(appRoot, 'pubspec.lock'), dest],
          workingDirectory: dirPath);
    }

    // Clean out temporary files
    await Process.run(
        'find',
        [baseDest]..addAll(
            '( -name *.ng_*.json -o -name *.ng_placeholder ) -exec rm -f {} +'
                .split(' ')));

    _logger.fine('Committing gh-pages changes for $dirPath.');
    await _git(['add', '.'], workingDirectory: dirPath);
    final statusLines = (await this.statusLines())
      ..removeWhere(
          (line) => line.startsWith('M') && line.contains(buildInfoFileName));
    if (statusLines.length == 0) {
      final msg =
          'At most the $buildInfoFileName file has changed: nothing to commit';
      _logger.fine('  $msg');
      throw msg;
    }
    await _git(['commit', '-m', message], workingDirectory: dirPath);
  }

  /// Output from `git status --short`
  Future<List<String>> statusLines({Pattern removePattern}) async {
    final status = await _git(['status', '--short'], workingDirectory: dirPath);
    final statusLines = status.split('\n')
      // I don't think the output can contain empty lines, but just in case:
      ..removeWhere((statusLine) => statusLine.isEmpty);
    if (removePattern != null)
      statusLines.removeWhere((line) => line.contains(removePattern));
    return statusLines;
  }

  /// Fetch and checkout gh-pages. If it does not exist then create it as a
  /// new orphaned branch.
  Future checkoutGhPages() async {
    _logger.fine('Checkout gh-pages.');

    try {
      await _git(['fetch', 'origin', 'gh-pages'], workingDirectory: dirPath);
      await _git(['checkout', 'gh-pages'], workingDirectory: dirPath);
    } catch (e) {
      if (e is! GitException ||
          !e.message.contains("Couldn't find remote ref gh-pages")) throw e;
      _logger
          .fine('  Unable to fetch gh-pages: ${(e as GitException).message}');
      _logger.fine('  Creating new --orphan gh-pages branch.');
      await _git(['checkout', '--orphan', 'gh-pages'],
          workingDirectory: dirPath);
      await delete();
    }
  }

  /// Returns the commit hash at HEAD.
  Future<String> getCommitHash({bool short: false}) async {
    if (Process.options.dryRun) return new Future.value('COMMIT_HASH_CODE');

    final args = "rev-parse${short ? ' --short' : ''} HEAD".split(' ');
    final hash = await _git(args, workingDirectory: dirPath);

    return hash.split('\n')[0].trim();
  }

  Future<String> git(/*String|List<String>*/ dynamic args) =>
      _git(args is String ? args.split(' ') : args, workingDirectory: dirPath);
}

class GitException implements Exception {
  final String message;

  GitException(this.message);

  String toString() {
    if (message == null) return "GitException";
    return "GitException: $message";
  }
}

Future<String> _git(List<String> arguments,
    {String workingDirectory, Exception mkException(String msg)}) async {
  final r = await Process.run('git', arguments,
      workingDirectory: workingDirectory,
      mkException: (msg) => new GitException(msg));
  return r.stdout;
}
