import 'package:clashkingapp/features/pages/presentation/clan_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('clan member badge includes the 50-member capacity', () {
    expect(clanMemberCapacityLabel(39), '39/50');
    expect(clanMemberCapacityLabel(0), '0/50');
    expect(clanMemberCapacityLabel(50), '50/50');
  });
}
