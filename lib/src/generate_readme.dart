import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import 'options.dart';
import 'sync_data.dart';

final Logger _logger = new Logger('generateReadme');

/// Generates a README file for the example at [path].
Future generateReadme(String path, {String webdevNgPath}) async {
  final syncDataFile = new File(p.join(path, exampleConfigFileName));
  final dataExists = await syncDataFile.exists();

  final syncData = dataExists
      ? new SyncData.fromJson(await syncDataFile.readAsStringSync(),
          path: webdevNgPath)
      : new SyncData(title: p.basename(path), path: webdevNgPath);

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
      : '\nSee also:\n' +
          syncData.links.map((String link) {
            return '- $link';
          }).join('\n') +
          '\n';

  final newIssueUri =
      '//github.com/dart-lang/site-webdev/issues/new?title=[${options.branch}]%20${syncData.id}';

  String readmeContent = '''
$warningMessage## ${syncData.title}

Welcome to the example app used in the
[${syncData.title}](${syncData.docHref}) page
of [Dart for the web](${options.webdevURL}).
''';

  if (syncData.liveExampleHref.isNotEmpty)
    readmeContent += '''

You can run a [hosted copy](${syncData.liveExampleHref}) of this
sample. Or run your own copy:

1. Create a local copy of this repo (use the "Clone or download" button above).
2. Get the dependencies: `pub get`
''';

  var step = 3;
  if (options.useNewBuild)
    readmeContent += '''
${step++}. Get the webdev tool: `pub global activate webdev`
''';

  readmeContent += '''
${step++}. Launch a development server: `${options.useNewBuild ? 'webdev' : 'pub'} serve`
${step++}. In a browser, open [http://localhost:8080](http://localhost:8080)
''';

  if (!options.useNewBuild)
    readmeContent += '''

In Dartium, you'll see the app right away. In other modern browsers,
you'll have to wait a bit while pub converts the app.
''';

  readmeContent += '''
$linkSection
---

*Note:* The content of this repository is generated from the
[Angular docs repository][docs repo] by running the
[dart-doc-syncer](//github.com/dart-lang/dart-doc-syncer) tool.
If you find a problem with this sample's code, please open an [issue][].

[docs repo]: ${syncData.repoHref}
[issue]: $newIssueUri
''';

  final readmeFile = new File(p.join(path, 'README.md'));
  _logger.fine('Generating $readmeFile.');
  await readmeFile.writeAsString(readmeContent);
}
