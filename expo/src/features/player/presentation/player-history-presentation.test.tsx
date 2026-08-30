import { fireEvent, render, waitFor } from '@testing-library/react-native';
import { Dimensions, StyleSheet } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { I18nProvider } from '../../../i18n';
import { CKThemeProvider, ckColors } from '../../../ui';
import { ImageAssets } from '../../../core/assets/image-assets';
import {
  PlayerActivityFeed,
  PlayerBattlelogData,
  PlayerBattlelogEntry,
  PlayerCwlAttack,
  PlayerCwlClan,
  PlayerCwlHistory,
  PlayerCwlSeason,
  PlayerWarStats,
  WarStatsFilter,
} from '../models';
import {
  PlayerActivityTab,
  PlayerBattlelogTab,
  PlayerCwlTab,
  WarFilterModal,
  activityAccent,
  activityImage,
  activityTitle,
} from './player-detail-components';

const actions = {
  loadActivity: jest.fn(async () => undefined),
  openClan: jest.fn(),
} as never;
const wrap = (child: React.ReactElement) =>
  render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 0, right: 0, bottom: 0, left: 0 },
      }}
    >
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">{child}</CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );

describe('player history row parity', () => {
  it('renders each loot resource and at most six army entries', async () => {
    const entry = new PlayerBattlelogEntry(
      '1',
      'ranked',
      'history',
      true,
      '#OPP',
      'Opponent',
      17,
      3,
      100,
      1234,
      2345,
      345,
      new Date('2026-08-30T12:00:00Z'),
      30,
      '',
      { u_1: 2, u_2: 3, u_3: 4, u_4: 5, u_5: 6, u_6: 7, u_7: 8 },
    );
    const screen = await wrap(
      <PlayerBattlelogTab data={new PlayerBattlelogData([entry], true, true)} />,
    );
    expect(screen.getByLabelText('Gold: 1234')).toBeTruthy();
    expect(screen.getByLabelText('Elixir: 2345')).toBeTruthy();
    expect(screen.getByLabelText('Dark Elixir: 345')).toBeTruthy();
    for (const count of [2, 3, 4, 5, 6, 7]) expect(screen.getByText(`×${count}`)).toBeTruthy();
    expect(screen.queryByText('×8')).toBeNull();
  });

  it('suppresses super-troop detail and uses value-change detail for XP', async () => {
    const screen = await wrap(
      <PlayerActivityTab
        verifiedTracking
        actions={actions}
        data={
          new PlayerActivityFeed([
            {
              time: new Date(),
              kind: 'superTroopBoost',
              itemType: 'troop',
              name: 'Super Barbarian',
              itemId: 1,
              townHallLevel: 17,
              previousLevel: 1,
              currentLevel: 2,
              previousValue: null,
              currentValue: null,
            },
            {
              time: new Date(),
              kind: 'experienceLevelChange',
              itemType: 'profile',
              name: '',
              itemId: null,
              townHallLevel: null,
              previousLevel: 99,
              currentLevel: 100,
              previousValue: '99',
              currentValue: '100',
            },
          ])
        }
      />,
    );
    expect(screen.getByText('Super Barbarian boosted')).toBeTruthy();
    expect(screen.queryByText('Level 1 → 2')).toBeNull();
    expect(screen.getByText('99 → 100')).toBeTruthy();
    expect(screen.getByTestId('activity-responsive-grid')).toBeTruthy();
    fireEvent.press(screen.getByRole('button', { name: /Currently tracked/i }));
    expect(screen.getByText('Currently tracked')).toBeTruthy();
  });

  it('uses Flutter artwork and detail accent for every activity branch', () => {
    const event = (
      kind: Parameters<typeof activityImage>[0]['kind'],
      itemType: Parameters<typeof activityImage>[0]['itemType'],
      name = 'Barbarian',
      currentValue: string | null = null,
    ) => ({
      time: new Date('2026-08-01T12:00:00Z'),
      kind,
      itemType,
      name,
      itemId: 1,
      townHallLevel: 17,
      previousLevel: 1,
      currentLevel: 2,
      previousValue: '1',
      currentValue,
    });
    expect(activityImage(event('troopUpgrade', 'troop'))).toBe(
      ImageAssets.getTroopImage('Barbarian'),
    );
    expect(activityImage(event('heroUpgrade', 'hero', 'Barbarian King'))).toBe(
      ImageAssets.getHeroImage('Barbarian King'),
    );
    expect(activityImage(event('spellUpgrade', 'spell', 'Rage Spell'))).toBe(
      ImageAssets.getSpellImage('Rage Spell'),
    );
    expect(activityImage(event('petUpgrade', 'pet', 'L.A.S.S.I'))).toBe(
      ImageAssets.getPetImage('L.A.S.S.I'),
    );
    expect(activityImage(event('equipmentUpgrade', 'equipment', 'Giant Gauntlet'))).toBe(
      ImageAssets.getGearImage('Giant Gauntlet'),
    );
    expect(activityImage(event('townHallUpgrade', 'townHall'))).toBe(ImageAssets.townHall(2));
    expect(activityImage(event('experienceLevelChange', 'profile'))).toBe(ImageAssets.xp);
    expect(activityImage(event('trophyRecord', 'trophy'))).toBe(ImageAssets.trophies);
    expect(activityImage(event('builderTrophyRecord', 'trophy'))).toBe(
      ImageAssets.builderBaseTrophy,
    );
    expect(activityImage(event('warPreferenceChange', 'profile', '', 'in'))).toBe(
      ImageAssets.warPreferenceIn,
    );
    expect(activityAccent(event('superTroopBoost', 'troop'))).toBe(ckColors.capitalPurple);
    expect(activityAccent(event('townHallUpgrade', 'townHall'))).toBe(ckColors.warGold);
    expect(activityAccent(event('experienceLevelChange', 'profile'))).toBe(ckColors.builderBlue);
    expect(activityAccent(event('trophyRecord', 'trophy'))).toBe(ckColors.legendBlue);
    expect(activityAccent(event('itemUnlocked', 'troop'))).toBe(ckColors.donationGreen);
    expect(activityAccent(event('troopUpgrade', 'troop'))).toBe(ckColors.legendBlue);
    expect(
      activityTitle(event('builderTrophyRecord', 'trophy'), ((key: string) =>
        key === 'playerBestTrophies' ? 'Best Trophies' : 'Builder Base') as never),
    ).toBe('Best Trophies · Builder Base');
  });

  it('shows stars instead of an unexplained clan rank and reveals defender context on demand', async () => {
    const clan = new PlayerCwlClan(
      '#C',
      'Clan',
      'badge.png',
      'Crystal League I',
      1,
      2,
      0,
      10,
      8,
      99,
    );
    const attack = new PlayerCwlAttack(
      '#W',
      1,
      'Opponent Clan',
      '#O',
      'Defender',
      '#D',
      16,
      2,
      3,
      100,
      1,
      30,
    );
    const season = new PlayerCwlSeason('2026-08', 17, 15, clan, [attack], 2, 8, 0);
    const screen = await wrap(
      <PlayerCwlTab data={new PlayerCwlHistory([season])} actions={actions} />,
    );
    expect(screen.queryByText(/#2/)).toBeNull();
    expect(screen.getByText('3')).toBeTruthy();
    expect(screen.getByTestId('cwl-season-stars-2026-08-0')).toBeTruthy();
    expect(screen.queryByText(/Defender/)).toBeNull();
    await fireEvent.press(screen.getByTestId('cwl-season-2026-08-0'));
    expect(screen.getByText(/Defender/)).toBeTruthy();
    expect(screen.getByText(/Opponent Clan/)).toBeTruthy();
    expect(screen.getByText(/August 2026/)).toBeTruthy();
  });

  it('normalizes dated CWL seasons and keeps participant-only cards collapsed', async () => {
    const clan = new PlayerCwlClan(
      '#C',
      'Clan',
      'badge.png',
      'Crystal League I',
      1,
      2,
      0,
      10,
      8,
      99,
    );
    const season = new PlayerCwlSeason('2026-08-15', 17, 15, clan, [], null, null, 0);
    const screen = await wrap(
      <PlayerCwlTab data={new PlayerCwlHistory([season])} actions={actions} />,
    );
    const card = screen.getByTestId('cwl-season-2026-08-15-0');

    expect(screen.getByText('August 2026')).toBeTruthy();
    expect(screen.getByText('Participant Only')).toBeTruthy();
    expect(screen.queryByTestId('cwl-season-stars-2026-08-15-0')).toBeNull();
    expect(card.props.accessibilityState.disabled).toBe(true);
    fireEvent.press(card);
    expect(screen.queryByText('Stars')).toBeNull();
  });

  it('caps the war filter dialog at 80% of the viewport and scrolls its body', async () => {
    const screen = await wrap(
      <WarFilterModal
        visible
        initialFilter={WarStatsFilter.defaultFilter()}
        warStats={new PlayerWarStats('', '#P', 17, { start: 0, end: 0 }, {}, [])}
        actions={{ loadWarFilterPresets: jest.fn(async () => []) } as never}
        onClose={jest.fn()}
        onApply={jest.fn()}
      />,
    );
    const style = StyleSheet.flatten(screen.getByTestId('war-filter-dialog').props.style);
    expect(style.maxHeight).toBe(Dimensions.get('window').height * 0.8);
    expect(screen.getByTestId('war-filter-scroll')).toBeTruthy();
  });

  it('uses picker controls and confirms saved-preset deletion from long press', async () => {
    const save = jest.fn(async () => undefined);
    const screen = await wrap(
      <WarFilterModal
        visible
        initialFilter={WarStatsFilter.defaultFilter()}
        warStats={new PlayerWarStats('', '#P', 17, { start: 0, end: 0 }, {}, [])}
        actions={
          {
            loadWarFilterPresets: jest.fn(async () => [
              {
                name: 'Perfect wars',
                filter: new WarStatsFilter({ allowedStars: [3], limit: 50 }),
              },
            ]),
            saveWarFilterPresets: save,
          } as never
        }
        onClose={jest.fn()}
        onApply={jest.fn()}
      />,
    );
    await waitFor(() => expect(screen.getByText('Perfect wars')).toBeTruthy());
    fireEvent(screen.getByTestId('war-filter-preset-Perfect wars'), 'longPress');
    await waitFor(() => expect(screen.getByText('Apply Preset')).toBeTruthy());
    fireEvent.press(screen.getByTestId('war-filter-delete-preset'));
    await waitFor(() =>
      expect(screen.getByText('Are you sure you want to delete "Perfect wars"?')).toBeTruthy(),
    );
    fireEvent.press(screen.getByTestId('war-filter-confirm-delete-preset'));
    await waitFor(() => expect(save).toHaveBeenCalledWith([]));

    fireEvent.press(screen.getByTestId('war-filter-date-mode-custom'));
    await waitFor(() => expect(screen.getByText('Not set – Not set')).toBeTruthy());
    fireEvent.press(screen.getByText('Not set – Not set'));
    await waitFor(() => expect(screen.getByLabelText('Previous month')).toBeTruthy());
    fireEvent.press(screen.getByTestId('war-filter-date-mode-season'));
    await waitFor(() => expect(screen.getByText('Year')).toBeTruthy());
    expect(screen.getByText('Month')).toBeTruthy();
  });

  it('renames a saved preset from its long-press action with duplicate validation', async () => {
    const save = jest.fn(async () => undefined);
    const screen = await wrap(
      <WarFilterModal
        visible
        initialFilter={WarStatsFilter.defaultFilter()}
        warStats={new PlayerWarStats('', '#P', 17, { start: 0, end: 0 }, {}, [])}
        actions={
          {
            loadWarFilterPresets: jest.fn(async () => [
              { name: 'Perfect wars', filter: WarStatsFilter.defaultFilter() },
              { name: 'CWL', filter: new WarStatsFilter({ warTypes: ['cwl'], limit: 50 }) },
            ]),
            saveWarFilterPresets: save,
          } as never
        }
        onClose={jest.fn()}
        onApply={jest.fn()}
      />,
    );
    await waitFor(() => expect(screen.getByText('Perfect wars')).toBeTruthy());
    fireEvent(screen.getByTestId('war-filter-preset-Perfect wars'), 'longPress');
    fireEvent.press(await screen.findByTestId('war-filter-rename-preset'));
    await waitFor(() => expect(screen.getByText('Rename Preset')).toBeTruthy());
    const input = screen.getByTestId('war-filter-rename-name');
    fireEvent.changeText(input, 'CWL');
    await waitFor(() =>
      expect(screen.getByTestId('war-filter-rename-name').props.value).toBe('CWL'),
    );
    fireEvent.press(screen.getByTestId('war-filter-confirm-rename-preset'));
    await waitFor(() =>
      expect(screen.getAllByText('A preset with this name already exists').length).toBeGreaterThan(
        0,
      ),
    );
    fireEvent.changeText(input, 'Perfect attacks');
    await waitFor(() =>
      expect(screen.getByTestId('war-filter-rename-name').props.value).toBe('Perfect attacks'),
    );
    fireEvent.press(screen.getByTestId('war-filter-confirm-rename-preset'));
    await waitFor(() =>
      expect(save).toHaveBeenCalledWith(
        expect.arrayContaining([expect.objectContaining({ name: 'Perfect attacks' })]),
      ),
    );
  });
});
