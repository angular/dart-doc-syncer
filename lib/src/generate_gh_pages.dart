import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import 'runner.dart' as Process; // TODO(chalin) tmp name to avoid code changes
import 'options.dart';
import 'util.dart';

final Logger _logger = new Logger('generate_gh_pages');

/// Returns the path to the folder where the application assets have been
/// generated.
Future<String> generateApplication(
    Directory example, String exampleName) async {
  final applicationPath = p.join(workDirPath, '${exampleName}_app');

  // Copy the application code into a separate folder.
  await Process.run('cp', ['-a', p.join(example.path, '.'), applicationPath]);

  _logger.fine(
      'Adjust router <base href> in index.html so that it works under gh-pages');
  await transformFile(
      p.join(applicationPath, 'web/index.html'),
      (content) => content.replaceAll(
          '<base href="/">', '<base href="/$exampleName/">'));

  _logger.fine("Build the application assets into the 'build' folder");
  await Process.run('pub', ['get'], workingDirectory: applicationPath);
  await Process.run('pub', ['build'], workingDirectory: applicationPath);

  return p.join(applicationPath, 'build/web');
}
