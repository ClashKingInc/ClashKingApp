import { fireEvent, render } from '@testing-library/react-native';

import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import type { ClanRosterItem } from './contracts';
import { ClanRosterCard } from './clan-card';

const item: ClanRosterItem = {
  tag: '#CLAN',
  name: 'Clash King',
  badgeUrl: 'badge.png',
  members: 47,
  warLeague: 'Champion League I',
  clanPoints: 51_234,
  countryCode: 'US',
  locationName: 'United States',
  type: 'inviteOnly',
  accountCount: 2,
  bookmarked: false,
};

describe('ClanRosterCard', () => {
  it('renders exact roster metadata and delegates opening', async () => {
    const onOpen = jest.fn();
    const screen = await render(
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <ClanRosterCard item={item} onOpen={onOpen} />
        </CKThemeProvider>
      </I18nProvider>,
    );

    expect(screen.getByText('47/50')).toBeTruthy();
    expect(screen.getByText('51,234')).toBeTruthy();
    expect(screen.getByText('Invite Only')).toBeTruthy();
    expect(screen.getByText('2 accounts')).toBeTruthy();
    await fireEvent.press(screen.getByRole('button', { name: 'Open clan Clash King' }));
    expect(onOpen).toHaveBeenCalledTimes(1);
  });
});
