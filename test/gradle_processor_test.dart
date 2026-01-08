import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kflavor/src/processors/android/gradle_processor.dart';

void main() {
  group('updateApplyGradle', () {
    late Directory tmpDir;
    late Directory origCwd;

    setUp(() {
      origCwd = Directory.current;
      tmpDir = Directory.systemTemp.createTempSync('kflavor_gradle_proc_');
      Directory.current = tmpDir;
    });

    tearDown(() {
      Directory.current = origCwd;
      if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
    });

    test('creates apply block in build.gradle.kts when missing', () {
      final file = File('android/app/build.gradle.kts');
      file.createSync(recursive: true);
      file.writeAsStringSync('''
plugins { id("com.android.application") }
android { }
''');

      updateApplyGradle();

      final updated = file.readAsStringSync();
      expect(updated.contains('from("kflavor.gradle.kts")'), isTrue);
      // ensure apply block inserted only once
      expect(
        'from("kflavor.gradle.kts")'.allMatches(updated).length,
        equals(1),
      );
    });

    test(
      'inserts into existing apply block in build.gradle.kts and preserves content',
      () {
        final file = File('android/app/build.gradle.kts');
        file.createSync(recursive: true);
        file.writeAsStringSync('''
apply {
    // existing comment
}
''');

        updateApplyGradle();

        final updated = file.readAsStringSync();
        expect(updated.contains('// existing comment'), isTrue);
        expect(updated.contains('from("kflavor.gradle.kts")'), isTrue);
        // should not duplicate on second run
        updateApplyGradle();
        final updated2 = file.readAsStringSync();
        expect(
          'from("kflavor.gradle.kts")'.allMatches(updated2).length,
          equals(1),
        );
      },
    );

    test(
      'does not duplicate when flavor already present in kts apply block',
      () {
        final file = File('android/app/build.gradle.kts');
        file.createSync(recursive: true);
        file.writeAsStringSync('''
apply {
    from("kflavor.gradle.kts")
}
''');

        updateApplyGradle();

        final updated = file.readAsStringSync();
        expect(
          'from("kflavor.gradle.kts")'.allMatches(updated).length,
          equals(1),
        );
      },
    );

    test('creates apply block in build.gradle (groovy) when kts missing', () {
      final file = File('android/app/build.gradle');
      file.createSync(recursive: true);
      file.writeAsStringSync('''
// groovy build file
''');

      updateApplyGradle();

      final updated = file.readAsStringSync();
      expect(updated.contains("from('kflavor.gradle')"), isTrue);
      expect("from('kflavor.gradle')".allMatches(updated).length, equals(1));
    });

    test(
      'inserts into existing apply block in groovy and preserves content',
      () {
        final file = File('android/app/build.gradle');
        file.createSync(recursive: true);
        file.writeAsStringSync('''
apply {
    // some plugin
}
''');

        updateApplyGradle();

        final updated = file.readAsStringSync();
        expect(updated.contains('// some plugin'), isTrue);
        expect(updated.contains("from('kflavor.gradle')"), isTrue);
        updateApplyGradle();
        expect(
          "from('kflavor.gradle')".allMatches(updated).length,
          greaterThanOrEqualTo(1),
        );
      },
    );

    test('throws when neither build.gradle.kts nor build.gradle exist', () {
      // ensure no files exist
      final kts = File('android/app/build.gradle.kts');
      final groovy = File('android/app/build.gradle');
      if (kts.existsSync()) kts.deleteSync();
      if (groovy.existsSync()) groovy.deleteSync();

      expect(() => updateApplyGradle(), throwsA(isA<Exception>()));
    });
  });
}
