import 'dart:async';

import 'dart_doc_syncer.dart' as syncer;

final examplesToSync = <List<String>>[
  <String>[
    'public/docs/_examples/template-syntax/dart',
    'git@github.com:angular-examples/template-syntax.git'
  ]
];

/// Syncs all angular.io example applications.
Future main(List<String> args) async {
  for (List<String> example in examplesToSync) {
    await syncer.main(example..addAll(args));
  }
}
