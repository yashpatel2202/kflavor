import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kflavor/src/model/config.dart';
import 'package:kflavor/src/processors/ios/info_plist_processor.dart';

PlatformConfig _platformConfig({String iosScheme = ''}) => PlatformConfig(
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
    scheme: iosScheme,
    appLink: '',
    developmentTeam: '',
    icon: null,
  ),
  firebase: null,
);

void main() {
  group('Info.plist processor', () {
    late Directory tmpDir;
    late Directory origCwd;

    setUp(() {
      origCwd = Directory.current;
      tmpDir = Directory.systemTemp.createTempSync('kflavor_plist_test_');
      Directory.current = tmpDir;
      Directory('ios/Runner').createSync(recursive: true);
    });

    tearDown(() {
      Directory.current = origCwd;
      if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
    });

    test('sets CFBundleDisplayName and CFBundleName when keys absent', () {
      const content = '''<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
</dict>
</plist>
''';
      final file = File('ios/Runner/Info.plist');
      file.writeAsStringSync(content);

      final cfg = DefaultConfig(
        config: FlavorConfig(flavor: 'main', config: _platformConfig()),
        buildRunner: false,
      );

      updateInfoPlist(cfg);

      final updated = file.readAsStringSync();
      expect(updated.contains('<key>CFBundleDisplayName</key>'), isTrue);
      expect(updated.contains('<key>CFBundleName</key>'), isTrue);
      expect(updated.contains(r'$(APP_NAME)'), isTrue);
    });

    test('replaces existing CFBundleDisplayName and CFBundleName values', () {
      const content = '''<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
  <key>CFBundleDisplayName</key>
  <string>OldName</string>
  <key>CFBundleName</key>
  <string>OldName</string>
</dict>
</plist>
''';
      final file = File('ios/Runner/Info.plist');
      file.writeAsStringSync(content);

      final cfg = DefaultConfig(
        config: FlavorConfig(flavor: 'main', config: _platformConfig()),
        buildRunner: false,
      );

      updateInfoPlist(cfg);

      final updated = file.readAsStringSync();
      expect(updated.contains('<string>OldName</string>'), isFalse);
      expect(updated.contains(r'$(APP_NAME)'), isTrue);
    });

    test('adds CFBundleURLTypes with scheme when hasIOSScheme is true', () {
      const content = '''<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
</dict>
</plist>
''';
      final file = File('ios/Runner/Info.plist');
      file.writeAsStringSync(content);

      final cfg = DefaultConfig(
        config: FlavorConfig(
          flavor: 'main',
          config: _platformConfig(iosScheme: 'kflavor'),
        ),
        buildRunner: false,
      );

      // config.hasIOSScheme will be true when scheme non-empty
      updateInfoPlist(cfg);

      final updated = file.readAsStringSync();
      expect(updated.contains('CFBundleURLTypes'), isTrue);
      expect(updated.contains('CFBundleURLSchemes'), isTrue);
      expect(updated.contains(r'$(APP_URL_SCHEME)'), isTrue);
    });

    test('replaces existing CFBundleURLSchemes string when present', () {
      const content = '''<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
  <key>CFBundleURLTypes</key>
  <array>
    <dict>
      <key>CFBundleURLSchemes</key>
      <array>
        <string>oldscheme</string>
      </array>
    </dict>
  </array>
</dict>
</plist>
''';
      final file = File('ios/Runner/Info.plist');
      file.writeAsStringSync(content);

      final cfg = DefaultConfig(
        config: FlavorConfig(
          flavor: 'main',
          config: _platformConfig(iosScheme: 'kflavor'),
        ),
        buildRunner: false,
      );

      updateInfoPlist(cfg);

      final updated = file.readAsStringSync();
      expect(updated.contains('<string>oldscheme</string>'), isFalse);
      expect(updated.contains(r'$(APP_URL_SCHEME)'), isTrue);
    });

    test('removes CFBundleURLTypes block when scheme not provided', () {
      const content = '''<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
  <key>CFBundleURLTypes</key>
  <array>
    <dict>
      <key>CFBundleURLSchemes</key>
      <array>
        <string>toremove</string>
      </array>
    </dict>
  </array>
</dict>
</plist>
''';
      final file = File('ios/Runner/Info.plist');
      file.writeAsStringSync(content);

      final cfg = DefaultConfig(
        config: FlavorConfig(flavor: 'main', config: _platformConfig()),
        buildRunner: false,
      );

      updateInfoPlist(cfg);

      final updated = file.readAsStringSync();
      expect(updated.contains('CFBundleURLTypes'), isFalse);
      expect(updated.contains('toremove'), isFalse);
    });

    test('sets bundle name and display name', () {
      const content = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.example</string>
</dict>
</plist>
''';

      final file = File('ios/Runner/Info.plist');
      file.writeAsStringSync(content);

      final cfg = DefaultConfig(
        config: FlavorConfig(flavor: 'main', config: _platformConfig()),
        buildRunner: false,
      );

      updateInfoPlist(cfg);

      final updated = file.readAsStringSync();
      expect(updated.contains('<key>CFBundleDisplayName</key>'), isTrue);
      expect(updated.contains('<key>CFBundleName</key>'), isTrue);
      expect(updated.contains('<key>UILaunchStoryboardName</key>'), isTrue);
    });
  });
}
