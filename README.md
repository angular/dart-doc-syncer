# dart-doc-syncer

A utility for syncing Dart examples for the AngularDart docs (https://webdev.dartlang.org/angular).

Example sources are read from the [dart-lang/site-webdev repo](https://github.com/dart-lang/site-webdev) and written
to individual repos under [angular-examples](https://github.com/angular-examples).

## Syncing a single example

Use the example name as an argument. For example:

```
dart dart_doc_syncer architecture
```

## Syncing multiple examples

The `--match` option takes a regular expression as an argument.
The `dart_doc_syncer` will sync all examples that match the regex.
To sync all examples, you can use `.` (dot) as a "match-all" pattern:

```
dart dart_doc_syncer --match .
```

## Options

```
dart ~/GITHUB/dart-doc-syncer/bin/dart_doc_syncer.dart --help

Syncs Angular docs example apps.

Usage: dart_doc_syncer [options] [<exampleName> | <examplePath> <exampleRepo>]

-h, --help                show this usage information
-b, --branch              <branch-name>
                          git branch to fetch webdev and examples from
                          (defaults to "master")

-n, --dry-run             show which commands would be executed but make (almost) no changes;
                          only the temporary directory will be created

-f, --force-build         forces build of example app when sources have not changed
-g, --gh-pages-app-dir    <path>
                          directory in which the generated example apps will be placed (gh-pages branch)

-k, --keep-tmp            do not delete temporary working directory once done
    --pub-get             use `pub get` instead of `pub upgrade` before building apps
-p, --[no-]push           prepare updates and push to example repo
                          (defaults to on)

-m, --match               <dart-regexp>
                          sync all examples having a data file (.docsync.json)
                          and whose repo path matches the given regular expression;
                          use "." to match all

-u, --user                <user-id>
                          GitHub id of repo to fetch examples from
                          (defaults to "dart-lang")

-v, --verbose             
-w, --work-dir            <path>
                          path to a working directory; when unspecified a system-generated path to a temporary directory is used
```
