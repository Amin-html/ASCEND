import 'package:flutter_test/flutter_test.dart';

import 'package:ascend/features/profile/domain/user_profile.dart';

void main() {
  group('normalizeName', () {
    test('trims and collapses whitespace', () {
      expect(normalizeName('  Amin   Adilov  '), 'Amin Adilov');
      expect(normalizeName('Amin\t\nAdilov'), 'Amin Adilov');
    });

    test('empty input stays empty', () {
      expect(normalizeName(''), '');
      expect(normalizeName('   '), '');
    });

    test('long names are cut to the limit without a trailing space', () {
      final long = '${'a' * 39} bbbbbb';
      final result = normalizeName(long);

      expect(result.length, lessThanOrEqualTo(maxNameLength));
      expect(result, 'a' * 39);
      expect(normalizeName('x' * 100).length, maxNameLength);
    });

    test('names within the limit are untouched', () {
      expect(normalizeName('Amin'), 'Amin');
      expect(normalizeName('x' * maxNameLength), 'x' * maxNameLength);
    });
  });

  group('UserProfile', () {
    test('without a name', () {
      const profile = UserProfile();

      expect(profile.hasName, isFalse);
      expect(profile.initial, '');
    });

    test('initial is the uppercased first letter', () {
      expect(const UserProfile(name: 'amin').initial, 'A');
      expect(const UserProfile(name: 'Анна').initial, 'А');
      expect(const UserProfile(name: 'анна').initial, 'А');
    });
  });
}