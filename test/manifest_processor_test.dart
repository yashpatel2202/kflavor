import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kflavor/src/model/config.dart';
import 'package:kflavor/src/processors/android/manifest_processor.dart';

PlatformConfig _platformConfigWith({
  required String androidBundleId,
  String scheme = '',
  String appLink = '',
}) => PlatformConfig(
  android: Config(
    name: 'app',
    bundleId: androidBundleId,
    scheme: scheme,
    appLink: appLink,
    developmentTeam: '',
    icon: null,
  ),
  ios: Config(
    name: 'app',
    bundleId: androidBundleId,
    scheme: '',
    appLink: '',
    developmentTeam: '',
    icon: null,
  ),
  firebaseProject: '',
);

void main() {
  group('Android manifest processor', () {
    late Directory tmpDir;
    late Directory origCwd;

    setUp(() {
      origCwd = Directory.current;
      tmpDir = Directory.systemTemp.createTempSync('kflavor_manifest_test_');
      Directory.current = tmpDir;
      // ensure path exists
      Directory('android/app/src/main').createSync(recursive: true);
    });

    tearDown(() {
      Directory.current = origCwd;
      if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
    });

    test('adds https intent-filter when appLink present', () {
      const manifest = '''<?xml version="1.0" encoding="utf-8"?>
<manifest package="com.example.app" xmlns:android="http://schemas.android.com/apk/res/android">
    <application>
        <activity android:name=".MainActivity">
        </activity>
    </application>
</manifest>
''';

      final file = File('android/app/src/main/AndroidManifest.xml');
      file.writeAsStringSync(manifest);

      final cfg = DefaultConfig(
        config: FlavorConfig(
          flavor: 'main',
          config: _platformConfigWith(
            androidBundleId: 'com.example.app',
            appLink: 'example.com',
          ),
        ),
        buildRunner: false,
      );

      updateAndroidManifest(cfg);

      final updated = file.readAsStringSync();
      expect(
        updated.contains('autoVerify="true"') ||
            updated.contains('autoVerify="true"'),
        isTrue,
      );
      expect(updated.contains('host="@string/app_link"'), isTrue);
      expect(
        updated.contains('data') && updated.contains('scheme="https"'),
        isTrue,
      );
    });

    test('adds scheme intent-filter when scheme present', () {
      final manifest = '''<?xml version="1.0" encoding="utf-8"?>
<manifest package="com.example.app" xmlns:android="http://schemas.android.com/apk/res/android">
    <application>
        <activity android:name=".MainActivity">
        </activity>
    </application>
</manifest>
''';

      final file = File('android/app/src/main/AndroidManifest.xml');
      file.writeAsStringSync(manifest);

      final cfg = DefaultConfig(
        config: FlavorConfig(
          flavor: 'main',
          config: _platformConfigWith(
            androidBundleId: 'com.example.app',
            scheme: 'kflavor',
          ),
        ),
        buildRunner: false,
      );

      updateAndroidManifest(cfg);

      final updated = file.readAsStringSync();
      expect(updated.contains('scheme="@string/scheme"'), isTrue);
      expect(
        updated.contains('action') &&
            updated.contains('android.intent.action.VIEW'),
        isTrue,
      );
      expect(updated.contains('android.intent.category.BROWSABLE'), isTrue);
    });

    test('removes existing deep link intent-filters when flags are false', () {
      final manifest = '''<?xml version="1.0" encoding="utf-8"?>
<manifest package="com.example.app" xmlns:android="http://schemas.android.com/apk/res/android">
    <application>
        <activity android:name=".MainActivity">
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="https" android:host="example.com" />
            </intent-filter>
        </activity>
    </application>
</manifest>
''';

      final file = File('android/app/src/main/AndroidManifest.xml');
      file.writeAsStringSync(manifest);

      final cfg = DefaultConfig(
        config: FlavorConfig(
          flavor: 'main',
          config: _platformConfigWith(androidBundleId: 'com.example.app'),
        ),
        buildRunner: false,
      );

      updateAndroidManifest(cfg);

      final updated = file.readAsStringSync();
      // deep link intent filter should be removed
      expect(updated.contains('android.intent.action.VIEW'), isFalse);
      expect(updated.contains('android.intent.category.BROWSABLE'), isFalse);
      expect(
        updated.contains('data android:scheme="https"') ||
            updated.contains('scheme="https"'),
        isFalse,
      );
    });

    test('autoFormatManifest reformats multi-attribute opening tags', () {
      final manifest = '''<?xml version="1.0" encoding="utf-8"?>
<manifest package="com.example.app" xmlns:android="http://schemas.android.com/apk/res/android">
    <application>
        <activity android:name=".MainActivity" android:exported="true" android:label="@string/app_name">
        </activity>
    </application>
</manifest>
''';

      final file = File('android/app/src/main/AndroidManifest.xml');
      file.writeAsStringSync(manifest);

      autoFormatManifest();

      final updated = file.readAsStringSync();
      // Expect attributes to be on separate indented lines
      expect(
        updated.contains('\n            android:name=".MainActivity"'),
        isTrue,
      );
      expect(updated.contains('\n            android:exported="true"'), isTrue);
      expect(
        updated.contains('\n            android:label="@string/app_name"'),
        isTrue,
      );
    });
  });
}
