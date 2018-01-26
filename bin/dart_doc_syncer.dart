import 'dart:async';

import 'package:logging/logging.dart';

import 'package:dart_doc_syncer/documentation_updater.dart';
import 'package:dart_doc_syncer/example2uri.dart';
import 'package:dart_doc_syncer/options.dart';

/// Syncs an example app from the site-webdev repository to a
/// dedicated repository that will contain a generated cleaned-up version.
///
///    dart_doc_syncer [-h|options] [<examplePath> [<exampleRepo>]]
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
    case 2:
      final e2u = new Example2Uri(args[0]);
      exampleName = e2u.exampleName;
      path = e2u.path;
      repositoryUri = args.length == 1 ? e2u.repositoryUri : args[1];
      break;
    default:
      printUsageAndExit("Unrecognized arguments");
    // #NotReached
  }

  final documentation = new DocumentationUpdater();
  print('Working directory: ${workDir.path}');
  if (options.match == null) {
    await documentation.updateRepository(path, repositoryUri,
        clean: options.workDir == null && !options.keepTmp,
        exampleName: exampleName,
        push: options.push);
    print('Done updating $repositoryUri');
  } else {
    await documentation.updateMatchingRepo(options.match, options.skip,
        clean: options.workDir == null && !options.keepTmp, push: options.push);
  }
}
