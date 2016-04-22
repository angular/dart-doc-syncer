import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

class GitRepositoryFactory {
  GitRepository create(String directory) => new GitRepository(directory);
}

class GitRepository {
  final _logger = new Logger('GitRepository');

  final String directory;

  GitRepository(this.directory);

  /// Clones the git [repository] into this [directory].
  Future cloneFrom(String repository) async {
    _logger.fine('Cloning $repository into $directory.');
    await _assertSuccess(
        () => Process.run('git', ['clone', repository, directory]));
  }

  /// Deletes all files in this git [directory].
  Future deleteAll() async {
    _logger.fine('Deleting all the repository content in $directory.');
    await _assertSuccess(
        () => Process.run('git', ['rm', '*'], workingDirectory: directory));
  }

  /// Stages, commits with [message] and pushes local changes to origin for
  /// [directory].
  Future pushCurrent() async {
    _logger.fine('Pushing changes for $directory.');
    await _assertSuccess(
        () => Process.run('git', ['push'], workingDirectory: directory));
  }

  /// Stages, commits with [message] and pushes local changes to origin for
  /// [directory].
  Future pushGhPages() async {
    _logger.fine('Pushing changes to gh-pages for $directory.');
    await _assertSuccess(() => Process.run(
        'git', ['push', '--set-upstream', 'origin', 'gh-pages'],
        workingDirectory: directory));
  }

  Future updateMaster({String message}) async {
    _logger.fine('Checkout master.');
    await _assertSuccess(() => Process.run('git', ['checkout', 'master'],
        workingDirectory: directory));

    _logger.fine('Staging local changes for $directory.');
    await _assertSuccess(
        () => Process.run('git', ['add', '.'], workingDirectory: directory));

    _logger.fine('Comitting changes for $directory.');
    await _assertSuccess(() => Process.run('git', ['commit', '-m', message],
        workingDirectory: directory));
  }

  /// Clones the git [repository] into this [directory].
  Future updateGhPages(String sourcePath) async {
    _logger.fine('Checkout gh-pages.');

    try {
      await _assertSuccess(() => Process.run(
          'git', ['fetch', 'origin', 'gh-pages'],
          workingDirectory: directory));
      await _assertSuccess(() => Process.run('git', ['checkout', 'gh-pages'],
          workingDirectory: directory));
    } catch (e) {
      _logger.fine('Unable to fetch gh-pages: ${(e as GitException).message}');
      _logger.fine('Creating new --orphan gh-pages branch.');
      await _assertSuccess(() => Process.run(
          'git', ['checkout', '--orphan', 'gh-pages'],
          workingDirectory: directory));
    }

    // Remove all files from old working tree.
    _logger.fine('Remove existing files from old working tree in $directory.');
    await _assertSuccess(
        () => Process.run('git', ['add', '.'], workingDirectory: directory));
    await _assertSuccess(() =>
        Process.run('git', ['rm', '-rf', '*'], workingDirectory: directory));

    // Copy the application assets into this folder.
    _logger.fine('Copy from $sourcePath to $directory.');
    await Process.run('cp', ['-a', p.join(sourcePath, '.'), directory]);

    _logger.fine('Comitting gh-pages changes for $directory.');
    await _assertSuccess(
        () => Process.run('git', ['add', '.'], workingDirectory: directory));
    await _assertSuccess(() => Process.run('git', ['commit', '-m', 'Sync'],
        workingDirectory: directory));
  }
}

class GitException implements Exception {
  final String message;

  GitException(this.message);
}

/// Throws if the exitCode returned by [command] is not 0.
Future _assertSuccess(Future<ProcessResult> command()) async {
  final r = await command();
  if (r.exitCode != 0) {
    final message = r.stderr.isEmpty ? r.stdout : r.stderr;
    throw new GitException(message);
  }
}
