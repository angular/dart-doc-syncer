import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Generates a README file for the example at [path].
Future generateReadme(String path) async {
  final syncData = new File(p.join(path, '.docsync.json'));
  final dataExists = await syncData.exists();

  if (dataExists) {
    await _generateSpecificReadme(path, await syncData.readAsStringSync());
    await syncData.delete();
  } else {
    await _generateGenericReadme(path);
  }
}

/// Generates a README file for the example at [path] based on the json map
/// [syncData].
Future _generateSpecificReadme(String path, String syncDataJson) async {
  final syncData = new SyncData.fromJson(syncDataJson);

  final linkSection = 'See also:\n' +
      syncData.links.map((String link) {
        return '- $link';
      }).join('\n');

  final readmeContent = '''
${syncData.name}
---------------

Welcome to the example application used in angular.io/dart's [${syncData.name}](${syncData.docLink}) page.

You can run a [hosted copy](${syncData.liveExampleLink}) of this sample. Or run your own copy:
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

/// Generates a generic README file for the example at [path].
Future _generateGenericReadme(String path) async {
  // TODO(thso): Provide backup README if no '.docsync' file is present.
}

/// Holds metadata about the example application that is used to generate a
/// README file.
class SyncData {
  final String name;
  final String docLink;
  final String repoLink;
  final String liveExampleLink;
  final List<String> links;

  SyncData._(
      {this.name,
      this.docLink,
      this.repoLink,
      this.liveExampleLink,
      this.links});

  factory SyncData.fromJson(String json) {
    final data = JSON.decode(json);
    return new SyncData._(
        name: data['name'],
        docLink: data['docLink'],
        repoLink: data['repoLink'],
        liveExampleLink: data['liveExampleLink'],
        links: data['links']);
  }
}
