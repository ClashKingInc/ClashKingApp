import 'package:clashkingapp/features/war_cwl/models/cwl_clan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('weights clan attack and defense averages by played attempts', () {
    final clan = CwlClan.fromJson({
      'tag': '#CLAN',
      'name': 'Clan',
      'attack_count': 3,
      'members': [
        {
          'tag': '#ONE',
          'name': 'One',
          'attacks': {'stars': 3, 'attack_count': 1, 'total_destruction': 100},
          'defense': {'stars': 3, 'defense_count': 1, 'total_destruction': 100},
        },
        {
          'tag': '#TWO',
          'name': 'Two',
          'attacks': {'stars': 2, 'attack_count': 2, 'total_destruction': 150},
          'defense': {'stars': 1, 'defense_count': 2, 'total_destruction': 110},
        },
      ],
    });

    expect(clan.averageStars, closeTo(5 / 3, 0.0001));
    expect(clan.averageDestruction, closeTo(250 / 3, 0.0001));
    expect(clan.defAverageStars, closeTo(4 / 3, 0.0001));
    expect(clan.defAverageDestruction, closeTo(70, 0.0001));
  });

  test('returns zero averages when no attempts were played', () {
    final clan = CwlClan.fromJson({'members': []});

    expect(clan.averageStars, 0);
    expect(clan.averageDestruction, 0);
    expect(clan.defAverageStars, 0);
    expect(clan.defAverageDestruction, 0);
  });
}
