import 'dart:async';

import 'package:logging/logging.dart';

import 'package:dart_doc_syncer/documentation_updater.dart';
import 'package:dart_doc_syncer/example2uri.dart';
import 'package:dart_doc_syncer/options.dart';

/// Syncs an example application living in the Angular docs repository to a
/// dedicated repository that will contain a generated cleaned-up version.
///
///    dart_doc_syncer [-h|options] [<exampleName> | <examplePath> <exampleRepo>]
Future main(List<String> _args) async {
  var args = processArgs(_args);
  Logger.root.level = options.verbose ? Level.ALL : Level.WARNING;
  Logger.root.onRecord.listen((LogRecord rec) {
    var msg = '${rec.message}';
    if (!options.dryRun && !options.verbose)
      msg = '${rec.level.name}: ${rec.time}: ' + msg;
    print(msg);
  });

  var exampleName, path, repositoryUri;
  switch (args.length) {
    case 0:
      if (options.match == null)
        printUsageAndExit('No examples specified; name example or use --match');
        // #NotReached
      break;
    case 1:
      exampleName = args[0];
      var e2u = new Example2Uri(exampleName);
      path = e2u.path;
      repositoryUri = e2u.repositoryUri;
      break;
    case 2:
      path = args[0];
      repositoryUri = args[1];
      exampleName = getExampleName(path);
      break;
    default:
      printUsageAndExit("Too many arguments (${args.length})");
    // #NotReached
  }

  final documentation = new DocumentationUpdater();
  print('Working directory: ${workDir.path}');
  if (options.match == null) {
    await documentation.updateRepository(path, repositoryUri,
        clean: options.workDir == null && !options.keepTmp, exampleName: exampleName, push: options.push);
    print('Done updating $repositoryUri');
  } else {
    await documentation.updateMatchingRepo(options.match,
        clean: options.workDir == null && !options.keepTmp, push: options.push);
  }
}
