import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'runner.dart' as Process; // TODO(chalin) tmp name to avoid code changes
import 'options.dart';

/// Returns the path to the folder where the application assets have been
/// generated.
Future<String> generateApplication(
    Directory example, String exampleName) async {
  final applicationPath = p.join(workDirPath, '${exampleName}_app');

  // Copy the application code into a seperate folder.
  await Process.run('cp', ['-a', p.join(example.path, '.'), applicationPath]);

  // Build the application assets into the 'build' folder.
  await Process.run('pub', ['get'], workingDirectory: applicationPath);
  await Process.run('pub', ['build'], workingDirectory: applicationPath);

  return p.join(applicationPath, 'build/web');
}
