import { accountPresentationItem, linkedAccountTags } from './contracts';

describe('linked-account presentation contracts', () => {
  it('preserves verification and visibility while shaping player metadata', () => {
    expect(
      accountPresentationItem({
        playerTag: '#ABC',
        isVerified: true,
        hidden: true,
        raw: { name: 'Player', townHallLevel: 17 },
      }),
    ).toEqual(
      expect.objectContaining({
        playerTag: '#ABC',
        name: 'Player',
        townHallLevel: 17,
        isVerified: true,
        hidden: true,
      }),
    );
  });

  it('uses the account-list fallbacks without losing the link', () => {
    expect(
      accountPresentationItem({ playerTag: '#PENDING', isVerified: false, hidden: false, raw: {} }),
    ).toEqual(expect.objectContaining({ name: '#PENDING', townHallLevel: 1 }));
  });

  it('hydrates link-only accounts from the already-loaded player profile', () => {
    expect(
      accountPresentationItem(
        { playerTag: '#PROFILE', isVerified: true, hidden: false, raw: {} },
        { name: 'Magic Jr.', townHallLevel: 17 },
      ),
    ).toEqual(expect.objectContaining({ name: 'Magic Jr.', townHallLevel: 17 }));
  });

  it('preserves the live draggable destination order for deferred persistence', () => {
    expect(
      linkedAccountTags([{ playerTag: '#TWO' }, { playerTag: '#THREE' }, { playerTag: '#ONE' }]),
    ).toEqual(['#TWO', '#THREE', '#ONE']);
  });
});
