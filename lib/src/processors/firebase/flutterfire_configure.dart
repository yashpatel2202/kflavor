import 'dart:io';

import 'package:kflavor/src/model/config.dart';
import 'package:kflavor/src/utils/string_utils.dart';
import 'package:kflavor/src/utils/terminal_utils.dart';

import 'option_selector.dart';

/// Run `flutterfire configure` per-flavor when Firebase project ids are set.
///
/// This will cleanup previous firebase artifacts, run `flutterfire configure`
/// for each configured flavor (writing outputs to `lib/kflavor/firebase_options`)
/// and then generate a consolidated `lib/firebase_options.dart` selector.
Future<void> setupFirebase(KConfig config) async {
  await _cleanup();

  switch (config) {
    case DefaultConfig():
      await _flutterFireConfigure(_FFOption._fromConfig(config.config));
    case FlavoredConfig():
      for (final flavor in config.flavors) {
        await _flutterFireConfigure(_FFOption._fromConfig(flavor));
      }
  }

  generateFirebaseOptions(config);
}

/// Delete previous firebase configuration files and directories.
///
/// This removes the `lib/kflavor/firebase_options` directory, deletes
/// `android/app/src/google-services.json` and `ios/Runner/GoogleService-Info.plist`
/// if they exist, and runs a terminal command to remove the `Configs` directory
/// in the `ios` folder.
Future<void> _cleanup() async {
  const directoryPath = 'lib/kflavor/firebase_options';
  final directory = Directory(directoryPath);

  if (directory.existsSync()) {
    directory.deleteSync(recursive: true);
  }

  final androidFile = File('android/app/src/google-services.json');
  if (androidFile.existsSync()) androidFile.deleteSync(recursive: true);

  final iosFile = File('ios/Runner/GoogleService-Info.plist');
  if (iosFile.existsSync()) iosFile.deleteSync(recursive: true);

  await runInTerminal('cd ios && rm -rf Configs');
}

class _FFOption {
  final String androidAppId;
  final String iosBundleId;
  final String projectId;
  final String flavor;

  factory _FFOption._fromConfig(FlavorConfig config) {
    return ._(
      androidAppId: config.config.android.bundleId,
      iosBundleId: config.config.ios.bundleId,
      projectId: config.config.firebaseProject,
      flavor: config.flavor,
    );
  }

  const _FFOption._({
    required this.androidAppId,
    required this.iosBundleId,
    required this.projectId,
    required this.flavor,
  });
}

/// Configure Firebase for a specific flavor.
///
/// This runs the `flutterfire configure` command with the appropriate options
/// for the given flavor, including project ID, iOS bundle ID, and Android app ID.
///
/// The generated files are placed in the `lib/kflavor/firebase_options` directory,
/// and the command also specifies output locations for Android and iOS native code.
///
/// The [option] parameter must not have an empty project ID.
Future<void> _flutterFireConfigure(_FFOption option) async {
  if (!option.projectId.hasValue) return;

  final optionFileName =
      'lib/kflavor/firebase_options/firebase_options${option.flavor.hasValue ? '_${option.flavor}' : ''}.dart';

  final androidFileName =
      'android/app/src/${option.flavor.hasValue ? '${option.flavor}/' : ''}';

  final iosFileName =
      'ios/Configs/${option.flavor.hasValue ? '${option.flavor}/' : ''}';

  final command =
      '''flutterfire configure
                        --project=${option.projectId}
                        --ios-bundle-id=${option.iosBundleId}
                        --android-package-name=${option.androidAppId}
                        --out=$optionFileName
                        --android-out=$androidFileName
                        --ios-out=$iosFileName
                        --ios-target=Runner
                        --platforms=android,ios,web
                        --yes'''
          .spaceSterilize;

  await runInTerminal(command);
}
