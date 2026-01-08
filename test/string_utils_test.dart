import 'package:flutter_test/flutter_test.dart';
import 'package:kflavor/src/utils/string_utils.dart';

void main() {
  group('StringUtils', () {
    test('hasValue handles null, empty and whitespace-only', () {
      String? s;
      expect(s.hasValue, isFalse);

      s = '';
      expect(s.hasValue, isFalse);

      s = '   ';
      expect(s.hasValue, isFalse);

      s = '\n\t ';
      expect(s.hasValue, isFalse);

      s = 'a';
      expect(s.hasValue, isTrue);

      s = '  a  ';
      expect(s.hasValue, isTrue);
    });

    test('newLineSterilize collapses consecutive blank lines', () {
      String? s = 'a\n\n\nb';
      // Collapses multiple blank lines into single line breaks
      expect(s.newLineSterilize, equals('a\nb'));

      s = 'a\n\n\n\n\n\nb';
      expect(s.newLineSterilize, equals('a\nb'));

      s = null;
      expect(s.newLineSterilize, equals(''));

      s = 'a\n\n\nb\n\n\nc';
      expect(s.newLineSterilize, equals('a\nb\nc'));
    });

    test(
      'spaceSterilize collapses consecutive spaces but preserves single spaces and edges',
      () {
        String? s = 'a  b    c';
        expect(s.spaceSterilize, equals('a b c'));

        s = '   leading  and   multiple   ';
        // leading spaces preserved but consecutive internal spaces collapsed
        expect(s.spaceSterilize, equals(' leading and multiple '));

        s = null;
        expect(s.spaceSterilize, equals(''));

        s = 'noextra';
        expect(s.spaceSterilize, equals('noextra'));
      },
    );
  });
}
