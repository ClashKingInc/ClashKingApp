import { act, fireEvent, render } from '@testing-library/react-native';

import { StyleSheet } from 'react-native';
import { I18nProvider } from '../../../i18n';
import { CKThemeProvider, townHallDisplayColor } from '../../../ui';
import { StatsCwlResponse } from '../models';
import { CwlParticipationSection, estimatedRosterPlaces } from './cwl-participation-section';

test('normalized roster places add up to war size with stable rounding', () => {
  expect(estimatedRosterPlaces([
    { level: 18, count: 20 }, { level: 17, count: 10 }, { level: 16, count: 10 },
  ], 15)).toEqual([
    { level: 18, count: 20, share: 0.5, places: 7 },
    { level: 17, count: 10, share: 0.25, places: 4 },
    { level: 16, count: 10, share: 0.25, places: 4 },
  ]);
  expect(estimatedRosterPlaces([], 15)).toEqual([]);
  expect(estimatedRosterPlaces([{ level: 18, count: 10 }], 15, 20).map((item) => item.places)).toEqual([8, 7]);
});

test('shows the retained season roster and leaves unavailable hit rates unknown', async () => {
  const data = new StatsCwlResponse('2026-09', 8, 180, 1, [
    {
      leagueId: 48000022,
      warSize: 15,
      groupCount: 1,
      clanCount: 8,
      registeredPlayerCount: 180,
      townHallDistribution: [{ level: 18, count: 180 }],
      sameTownHallHitRates: null,
      finalizedWars: 7,
      archivedWars: 0,
      calculatedAt: '2026-09-22T00:00:00Z',
    },
  ]);
  const view = await render(
    <I18nProvider locale="en">
      <CKThemeProvider preference="light">
        <CwlParticipationSection data={data} />
      </CKThemeProvider>
    </I18nProvider>,
  );

  expect(view.getByText('September 2026')).toBeTruthy();
  expect(view.getByTestId('cwl-participation').children[0]).toBe(view.getByTestId('cwl-overall-counts'));
  expect(view.getByTestId('cwl-bucket-48000022-15')).toBeTruthy();
  expect(view.getByText(/15v15/)).toBeTruthy();
  expect(view.getByText('Legend League')).toBeTruthy();
  expect(view.getByText('TH18 100%')).toBeTruthy();
  expect(view.queryByText('≈15/15')).toBeNull();
  await act(async () => fireEvent.press(view.getByTestId('cwl-bucket-toggle-48000022-15')));
  expect(view.getByText('TH18')).toBeTruthy();
  expect(view.getByText('100%')).toBeTruthy();
  expect(view.getByText('≈15/15')).toBeTruthy();
  expect(view.queryByRole('button', { name: 'Season' })).toBeNull();
});

test('labels the stored legacy CWL badge as Unranked', async () => {
  const data = new StatsCwlResponse('2026-09', 0, 0, 0, [{
    leagueId: 48000000, warSize: 15, groupCount: 1, clanCount: 8,
    registeredPlayerCount: 0, townHallDistribution: [], sameTownHallHitRates: null,
    finalizedWars: 0, archivedWars: 0, calculatedAt: '2026-09-22T00:00:00Z',
  }]);
  const view = await render(<I18nProvider locale="en"><CKThemeProvider preference="light">
    <CwlParticipationSection data={data} />
  </CKThemeProvider></I18nProvider>);
  expect(view.getByText('Unranked')).toBeTruthy();
  expect(view.getByTestId('cwl-bucket-toggle-48000000-15')).toBeTruthy();
});

test('uses stable Town Hall display colors in the roster-mix peek', async () => {
  const data = new StatsCwlResponse('2026-09', 0, 0, 0, [{
    leagueId: 48000022, warSize: 15, groupCount: 1, clanCount: 8,
    registeredPlayerCount: 100, townHallDistribution: [
      { level: 18, count: 60 }, { level: 17, count: 40 },
    ], sameTownHallHitRates: null,
    finalizedWars: 0, archivedWars: 0, calculatedAt: '2026-09-22T00:00:00Z',
  }]);
  const view = await render(<I18nProvider locale="en"><CKThemeProvider preference="dark">
    <CwlParticipationSection data={data} />
  </CKThemeProvider></I18nProvider>);
  const color18 = StyleSheet.flatten(view.getByTestId('cwl-th-mix-48000022-15-18').props.style).backgroundColor;
  const color17 = StyleSheet.flatten(view.getByTestId('cwl-th-mix-48000022-15-17').props.style).backgroundColor;
  expect(color18).toBe(townHallDisplayColor(18));
  expect(color17).toBe(townHallDisplayColor(17));
  expect(color18).not.toBe(color17);
});
