import 'dart:io';

import 'package:ansi_styles/ansi_styles.dart';
import 'package:logging/logging.dart';

final log = Logger('KFlavor');

void setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    final colored = _colorize(record.level, '\n${record.message}');
    stdout.writeln(colored);
  });
}

String _colorize(Level level, String message) {
  if (level == Level.SEVERE || level == Level.SHOUT) {
    return AnsiStyles.red(message);
  }
  if (level == Level.WARNING) return AnsiStyles.yellow(message);
  if (level == Level.INFO) return AnsiStyles.white(message);
  if (level == Level.CONFIG) return AnsiStyles.blue(message);
  if (level == Level.FINEST) return AnsiStyles.green(message);
  if (level == Level.FINE || level == Level.FINER) {
    return AnsiStyles.cyan(message);
  }
  return message;
}
