import 'package:args/args.dart';
import 'package:kflavor/src/config/loader.dart';
import 'package:kflavor/src/logging/logger.dart';
import 'package:kflavor/src/model/config.dart';
import 'package:kflavor/src/processors/android/application_id_processor.dart';
import 'package:kflavor/src/processors/android/flavor_gradle_processor.dart';
import 'package:kflavor/src/processors/android/gradle_processor.dart';
import 'package:kflavor/src/processors/android/manifest_processor.dart';
import 'package:kflavor/src/processors/firebase/flutterfire_configure.dart';
import 'package:kflavor/src/processors/flavor_generator.dart';
import 'package:kflavor/src/processors/icon/icon_processor.dart';
import 'package:kflavor/src/utils/terminal_utils.dart';

class KFlavorRunner {
  KFlavorRunner() {
    setupLogging();
  }

  Future<void> run(List<String> args) async {
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

      await _execute(result);
    } catch (e) {
      log.severe(e);
    }
  }

  Future<void> _execute(ArgResults args) async {
    final config = _fetchConfig(args);

    _setupAndroid(config);

    //todo: in option selector, return null if no access to project
    await setupFirebase(config);

    await generateIcons(config);

    await runInTerminal('flutter clean');
    await runInTerminal('flutter pub get');

    log.finest('flavors generated successfully');
  }
}

KConfig _fetchConfig(ArgResults args) {
  log.fine('Loading configuration...');

  final filePath = args['file'] as String?;
  final config = ConfigLoader.load(filePath: filePath);

  generateFlavorProvider(config);

  log.fine('Configuration loaded successfully');
  return config;
}

void _setupAndroid(KConfig config) {
  saveGradleKts(config);
  updateApplyGradle();
  removeApplicationId();

  log.fine('gradle file updated successfully');

  updateAndroidManifest(config);
  autoFormatManifest();

  log.fine('manifest file updated successfully');
}
