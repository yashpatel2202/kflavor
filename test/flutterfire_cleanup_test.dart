import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kflavor/src/model/config.dart';
import 'package:kflavor/src/processors/firebase/flutterfire_configure.dart';

PlatformConfig _platformConfig(String id) => PlatformConfig(
  android: Config(
    name: id,
    bundleId: id,
    scheme: '',
    appLink: '',
    developmentTeam: '',
    icon: null,
  ),
  ios: Config(
    name: id,
    bundleId: id,
    scheme: '',
    appLink: '',
    developmentTeam: '',
    icon: null,
  ),
  firebaseProject: '',
);

void main() {
  group('setupFirebase cleanup', () {
    late Directory tmpDir;
    late Directory origCwd;

    setUp(() {
      origCwd = Directory.current;
      tmpDir = Directory.systemTemp.createTempSync('kflavor_ff_cleanup_');
      Directory.current = tmpDir;
      // ensure ios folder exists to satisfy cd ios && rm -rf Configs
      Directory('ios').createSync(recursive: true);
    });

    tearDown(() {
      Directory.current = origCwd;
      if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
    });

    test(
      'removes firebase options directory and platform files for DefaultConfig',
      () async {
        // arrange: create paths that _cleanup would remove
        final optionsDir = Directory('lib/kflavor/firebase_options');
        optionsDir.createSync(recursive: true);
        File(
          'lib/kflavor/firebase_options/dummy.dart',
        ).writeAsStringSync('// dummy');

        final androidFile = File('android/app/src/google-services.json');
        androidFile.createSync(recursive: true);
        androidFile.writeAsStringSync('{}');

        final iosFile = File('ios/Runner/GoogleService-Info.plist');
        iosFile.createSync(recursive: true);
        iosFile.writeAsStringSync('<plist></plist>');

        // create ios Configs folder (the cleanup will remove ios/Configs via shell)
        Directory('ios/Configs').createSync(recursive: true);
        Directory('ios/Configs/dev').createSync(recursive: true);

        final cfg = DefaultConfig(
          config: FlavorConfig(
            flavor: 'main',
            config: _platformConfig('com.example'),
          ),
          buildRunner: false,
        );

        // act
        await setupFirebase(cfg);

        // assert: options dir and files removed
        expect(optionsDir.existsSync(), isFalse);
        expect(androidFile.existsSync(), isFalse);
        expect(iosFile.existsSync(), isFalse);
        // ios/Configs may be removed by shell; either removed or empty
        final configsDir = Directory('ios/Configs');
        expect(configsDir.existsSync(), isFalse);
      },
    );

    test(
      'removes firebase options and platform files for FlavoredConfig',
      () async {
        // arrange: create paths
        final optionsDir = Directory('lib/kflavor/firebase_options');
        optionsDir.createSync(recursive: true);
        File(
          'lib/kflavor/firebase_options/dummy2.dart',
        ).writeAsStringSync('// dummy');

        final androidFile = File('android/app/src/google-services.json');
        androidFile.createSync(recursive: true);
        androidFile.writeAsStringSync('{}');

        final iosFile = File('ios/Runner/GoogleService-Info.plist');
        iosFile.createSync(recursive: true);
        iosFile.writeAsStringSync('<plist></plist>');

        Directory('ios/Configs/dev').createSync(recursive: true);

        final cfg = FlavoredConfig(
          flavors: [
            FlavorConfig(
              flavor: 'dev',
              config: _platformConfig('com.example.dev'),
            ),
          ],
          buildRunner: false,
        );

        // act
        await setupFirebase(cfg);

        // assert
        expect(optionsDir.existsSync(), isFalse);
        expect(androidFile.existsSync(), isFalse);
        expect(iosFile.existsSync(), isFalse);
        final configsDir = Directory('ios/Configs');
        expect(configsDir.existsSync(), isFalse);
      },
    );
  });
}
