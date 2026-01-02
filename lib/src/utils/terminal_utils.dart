import 'dart:convert';
import 'dart:io';

import 'package:kflavor/src/logging/logger.dart';

Future<void> runInTerminal(String command) async {
  log.config('running \'$command\'');

  final splitCommand = command.split(' ');
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
