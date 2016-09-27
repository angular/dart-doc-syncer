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

How to get the tools
--------------------

1. Clone the repo: `git clone git@github.com:angular/dart-doc-syncer.git`
2. Make the bin files executable: `chmod 755 dart-doc-syncer/bin/*`
3. Get the dependencies: `cd dart-doc-syncer; pub get`

Options
-------

```
dart ~/GITHUB/dart-doc-syncer/bin/dart_doc_syncer.dart --help

Syncs angular.io example applications..

Usage: dart_doc_syncer [options] [<exampleName> | <examplePath> <exampleRepo>]

-h, --help           show this usage information
-b, --branch         <branch-name>
                     git angular.io branch to fetch
                     (defaults to "master")

-n, --dry-run        show which commands would be executed but make (almost) no changes;
                     only the temporary directory will be created

-f, --force-build    forces build of example app when sources have not changed
-k, --keep-tmp       do not delete temporary working directory (.tmp) once done
-p, --[no-]push      prepare updates and push to example repo
                     (defaults to on)

-m, --match          <dart-regexp>
                     sync all examples having a data file (.docsync.json)
                     and whose repo path matches the given regular expression;
                     use "." to match all

-u, --user           <user-id>
                     GitHub id of angular.io repo to fetch
                     (defaults to "angular")

-v, --verbose        
```
