import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kflavor/src/model/config.dart';
import 'package:kflavor/src/processors/firebase/option_selector.dart';

PlatformConfig _platformConfig(String id, {String firebase = ''}) =>
    PlatformConfig(
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
      firebaseProject: firebase,
    );

void main() {
  group('generateFirebaseOptions', () {
    late Directory tmpDir;
    late Directory origCwd;

    setUp(() {
      origCwd = Directory.current;
      tmpDir = Directory.systemTemp.createTempSync('kflavor_opt_sel_');
      Directory.current = tmpDir;
      // ensure directories exist
      Directory('lib/kflavor/firebase_options').createSync(recursive: true);
    });

    tearDown(() {
      Directory.current = origCwd;
      if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
    });

    test('does not create file when config has no firebase', () {
      final cfg = DefaultConfig(
        config: FlavorConfig(
          flavor: 'main',
          config: _platformConfig('com.example', firebase: ''),
        ),
        buildRunner: false,
      );

      generateFirebaseOptions(cfg);
      final out = File('lib/firebase_options.dart');
      expect(out.existsSync(), isFalse);
    });

    test(
      'creates file with import and switch for DefaultConfig flavor when option file exists',
      () {
        // create flavor-specific generated options file so _getAccessibleFlavor finds it
        final flavorFile = File(
          'lib/kflavor/firebase_options/firebase_options_dev.dart',
        );
        flavorFile.createSync(recursive: true);
        flavorFile.writeAsStringSync('// dummy firebase options for dev');

        final cfg = DefaultConfig(
          config: FlavorConfig(
            flavor: 'dev',
            config: _platformConfig('com.example', firebase: 'proj'),
          ),
          buildRunner: false,
        );

        generateFirebaseOptions(cfg);

        final out = File('lib/firebase_options.dart');
        expect(out.existsSync(), isTrue);
        final content = out.readAsStringSync();
        expect(content.contains('firebase_options_dev.dart'), isTrue);
        expect(content.contains('KFlavorType.dev'), isTrue);
      },
    );

    test(
      'creates file with imports for multiple flavored config when files exist',
      () {
        final dev = File(
          'lib/kflavor/firebase_options/firebase_options_dev.dart',
        );
        dev.createSync(recursive: true);
        dev.writeAsStringSync('// dev');
        final prod = File(
          'lib/kflavor/firebase_options/firebase_options_prod.dart',
        );
        prod.createSync(recursive: true);
        prod.writeAsStringSync('// prod');

        final cfg = FlavoredConfig(
          flavors: [
            FlavorConfig(
              flavor: 'dev',
              config: _platformConfig('com.example.dev', firebase: 'p'),
            ),
            FlavorConfig(
              flavor: 'prod',
              config: _platformConfig('com.example.prod', firebase: 'p'),
            ),
          ],
          buildRunner: false,
        );

        generateFirebaseOptions(cfg);

        final out = File('lib/firebase_options.dart');
        expect(out.existsSync(), isTrue);
        final content = out.readAsStringSync();
        expect(content.contains('firebase_options_dev.dart'), isTrue);
        expect(content.contains('firebase_options_prod.dart'), isTrue);
        expect(content.contains('KFlavorType.dev'), isTrue);
        expect(content.contains('KFlavorType.prod'), isTrue);
      },
    );
  });
}
