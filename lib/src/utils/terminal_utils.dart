import 'dart:convert';
import 'dart:io';

import 'package:kflavor/src/logging/logger.dart';
import 'package:kflavor/src/utils/string_utils.dart';

Future<void> runInTerminal(String command) async {
  final actualCommand = command.spaceSterilize.replaceAll('\n', ' ');
  log.config('running \'$actualCommand\'');

  final splitCommand = actualCommand.split(' ');

  final process = await Process.start(
    splitCommand[0],
    splitCommand.length > 1 ? splitCommand.sublist(1) : [],
  );

  process.stdout.transform(utf8.decoder).listen((data) => stdout.write(data));

  process.stderr.transform(utf8.decoder).listen((data) => stderr.write(data));

  final exitCode = await process.exitCode;

  if (exitCode != 0) {
    log.severe('\nProcess exited with error code: $exitCode');
  }
}
