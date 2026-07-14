import 'package:flutter_test/flutter_test.dart';
import 'package:tournaq/utils/player_name_generator.dart';

void main() {
  group('randomName', () {
    test('returns a "First Last" pair', () {
      for (var i = 0; i < 100; i++) {
        final name = PlayerNameGenerator.randomName();
        final parts = name.split(' ');
        expect(parts.length, greaterThanOrEqualTo(2));
        expect(parts.every((p) => p.isNotEmpty), isTrue);
      }
    });
  });

  group('uniqueNames', () {
    for (final count in [4, 32, 64, 128]) {
      test('returns $count distinct names', () {
        final names = PlayerNameGenerator.uniqueNames(count);
        expect(names.length, count);
        expect(names.toSet().length, count, reason: 'names must be unique');
      });
    }

    test('honours the excluding set', () {
      final taken = PlayerNameGenerator.uniqueNames(10).toSet();
      final more = PlayerNameGenerator.uniqueNames(10, excluding: taken);
      expect(more.length, 10);
      expect(more.toSet().intersection(taken), isEmpty);
    });

    test('count of zero yields an empty list', () {
      expect(PlayerNameGenerator.uniqueNames(0), isEmpty);
    });
  });
}
