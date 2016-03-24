import 'dart:async';

import 'package:dart_doc_syncer/src/git_documentation_updater.dart';
import 'package:dart_doc_syncer/src/git_repository.dart';

abstract class DocumentationUpdater {
  factory DocumentationUpdater() =>
      new GitDocumentationUpdater(new GitRepositoryFactory());

  /// Updates [outRepositoryUri] based on the content of the example under
  /// [examplePath] in the angular.io repository.
  Future updateRepository(String examplePath, String outRepositoryUri,
      {bool push: true, bool clean: true, String commitMessage: "Sync"});
}
