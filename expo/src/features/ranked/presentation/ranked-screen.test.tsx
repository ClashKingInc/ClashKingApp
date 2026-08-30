import { fireEvent, render } from '@testing-library/react-native';
import { StyleSheet } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { ImageAssets } from '../../../core/assets/image-assets';
import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import {
  PlayerClanOverview,
  RankedLeagueData,
  RankedLeagueGroup,
  RankedLeagueMember,
  RankedLeagueTier,
  type Player,
} from '../../player/models';
import { RankedScreen } from './ranked-screen';

const player = {
  name: 'Alpha',
  tag: '#ALPHA',
  townHallLevel: 18,
  townHallPic: 'town-hall.png',
  trophies: 1200,
  bestTrophies: 1300,
  clan: null,
  clanOverview: new PlayerClanOverview('#CLAN', 'Alpha Clan', 20, {
    small: 'badge.png',
    medium: '',
    large: '',
  }),
} as Player;

const tier = new RankedLeagueTier(2, 'Gold', 'tier-small.png', 'tier-large.png');
const member = new RankedLeagueMember('#ALPHA', 'Alpha', '#CLAN', 'Alpha Clan', 1200, 2, 1, 1, 2);
const group = new RankedLeagueGroup('#GROUP', 1_777_000_000, [member], [], []);
const data = new RankedLeagueData(
  ' alpha ',
  'Alpha',
  18,
  1200,
  1300,
  tier,
  new Map([[tier.id, tier]]),
  [],
  group,
);
const secondPlayer = { ...player, name: 'Beta', tag: '#BETA' } as Player;
const onSwitchPlayer = jest.fn();

const wrap = () =>
  render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <I18nProvider locale="en_GB">
        <CKThemeProvider preference="dark">
          <RankedScreen
            player={player}
            data={data}
            loading={false}
            refreshing={false}
            error={null}
            accounts={[player, secondPlayer]}
            bookmarked={false}
            linked
            onBack={jest.fn()}
            onRefresh={jest.fn(async () => undefined)}
            onSwitchPlayer={onSwitchPlayer}
            onToggleBookmark={jest.fn(async () => undefined)}
            onOpenInGame={jest.fn()}
            onOpenPlayerTag={jest.fn(async () => undefined)}
          />
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );

describe('RankedScreen player presentation', () => {
  beforeEach(() => onSwitchPlayer.mockClear());
  it('uses a compact safe-area hero with the shared full-bleed player backdrop', async () => {
    const screen = await wrap();

    const headerStyle = StyleSheet.flatten(screen.getByTestId('ranked-player-header').props.style);
    expect(headerStyle.minHeight).toBeUndefined();
    expect(headerStyle.overflow).toBe('hidden');
    expect(headerStyle.marginBottom).toBe(-44);
    const background = screen.getByTestId('ranked-header-background');
    expect(background.props.source).toContainEqual({ uri: ImageAssets.homeBaseBackground });
    expect(background.props.contentFit).toBe('cover');
    expect(StyleSheet.flatten(background.props.style)).toMatchObject({
      position: 'absolute',
      top: 0,
      right: 0,
      bottom: 0,
      left: 0,
    });
    expect(
      StyleSheet.flatten(screen.getByTestId('ranked-header-scrim').props.style).backgroundColor,
    ).toBe('#00000080');
    expect(
      StyleSheet.flatten(screen.getByTestId('ranked-header-fade-tail').props.style).height,
    ).toBe(44);
    expect(
      StyleSheet.flatten(screen.getByTestId('ranked-header-content').props.style),
    ).toMatchObject({
      paddingTop: 47,
      paddingBottom: 12,
      gap: 6,
    });
    expect(screen.getByText('Alpha Clan')).toBeTruthy();
  });

  it('uses the Flutter-style scrollable info popup with a text action', async () => {
    const screen = await wrap();

    await fireEvent.press(screen.getByLabelText('About Ranked League'));
    expect(screen.getByText('About Ranked League')).toBeTruthy();
    expect(screen.getByText('OK')).toBeTruthy();
    expect(StyleSheet.flatten(screen.getByText('OK').props.style).color).toBeTruthy();
    expect(
      StyleSheet.flatten(screen.getByTestId('ranked-info-action').props.style).backgroundColor,
    ).toBeUndefined();
  });

  it('renders and locates the current player in the live ranking', async () => {
    const screen = await wrap();

    await fireEvent.press(screen.getByText('Rankings'));
    expect(screen.getByTestId('ranked-current-player-row')).toBeTruthy();
    expect(screen.getByText('Jump to my rank')).toBeTruthy();
  });

  it('uses Flutter underline and compact ranked navigation treatments', async () => {
    const screen = await wrap();

    expect(
      StyleSheet.flatten(screen.getByTestId('profile-tabs-underline').props.style).height,
    ).toBe(50);
    expect(
      StyleSheet.flatten(screen.getByTestId('profile-tabs-underline-tab-period').props.style)
        .backgroundColor,
    ).toBeUndefined();
    expect(StyleSheet.flatten(screen.getByTestId('profile-tabs-compact').props.style).height).toBe(
      32,
    );
  });

  it('uses the shared centered account picker and selects by player tag', async () => {
    const screen = await wrap();

    await fireEvent.press(screen.getByRole('button', { name: /Switch account/i }));
    await fireEvent.press(screen.getByRole('radio', { name: 'Beta' }));
    expect(onSwitchPlayer).toHaveBeenCalledWith(secondPlayer);
  });

  it('restores independent Season and History scroll offsets', async () => {
    const screen = await wrap();
    const period = screen.getByTestId('ranked-scroll-period');
    await fireEvent.scroll(period, { nativeEvent: { contentOffset: { x: 0, y: 220 } } });
    await fireEvent(period, 'scrollEndDrag', {
      nativeEvent: { contentOffset: { x: 0, y: 220 } },
    });

    await fireEvent.press(screen.getByRole('tab', { name: 'History' }));
    expect(screen.getByTestId('ranked-scroll-history').props.contentOffset.y).toBe(0);
    const history = screen.getByTestId('ranked-scroll-history');
    await fireEvent.scroll(history, { nativeEvent: { contentOffset: { x: 0, y: 80 } } });
    await fireEvent(history, 'scrollEndDrag', {
      nativeEvent: { contentOffset: { x: 0, y: 80 } },
    });

    await fireEvent.press(screen.getByRole('tab', { name: 'Season' }));
    expect(screen.getByTestId('ranked-scroll-period').props.contentOffset.y).toBe(220);
  });

  it('ignores native scroll-end callbacks that arrive without an offset', async () => {
    const screen = await wrap();
    const period = screen.getByTestId('ranked-scroll-period');

    expect(() => period.props.onMomentumScrollEnd({ nativeEvent: null })).not.toThrow();
    expect(() => period.props.onScrollEndDrag({ nativeEvent: null })).not.toThrow();
    expect(period.props.contentOffset.y).toBe(0);
  });
});
