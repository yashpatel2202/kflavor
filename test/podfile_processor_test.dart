import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kflavor/src/model/config.dart';
import 'package:kflavor/src/processors/ios/podfile_processor.dart';

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
  group('updatePodFile', () {
    late Directory tmpDir;
    late Directory origCwd;

    setUp(() {
      origCwd = Directory.current;
      tmpDir = Directory.systemTemp.createTempSync('kflavor_podfile_test_');
      Directory.current = tmpDir;
      Directory('ios').createSync(recursive: true);
    });

    tearDown(() {
      Directory.current = origCwd;
      if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
    });

    test('replaces project Runner block when present', () {
      final podfile = File('ios/Podfile');
      podfile.writeAsStringSync('''# some header
project 'Runner', {
  'Debug' => :debug,
}
# footer
''');

      final cfg = DefaultConfig(
        config: FlavorConfig(
          flavor: 'main',
          config: _platformConfig('com.example'),
        ),
        buildRunner: false,
      );

      updatePodFile(cfg);

      final updated = podfile.readAsStringSync();
      // Should have new project block with lines produced by _typeLine
      // DefaultConfig with flavor 'main' will generate suffixed entries like 'Debug-main'
      expect(updated.contains("'Debug-main' => :debug"), isTrue);
      expect(updated.contains("'Profile-main' => :release"), isTrue);
      expect(updated.contains("'Release-main' => :release"), isTrue);
    });

    test('no-op when project Runner block missing', () {
      final podfile = File('ios/Podfile');
      const orig = "# Podfile with no project block\nuse_frameworks!\n";
      podfile.writeAsStringSync(orig);

      final cfg = DefaultConfig(
        config: FlavorConfig(
          flavor: 'main',
          config: _platformConfig('com.example'),
        ),
        buildRunner: false,
      );

      updatePodFile(cfg);

      final updated = podfile.readAsStringSync();
      expect(updated, equals(orig));
    });

    test('generates flavor-specific entries for FlavoredConfig', () {
      final podfile = File('ios/Podfile');
      podfile.writeAsStringSync('''project 'Runner', {
  'Debug' => :debug,
}
''');

      final cfg = FlavoredConfig(
        flavors: [
          FlavorConfig(
            flavor: 'dev',
            config: _platformConfig('com.example.dev'),
          ),
          FlavorConfig(flavor: 'qa', config: _platformConfig('com.example.qa')),
        ],
        buildRunner: false,
      );

      updatePodFile(cfg);

      final updated = podfile.readAsStringSync();
      // Should contain Debug-dev and Debug-qa entries
      expect(updated.contains("'Debug-dev' => :debug"), isTrue);
      expect(updated.contains("'Debug-qa' => :debug"), isTrue);
      // Should also contain Release-dev/qa mappings
      expect(updated.contains("'Release-dev' => :release"), isTrue);
      expect(updated.contains("'Release-qa' => :release"), isTrue);
    });
  });
}
