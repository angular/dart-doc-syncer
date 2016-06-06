import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';

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
  if (!options.dryRun) return new Future.value();
  _logger.fine('[dryrun] mkdir $path.');
  var dir = new Directory(path);
  return await dir.create();
}
