import 'package:flutter_test/flutter_test.dart';
import 'package:kflavor/src/config/loader.dart';
import 'package:kflavor/src/model/config.dart';

void main() {
  group('parser.kConfigFromJson', () {
    test('no flavors returns DefaultConfig with buildRunner false', () {
      final json = <String, dynamic>{};
      final cfg = kConfigFromJson(json);
      expect(cfg, isA<DefaultConfig>());
      expect(cfg.buildRunner, isFalse);
    });

    test('build_runner string "yes" is parsed as true', () {
      final json = <String, dynamic>{'build_runner': 'yes'};
      final cfg = kConfigFromJson(json);
      expect(cfg.buildRunner, isTrue);
    });

    test('single flavor yields DefaultConfig with bundleId set', () {
      final json = {
        'flavors': {
          'dev': {'name': 'Dev App', 'id': 'com.example.dev'},
        },
      };

      final cfg = kConfigFromJson(json);
      expect(cfg, isA<DefaultConfig>());
      final c = cfg as DefaultConfig;
      expect(c.config.config.android.bundleId, equals('com.example.dev'));
      expect(c.config.config.ios.bundleId, equals('com.example.dev'));
    });

    test('multiple flavors yields FlavoredConfig with correct entries', () {
      final json = {
        'flavors': {
          'dev': {'name': 'Dev', 'id': 'com.example.dev'},
          'prod': {'name': 'Prod', 'id': 'com.example.prod'},
        },
      };

      final cfg = kConfigFromJson(json);
      expect(cfg, isA<FlavoredConfig>());
      final f = cfg as FlavoredConfig;
      expect(f.flavors.length, equals(2));
      expect(
        f.flavors.map((e) => e.flavor).toList(),
        containsAll(['dev', 'prod']),
      );
    });

    test('missing name throws StateError', () {
      final json = {
        'flavors': {
          'dev': {'id': 'com.example.dev'},
        },
      };

      expect(() => kConfigFromJson(json), throwsA(isA<StateError>()));
    });

    test('missing id throws StateError', () {
      final json = {
        'flavors': {
          'dev': {'name': 'Dev App'},
        },
      };

      expect(() => kConfigFromJson(json), throwsA(isA<StateError>()));
    });
  });
}
