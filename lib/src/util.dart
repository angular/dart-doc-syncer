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
Future<Null> transformFile(String path, String transformer(String content)) async {
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
