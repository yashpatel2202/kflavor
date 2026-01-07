import 'dart:convert';
import 'dart:io';

import 'package:kflavor/src/logging/logger.dart';
import 'package:kflavor/src/utils/string_utils.dart';

int failed = 0;

Future<void> runInTerminal(String command) async {
  final actualCommand = command.spaceSterilize.replaceAll('\n', ' ');
  log.config('running \'$actualCommand\'');

  final process = await Process.start('/bin/bash', ['-c', actualCommand]);

  process.stdout.transform(utf8.decoder).listen((data) => stdout.write(data));

  process.stderr.transform(utf8.decoder).listen((data) => stderr.write(data));

  final exitCode = await process.exitCode;

  if (exitCode != 0) {
    failed++;
    log.severe('\nProcess exited with error code: $exitCode');
  }
}

Future<bool> commandExists(String command) async {
  final isWindows = Platform.isWindows;

  final result = await Process.run(isWindows ? 'where' : 'which', [
    command,
  ], runInShell: true);

  return result.exitCode == 0;
}
