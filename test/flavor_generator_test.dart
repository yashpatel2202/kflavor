import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kflavor/src/model/config.dart';
import 'package:kflavor/src/processors/flavor_generator.dart';

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
  group('generateFlavorProvider', () {
    late Directory tmpDir;
    late Directory origCwd;

    setUp(() {
      origCwd = Directory.current;
      tmpDir = Directory.systemTemp.createTempSync('kflavor_fg_test_');
      Directory.current = tmpDir;
    });

    tearDown(() {
      Directory.current = origCwd;
      if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
    });

    test('writes flavors.dart for DefaultConfig', () {
      final cfg = DefaultConfig(
        config: FlavorConfig(flavor: 'main', config: _platformConfig('App')),
        buildRunner: false,
      );

      generateFlavorProvider(cfg);

      final out = File('lib/kflavor/flavors.dart');
      expect(out.existsSync(), isTrue);
      final content = out.readAsStringSync();
      expect(content.contains('enum KFlavorType'), isTrue);
      // DefaultConfig generates a 'none' entry per current generator logic
      expect(content.contains('none'), isTrue);
    });

    test('writes flavors.dart with multiple flavors for FlavoredConfig', () {
      final cfg = FlavoredConfig(
        flavors: [
          FlavorConfig(flavor: 'dev', config: _platformConfig('AppDev')),
          FlavorConfig(flavor: 'prod', config: _platformConfig('AppProd')),
        ],
        buildRunner: false,
      );

      generateFlavorProvider(cfg);

      final out = File('lib/kflavor/flavors.dart');
      expect(out.existsSync(), isTrue);
      final content = out.readAsStringSync();
      expect(content.contains('enum KFlavorType'), isTrue);
      expect(content.contains('dev'), isTrue);
      expect(content.contains('prod'), isTrue);
      // Ensure class names for flavors were generated
      expect(content.contains('_DevFlavor'), isTrue);
      expect(content.contains('_ProdFlavor'), isTrue);
    });

    test('calling generator twice overwrites file', () {
      final cfg1 = FlavoredConfig(
        flavors: [FlavorConfig(flavor: 'one', config: _platformConfig('One'))],
        buildRunner: false,
      );
      final cfg2 = FlavoredConfig(
        flavors: [FlavorConfig(flavor: 'two', config: _platformConfig('Two'))],
        buildRunner: false,
      );

      generateFlavorProvider(cfg1);
      final out = File('lib/kflavor/flavors.dart');
      final first = out.readAsStringSync();
      expect(first.contains('one'), isTrue);

      generateFlavorProvider(cfg2);
      final second = out.readAsStringSync();
      expect(second.contains('two'), isTrue);
      expect(second.contains('one'), isFalse);
    });

    test('platform scheme and appLink are represented correctly', () {
      final cfg = DefaultConfig(
        config: FlavorConfig(flavor: 'main', config: _platformConfig('App')),
        buildRunner: false,
      );

      generateFlavorProvider(cfg);
      var content = File('lib/kflavor/flavors.dart').readAsStringSync();
      // default empty scheme/appLink should be 'null' strings in generated code
      expect(content.contains("scheme: 'null'"), isTrue);
      expect(content.contains("appLink: 'null'"), isTrue);

      // now generate with scheme/appLink values by creating a FlavorConfig with values
      final flav = FlavorConfig(
        flavor: 'main',
        config: PlatformConfig(
          android: Config(
            name: 'App',
            bundleId: 'com.example',
            scheme: 'kflavor',
            appLink: 'example.com',
            developmentTeam: '',
            icon: null,
          ),
          ios: Config(
            name: 'App',
            bundleId: 'com.example',
            scheme: 'kflavor',
            appLink: 'example.com',
            developmentTeam: '',
            icon: null,
          ),
          firebaseProject: '',
        ),
      );

      generateFlavorProvider(
        FlavoredConfig(flavors: [flav], buildRunner: false),
      );
      content = File('lib/kflavor/flavors.dart').readAsStringSync();
      expect(content.contains("scheme: 'kflavor'"), isTrue);
      expect(content.contains("appLink: 'example.com'"), isTrue);
    });

    test('handles hyphenated flavor names and pascal-casing', () {
      final cfg = FlavoredConfig(
        flavors: [
          FlavorConfig(flavor: 'dev-beta', config: _platformConfig('AppDev')),
        ],
        buildRunner: false,
      );

      generateFlavorProvider(cfg);

      final out = File('lib/kflavor/flavors.dart');
      expect(out.existsSync(), isTrue);
      final content = out.readAsStringSync();
      // ReCase should convert 'dev-beta' to 'DevBeta' for class name
      expect(content.contains('_DevBetaFlavor'), isTrue);
      expect(content.contains('dev-beta'), isTrue);
    });

    test('empty flavor name falls back to none', () {
      final cfg = FlavoredConfig(
        flavors: [
          FlavorConfig(flavor: '', config: _platformConfig('AppEmpty')),
        ],
        buildRunner: false,
      );

      generateFlavorProvider(cfg);

      final out = File('lib/kflavor/flavors.dart');
      expect(out.existsSync(), isTrue);
      final content = out.readAsStringSync();
      // empty flavor should map to 'none' in enum and class naming uses 'None'
      expect(content.contains('none'), isTrue);
      expect(content.contains('_NoneFlavor'), isTrue);
    });
  });
}
