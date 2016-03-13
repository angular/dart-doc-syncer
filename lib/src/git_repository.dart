import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';

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
    _logger.fine('Deleting all repository content.');
    await Process.run('git', ['rm', '*'], workingDirectory: directory);
  }

  /// Stages, commits with [message] and pushes local changes to origin for
  /// [directory].
  Future pushContent({String message}) async {
    _logger.fine('Staging local changes for $directory.');
    await _assertSuccess(
        () => Process.run('git', ['add', '.'], workingDirectory: directory));

    _logger.fine('Comitting changes for $directory.');
    await _assertSuccess(() => Process.run('git', ['commit', '-m', message],
        workingDirectory: directory));

    _logger.fine('Pushing changes for $directory.');
    await _assertSuccess(
        () => Process.run('git', ['push'], workingDirectory: directory));
  }
}

/// Throws if the exitCode returned by [gitCommand] is not 0.
Future _assertSuccess(Future gitCommand()) async {
  final r = await gitCommand();
  if (r.exitCode != 0) throw r.stderr;
}
