import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import 'options.dart';

final Logger _logger = new Logger('update_doc_repo');

// TODO: consider using this helper method so that we can log dir creation.
//Future mkdir(String path) async {
//  _logger.fine('mkdir $path.');
//  if (dryRun) return new Future.value();
//  return await new Directory(path).create();
//}

/// Create directory only during dry runs.
Future dryRunMkDir(String path) async {
  var dir = new Directory(path);
  if (!options.dryRun || dir.existsSync()) return new Future.value();
  _logger.fine('[dryrun] mkdir $path.');
  return dir.create();
}

/// Read [path] as a string, apply [transformer] and write back the result.
Future<Null> transformFile(
    String path, String transformer(String content)) async {
  _logger.fine('  Transform file $path');
  if (options.dryRun) return new Future.value();

  File file = new File(path);
  await file.writeAsString(transformer(await file.readAsString()));
}

/// Like path.join(...), but first filters out null and empty path parts.
String pathJoin(List<String> pathParts) =>
    p.joinAll(pathParts.where((p) => p != null && p.isNotEmpty));

String stripPathPrefix(String prefix, String path) {
  if (prefix == null || prefix.isEmpty) return path;
  if (path == prefix) return '.';
  final normalizedPrefix = prefix.endsWith('/') ? prefix : '$prefix/';
  assert(path.startsWith(normalizedPrefix),
      '"$path" should start with "$normalizedPrefix"');
  return path.substring(normalizedPrefix.length);
}

// Dart 1 polyfill
// ignore_for_file: deprecated_member_use
int tryParse(String s) => int.parse(s, onError: (_) => null);

/// Return list of directories containing pubspec files. If [dir] contains
/// a pubspec, return `[dir]`, otherwise look one level down in the
/// subdirectories of [dir], for pubspecs.
List<Directory> getAppRoots(Directory dir) {
  final List<Directory> appRoots = [];
  if (_containsPubspec(dir)) {
    appRoots.add(dir);
  } else {
    for (var fsEntity in dir.listSync(followLinks: false)) {
      if (p.basename(fsEntity.path).startsWith('.') ||
          options.containsBuildDir(fsEntity.path)) continue;
      if (fsEntity is Directory) {
        if (!_containsPubspec(fsEntity)) continue;
        _logger.finer('  >> pubspec found under ${fsEntity.path}');
        appRoots.add(fsEntity);
      }
    }
  }
  if (appRoots.length == 0)
    throw new Exception('No pubspec.yaml found under ${dir.path}');
  return appRoots;
}

bool _containsPubspec(Directory dir) =>
    new File(p.join(dir.path, 'pubspec.yaml')).existsSync();

String pathToBuiltApp(String projectRootPath) =>
    // We build for deployment only now, so options.buildDir contains the built
    // app (as opposed to it being under the `web` subfolder of the buildDir).
    p.join(projectRootPath, options.buildDir);
