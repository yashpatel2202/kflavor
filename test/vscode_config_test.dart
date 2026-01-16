import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kflavor/src/model/config.dart';
import 'package:kflavor/src/processors/ide/vscode/visual_studio_config.dart';

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
  firebase: null,
);

void main() {
  group('generateVSCodeRunConfig', () {
    late Directory tmpDir;
    late Directory origCwd;

    setUp(() {
      origCwd = Directory.current;
      tmpDir = Directory.systemTemp.createTempSync('kflavor_vscode_test_');
      Directory.current = tmpDir;
    });

    tearDown(() {
      Directory.current = origCwd;
      if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
    });

    test('preserves non-dart configs and adds main run/debug configs', () {
      // create existing launch.json with a non-dart configuration
      Directory('.vscode').createSync(recursive: true);
      final file = File('.vscode/launch.json');
      final existing = {
        'version': '0.2.0',
        'configurations': [
          {
            'name': 'Python: Current File',
            'type': 'python',
            'request': 'launch',
            'program': 'main.py',
          },
          {'name': 'Old Dart', 'type': 'dart', 'program': 'lib/old.dart'},
        ],
      };
      file.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(existing),
      );

      final cfg = DefaultConfig(
        config: FlavorConfig(
          flavor: 'main',
          config: _platformConfig('com.example'),
        ),
        buildRunner: false,
      );

      generateVSCodeRunConfig(cfg);

      final content =
          json.decode(file.readAsStringSync()) as Map<String, dynamic>;
      final configs = (content['configurations'] as List)
          .cast<Map<String, dynamic>>();

      // non-dart config should remain
      expect(configs.any((c) => c['type'] == 'python'), isTrue);
      // old dart config should be removed and replaced by Run main.dart and Debug main.dart
      expect(configs.any((c) => c['program'] == 'lib/old.dart'), isFalse);
      expect(configs.any((c) => c['name'] == 'Run main.dart'), isTrue);
      expect(configs.any((c) => c['name'] == 'Debug main.dart'), isTrue);
    });

    test('adds run/debug entries for each flavor', () {
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

      generateVSCodeRunConfig(cfg);

      final file = File('.vscode/launch.json');
      expect(file.existsSync(), isTrue);
      final content =
          json.decode(file.readAsStringSync()) as Map<String, dynamic>;
      final configs = (content['configurations'] as List)
          .cast<Map<String, dynamic>>();

      expect(configs.any((c) => c['name'] == 'Run dev'), isTrue);
      expect(configs.any((c) => c['name'] == 'Debug dev'), isTrue);
      expect(configs.any((c) => c['name'] == 'Run prod'), isTrue);
      expect(configs.any((c) => c['name'] == 'Debug prod'), isTrue);

      // args should include --flavor for flavored entries
      expect(
        configs.any(
          (c) => c['args'] is List && (c['args'] as List).contains('--flavor'),
        ),
        isTrue,
      );
    });
  });
}
