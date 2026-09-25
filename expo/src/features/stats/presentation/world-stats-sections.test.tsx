import { act, fireEvent, render, waitFor } from '@testing-library/react-native';
import { Image } from 'react-native';
import * as Clipboard from 'expo-clipboard';
import { captureRef } from 'react-native-view-shot';

import {
  gameDataState,
  replaceGameDataSection,
  resetGameDataStateForTesting,
} from '../../../core/game-data/game-data-state';
import { applyGameTranslations } from '../../../core/game-data/game-data-localization';
import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import { StatsClanCountsResponse, StatsGroupedCount, StatsPlayerCountsResponse } from '../models';
import { ClansSection, PlayersSection } from './world-stats-sections';

jest.mock('expo-clipboard', () => ({ setImageAsync: jest.fn() }));
jest.mock('react-native-view-shot', () => ({ captureRef: jest.fn() }));

afterEach(resetGameDataStateForTesting);

function Harness({
  children,
  locale = 'en',
}: {
  readonly children: React.ReactNode;
  readonly locale?: React.ComponentProps<typeof I18nProvider>['locale'];
}) {
  return (
    <I18nProvider locale={locale}>
      <CKThemeProvider preference="light">{children}</CKThemeProvider>
    </I18nProvider>
  );
}

test('shows every Town Hall at once with counts and shares', async () => {
  const townHalls = Array.from(
    { length: 8 },
    (_, index) => new StatsGroupedCount(index + 1, (index + 1) * 10),
  );
  const view = await render(
    <Harness>
      <PlayersSection data={new StatsPlayerCountsResponse(townHalls, [])} />
    </Harness>,
  );

  expect(view.queryByText('Current tracked player population')).toBeNull();
  expect(view.queryByText('360')).toBeNull();
  expect(view.getByText('TH8')).toBeTruthy();
  expect(view.getByLabelText('TH8, 80, 22.2%')).toBeTruthy();
  expect(view.getByText('TH2')).toBeTruthy();
  expect(view.queryByRole('button', { name: 'Expand' })).toBeNull();
  expect(view.getByTestId('town-halls-artwork-8')).toBeTruthy();
});

test('shows every ranked league in tier order without hiding the lower ranks', async () => {
  const leagues = Array.from(
    { length: 12 },
    (_, index) => new StatsGroupedCount(105000011 + index, index + 1),
  );
  const view = await render(
    <Harness>
      <PlayersSection data={new StatsPlayerCountsResponse([], leagues)} />
    </Harness>,
  );
  expect(view.getByText('L1')).toBeTruthy();
  expect(view.queryByRole('button', { name: 'Expand' })).toBeNull();
  const rows = view.getAllByTestId(/^ranked-leagues-row-/);
  expect(rows).toHaveLength(12);
  expect(rows[0]?.props.testID).toBe('ranked-leagues-row-105000022');
  expect(rows[11]?.props.testID).toBe('ranked-leagues-row-105000011');
});

test('uses current game metadata for ranked league identity and artwork', async () => {
  replaceGameDataSection(gameDataState.playerLeagueData, {
    leagues: {
      titan: {
        _id: 105000020,
        name: 'Titan League III',
        TID: { name: 'TID_LEAGUE_TITAN3' },
      },
    },
  });
  applyGameTranslations({ translations: { TID_LEAGUE_TITAN3: { FR: 'Ligue Titan III' } } }, 'FR');
  const view = await render(
    <Harness locale="fr">
      <PlayersSection
        data={new StatsPlayerCountsResponse([], [new StatsGroupedCount(105000020, 12)])}
      />
    </Harness>,
  );

  expect(view.getByText('Ligue Titan III')).toBeTruthy();
  expect(view.getByTestId('ranked-leagues-artwork-105000020')).toBeTruthy();
});

test('renders location distribution values instead of a cardinality-only summary', async () => {
  const view = await render(
    <Harness>
      <ClansSection
        data={
          new StatsClanCountsResponse(
            [new StatsGroupedCount(32000006, 30), new StatsGroupedCount(32000007, 10)],
            [new StatsGroupedCount(48_000_017, 12)],
            [new StatsGroupedCount(85_000_001, 8)],
            [{ id: 32000006, name: 'United States', countryCode: 'US' }],
          )
        }
      />
    </Harness>,
  );

  expect(view.getByText('Clan Locations')).toBeTruthy();
  expect(view.getByText('CWL leagues')).toBeTruthy();
  expect(view.getByText('Capital leagues')).toBeTruthy();
  expect(view.getByText('United States')).toBeTruthy();
  expect(view.getByLabelText('United States, 30, 75%')).toBeTruthy();
  expect(JSON.stringify(view.getByTestId('locations-artwork-32000006').props)).toContain(
    '/country-flags/us.png',
  );
  expect(view.getByText('Champion II')).toBeTruthy();
  expect(view.queryByText('Current tracked clan population')).toBeNull();
  expect(view.queryByText('40')).toBeNull();
  expect(view.queryByText('Coming Soon')).toBeNull();
});

test('keeps canonical CWL names for artwork while localizing the visible label', async () => {
  replaceGameDataSection(gameDataState.warLeagueData, {
    leagues: {
      'Champion League I': {
        _id: 48_000_018,
        name: 'Champion League I',
        TID: { name: 'TID_LEAGUE_CHAMPION1' },
      },
    },
  });
  applyGameTranslations(
    { translations: { TID_LEAGUE_CHAMPION1: { FR: 'Ligue des champions I' } } },
    'FR',
  );
  const view = await render(
    <Harness locale="fr">
      <ClansSection
        data={new StatsClanCountsResponse([], [new StatsGroupedCount(48_000_018, 12)], [])}
      />
    </Harness>,
  );

  expect(view.getByText('Ligue des champions I')).toBeTruthy();
  const artwork = JSON.stringify(view.getByTestId('cwl-leagues-artwork-48000018').props);
  expect(artwork).toContain('champion_league_1.png');
  expect(artwork).not.toContain('ligue_des_champions');
});

test('keeps empty distributions visible as quiet localized states', async () => {
  const view = await render(
    <Harness>
      <PlayersSection data={new StatsPlayerCountsResponse([], [])} />
    </Harness>,
  );

  expect(view.getByText('Town Halls')).toBeTruthy();
  expect(view.getByText('Ranked leagues')).toBeTruthy();
  expect(view.getAllByText('No data available.')).toHaveLength(2);
});

test('shows zero-count Town Halls and folds the legacy Legend badge into Unranked', async () => {
  const view = await render(
    <Harness>
      <PlayersSection data={new StatsPlayerCountsResponse(
        [new StatsGroupedCount(3, 20), new StatsGroupedCount(1, 10)],
        [new StatsGroupedCount(29000022, 20), new StatsGroupedCount(105000000, 10), new StatsGroupedCount(105000036, 5)],
      )} />
    </Harness>,
  );
  expect(view.getByLabelText('TH2, 0, 0%')).toBeTruthy();
  expect(view.getByText('Unranked')).toBeTruthy();
  expect(view.queryByText('Legend League')).toBeNull();
  expect(view.getByLabelText('Unranked, 30, 85.7%')).toBeTruthy();
  expect(view.getByText('Legend League 1')).toBeTruthy();
  expect(view.getByText('TH1')).toBeTruthy();
  expect(view.getByText('TH3')).toBeTruthy();
});

test('uses the verified Unranked CWL badge and excludes unknown locations from known-place percentages', async () => {
  const view = await render(<Harness>
    <ClansSection data={new StatsClanCountsResponse(
      [new StatsGroupedCount(null, 40), new StatsGroupedCount(32000006, 30), new StatsGroupedCount(32000007, 10)],
      [new StatsGroupedCount(48000000, 12)],
      [],
      [{ id: 32000006, name: 'United States', countryCode: 'US' }],
    )} />
  </Harness>);
  expect(view.getByText('Unranked')).toBeTruthy();
  expect(JSON.stringify(view.getByTestId('cwl-leagues-artwork-48000000').props)).toContain('unranked.png');
  expect(view.getByLabelText('United States, 30, 75%')).toBeTruthy();
  expect(view.queryByTestId('locations-row-unknown')).toBeNull();
});

test('copies the clan league chart through its export action', async () => {
  jest.spyOn(Image, 'prefetch').mockResolvedValue(true);
  jest.mocked(captureRef).mockResolvedValue('encoded-image');
  jest.mocked(Clipboard.setImageAsync).mockResolvedValue();
  const view = await render(<Harness>
    <ClansSection data={new StatsClanCountsResponse(
      [], [new StatsGroupedCount(48000022, 12)], [],
    )} />
  </Harness>);
  expect(view.queryByText('ClashKing')).toBeNull();
  await act(async () => fireEvent.press(view.getByTestId('cwl-leagues-copy')));
  await act(async () => view.getByTestId('stats-chart-export', { includeHiddenElements: true }).props.onLayout());
  await waitFor(() => expect(Clipboard.setImageAsync).toHaveBeenCalledWith('encoded-image'));
  expect(view.getByRole('button', { name: 'Copied to clipboard' })).toBeTruthy();
});

test('shows populated clan member-size bins in numeric order', async () => {
  const view = await render(<Harness>
    <ClansSection data={new StatsClanCountsResponse([], [], [], [], [
      { minMembers: 46, maxMembers: 50, count: 12 },
      { minMembers: 1, maxMembers: 5, count: 9 },
      { minMembers: 0, maxMembers: 0, count: 1 },
    ])} />
  </Harness>);
  const rows = view.getAllByTestId(/^clan-members-row-/);
  expect(rows.map((row) => row.props.testID)).toEqual([
    'clan-members-row-1', 'clan-members-row-46',
  ]);
  expect(view.getByText('1–5')).toBeTruthy();
  expect(view.getByText('46–50')).toBeTruthy();
  expect(view.queryByRole('button', { name: 'Expand' })).toBeNull();
});
