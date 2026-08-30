import {
  clanInfoTabOrder,
  extractDiscordInviteCode,
  visibleClanInfoTabs,
} from './clan-info-contracts';

describe('clan info presentation contracts', () => {
  it('keeps the Flutter destination order and filters only explicitly disabled tabs', () => {
    expect(clanInfoTabOrder).toEqual([
      'members',
      'warLog',
      'joinLeave',
      'statistics',
      'rankings',
      'cwlHistory',
      'leaderboardHistory',
      'legendHistory',
      'records',
    ]);
    expect(visibleClanInfoTabs({ rankings: false, legendHistory: false })).toEqual([
      'members',
      'warLog',
      'joinLeave',
      'statistics',
      'cwlHistory',
      'leaderboardHistory',
      'records',
    ]);
  });

  it('extracts only the Discord invite code accepted by the Flutter header', () => {
    expect(extractDiscordInviteCode('Join us at https://discord.gg/Clash123 today')).toBe(
      'Clash123',
    );
    expect(extractDiscordInviteCode('discord.com/invite/King456')).toBe('King456');
    expect(extractDiscordInviteCode('no invite here')).toBeNull();
  });
});
