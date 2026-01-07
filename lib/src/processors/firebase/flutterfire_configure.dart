import 'dart:io';

import 'package:kflavor/src/model/config.dart';
import 'package:kflavor/src/utils/string_utils.dart';
import 'package:kflavor/src/utils/terminal_utils.dart';

import 'option_selector.dart';

Future<void> setupFirebase(KConfig config) async {
  _cleanup();

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
