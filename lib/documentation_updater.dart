import 'dart:async';

import 'package:dart_doc_syncer/src/git_documentation_updater.dart';
import 'package:dart_doc_syncer/src/git_repository.dart';

abstract class DocumentationUpdater {
  factory DocumentationUpdater() =>
      new GitDocumentationUpdater(new GitRepositoryFactory());

  /// Updates [outRepositoryUri] based on the content of the example under
  /// [examplePath] in the Angular docs repository.
  Future<bool> updateRepository(String examplePath, String outRepositoryUri,
      {String exampleName, bool push, bool clean});

  /// Updates all example repositories containing a doc syncer data file
  /// and whose path matches [re].
  Future<int> updateMatchingRepo(RegExp re, {bool push, bool clean});
}
