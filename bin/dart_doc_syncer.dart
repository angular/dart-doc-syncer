import 'dart:async';

import 'package:logging/logging.dart';

import 'package:dart_doc_syncer/documentation_updater.dart';
import 'package:dart_doc_syncer/options.dart';

/// Syncs an example application living in the angular.io repository to a
/// dedicated repository that will contain a generated cleaned-up version.
///
///     dart_doc_syncer [-n|-h] <examplePath> <exampleRepository>
Future main(List<String> _args) async {
  var args = processArgs(_args);
  if (args.length != 2)
    printUsageAndExit("Expected 2 arguments but found ${args.length}");


  Logger.root.level = dryRun ? Level.ALL : Level.WARNING;
  Logger.root.onRecord.listen((LogRecord rec) {
    var msg = '${rec.message}';
    if (!dryRun) msg = '${rec.level.name}: ${rec.time}: ' + msg;
    print(msg);
  });

  final path = args[0];
  final repository = args[1];

  final documentation = new DocumentationUpdater();
  await documentation.updateRepository(path, repository);

  print('Done updating $repository');
}
