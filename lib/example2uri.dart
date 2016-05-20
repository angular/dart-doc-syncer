class Example2Uri {
  final String _exampleName;

  Example2Uri(this._exampleName);

  String get path => 'public/docs/_examples/$_exampleName/dart';

  String get repositoryUri =>
      'git@github.com:angular-examples/$_exampleName.git';
}
