import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kflavor/src/model/config.dart';
import 'package:kflavor/src/processors/ide/android_studio/android_studio_config.dart';

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
  group('generateAndroidStudioRunConfig', () {
    late Directory tmpDir;
    late Directory origCwd;

    setUp(() {
      origCwd = Directory.current;
      tmpDir = Directory.systemTemp.createTempSync('kflavor_as_test_');
      Directory.current = tmpDir;
      Directory('.idea').createSync();
    });

    tearDown(() {
      Directory.current = origCwd;
      if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
    });

    test('generates config for main only', () {
      final workspace = File('.idea/workspace.xml');
      workspace.createSync(recursive: true);
      // minimal workspace xml with project root element
      workspace.writeAsStringSync(
        '<?xml version="1.0" encoding="UTF-8"?>\n<project version="4">\n</project>',
      );

      final config = DefaultConfig(
        config: FlavorConfig(
          flavor: 'main',
          config: _platformConfig('com.example.main'),
        ),
        buildRunner: false,
      );

      generateAndroidStudioRunConfig(config);

      final updated = workspace.readAsStringSync();
      expect(updated.contains('<component'), isTrue);
      expect(updated.contains('RunManager'), isTrue);
      expect(updated.contains('configuration'), isTrue);
    });

    test('generates config for flavors', () {
      final workspace = File('.idea/workspace.xml');
      workspace.createSync(recursive: true);
      workspace.writeAsStringSync(
        '<?xml version="1.0" encoding="UTF-8"?>\n<project version="4">\n</project>',
      );

      final config = FlavoredConfig(
        flavors: [
          FlavorConfig(
            flavor: 'dev',
            config: _platformConfig('com.example.dev'),
          ),
          FlavorConfig(
            flavor: 'prod',
            config: _platformConfig('com.example.prod'),
          ),
        ],
        buildRunner: false,
      );

      generateAndroidStudioRunConfig(config);

      final updated = workspace.readAsStringSync();
      expect(updated.contains('dev'), isTrue);
      expect(updated.contains('prod'), isTrue);
      expect(updated.contains('FlutterRunConfigurationType'), isTrue);
    });
  });
}
