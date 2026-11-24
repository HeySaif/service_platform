import 'package:flutter_test/flutter_test.dart';
import 'package:service_platform/src/core/validators.dart';

void main() {
  group('Validators', () {
    test('email', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('nope'), isNotNull);
      expect(Validators.email('a@b.co'), isNull);
    });

    test('password needs 6+ chars', () {
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password('123456'), isNull);
    });

    test('length bounds (title 5–80)', () {
      final v = Validators.length('Title', 5, 80);
      expect(v('abcd'), isNotNull);
      expect(v('abcde'), isNull);
      expect(v('a' * 81), isNotNull);
      expect(v('   '), isNotNull);
    });

    test('positive number, optional budget', () {
      expect(Validators.positiveNumber('', optional: true), isNull);
      expect(Validators.positiveNumber(''), isNotNull);
      expect(Validators.positiveNumber('0'), isNotNull);
      expect(Validators.positiveNumber('-5'), isNotNull);
      expect(Validators.positiveNumber('1500'), isNull);
    });
  });
}
