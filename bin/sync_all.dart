import 'dart:async';

import 'dart_doc_syncer.dart' as syncer;

final examplesToSync = <List<String>>[
  <String>[
    'public/docs/_examples/template-syntax/dart',
    'https://github.com/thso/dart-doc-syncer-test'
  ]
];

/// Syncs all angular.io example applications.
Future main(List<String> args) async {
  for (List<String> example in examplesToSync) {
    await syncer.main(example..addAll(args));
  }
}
