import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import 'runner.dart' as Process; // TODO(chalin) tmp name to avoid code changes
import 'options.dart';
import 'util.dart';

class GitRepositoryFactory {
  GitRepository create(String directory, [String branch = 'master']) =>
      new GitRepository(directory, branch);
}

class GitRepository {
  final _logger = new Logger('GitRepository');
  final String branch;

  /// Local path to directory where this repo will reside.
  final String directory; // FIXME: rename to dirPath later
  final Directory dir;

  GitRepository(this.directory, this.branch) : dir = new Directory(directory);

  /// Clones the git [repository]'s [branch] into this [directory].
  Future cloneFrom(String repository) async {
    _logger.fine('Cloning $repository ($branch) into $directory.');
    dryRunMkDir(directory);
    if (dir.existsSync()) {
      _logger.fine('  > clone already exists for $directory');
      await checkout();
      return;
    }
    try {
      await _git(['clone', '-b', branch, repository, directory]);
      return;
    } catch (e) {
      // if (!e.toString().contains('Remote branch $branch not found'))
      throw e;
    }
    // Disable example repo branch creation for now. Handle it outside the dds.
    // _logger.info('Branch $branch does not exist, creating it from master');
    // await _git(['clone', '-b', 'master', repository, directory]);
    // await _git(['checkout', '-b', branch], workingDirectory: directory);
  }

  Future checkout() async {
    _logger.fine('Checkout $branch.');
    await _git(['checkout', branch], workingDirectory: directory);
  }

  /// Delete all files under [directory]/subdir.
  Future delete([String subdir = '']) async {
    final dir = p.join(directory, subdir);
    _logger.fine('Git rm * under $dir.');
    if (new Directory(dir).existsSync()) {
      try {
        await _git(['rm', '-r', '*'], workingDirectory: dir);
        return;
      } catch (e) {
        if (!e.toString().contains('did not match any files')) throw e;
      }
    }
    _logger.fine('  > No matching files; probably already removed ($dir)');
  }

  /// Push given branch, or [branch] to origin from [directory].
  Future push([String _branch]) async {
    final branch = _branch ?? this.branch;
    _logger.fine('Pushing $branch from $directory.');
    await _git(['push', '--set-upstream', 'origin', branch],
        workingDirectory: directory);
  }

  Future update({String commitMessage}) async {
    await checkout();

    _logger.fine('Staging local changes for $directory.');
    await _git(['add', '.'], workingDirectory: directory);

    _logger.fine('Committing changes for $directory.');
    await _git(['commit', '-m', commitMessage], workingDirectory: directory);
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

    await delete(options.ghPagesAppDir);

    // Copy the application assets into this folder.
    _logger.fine('Copy from $sourcePath to $directory.');
    final dest = p.join(directory, options.ghPagesAppDir);
    await Process.run('cp', ['-a', p.join(sourcePath, '.'), dest]);

    await Process.run(
        'find',
        [dest]..addAll(
            '( -name *.ng_*.json -o -name *.ng_placeholder ) -exec rm -f {} +'
                .split(' ')));

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
