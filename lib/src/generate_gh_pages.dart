import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import 'runner.dart' as Process; // TODO(chalin) tmp name to avoid code changes
import 'util.dart';

final Logger _logger = new Logger('generate_gh_pages');

Future adjustBaseHref(String pathToWebFolder, String href) async {
  _logger.fine(
      'Adjust index.html <base href="$href"> so that app runs under gh-pages');

  // If the `index.html` either statically or dynamically sets <base href>
  // replace that element by a <base href> appropriate for serving via GH pages.
  final baseHrefEltOrScript = new RegExp(r'<base href="/">|'
      r'<script>(\s|[^<])+<base href(\s|[^<]|<[^/])+</script>');

  final appBaseHref = '<base href="$href">';
  await transformFile(
      p.join(pathToWebFolder, 'index.html'),
      (String content) =>
          content.replaceFirst(baseHrefEltOrScript, appBaseHref));
}

final errorOrFailure = new RegExp('^(error|fail)', caseSensitive: false);

bool isException(ProcessResult r) {
  final stderr = r.stderr;
  return stderr is! String || stderr.contains(errorOrFailure);
}

Future buildApp(Directory example) async {
  _logger.fine("Building ${example.path}");
  await Process.run('pub', ['get'],
      workingDirectory: example.path, isException: isException);
  await Process.run('pub', ['build'],
      workingDirectory: example.path, isException: isException);
}

const filesToExclude = '''
.packages
.pub/
build/
pubspec.lock
''';

/// Files created when the app was build should be ignored.
void excludeTmpBuildFiles(Directory exampleRepo, Iterable<String> appDirPaths) {
  final excludeFilePath = p.join(exampleRepo.path, '.git', 'info', 'exclude');
  final excludeFile = new File(excludeFilePath);
  final excludeFileAsString = excludeFile.readAsStringSync();
  final excludes = appDirPaths.length < 2
      ? filesToExclude
      : appDirPaths.map((p) => '/$p').join('\n');
  if (!excludeFileAsString.contains(filesToExclude)) {
    _logger.fine('  > Adding tmp build files to $excludeFilePath');
    excludeFile.writeAsStringSync('$excludeFileAsString\n$excludes\n');
  }
}
