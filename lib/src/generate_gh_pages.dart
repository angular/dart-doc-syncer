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

  _logger
      .fine('Adjust <base href> in index.html so that app runs under gh-pages');

  // If the `index.html` either statically or dynamically sets <base href>
  // replace that element by a <base href> appropriate for serving via GH pages.
  final baseHrefEltOrScript = new RegExp(r'<base href="/">|'
      r'<script>(\s|[^<])+<base href(\s|[^<]|<[^/])+</script>');

  final appBaseHref = '<base href="/$exampleName/">';
  await transformFile(
      p.join(applicationPath, 'web/index.html'),
      (String content) =>
          content.replaceFirst(baseHrefEltOrScript, appBaseHref));

  _logger.fine("Build the application assets into the 'build' folder");
  await Process.run('pub', ['get'], workingDirectory: applicationPath);
  await Process.run('pub', ['build'], workingDirectory: applicationPath);

  return p.join(applicationPath, 'build/web');
}
