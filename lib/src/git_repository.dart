import 'dart:async';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import 'runner.dart' as Process; // TODO(chalin) tmp name to avoid code changes
import 'util.dart';

class GitRepositoryFactory {
  GitRepository create(String directory, [String branch = 'master']) =>
      new GitRepository(directory, branch);
}

class GitRepository {
  final _logger = new Logger('GitRepository');
  final String branch;
  /// Local path to directory where this repo will reside.
  final String directory;

  GitRepository(this.directory, this.branch);

  /// Clones the git [repository]'s [branch] into this [directory].
  Future cloneFrom(String repository) async {
    _logger.fine('Cloning $repository ($branch) into $directory.');
    dryRunMkDir(directory);
    await _git(['clone', '-b', branch, repository, directory]);
  }

  /// Deletes all files in this git [directory].
  Future deleteAll() async {
    _logger.fine('Deleting all the repository content in $directory.');
    await _git(['rm', '*'], workingDirectory: directory);
  }

  /// Stages, commits with [message] and pushes local changes to origin for
  /// [directory].
  Future pushCurrent() async {
    _logger.fine('Pushing changes for $directory.');
    await _git(['push'], workingDirectory: directory);
  }

  /// Stages, commits with [message] and pushes local changes to origin for
  /// [directory].
  Future pushGhPages() async {
    _logger.fine('Pushing changes to gh-pages for $directory.');
    await _git(['push', '--set-upstream', 'origin', 'gh-pages'],
        workingDirectory: directory);
  }

  Future update({String message}) async {
    _logger.fine('Checkout $branch.');
    await _git(['checkout', branch], workingDirectory: directory);

    _logger.fine('Staging local changes for $directory.');
    await _git(['add', '.'], workingDirectory: directory);

    _logger.fine('Committing changes for $directory.');
    await _git(['commit', '-m', message], workingDirectory: directory);
  }

  /// Clones the git [repository] into this [directory].
  Future updateGhPages(String sourcePath, String message) async {
    _logger.fine('Checkout gh-pages.');

    try {
      await _git(['fetch', 'origin', 'gh-pages'], workingDirectory: directory);
      await _git(['checkout', 'gh-pages'], workingDirectory: directory);
    } catch (e) {
      _logger.fine('Unable to fetch gh-pages: ${(e as GitException).message}');
      _logger.fine('Creating new --orphan gh-pages branch.');
      await _git(['checkout', '--orphan', 'gh-pages'],
          workingDirectory: directory);
    }

    // Remove all files from old working tree.
    _logger.fine('Remove existing files from old working tree in $directory.');
    await _git(['add', '.'], workingDirectory: directory);
    await _git(['rm', '-rf', '*'], workingDirectory: directory);

    // Copy the application assets into this folder.
    _logger.fine('Copy from $sourcePath to $directory.');
    await Process.run('cp', ['-a', p.join(sourcePath, '.'), directory]);

    _logger.fine('Committing gh-pages changes for $directory.');
    await _git(['add', '.'], workingDirectory: directory);
    await _git(['commit', '-m', message], workingDirectory: directory);
  }

  /// Returns the commit hash at HEAD.
  Future<String> getCommitHash({bool short: false}) async {
    if (Process.options.dryRun) return new Future.value('COMMIT_HASH_CODE');

    final args = "rev-parse${short ? ' --short' : ''} HEAD".split(' ');
    final hash = await _git(args, workingDirectory: directory);

    return hash.split('\n')[0].trim();
  }
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
