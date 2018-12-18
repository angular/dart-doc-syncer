# dart-doc-syncer

A utility for syncing Dart examples for the AngularDart docs (https://webdev.dartlang.org/angular).

Example sources are read from the [dart-lang/site-webdev repo](https://github.com/dart-lang/site-webdev) and written
to individual repos under [angular-examples](https://github.com/angular-examples).

For specific commands to use when updating the AngularDart docs and examples, see
https://github.com/dart-lang/site-webdev/wiki/Updating-Angular-docs.

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

-h, --help                Show this usage information
-b, --branch              <branch-name>
                          Git branch to fetch webdev and examples from
                          (defaults to "master")

-n, --dry-run             Show which commands would be executed but make (almost) no changes;
                          only the temporary directory will be created

-f, --force-build         Forces build of example app when sources have not changed
-g, --gh-pages-app-dir    <path>
                          Directory in which the generated example apps will be placed (gh-pages branch)

-k, --keep-tmp            Do not delete temporary working directory once done
    --pub-get             Use `pub get` instead of `pub upgrade` before building apps
-p, --[no-]push           Prepare updates and push to example repo
                          (defaults to on)

-m, --match               <dart-regexp>
                          Sync all examples having a data file (.docsync.json)
                          and whose repo path matches the given regular expression;
                          use "." to match all

    --skip                <dart-regexp>
                          Negative filter applied to the project list created by use of the --match option

    --url                 [dev|main]
                          Webdev site URL to use in generated README.
                          (defaults to "main")

-u, --user                <user-id>
                          GitHub id of repo to fetch examples from
                          (defaults to "dart-lang")

-v, --verbose             
    --web-compiler        <compiler>, either dart2js or dartdevc
                          (defaults to "dart2js")

-w, --work-dir            <path>
                          Path to a working directory; when unspecified a system-generated path to a temporary directory is used
```
