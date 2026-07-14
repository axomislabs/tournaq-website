import 'package:flutter_test/flutter_test.dart';
import 'package:tournaq/utils/team_name_generator.dart';

List<String> _ids(int start, int n) =>
    List.generate(n, (i) => 'p${start + i}');

void main() {
  group('uniqueNames', () {
    // Regression for the reported bug: tournaments with many teams used to
    // repeat names once they passed the small pool size.
    for (final count in [2, 32, 64, 128, 256]) {
      test('returns $count distinct names', () {
        final names = TeamNameGenerator.uniqueNames(count);
        expect(names.length, count);
        expect(names.toSet().length, count, reason: 'all names must be unique');
        expect(names.any((n) => n.trim().isEmpty), isFalse);
      });
    }

    test('honours the excluding set', () {
      final taken = TeamNameGenerator.uniqueNames(10).toSet();
      final more = TeamNameGenerator.uniqueNames(10, excluding: taken);
      expect(more.length, 10);
      expect(more.toSet().intersection(taken), isEmpty);
    });

    test('count of zero or less yields an empty list', () {
      expect(TeamNameGenerator.uniqueNames(0), isEmpty);
      expect(TeamNameGenerator.uniqueNames(-5), isEmpty);
    });
  });

  group('deterministic (per-player) naming', () {
    test('forPlayers is stable for the same players regardless of order', () {
      final a = TeamNameGenerator.forPlayers(['p3', 'p1', 'p2']);
      final b = TeamNameGenerator.forPlayers(['p1', 'p2', 'p3']);
      final c = TeamNameGenerator.forPlayers(['p1', 'p2', 'p3']);
      expect(a, b);
      expect(b, c);
    });

    test('pairForPlayers returns two different names', () {
      for (var i = 0; i < 50; i++) {
        final (nameA, nameB) = TeamNameGenerator.pairForPlayers(
          _ids(i * 2, 2),
          _ids(i * 2 + 1000, 2),
        );
        expect(nameA, isNotEmpty);
        expect(nameB, isNotEmpty);
        expect(nameA, isNot(nameB));
      }
    });

    test('uniqueForTeams gives every team on a court a distinct name', () {
      final teams = List.generate(20, (i) => _ids(i * 2, 2));
      final names = TeamNameGenerator.uniqueForTeams(teams);
      expect(names.length, teams.length);
      expect(names.toSet().length, teams.length);
    });

    test('uniqueForTeams is deterministic for the same input', () {
      final teams = List.generate(8, (i) => _ids(i * 2, 2));
      expect(
        TeamNameGenerator.uniqueForTeams(teams),
        TeamNameGenerator.uniqueForTeams(teams),
      );
    });
  });

  group('randomName', () {
    test('never returns the excluded value', () {
      const excluded = 'Wave Crushers';
      for (var i = 0; i < 200; i++) {
        expect(TeamNameGenerator.randomName(excluding: excluded),
            isNot(excluded));
      }
    });

    test('returns a non-empty name', () {
      expect(TeamNameGenerator.randomName(), isNotEmpty);
    });
  });
}
