import { fireEvent, render, waitFor } from '@testing-library/react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { I18nProvider } from '../../i18n';
import { CKThemeProvider } from '../../ui';
import {
  BuildingDefinition,
  BuildingLevelDefinition,
  DamageCatalog,
  DamageCalculatorSession,
  DamageLevel,
  DamageSourceDefinition,
  DamageSourceKind,
} from '../damage-calculator';
import { CalculatorsScreen } from './calculators-screen';

const catalog = new DamageCatalog({
  maxTownHall: 10,
  buildings: [
    new BuildingDefinition({
      id: 'town-hall',
      name: 'Town Hall',
      imageName: 'Town Hall',
      zapQuakeEligible: true,
      levels: [
        new BuildingLevelDefinition({
          level: 10,
          hitpoints: 5000,
          requiredTownHall: 10,
          upgradeResource: 'Gold',
          upgradeCost: 1_000_000,
        }),
      ],
    }),
  ],
  sources: [
    new DamageSourceDefinition({
      kind: DamageSourceKind.Lightning,
      name: 'Lightning Spell',
      imageUrl: 'https://assets.test/lightning.png',
      levels: [new DamageLevel({ level: 1, requiredTownHall: 1, damage: 500 })],
    }),
    new DamageSourceDefinition({
      kind: DamageSourceKind.Earthquake,
      name: 'Earthquake Spell',
      imageUrl: 'https://assets.test/earthquake.png',
      levels: [new DamageLevel({ level: 1, requiredTownHall: 1, earthquakePercent: 29 })],
    }),
  ],
});

function renderCalculator() {
  return render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <CalculatorsScreen
            session={new DamageCalculatorSession(catalog, { townHall: 10 })}
            accountPresets={[]}
            trackerSnapshot={null}
            trackerLoading={false}
            onFarmAccountChanged={jest.fn()}
            onOpenUpgradeTracker={jest.fn()}
            onBack={jest.fn()}
          />
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );
}

describe('CalculatorsScreen', () => {
  it('renders the complete Damage hierarchy and exact quick setups available from data', async () => {
    const view = await renderCalculator();
    expect(view.getByRole('button', { name: 'Back' })).toBeTruthy();
    expect(view.getByText('Account')).toBeTruthy();
    expect(view.getByText('Building to destroy')).toBeTruthy();
    expect(view.getByText('Manual attack stack')).toBeTruthy();
    expect(view.getByText('Custom')).toBeTruthy();
    expect(view.getByText('Zap + quake')).toBeTruthy();
  });

  it('switches to Farm Goal with account, target, loot, and missing-target result states', async () => {
    const view = await renderCalculator();
    fireEvent.press(view.getByText('Farm goal'));
    await waitFor(() => expect(view.getByText('Building to upgrade')).toBeTruthy());
    expect(view.getByText('Account')).toBeTruthy();
    expect(view.getByLabelText('Loot available in the village')).toBeTruthy();
    expect(
      view.getByText('Choose a building and target level to calculate the required attacks.'),
    ).toBeTruthy();
  });

  it('hides the Zap + quake optimizer until Flutter has a target to evaluate', async () => {
    const view = await renderCalculator();
    fireEvent.press(view.getByText('Zap + quake'));
    await waitFor(() => expect(view.getByText('Zap + quake')).toBeTruthy());
    expect(view.queryByText('Zap Quake optimizer')).toBeNull();

    fireEvent.press(view.getByRole('button', { name: 'Choose a building' }));
    await waitFor(() => expect(view.getByText('Town Hall')).toBeTruthy());
    fireEvent.press(view.getByText('Town Hall'));
    await waitFor(() => expect(view.getByText('Zap Quake optimizer')).toBeTruthy());
  });

  it('exposes Flutter-equivalent close and clear-search semantics in calculator sheets', async () => {
    const view = await renderCalculator();
    fireEvent.press(view.getByRole('button', { name: 'Choose a building' }));
    await waitFor(() => expect(view.getByRole('button', { name: 'Close' })).toBeTruthy());

    const search = view.getByLabelText('Search buildings');
    fireEvent.changeText(search, 'missing');
    await waitFor(() => expect(view.getByRole('button', { name: 'Clear search' })).toBeTruthy());
  });
});
