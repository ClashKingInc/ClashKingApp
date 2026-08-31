import { fireEvent, render } from '@testing-library/react-native';
import { StyleSheet } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { I18nProvider, type SupportedLocale } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import { PlayerSuperTroop, PlayerTroop } from '../models/player-items';
import {
  PlayerItemSection,
  formatDurationSeconds,
  formatPlayerResourceAmount,
} from './player-detail-components';
import {
  detailAccent,
  detailModalMaximumContentHeight,
  detailScaleDownFactor,
  upgradeDetailGradientEnd,
} from '../../upgrade-tracker/presentation/upgrade-tracker-breakdowns';
import { UpgradeCategory } from '../../upgrade-tracker/models';

const wrap = (child: React.ReactElement, locale: SupportedLocale = 'en') =>
  render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 0, right: 0, bottom: 0, left: 0 },
      }}
    >
      <I18nProvider locale={locale}>
        <CKThemeProvider preference="light">{child}</CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );
const source = {
  name: 'Barbarian',
  level: 7,
  maxLevel: 10,
  isUnlocked: true,
  meta: {
    info: 'First sentence. Second sentence. Third sentence.',
    levels: [
      { level: 1, required_townhall: 1, upgrade_time: 60, upgrade_cost: 100 },
      { level: 7, required_townhall: 13, upgrade_time: 60, upgrade_cost: 100 },
      { level: 10, required_townhall: 17, upgrade_time: 60, upgrade_cost: 100 },
    ],
  },
};

describe('PlayerItemSection modal routing', () => {
  it('routes ordinary items through the shared upgrade detail modal', async () => {
    const screen = await wrap(
      <PlayerItemSection
        title="Troops"
        items={[PlayerTroop.fromRaw(source)]}
        townHallLevel={17}
        initiallyExpanded
      />,
    );
    await fireEvent.press(screen.getByRole('button', { name: /Barbarian/ }));
    expect(await screen.findByRole('adjustable', { name: 'Level 7' })).toBeTruthy();
    expect(screen.getByText('First sentence. Second sentence.').props.numberOfLines).toBe(4);
    expect(screen.getByTestId('breakdown-fixed-content')).toBeTruthy();
    expect(screen.queryByTestId('breakdown-scroll')).toBeNull();
    expect(screen.getByTestId('upgrade-detail-hero')).toBeTruthy();
    const gradient = screen.getByTestId('upgrade-detail-gradient');
    expect(gradient.props.width).toBeUndefined();
    expect(gradient.props.height).toBeUndefined();
    expect(StyleSheet.flatten(gradient.props.style)).toMatchObject({
      position: 'absolute',
      top: 0,
      right: 0,
      bottom: 0,
      left: 0,
    });
    expect(
      StyleSheet.flatten(screen.getByTestId('upgrade-detail-dialog').props.style),
    ).toMatchObject({
      maxWidth: 440,
      maxHeight: '88%',
      overflow: 'hidden',
    });
    expect(upgradeDetailGradientEnd).toBe('100%');

    await fireEvent.press(screen.getByTestId('upgrade-detail-dialog'));
    expect(screen.getByRole('adjustable', { name: 'Level 7' })).toBeTruthy();
    await fireEvent.press(
      screen.getByTestId('upgrade-detail-backdrop', { includeHiddenElements: true }),
    );
    expect(screen.queryByRole('adjustable', { name: 'Level 7' })).toBeNull();
  });

  it('matches Flutter resource abbreviation and category accents', () => {
    expect(formatPlayerResourceAmount(160_500_000, 'en')).toBe('160.5M');
    expect(formatPlayerResourceAmount(160_000_000, 'en')).toBe('160M');
    expect(detailAccent(UpgradeCategory.heroes)).toBe('#AA57E8');
    expect(detailAccent(UpgradeCategory.troops)).toBe('#7A65D9');
    expect(detailAccent(UpgradeCategory.pets)).toBe('#E56B9F');
    expect(detailScaleDownFactor(700, 400)).toBeCloseTo(400 / 700);
    expect(detailScaleDownFactor(300, 400)).toBe(1);
    expect(detailModalMaximumContentHeight(844)).toBeCloseTo(844 * 0.88 - 40);
    expect(formatDurationSeconds(90_000, 'en')).toBe('1d 1h');
    expect(formatDurationSeconds(90_000, 'fr')).toBe('1j 1h');
  });

  it('localizes the remaining-upgrade summary and its accessibility copy', async () => {
    const screen = await wrap(
      <PlayerItemSection
        title="Troupes"
        items={[PlayerTroop.fromRaw(source)]}
        townHallLevel={17}
      />,
      'fr',
    );

    await fireEvent.press(screen.getByRole('button', { name: 'Restant pour l’Hôtel de ville 17' }));

    expect(screen.getByText('70 % terminé pour HDV17')).toBeTruthy();
    expect(screen.getByText('Temps restant')).toBeTruthy();
    expect(screen.getByText('Ressources')).toBeTruthy();
    expect(screen.getByRole('button', { name: 'Fermer' })).toBeTruthy();
  });

  it('uses Flutter one-decimal, intrinsic progress badges', async () => {
    const item = PlayerTroop.fromRaw({
      ...source,
      level: 1,
      maxLevel: 3,
      meta: {
        levels: [
          { level: 1, required_townhall: 1 },
          { level: 3, required_townhall: 17 },
        ],
      },
    });
    const screen = await wrap(
      <PlayerItemSection title="Troops" items={[item]} townHallLevel={17} />,
    );
    const badge = screen.getByTestId('section-progress-badge');
    const style = StyleSheet.flatten(badge.props.style);

    expect(screen.getByText('33.3%')).toBeTruthy();
    expect(screen.queryByText('33.33%')).toBeNull();
    expect(style.width).toBeUndefined();
    expect(style.height).toBeUndefined();
    expect(style.paddingHorizontal).toBe(10);
    expect(style.paddingVertical).toBe(6);
  });
  it('keeps the distinct Flutter super troop dialog and hides section progress', async () => {
    const superTroop = PlayerSuperTroop.fromRaw({
      ...source,
      name: 'Super Barbarian',
      meta: { name: 'Localized Super Barbarian', info: 'A localized super troop overview.' },
      superTroopIsActive: true,
    });
    const screen = await wrap(
      <PlayerItemSection
        title="Super Troops"
        items={[superTroop]}
        townHallLevel={17}
        initiallyExpanded
      />,
    );
    expect(screen.queryByText(/%/)).toBeNull();
    await fireEvent.press(screen.getByRole('button', { name: 'Super Barbarian' }));
    expect(await screen.findByText('Localized Super Barbarian')).toBeTruthy();
    expect(screen.getByText('Active')).toBeTruthy();
    expect(screen.getByText('Overview')).toBeTruthy();
    expect(screen.getByText('A localized super troop overview.')).toBeTruthy();
    expect(screen.queryByRole('adjustable')).toBeNull();
    expect(screen.queryByText('Upgrade plan')).toBeNull();
    expect(screen.queryByText('Levels left')).toBeNull();
    expect(screen.queryByText('Item stats')).toBeNull();

    await fireEvent.press(screen.getByTestId('player-item-detail-dialog'));
    expect(screen.getByText('Localized Super Barbarian')).toBeTruthy();
    await fireEvent.press(
      screen.getByTestId('player-item-detail-backdrop', { includeHiddenElements: true }),
    );
    expect(screen.queryByText('Localized Super Barbarian')).toBeNull();
  });
});
