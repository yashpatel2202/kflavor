import 'package:args/args.dart';
import 'package:kflavor/src/config/loader.dart';
import 'package:kflavor/src/logging/logger.dart';

class KFlavorRunner {
  KFlavorRunner() {
    setupLogging();
  }

  void run(List<String> args) {
    try {
      final parser = ArgParser()
        ..addFlag('help', abbr: 'h', help: 'Display help message')
        ..addOption(
          'file',
          abbr: 'f',
          help: 'Path to configuration file',
          valueHelp: 'path/to/kflavor.yaml',
        );

      final result = parser.parse(args);

      if (result['help'] as bool) {
        log.info(parser.usage);
        return;
      }

      _execute(result);
    } catch (e) {
      log.severe(e);
    }
  }

  void _execute(ArgResults args) {
    log.fine('Loading configuration...');

    final filePath = args['file'] as String?;

    if (filePath != null && filePath.isNotEmpty) {
      log.info('Loading configuration from: $filePath');
      ConfigLoader.load(filePath: filePath);
    } else {
      log.info('Loading configuration from default location');
      ConfigLoader.load();
    }

    log.finest('Configuration loaded successfully');
  }
}
