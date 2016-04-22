import 'dart:async';

import 'package:dart_doc_syncer/documentation_updater.dart';
import 'package:logging/logging.dart';

/// Syncs all angular.io example applications.
Future main() async {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });

  for (List<String> example in _examplesToSync) {
    try {
      final documentation = new DocumentationUpdater();
      await documentation.updateRepository(example[0], example[1],
          clean: _examplesToSync.last == example);
    } catch (e, stacktrace) {
      print('Error: $e, \nCause: $stacktrace');
    }
  }
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
