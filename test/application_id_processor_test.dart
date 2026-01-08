import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kflavor/src/processors/android/application_id_processor.dart';

void main() {
  group('application_id_processor.removeApplicationId', () {
    late Directory tmpDir;
    late Directory origCwd;

    setUp(() {
      origCwd = Directory.current;
      tmpDir = Directory.systemTemp.createTempSync('kflavor_appid_test_');
      Directory.current = tmpDir;
    });

    tearDown(() {
      Directory.current = origCwd;
      if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
    });

    test(
      'removes applicationId from defaultConfig block in build.gradle.kts',
      () {
        const buildGradle = r'''
plugins {
    id("com.android.application")
}

android {
    namespace = "com.example.app"

    defaultConfig {
        applicationId = "com.example.removeme"
        minSdk = 21
    }

    buildTypes {
        release {
            isMinifyEnabled = false
        }
    }
}
''';

        final file = File('android/app/build.gradle.kts');
        file.createSync(recursive: true);
        file.writeAsStringSync(buildGradle);

        removeApplicationId();

        final updated = file.readAsStringSync();
        // Should no longer contain applicationId assignment
        expect(updated.contains('applicationId'), isFalse);
        // Other content should remain
        expect(updated.contains('minSdk = 21'), isTrue);
        expect(updated.contains('namespace = "com.example.app"'), isTrue);
      },
    );

    test('leaves file unchanged when no applicationId present', () {
      const buildGradle = r'''
android {
    defaultConfig {
        minSdk = 21
    }
}
''';

      final file = File('android/app/build.gradle.kts');
      file.createSync(recursive: true);
      file.writeAsStringSync(buildGradle);

      removeApplicationId();

      final updated = file.readAsStringSync();
      expect(updated, equals(buildGradle));
    });

    test(
      'does not remove lines inside strings or comments that resemble applicationId',
      () {
        const buildGradle = r'''
android {
    defaultConfig {
        // applicationId = "should_not_remove_in_comment"
        val tricky = "this has applicationId = in a string"
        applicationId = "com.example.to_remove"
    }
}
''';

        final file = File('android/app/build.gradle.kts');
        file.createSync(recursive: true);
        file.writeAsStringSync(buildGradle);

        removeApplicationId();

        final updated = file.readAsStringSync();
        // commented and string occurrences should remain
        expect(updated.contains('should_not_remove_in_comment'), isTrue);
        expect(
          updated.contains('this has applicationId = in a string'),
          isTrue,
        );
        // actual applicationId assignment should be removed
        expect(updated.contains('com.example.to_remove'), isFalse);
      },
    );
  });
}
