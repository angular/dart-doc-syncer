### 0.2.0

This is the first changelog entry.

- Add support for new build system used as of Angular 5 alpha,
  in particular with a workaround for
  https://github.com/dart-lang/build/issues/890.
- Add support for `--web-compiler` option, with `dart2js` being the default.
- Commit `pubspec.lock` to `gh-pages` so that we know exactly
  which packages were used to build the app.
- Output of commands (like `git`) is now printed when
  `--verbose` is specified.
