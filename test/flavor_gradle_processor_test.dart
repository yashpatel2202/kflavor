import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kflavor/src/model/config.dart';
import 'package:kflavor/src/processors/android/flavor_gradle_processor.dart';

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
  group('saveGradleKts', () {
    late Directory tmpDir;
    late Directory origCwd;

    setUp(() {
      origCwd = Directory.current;
      tmpDir = Directory.systemTemp.createTempSync('kflavor_gradle_test_');
      Directory.current = tmpDir;
    });

    tearDown(() {
      Directory.current = origCwd;
      if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
    });

    test('creates kflavor.gradle.kts when build.gradle.kts exists', () {
      // Arrange: create build.gradle.kts to prefer Kotlin
      final buildKts = File('android/app/build.gradle.kts');
      buildKts.createSync(recursive: true);
      buildKts.writeAsStringSync('// kotlin build file');

      final cfg = DefaultConfig(
        config: FlavorConfig(
          flavor: 'main',
          config: _platformConfig('com.example.main'),
        ),
        buildRunner: false,
      );

      // Act
      saveGradleKts(cfg);

      // Assert
      final out = File('android/app/kflavor.gradle.kts');
      expect(out.existsSync(), isTrue);
      final content = out.readAsStringSync();
      expect(
        content,
        contains('applicationId'),
      ); // default config includes applicationId
    });

    test(
      'creates kflavor.gradle (groovy) when build.gradle exists and kts missing',
      () {
        // Arrange: ensure build.gradle.kts absent, but create build.gradle
        final buildGroovy = File('android/app/build.gradle');
        buildGroovy.createSync(recursive: true);
        buildGroovy.writeAsStringSync('// groovy build file');

        final cfg = FlavoredConfig(
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

        // Act
        saveGradleKts(cfg);

        // Assert
        final out = File('android/app/kflavor.gradle');
        expect(out.existsSync(), isTrue);
        final content = out.readAsStringSync();
        expect(
          content.contains('productFlavors') ||
              content.contains('android.productFlavors'),
          isTrue,
        );
        expect(content, contains('dev'));
        expect(content, contains('prod'));
      },
    );

    test('throws when neither build.gradle.kts nor build.gradle exist', () {
      final cfg = DefaultConfig(
        config: FlavorConfig(
          flavor: 'main',
          config: _platformConfig('com.example.main'),
        ),
        buildRunner: false,
      );

      expect(() => saveGradleKts(cfg), throwsA(isA<Exception>()));
    });
  });
}
