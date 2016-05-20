import 'dart:io';

import 'package:args/args.dart';

/// Global option
bool dryRun = true;
bool verbose = false;
ArgParser _parser;

/// Processes command line options and returns remaining arguments.
List<String> processArgs(List<String> args) {
  _parser = new ArgParser(allowTrailingOptions: true);

  _parser.addFlag('help',
      abbr: 'h', negatable: false, help: 'Shows usage information.');
  const dryRunMsg = 'Show which commands would be executed but make (almost) '
      'no changes. (Only the temporary directory will be created and deleted.)';
  _parser.addFlag('dry-run', abbr: 'n', negatable: false, help: dryRunMsg);
  _parser.addFlag('verbose', abbr: 'v', negatable: false);

  var argResults;
  try {
    argResults = _parser.parse(args);
  } on FormatException catch (e) {
    printUsageAndExit(e.message, 0);
  }

  if (argResults['help']) printUsageAndExit();

  dryRun = argResults['dry-run'];
  verbose = argResults['verbose'];
  return argResults.rest;
}

void printUsageAndExit([String _msg, int exitCode = 1]) {
  var msg = 'Syncs angular.io example applications.';
  if (_msg != null) msg = _msg;
  print('''

$msg.

Usage: ${Platform.script} [options] [<exampleName> | <examplePath> <exampleRepo>]

${_parser != null ? _parser.usage : ''}
''');
  exit(exitCode);
}
