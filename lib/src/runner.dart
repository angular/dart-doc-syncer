import 'dart:async';
import 'dart:io';
import 'package:logging/logging.dart';
import 'options.dart';

export 'options.dart' show dryRun;

final Logger _logger = new Logger('runner');

Future<ProcessResult> run(String executable, List<String> arguments,
    {String workingDirectory}) {
  if (!dryRun)
    return Process.run(executable, arguments,
        workingDirectory: workingDirectory);

  var message = "  > $executable ${arguments.join(' ')}";
  if (workingDirectory != null) message += " ($workingDirectory)";
  _logger.finest(message);
  if (executable == 'git' && arguments[0] == 'clone') {
    var path = arguments[2];
    new Directory(path).createSync(recursive: true);
  }
  const int _bogusPid = 0;
  const int _exitOk = 0;
  return new Future.value(new ProcessResult(_bogusPid, _exitOk, null, null));
}
