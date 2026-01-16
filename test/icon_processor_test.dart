import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kflavor/src/model/config.dart';
import 'package:kflavor/src/processors/icon/icon_processor.dart';

PlatformConfig _platformConfig({
  String androidIcon = '',
  String iosIcon = '',
}) => PlatformConfig(
  android: Config(
    name: 'app',
    bundleId: 'com.example',
    scheme: '',
    appLink: '',
    developmentTeam: '',
    icon: androidIcon.hasValue
        ? IconConfig(path: androidIcon, background: '#FFFFFF')
        : null,
  ),
  ios: Config(
    name: 'app',
    bundleId: 'com.example',
    scheme: '',
    appLink: '',
    developmentTeam: '',
    icon: iosIcon.hasValue ? IconConfig(path: iosIcon, background: '') : null,
  ),
  firebase: null,
);

extension _StringX on String {
  bool get hasValue => this.isNotEmpty;
}

void main() {
  group('generateIcons', () {
    late Directory tmpDir;
    late Directory origCwd;

    setUp(() {
      origCwd = Directory.current;
      tmpDir = Directory.systemTemp.createTempSync('kflavor_icons_test_');
      Directory.current = tmpDir;
    });

    tearDown(() {
      Directory.current = origCwd;
      if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
    });

    test('no-op when no icons present', () async {
      final cfg = DefaultConfig(
        config: FlavorConfig(flavor: 'main', config: _platformConfig()),
        buildRunner: false,
      );

      await generateIcons(cfg);

      // No flutter_launcher_icons yaml files should exist
      final files = Directory.current
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('flutter_launcher_icons'))
          .toList();
      expect(files, isEmpty);
    });

    test(
      'default config creates and removes flutter_launcher_icons.yaml',
      () async {
        final cfg = DefaultConfig(
          config: FlavorConfig(
            flavor: 'main',
            config: _platformConfig(androidIcon: 'assets/icon.png'),
          ),
          buildRunner: false,
        );

        await generateIcons(cfg);

        // After run, files should be cleaned up by the function
        final files = Directory.current
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.contains('flutter_launcher_icons'))
            .toList();
        expect(files, isEmpty);
      },
    );

    test('flavors create and remove flavor-specific yaml files', () async {
      final cfg = FlavoredConfig(
        flavors: [
          FlavorConfig(
            flavor: 'dev',
            config: _platformConfig(androidIcon: 'assets/icon_dev.png'),
          ),
          FlavorConfig(
            flavor: 'qa',
            config: _platformConfig(iosIcon: 'assets/icon_qa.png'),
          ),
        ],
        buildRunner: false,
      );

      await generateIcons(cfg);

      final files = Directory.current
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.contains('flutter_launcher_icons'))
          .toList();
      expect(files, isEmpty);
    });
  });
}
