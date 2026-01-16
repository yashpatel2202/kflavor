import 'dart:convert';
import 'dart:io';

import 'package:kflavor/src/logging/logger.dart';
import 'package:kflavor/src/utils/string_utils.dart';

/// Global counter incremented for any non-zero exit code from `runInTerminal`.
int failed = 0;

/// Run [command] in a bash subshell and stream output to stdout/stderr.
///
/// The function blocks until the process exits and increments [failed] if the
/// exit code is non-zero. Use this for short-lived external tool invocations.
Future<void> runInTerminal(String command, {bool report = false}) async {
  final actualCommand = command.spaceSterilize.replaceAll('\n', ' ');
  log.config('running \'$actualCommand\'');

  final isWindows = Platform.isWindows;

  // Use the native shell on Windows (cmd.exe). On POSIX systems use /bin/bash.
  final Process process;
  if (isWindows) {
    process = await Process.start('cmd.exe', ['/C', actualCommand]);
  } else {
    process = await Process.start('/bin/bash', ['-c', actualCommand]);
  }

  process.stdout.transform(utf8.decoder).listen((data) => stdout.write(data));

  process.stderr.transform(utf8.decoder).listen((data) => stderr.write(data));

  final exitCode = await process.exitCode;

  if (exitCode != 0 && report) {
    failed++;
    log.severe('\nProcess exited with error code: $exitCode');
  }
}

/// Check whether [command] exists in PATH by running `which` (or `where` on
/// Windows). Returns true when the executable is found.
Future<bool> commandExists(String command) async {
  final isWindows = Platform.isWindows;

  final result = await Process.run(isWindows ? 'where' : 'which', [
    command,
  ], runInShell: true);

  return result.exitCode == 0;
}
