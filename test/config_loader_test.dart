import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kflavor/src/config/loader.dart';

void main() {
  group('ConfigLoader', () {
    late Directory tempDir;
    late Directory origCwd;

    setUp(() {
      origCwd = Directory.current;
      tempDir = Directory.systemTemp.createTempSync('kflavor_test_loader_');
      Directory.current = tempDir;
    });

    tearDown(() {
      Directory.current = origCwd;
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('loads config from file', () {
      final file = File('flavors.yaml');
      file.writeAsStringSync('flavors: []');
      final config = ConfigLoader.load(filePath: 'flavors.yaml');
      expect(config, isNotNull);
    });

    test('throws on missing file', () {
      expect(
        () => ConfigLoader.load(filePath: 'missing.yaml'),
        throwsException,
      );
    });
  });
}
