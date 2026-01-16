import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kflavor/src/runner.dart';

void main() {
  group('KFlavorRunner', () {
    late Directory tempDir;
    late Directory origCwd;

    setUp(() {
      origCwd = Directory.current;
      tempDir = Directory.systemTemp.createTempSync('kflavor_test_runner_');
      Directory.current = tempDir;
    });

    tearDown(() {
      Directory.current = origCwd;
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('parses --help and exits without throwing', () async {
      final runner = KFlavorRunner();
      await runner.run(['--help']);
    });

    test('runs with --file when file exists', () async {
      final runner = KFlavorRunner();
      final file = File('flavors.yaml');
      file.writeAsStringSync('flavors: []');
      await runner.run(['--file', 'flavors.yaml']);
    });

    test('runs generate subcommand with --file after subcommand', () async {
      final runner = KFlavorRunner();
      final file = File('flavors.yaml');
      file.writeAsStringSync('flavors: []');
      await runner.run(['generate', '--file', 'flavors.yaml']);
    });

    test(
      'configure subcommand parses --android-studio without throwing',
      () async {
        final runner = KFlavorRunner();
        await runner.run(['configure', '--android-studio']);
      },
    );
  });
}
