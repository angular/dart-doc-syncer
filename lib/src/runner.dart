import 'dart:async';
import 'dart:io';
import 'package:logging/logging.dart';
import 'options.dart';

export 'options.dart' show options;

final Logger _logger = new Logger('runner');

Exception newException(String msg) => new Exception(msg);

Future<ProcessResult> run(String executable, List<String> arguments,
    {Map<String, String> environment,
    String workingDirectory,
    bool isException(ProcessResult r),
    Exception mkException(String msg): newException}) async {
  var cmd = "$executable ${arguments.join(' ')}";
  if (workingDirectory != null) cmd += ' ($workingDirectory)';
  _logger.finest('  > $cmd');

  if (!options.dryRun) {
    final r = await Process.run(executable, arguments,
        workingDirectory: workingDirectory, environment: environment);
    if (r.exitCode == 0 && (isException == null || !isException(r))) return r;
    // _logger.info('ERROR running: $cmd. Here are stderr and stdout:');
    // _logger.info(r.stderr);
    // _logger.info('\n' + '=' * 50 + '\nSTDOUT:\n');
    // _logger.info(r.stdout);
    throw mkException(r.stderr.isEmpty ? r.stdout : r.stderr);
  }

  if (executable == 'git' && arguments[0] == 'clone') {
    var path = arguments[2];
    new Directory(path).createSync(recursive: true);
  }
  const int _bogusPid = 0;
  const int _exitOk = 0;
  return new Future.value(new ProcessResult(_bogusPid, _exitOk, null, null));
}
