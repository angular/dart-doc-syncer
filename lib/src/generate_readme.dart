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
      : 'See also:\n' +
          syncData.links.map((String link) {
            return '- $link';
          }).join('\n');

  final liveExampleSection = syncData.liveExampleHref.isEmpty
      ? 'To run your own copy:'
      : 'You can run a [hosted copy](${syncData.liveExampleHref}) of this '
      'sample. Or run your own copy:';

  final newIssueUri = '//github.com/dart-lang/site-webdev/issues/new'
      '?labels=example&title=%5BAngular%5D%5Bexample%5D%20'
      '${syncData.id}%3A%20';

  final readmeContent = '''
$warningMessage

## ${syncData.title}

Welcome to the example application used in AngularDart's
[${syncData.title}](${syncData.docHref}) page.

$liveExampleSection

1. Clone or [download][] this repo.
   [download]: //github.com/angular-examples/${syncData.name}/archive/master.zip
2. Get the dependencies:

  `pub get`
3. Launch a development server:

  `pub serve`
4. Open a browser to `http://localhost:8080`.<br/>
  In Dartium, you'll see the app right away. In other modern browsers,
  you'll have to wait a bit while pub converts the app.

$linkSection

-------------------------------------------------------

*Note:* The content of this repository is generated from
[the Angular docs repository](${syncData.repoHref}) by running the
[dart-doc-syncer](//github.com/angular/dart-doc-syncer) tool.
If you find a problem with this sample's code, please open an
[issue]($newIssueUri).
''';

  final readmeFile = new File(p.join(path, 'README.md'));
  _logger.fine('Generating $readmeFile.');
  await readmeFile.writeAsString(readmeContent);
}
