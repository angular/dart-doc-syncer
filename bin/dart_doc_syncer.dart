import 'dart:async';

import 'package:logging/logging.dart';

import 'package:dart_doc_syncer/documentation_updater.dart';

/// Syncs an example application living in the angular.io repository to a
/// dedicated repository that will contain a generated cleaned-up version.
///
///     dart_doc_syncer <examplePath> <exampleRepository>
Future main(List<String> args) async {
  Logger.root.level = Level.WARNING;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });

  final path = args[0];
  final repository = args[1];

  final documentation = new DocumentationUpdater();
  await documentation.updateRepository(path, repository);

  print('Done updating $repository');
}
