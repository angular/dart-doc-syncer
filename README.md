# dart-doc-syncer
A utility for syncing Dart examples for the Angular 2 docs (http://angular.io/dart).

The original use case is syncing examples from the [angular/angular.io repo](https://github.com/angular/angular.io)
to individual repos under [angular-examples](https://github.com/angular-examples).
For example, the definitive version of the
[Template Syntax](https://angular.io/docs/dart/latest/guide/template-syntax.html) chapter's example
lives under the angular/angular.io repo at
[`public/docs/_examples/template-syntax/dart`](https://github.com/angular/angular.io/tree/master/public/docs/_examples/template-syntax/dart).
For ease of downloading and viewing, dart-doc-syncer copies this example's files (with some modifications)
to https://github.com/angular-examples/template-syntax.
dart-doc-syncer also creates a running version of the sample, which lives at
https://angular-examples.github.io/template-syntax/.


Syncing a single example
------------------------

Run `dart_doc_syncer` to sync a single angular.io example folder to a given
example repository.

```
dart dart_doc_syncer <path_to_example> <repository>
```

- `path_to_example` the path to the example folder on the master branch of the
angular.io repository.
- `repository` the repository to copy the angular.io example to.

Syncing all configured examples
-------------------------------

Run `sync_all` to efficiently synchronize all configured examples.

```
dart sync_all
```
