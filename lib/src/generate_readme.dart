import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_doc_syncer/example2uri.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import 'options.dart';

final Logger _logger = new Logger('generateReadme');

/// Generates a README file for the example at [path].
Future generateReadme(String path, {String angularIoPath}) async {
  final syncDataFile = new File(p.join(path, exampleConfigFileName));
  final dataExists = await syncDataFile.exists();

  final syncData = dataExists
      ? new SyncData.fromJson(await syncDataFile.readAsStringSync(),
          path: angularIoPath)
      : new SyncData(title: p.basename(path), path: angularIoPath);

  await _generateReadme(path, syncData);
  if (dataExists) await syncDataFile.delete();
}

/// Generates a README file for the example at [path] based on [syncData].
Future _generateReadme(String path, SyncData syncData) async {
  final warningMessage = (syncData.docHref.isEmpty)
      ? '''
**WARNING:** This example is preliminary and subject to change.

------------------------------------------------------------------
      '''
      : '';

  final linkSection = syncData.links.isEmpty
      ? ''
      : 'See also:\n' +
          syncData.links.map((String link) {
            return '- $link';
          }).join('\n');

  final liveExampleSection = syncData.liveExampleHref.isEmpty
      ? 'To run your own copy:'
      : 'You can run a [hosted copy](${syncData.liveExampleHref}) of this '
      'sample. Or run your own copy:';

  final newIssueUri = '//github.com/angular/angular.io/issues/new'
      '?labels=dart,example&title=%5BDart%5D%5Bexample%5D%20'
      '${syncData.id}%3A%20';

  final readmeContent = '''
$warningMessage

## ${syncData.title}

Welcome to the example application used in angular.io/dart's
[${syncData.title}](${syncData.docHref}) page.

$liveExampleSection

1. Clone this repo.
2. Download the dependencies:

  `pub get`
3. Launch a development server:

  `pub serve`
4. Open a browser to `http://localhost:8080`.<br/>
  In Dartium, you'll see the app right away. In other modern browsers,
  you'll have to wait a bit while pub converts the app.

$linkSection

-------------------------------------------------------

*Note:* The content of this repository is generated from
[the angular.io repository](${syncData.repoHref}) by running the
[dart-doc-syncer](//github.com/angular/dart-doc-syncer) tool.
If you find a problem with this sample's code, please open an
[issue at angular/angular.io]($newIssueUri).
''';

  final readmeFile = new File(p.join(path, 'README.md'));
  _logger.fine('Generating $readmeFile.');
  await readmeFile.writeAsStringSync(readmeContent);
}

/// Holds metadata about the example application that is used to generate a
/// README file.
class SyncData {
  final String name; // e.g., 'architecture'
  final String title; // e.g. 'Architecture Overview'
  final String docPart; // e.g. 'guide' (from 'guide/architecture')
  final String docHref;
  final String repoHref;
  final String liveExampleHref;
  final List<String> links;

  String get id => p.join(docPart, name); // e.g. 'quickstart' or 'guide/architecture'

  SyncData(
      {String name: '',
      this.title: '',
      String docPart: '',
      String docHref: '',
      String liveExampleHref: '',
      this.links: const [],
      String repoHref: '',
      String path})
      : this.name = name.isEmpty ? getExampleName(path) : name,
        this.docPart = docPart,
        this.docHref = docHref.isEmpty
            ? p.join(dartDocUriPrefix, docPart, '${getExampleName(path)}.html')
            : docHref.startsWith('http')
                ? docHref
                : p.join(dartDocUriPrefix, docPart, docHref),
        this.liveExampleHref = liveExampleHref.isEmpty
            ? p.join(exampleHostUriPrefix, getExampleName(path))
            : liveExampleHref.startsWith('http')
                ? liveExampleHref
                : p.join(exampleHostUriPrefix, liveExampleHref),
        this.repoHref = repoHref.isEmpty
            ? '//github.com/angular/angular.io/tree/master/' + path
            : repoHref;

  factory SyncData.fromJson(String json, {String path}) {
    final data = JSON.decode(json);
    return new SyncData(
        name: data['name'] ?? '',
        title: data['title'] ?? '',
        docPart: data['docPart'] ?? '',
        docHref: data['docHref'] ?? '',
        repoHref: data['repoHref'] ?? '',
        liveExampleHref: data['liveExampleHref'] ?? '',
        links: data['links'] ?? [],
        path: path);
  }
}
