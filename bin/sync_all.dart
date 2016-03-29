import 'dart:async';

import 'dart_doc_syncer.dart' as syncer;

final examplesToSync = <List<String>>[
  <String>[
    'public/docs/_examples/template-syntax/dart',
    'https://github.com/angular-examples/template-syntax'
  ]
];

/// Syncs all angular.io example applications.
Future main(List<String> args) async {
  for (List<String> example in examplesToSync) {
    await syncer.main(example..addAll(args));
  }
}
