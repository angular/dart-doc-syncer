import 'dart:async';

import 'src/git_documentation_updater.dart';
import 'src/git_repository.dart';

abstract class DocumentationUpdater {
  factory DocumentationUpdater() =>
      new GitDocumentationUpdater(new GitRepositoryFactory());

  /// Updates [outRepositoryUri] based on the content of the example under
  /// [examplePath] in the Angular docs repository.
  Future<bool> updateRepository(String examplePath, String outRepositoryUri,
      {String exampleName, bool push, bool clean});

  /// Updates all example repositories containing a doc syncer data file
  /// and whose path matches [match] but not [skip].
  Future<int> updateMatchingRepo(RegExp match, RegExp skip, {bool push, bool clean});
}
