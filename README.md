# dart-doc-syncer
A utility for syncing dart examples for the public docs

Syncing a single example
------------------------

Run `dart_doc_syncer` to sync a single angular.io example folder to a given
example repository.

```
dart dart_doc_syncer <path_to_example> <repository>
```

- `path_to_example` the path to the example folder on the master branch of the
angular.io repository.
- `repository` the repository to which the content of the angular.io example
will be pushed to.

Syncing all configured examples
-------------------------------

Run `sync_all` to efficiently synchronize all configured examples.

```
dart sync_all
```
