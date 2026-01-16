import 'dart:io';

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
import 'package:kflavor/src/processors/ide/android_studio/android_studio_config.dart';
import 'package:kflavor/src/processors/ide/vscode/visual_studio_config.dart';
import 'package:kflavor/src/processors/ios/xcodegen_processor.dart';
import 'package:kflavor/src/utils/terminal_utils.dart';

/// Entrypoint runner for the `kflavor` CLI and programmatic usage.
///
/// Parses command-line flags, loads the flavor configuration, and invokes the
/// platform-specific generators and helpers (Android, iOS, icons, Firebase,
/// IDE run configs). Construct and call `run` with the CLI `args` to execute.
class KFlavorRunner {
  KFlavorRunner() {
    setupLogging();
  }

  /// Runs the kflavor workflow using the provided CLI arguments.
  ///
  /// The `args` list should come from `main(List<String> args)` or similar; the
  /// method parses flags like `--file`, `--configure-android-studio`, and
  /// `--configure-vscode` and executes the corresponding steps. Errors are
  /// logged to the shared `log` instance.
  Future<void> run(List<String> args) async {
    try {
      final parser = ArgParser()
        ..addFlag('help', abbr: 'h', help: 'Display help message')
        ..addOption(
          'file',
          abbr: 'f',
          help: 'Path to configuration file',
          valueHelp: 'path/to/kflavor.yaml',
        )
        ..addFlag(
          'configure-android-studio',
          help: 'Generate Android Studio run configurations',
          defaultsTo: false,
        )
        ..addFlag(
          'cas',
          help: 'Alias for --configure-android-studio',
          defaultsTo: false,
        )
        ..addFlag(
          'configure-vscode',
          help: 'Generate VSCode run/debug configurations',
          defaultsTo: false,
        )
        ..addFlag(
          'cvs',
          help: 'Alias for --configure-vscode',
          defaultsTo: false,
        );

      // Register top-level subcommands. Users can call `kflavor generate` or
      // `kflavor configure`.
      // Define `generate` subcommand and add common flags so options can be
      // passed after the subcommand (e.g. `kflavor generate --file path`).
      parser.addCommand('generate')
        ..addOption(
          'file',
          abbr: 'f',
          help: 'Path to configuration file',
          valueHelp: 'path/to/kflavor.yaml',
        )
        ..addFlag(
          'configure-android-studio',
          help: 'Generate Android Studio run configurations',
          defaultsTo: false,
        )
        ..addFlag(
          'cas',
          help: 'Alias for --configure-android-studio',
          defaultsTo: false,
        )
        ..addFlag(
          'configure-vscode',
          help: 'Generate VSCode run/debug configurations',
          defaultsTo: false,
        )
        ..addFlag(
          'cvs',
          help: 'Alias for --configure-vscode',
          defaultsTo: false,
        );

      // Add flags for the `configure` subcommand. We add both long and short
      // aliases where requested (e.g. --android-studio and --as).
      parser.addCommand('configure')
        ..addFlag(
          'flutter-clean',
          help: 'Run `flutter clean && flutter pub get`',
          defaultsTo: false,
        )
        ..addFlag(
          'clear-pod',
          help:
              "Remove iOS Pods/ and Podfile.lock and run `pod install` on macOS",
          defaultsTo: false,
        )
        ..addFlag(
          'android-studio',
          help: 'Generate Android Studio run configurations',
          defaultsTo: false,
        )
        ..addFlag('as', help: 'Alias for --android-studio', defaultsTo: false)
        ..addFlag(
          'vscode',
          help: 'Generate VSCode run/debug configurations',
          defaultsTo: false,
        )
        ..addFlag('vs', help: 'Alias for --vscode', defaultsTo: false);

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

    // Determine which subcommand (if any) was invoked. `args.command` will be
    // non-null when a registered subcommand was used (e.g. `generate` or
    // `configure`). Only execute the corresponding workflow when the
    // command matches the requested action.
    final invokedCommand = args.command?.name;

    if (invokedCommand == 'generate') {
      // Pass the subcommand ArgResults so flags supplied after `generate`
      // are visible to `_generate`.
      await _generate(config, args.command ?? args);
      return;
    }

    if (invokedCommand == 'configure') {
      await _configure(config, args.command ?? args);
      return;
    }

    // If no subcommand was provided, default behaviour: run `generate`.
    // Keep passing the root args so existing root flags still work.
    await _generate(config, args);
  }
}

Future<void> _configure(KConfig config, ArgResults args) async {
  // The subcommand's ArgResults live in args.command when a subcommand was
  // used. Fall back to the root args so this function can be called directly
  // in tests.
  final sub = args.command ?? args;

  // --flutter-clean
  final flutterClean = (sub['flutter-clean'] as bool?) ?? false;

  // --clear-pod
  final clearPod = (sub['clear-pod'] as bool?) ?? false;

  // --android-studio / --as
  final androidStudio =
      ((sub['android-studio'] as bool?) ?? false) ||
      ((sub['as'] as bool?) ?? false);

  // --vscode / --vs
  final vscode =
      ((sub['vscode'] as bool?) ?? false) || ((sub['vs'] as bool?) ?? false);

  // Call each handler separately. No `else` branches are used so multiple
  // flags can be combined and each handler remains isolated.
  if (flutterClean) await _runFlutterClean();
  if (clearPod) await _runClearPod();
  if (androidStudio) _runAndroidStudioConfig(config);
  if (vscode) _runVSCodeConfig(config);

  if (failed > 0) {
    log.warning('Process completed with intermediate failures.');
    return;
  }

  log.finest('configurations applied successfully.');
}

// Handler for `--flutter-clean`.
Future<void> _runFlutterClean() async {
  await runInTerminal('flutter clean && flutter pub get');
}

// Handler for `--clear-pod`.
Future<void> _runClearPod() async {
  // Remove Pods/ and Podfile.lock if they exist.
  const removeCmd =
      'cd ios && if [ -d Pods ]; then rm -rf Pods; fi; if [ -f Podfile.lock ]; then rm -f Podfile.lock; fi;';
  await runInTerminal(removeCmd);
  if (Platform.isMacOS) {
    await runInTerminal('cd ios && pod install');
  } else {
    log.warning(
      '`--clear-pod` requested but not running on macOS; skipping `pod install`.',
    );
  }
}

// Handler for `--android-studio` / `--as`.
void _runAndroidStudioConfig(KConfig config) {
  generateAndroidStudioRunConfig(config);
}

// Handler for `--vscode` / `--vs`.
void _runVSCodeConfig(KConfig config) {
  generateVSCodeRunConfig(config);
}

Future<void> _generate(KConfig config, ArgResults args) async {
  await setupFirebase(config);

  _setupAndroid(config);

  await _setupIOS(config);

  await generateIcons(config);

  await runInTerminal('flutter clean');
  await runInTerminal('flutter pub get');

  if (Platform.isMacOS) {
    await runInTerminal(
      'cd ios && if [ -d Pods ]; then rm -rf Pods; fi; if [ -f Podfile.lock ]; then rm -f Podfile.lock; fi; pod install',
    );
  }

  if (config.buildRunner) {
    await runInTerminal('dart run build_runner build -d');
  }

  if (args['configure-android-studio'] == true || args['cas'] == true) {
    generateAndroidStudioRunConfig(config);
  }
  if (args['configure-vscode'] == true || args['cvs'] == true) {
    generateVSCodeRunConfig(config);
  }

  if (failed > 0) {
    log.warning('Process completed with intermediate failures.');
    return;
  }

  log.finest('flavors generated successfully');
}

/// Load configuration from the provided `ArgResults`.
///
/// Reads `--file` if provided, parses the flavors configuration, and generates
/// the `lib/kflavor/flavors.dart` provider used by downstream steps.
KConfig _fetchConfig(ArgResults args) {
  log.fine('Loading configuration...');

  final filePath = args['file'] as String?;
  final config = ConfigLoader.load(filePath: filePath);

  generateFlavorProvider(config);

  log.fine('Configuration loaded successfully');
  return config;
}

/// Applies Android-specific project updates (gradle files, manifest,
/// application id removal).
void _setupAndroid(KConfig config) {
  saveGradleKts(config);
  updateApplyGradle();
  removeApplicationId();

  updateAndroidManifest(config);
  autoFormatManifest();

  log.fine('android project updated successfully');
}

/// Applies iOS-specific project updates (xcodegen project creation and
/// related file updates). No-op on non-macOS platforms.
Future<void> _setupIOS(KConfig config) async {
  if (!Platform.isMacOS) return;

  await createXCodeProject(config);

  log.fine('ios project updated successfully');
}
