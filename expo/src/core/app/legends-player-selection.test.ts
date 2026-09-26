import { Player } from '../../features/player/models';
import { selectLegendsPlayer } from './legends-player-selection';

const player = (tag: string, name: string) => Player.fromJson({ tag, name });

test('selects the viewed player for Legends even when that player is not a verified account', () => {
  const authenticatedPlayer = player('#AUTH', 'Authenticated');
  const viewedPlayer = player('#VIEWED', 'Viewed');

  expect(
    selectLegendsPlayer(
      [authenticatedPlayer, viewedPlayer],
      [authenticatedPlayer.tag],
      viewedPlayer.tag,
    ),
  ).toBe(viewedPlayer);
});

test('defaults to a verified account when Legends opens without a viewed player', () => {
  const unverifiedPlayer = player('#OTHER', 'Other');
  const verifiedPlayer = player('#AUTH', 'Authenticated');

  expect(
    selectLegendsPlayer([unverifiedPlayer, verifiedPlayer], [verifiedPlayer.tag]),
  ).toBe(verifiedPlayer);
});
