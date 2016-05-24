import 'dart:async';

import 'package:dart_doc_syncer/documentation_updater.dart';
import 'package:dart_doc_syncer/options.dart';
import 'package:logging/logging.dart';

/// Syncs all angular.io example applications.
Future main(List<String> _args) async {
  processArgs(_args);

  Logger.root.level = dryRun || verbose ? Level.ALL : Level.WARNING;
  Logger.root.onRecord.listen((LogRecord rec) {
    var msg = '${rec.message}';
    if (!dryRun) msg = '${rec.level.name}: ${rec.time}: ' + msg;
    print(msg);
  });

  var nUpdated = 0;
  for (List<String> example in _examplesToSync) {
    try {
      final examplePath = example[0];
      final exampleRepository = example[1];
      final documentation = new DocumentationUpdater();
      final isUpdated = await documentation.updateRepository(
          examplePath, exampleRepository,
          clean: _examplesToSync.last == example);
      if (isUpdated) nUpdated++;
    } catch (e, stacktrace) {
      print('Error: $e, \nCause: $stacktrace');
    }
  }

  print("Processed ${_examplesToSync.length} samples.");
  print("Updated $nUpdated repos.");
}

final _examplesToSync = <List<String>>[
  <String>[
    'public/docs/_examples/template-syntax/dart',
    'git@github.com:angular-examples/template-syntax.git'
  ],
  <String>[
    'public/docs/_examples/pipes/dart',
    'git@github.com:angular-examples/pipes.git'
  ],
  <String>[
    'public/docs/_examples/server-communication/dart',
    'git@github.com:angular-examples/server-communication.git'
  ],
  <String>[
    'public/docs/_examples/quickstart/dart',
    'git@github.com:angular-examples/quickstart.git'
  ],
  <String>[
    'public/docs/_examples/displaying-data/dart',
    'git@github.com:angular-examples/displaying-data.git'
  ],
  <String>[
    'public/docs/_examples/forms/dart',
    'git@github.com:angular-examples/forms.git'
  ],
  <String>[
    'public/docs/_examples/hierarchical-dependency-injection/dart',
    'git@github.com:angular-examples/hierarchical-dependency-injection.git'
  ],
  <String>[
    'public/docs/_examples/dependency-injection/dart',
    'git@github.com:angular-examples/dependency-injection.git'
  ],
  <String>[
    'public/docs/_examples/attribute-directives/dart',
    'git@github.com:angular-examples/attribute-directives.git'
  ],
  <String>[
    'public/docs/_examples/architecture/dart',
    'git@github.com:angular-examples/architecture.git'
  ],
];
