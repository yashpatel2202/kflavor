import 'package:flutter_test/flutter_test.dart';
import 'package:kflavor/src/logging/logger.dart';
import 'package:logging/logging.dart';

void main() {
  group('Logger colorization', () {
    test('colorizeMessage for known levels', () {
      final s1 = colorizeMessage(Level.SEVERE, 'err');
      final s2 = colorizeMessage(Level.WARNING, 'warn');
      final s3 = colorizeMessage(Level.INFO, 'info');
      final s4 = colorizeMessage(Level.CONFIG, 'cfg');
      final s5 = colorizeMessage(Level.FINE, 'fine');
      final s6 = colorizeMessage(Level.FINER, 'finer');
      final s7 = colorizeMessage(Level.FINEST, 'finest');

      expect(s1.contains('err'), isTrue);
      expect(s2.contains('warn'), isTrue);
      expect(s3.contains('info'), isTrue);
      expect(s4.contains('cfg'), isTrue);
      expect(s5.contains('fine'), isTrue);
      expect(s6.contains('finer'), isTrue);
      expect(s7.contains('finest'), isTrue);
    });

    test('colorizeMessage for unknown level returns plain', () {
      final custom = Level('CUSTOM', 1500);
      final s = colorizeMessage(custom, 'plain');
      expect(s.contains('plain'), isTrue);
      expect(s.contains('\x1B['), isFalse);
    });
  });
}
