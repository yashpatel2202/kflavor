import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kflavor/src/model/config.dart';
import 'package:kflavor/src/processors/ios/entitlement_processor.dart';

PlatformConfig _platformConfig({String iosAppLink = ''}) => PlatformConfig(
  android: const Config(
    name: 'app',
    bundleId: 'com.example',
    scheme: '',
    appLink: '',
    developmentTeam: '',
    icon: null,
  ),
  ios: Config(
    name: 'app',
    bundleId: 'com.example',
    scheme: '',
    appLink: iosAppLink,
    developmentTeam: '',
    icon: null,
  ),
  firebaseProject: '',
);

void main() {
  group('Entitlement processor', () {
    late Directory tmpDir;
    late Directory origCwd;

    setUp(() {
      origCwd = Directory.current;
      tmpDir = Directory.systemTemp.createTempSync('kflavor_ent_test_');
      Directory.current = tmpDir;
      Directory('ios/Runner').createSync(recursive: true);
    });

    tearDown(() {
      Directory.current = origCwd;
      if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
    });

    test('no-op when entitlement file missing', () {
      final cfg = DefaultConfig(
        config: FlavorConfig(flavor: 'main', config: _platformConfig()),
        buildRunner: false,
      );

      // Should not throw
      updateEntitlement(cfg);
    });

    test(
      'inserts associated-domains block before </dict> when appLink present',
      () {
        const content = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.example</string>
</dict>
</plist>
''';
        final file = File('ios/Runner/Runner.entitlements');
        file.writeAsStringSync(content);

        final cfg = DefaultConfig(
          config: FlavorConfig(
            flavor: 'main',
            config: _platformConfig(iosAppLink: 'example.com'),
          ),
          buildRunner: false,
        );

        updateEntitlement(cfg);

        final updated = file.readAsStringSync();
        expect(
          updated.contains('com.apple.developer.associated-domains'),
          isTrue,
        );
        expect(updated.contains('applinks:\$(APP_ASSOCIATED_DOMAIN)'), isTrue);
        // formatted output should include tabs since XmlDocument pretty prints with indent '\t'
        expect(updated.contains('\n\t'), isTrue);
      },
    );

    test('replaces existing associated-domains block when present', () {
      const content = '''<?xml version="1.0"?>
<plist>
<dict>
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:oldvalue</string>
</array>
</dict>
</plist>
''';
      final file = File('ios/Runner/Runner.entitlements');
      file.writeAsStringSync(content);

      final cfg = DefaultConfig(
        config: FlavorConfig(
          flavor: 'main',
          config: _platformConfig(iosAppLink: 'example.com'),
        ),
        buildRunner: false,
      );

      updateEntitlement(cfg);

      final updated = file.readAsStringSync();
      expect(updated.contains('applinks:oldvalue'), isFalse);
      expect(updated.contains('applinks:\$(APP_ASSOCIATED_DOMAIN)'), isTrue);
    });

    test('removes associated-domains block when appLink not present', () {
      const content = '''<?xml version="1.0"?>
<plist>
<dict>
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:example.com</string>
</array>
</dict>
</plist>
''';
      final file = File('ios/Runner/Runner.entitlements');
      file.writeAsStringSync(content);

      final cfg = DefaultConfig(
        config: FlavorConfig(flavor: 'main', config: _platformConfig()),
        buildRunner: false,
      );

      updateEntitlement(cfg);

      final updated = file.readAsStringSync();
      expect(
        updated.contains('com.apple.developer.associated-domains'),
        isFalse,
      );
      expect(updated.contains('applinks:'), isFalse);
    });

    test('supports <dict/> self-closing by replacing with full dict', () {
      const content = '''<?xml version="1.0"?>
<plist>
<dict/>
</plist>
''';
      final file = File('ios/Runner/Runner.entitlements');
      file.writeAsStringSync(content);

      final cfg = DefaultConfig(
        config: FlavorConfig(
          flavor: 'main',
          config: _platformConfig(iosAppLink: 'example.com'),
        ),
        buildRunner: false,
      );

      updateEntitlement(cfg);

      final updated = file.readAsStringSync();
      expect(updated.contains('<dict>'), isTrue);
      expect(
        updated.contains('com.apple.developer.associated-domains'),
        isTrue,
      );
    });
  });
}
