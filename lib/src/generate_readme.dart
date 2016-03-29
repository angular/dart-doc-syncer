import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Generates a README file for the example at [path].
Future generateReadme(String path, {String angularIoPath}) async {
  final syncDataFile = new File(p.join(path, '.docsync.json'));
  final dataExists = await syncDataFile.exists();

  final syncData = dataExists
      ? new SyncData.fromJson(await syncDataFile.readAsStringSync())
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

  final liveExampleSection = syncData.liveExampleLink == null
      ? 'To run your own copy:\n'
      : 'You can run a [hosted copy](${syncData.liveExampleLink}) of this'
      'sample. Or run your own copy:\n';

  final readmeContent = '''
${syncData.name}
---------------

Welcome to the example application used in angular.io/dart's [${syncData.name}](${syncData.docLink}) page.

$liveExampleSection
- Clone this repo.
- Download the dependencies.
    ```
    pub get
    ```
- Launch a development server.
    ```
    pub serve
    ```
- Open a browser to `http://localhost:8080`.
  In Dartium, you'll see the app right away. In other modern browsers, you'll have to wait a bit while pub converts the app.

$linkSection
''';

  final readmeFile = new File(p.join(path, 'README.md'));
  await readmeFile.writeAsStringSync(readmeContent);
}

/// Holds metadata about the example application that is used to generate a
/// README file.
class SyncData {
  final String name;
  final String docLink;
  final String repoLink;
  final String liveExampleLink;
  final List<String> links;

  SyncData(
      {this.name,
      this.docLink,
      this.repoLink,
      this.liveExampleLink,
      this.links: const []});

  factory SyncData.fromJson(String json) {
    final data = JSON.decode(json);
    return new SyncData(
        name: data['name'],
        docLink: data['docLink'],
        repoLink: data['repoLink'],
        liveExampleLink: data['liveExampleLink'],
        links: data['links']);
  }
}
