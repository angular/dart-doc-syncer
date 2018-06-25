import 'dart:async';
import 'dart:convert';

import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'options.dart';
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

  await Process.runCmd('pub ${options.pubGetOrUpgrade} --no-precompile',
      workingDirectory: example.path, isException: isException);

  // Use default build config for now.
  // await _generateBuildYaml(example.path);
  final pubBuild = options.useNewBuild
      ? 'pub run build_runner build --release --delete-conflicting-outputs --output=web:${options.buildDir}'
      : 'pub ${options.buildDir}';
  await Process.runCmd(pubBuild,
      workingDirectory: example.path, isException: isException);
}

// Currently unused, but keeping the code in case we need to generate build
// config files later on.
// ignore: unused_element
Future _generateBuildYaml(String projectPath) async {
  final pubspecYamlFile = new File(p.join(projectPath, 'pubspec.yaml'));
  final pubspecYaml =
      loadYaml(await pubspecYamlFile.readAsString()) as YamlMap;
  final buildYaml = _buildYaml(pubspecYaml['name'], options.webCompiler,
      _extractNgVers(pubspecYaml) ?? 0);
  final buildYamlFile = new File(p.join(projectPath, 'build.yaml'));
  _logger.info('Generating ${buildYamlFile.path}:\n$buildYaml');
  await buildYamlFile.writeAsString(buildYaml);
}

// This is currently unused.
// Note: we could use ${pkgName} as the target.
String _buildYaml(String pkgName, String webCompiler, int majorNgVers) =>
    '''
targets:
  \$default:
    builders:
      build_web_compilers|entrypoint:
        generate_for:
          - web/main.dart
        options:
          compiler: $webCompiler
          dart2js_args:
            - --fast-startup
            - --minify
            - --trust-type-annotations
''' +
    (majorNgVers >= 5
        ? '''
            - --enable-asserts
            # - --preview-dart-2 # This option isn't supported yet
'''
        : '');

int _extractNgVers(YamlMap pubspecYaml) {
  final ngVersConstraint = pubspecYaml['dependencies']['angular'];
  final match = new RegExp(r'\^?(\d+)\.').firstMatch(ngVersConstraint);
  if (match == null) return null;
  return int.tryParse(match[1]);
}

// Until we can specify the needed web-compiler on the command line
// (https://github.com/dart-lang/build/issues/801), we'll auto-
// generate build.yml. Ignore the generated build.yaml.
String _filesToExclude() => '''
.dart_tool/
.packages
.pub/
${options.buildDir}/
build.yaml
''';

/// Files created when the app was built should be ignored.
void excludeTmpBuildFiles(Directory exampleRepo, Iterable<String> appDirPaths) {
  final excludeFilePath = p.join(exampleRepo.path, '.git', 'info', 'exclude');
  final excludeFile = new File(excludeFilePath);
  final excludeFileAsString = excludeFile.readAsStringSync();
  var filesToExclude = _filesToExclude();
  if (options.ghPagesAppDir.isNotEmpty) filesToExclude += '\n/pubspec.lock';
  final excludes = appDirPaths.length < 2
      ? filesToExclude
      : appDirPaths.map((p) => '/$p').join('\n');
  if (!excludeFileAsString.contains(filesToExclude)) {
    _logger.fine('  > Adding tmp build files to $excludeFilePath: ' +
        filesToExclude.replaceAll('\n', ' '));
    excludeFile.writeAsStringSync('$excludeFileAsString\n$excludes\n');
  }
}

Future createBuildInfoFile(
    String pathToWebFolder, String exampleName, String commitHash) async {
  final buildInfoFile = new File(p.join(pathToWebFolder, buildInfoFileName));

  // We normalize the build timestamp to TZ=US/Pacific, which is easier
  // to do using the OS date command. Failing that use DateTime.now().
  final r = await Process.run('date', [], environment: {'TZ': 'US/Pacific'});
  final date = r.stdout as String;

  final json = {
    'build-time': date.isNotEmpty ? date.trim() : new DateTime.now(),
    'commit-sha':
        'https://github.com/angular-examples/$exampleName/commit/$commitHash'
  };
  buildInfoFile.writeAsStringSync(jsonEncode(json));
}
