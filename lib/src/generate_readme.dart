import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Generates a README file for the example at [path].
Future generateReadme(String path, {String angularIoPath}) async {
  final syncDataFile = new File(p.join(path, '.docsync.json'));
  final dataExists = await syncDataFile.exists();

  final syncData = dataExists
      ? new SyncData.fromJson(await syncDataFile.readAsStringSync(),
          path: angularIoPath)
      : new SyncData(
          name: angularIoPath,
          docLink: '//github.com/angular/angular.io/' + angularIoPath);

  await _generateReadme(path, syncData);
  if (dataExists) await syncDataFile.delete();
}

/// Generates a README file for the example at [path] based on [syncData].
Future _generateReadme(String path, SyncData syncData) async {
  final linkSection = syncData.links.isEmpty
      ? ''
      : 'See also:\n' +
          syncData.links.map((String link) {
            return '- $link';
          }).join('\n');

  final liveExampleSection = syncData.liveExampleHref == null
      ? 'To run your own copy:\n'
      : 'You can run a [hosted copy](${syncData.liveExampleHref}) of this'
      'sample. Or run your own copy:\n';

  final readmeContent = '''
${syncData.name}
---------------

Welcome to the example application used in angular.io/dart's
[${syncData.name}](${syncData.repoHref}) page.

$liveExampleSection
- Clone this repo.
- Download the dependencies:

  `pub get`
- Launch a development server:

  `pub serve`
- Open a browser to `http://localhost:8080`.<br/>
  In Dartium, you'll see the app right away. In other modern browsers,
  you'll have to wait a bit while pub converts the app.

$linkSection
''';

  final readmeFile = new File(p.join(path, 'README.md'));
  await readmeFile.writeAsStringSync(readmeContent);
}

/// Holds metadata about the example application that is used to generate a
/// README file.
class SyncData {
  final String name;
  final String repoHref;
  final String liveExampleHref;
  final List<String> links;

  SyncData(
      {this.name, this.repoHref, this.liveExampleHref, this.links: const []});

  factory SyncData.fromJson(String json, {String path}) {
    final data = JSON.decode(json);
    return new SyncData(
        name: data['name'],
        repoHref: data['repoHref'] ?? '//github.com/angular/angular.io/' + path,
        liveExampleHref: data['liveExampleHref'],
        links: data['links'] ?? []);
  }
}
