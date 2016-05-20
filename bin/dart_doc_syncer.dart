import 'dart:async';

import 'package:logging/logging.dart';

import 'package:dart_doc_syncer/documentation_updater.dart';
import 'package:dart_doc_syncer/example2uri.dart';
import 'package:dart_doc_syncer/options.dart';

/// Syncs an example application living in the angular.io repository to a
/// dedicated repository that will contain a generated cleaned-up version.
///
///    dart_doc_syncer [-h|-n|-v] [<exampleName> | <examplePath> <exampleRepo>]
Future main(List<String> _args) async {
  var args = processArgs(_args);
  Logger.root.level = dryRun || verbose ? Level.ALL : Level.WARNING;
  Logger.root.onRecord.listen((LogRecord rec) {
    var msg = '${rec.message}';
    if (!dryRun) msg = '${rec.level.name}: ${rec.time}: ' + msg;
    print(msg);
  });

  var path, repositoryUri;
  switch (args.length) {
    case 1:
      var e2u = new Example2Uri(args[0]);
      path = e2u.path;
      repositoryUri = e2u.repositoryUri;
      break;
    case 2:
      path = args[0];
      repositoryUri = args[1];
      break;
    default:
      printUsageAndExit("Expected 1 or 2 arguments but found ${args.length}");
    // #NotReached
  }

  final documentation = new DocumentationUpdater();
  await documentation.updateRepository(path, repositoryUri);

  print('Done updating $repositoryUri');
}
