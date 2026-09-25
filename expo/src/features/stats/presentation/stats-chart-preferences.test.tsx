import { act, fireEvent, render } from '@testing-library/react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { I18nProvider } from '../../../i18n';
import { CKText, CKThemeProvider } from '../../../ui';
import type { StatsProvider } from '../data';
import { StatsDateFilter, StatsSection, type StatsSectionValue } from '../models';
import {
  StatsChartPreferencesProvider,
  StatsChartSettings,
  statsPresetDates,
  useChartGranularity,
  statsIntervalOptions,
} from './stats-chart-preferences';

function GranularityProbe() {
  const granularity = useChartGranularity();
  return <CKText testID="granularity-value">{granularity}</CKText>;
}

function makeProvider(section: StatsSectionValue, days = 30) {
  const dates = statsPresetDates(days);
  const setDates = jest.fn(async () => undefined);
  const setWarDates = jest.fn(async () => undefined);
  const provider = {
    section,
    dates,
    warDates: dates,
    setDates,
    setWarDates,
  } as unknown as StatsProvider;
  return { provider, setDates, setWarDates };
}

async function renderSettings(provider: StatsProvider, persistent = false) {
  return render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 320, height: 700 },
        insets: { top: 30, right: 0, bottom: 20, left: 0 },
      }}
    >
      <I18nProvider locale="en">
        <CKThemeProvider preference="dark">
          <StatsChartPreferencesProvider provider={persistent ? provider : undefined}>
            <StatsChartSettings provider={provider} />
            <GranularityProbe />
          </StatsChartPreferencesProvider>
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );
}

async function openSettings(view: Awaited<ReturnType<typeof renderSettings>>) {
  await act(async () => fireEvent.press(view.getByRole('button', { name: 'Settings' })));
}

test('War offers 365 days and All Time, applying either through setWarDates', async () => {
  const { provider, setDates, setWarDates } = makeProvider(StatsSection.war);
  const view = await renderSettings(provider);
  await openSettings(view);

  expect(view.getAllByRole('radio')).toHaveLength(5);
  expect(view.getByRole('radio', { name: '1 Year' })).toBeTruthy();
  expect(view.getByRole('radio', { name: 'All Time' })).toBeTruthy();
  expect(view.queryByRole('button', { name: 'Date range' })).toBeNull();

  await act(async () => fireEvent.press(view.getByRole('radio', { name: 'All Time' })));
  await act(async () => fireEvent.press(view.getByRole('button', { name: 'Apply' })));
  expect(setWarDates).toHaveBeenCalledWith(new Date(2012, 7, 2), expect.any(Date));
  expect(setDates).not.toHaveBeenCalled();

  await openSettings(view);
  await act(async () => fireEvent.press(view.getByRole('radio', { name: '1 Year' })));
  await act(async () => fireEvent.press(view.getByRole('button', { name: 'Apply' })));
  const expected = statsPresetDates(365);
  expect(setWarDates).toHaveBeenLastCalledWith(expected.start, expected.end);
  expect(setWarDates).toHaveBeenCalledTimes(2);
});

test.each([StatsSection.ranked, StatsSection.items])(
  '%s offers at most 90 days and calls setDates',
  async (section) => {
    const { provider, setDates, setWarDates } = makeProvider(section);
    const view = await renderSettings(provider);
    await openSettings(view);

    expect(view.getAllByRole('radio')).toHaveLength(3);
    expect(view.queryByRole('radio', { name: '1 Year' })).toBeNull();
    expect(view.queryByRole('radio', { name: 'All Time' })).toBeNull();
    expect(view.queryByRole('button', { name: 'Date range' })).toBeNull();

    await act(async () => fireEvent.press(view.getByRole('radio', { name: 'Last 90 days' })));
    await act(async () => fireEvent.press(view.getByRole('button', { name: 'Apply' })));
    const expected = statsPresetDates(90);
    expect(setDates).toHaveBeenCalledWith(expected.start, expected.end);
    expect(setWarDates).not.toHaveBeenCalled();
  },
);

test('Cancel discards draft range and granularity; Apply commits both', async () => {
  const { provider, setDates, setWarDates } = makeProvider(StatsSection.ranked);
  const view = await renderSettings(provider);
  await openSettings(view);

  await act(async () => fireEvent.press(view.getByRole('radio', { name: 'Last 7 days' })));
  await act(async () => fireEvent.press(view.getByRole('tab', { name: 'Weekly' })));
  await act(async () => fireEvent.press(view.getAllByRole('button', { name: 'Cancel' })[0]!));
  expect(setDates).not.toHaveBeenCalled();
  expect(setWarDates).not.toHaveBeenCalled();
  expect(view.getByTestId('granularity-value').props.children).toBe('day');

  await openSettings(view);
  expect(view.getByRole('radio', { name: 'Last 30 days' }).props.accessibilityState.checked).toBe(
    true,
  );
  expect(view.getByRole('tab', { name: 'Daily' }).props.accessibilityState.selected).toBe(true);
  await act(async () => fireEvent.press(view.getByRole('radio', { name: 'Last 7 days' })));
  await act(async () => fireEvent.press(view.getByRole('tab', { name: 'Monthly' })));
  await act(async () => fireEvent.press(view.getByRole('button', { name: 'Apply' })));
  expect(view.getByTestId('granularity-value').props.children).toBe('month');
  const expected = statsPresetDates(7);
  expect(setDates).toHaveBeenCalledWith(expected.start, expected.end);
  expect(setDates).toHaveBeenCalledTimes(1);
});

test('changing only granularity preserves a direct-linked historical 30-day range without refetching', async () => {
  const { provider, setDates, setWarDates } = makeProvider(StatsSection.ranked);
  provider.dates = new StatsDateFilter(new Date(2026, 6, 1), new Date(2026, 6, 30));
  const view = await renderSettings(provider);
  await openSettings(view);

  expect(
    view.getAllByRole('radio').every((radio) => radio.props.accessibilityState.checked === false),
  ).toBe(true);
  await act(async () => fireEvent.press(view.getByRole('tab', { name: 'Weekly' })));
  await act(async () => fireEvent.press(view.getByRole('button', { name: 'Apply' })));
  expect(view.getByTestId('granularity-value').props.children).toBe('week');
  expect(setDates).not.toHaveBeenCalled();
  expect(setWarDates).not.toHaveBeenCalled();
  expect(StatsDateFilter.formatDate(provider.dates.start)).toBe('2026-07-01');
});

test('a direct-linked 366-day War range is not mistaken for All Time', async () => {
  const { provider, setDates, setWarDates } = makeProvider(StatsSection.war);
  provider.warDates = new StatsDateFilter(new Date(2024, 0, 1), new Date(2024, 11, 31));
  const view = await renderSettings(provider);
  await openSettings(view);

  expect(view.getByRole('radio', { name: 'All Time' }).props.accessibilityState.checked).toBe(
    false,
  );
  expect(view.queryByRole('tab', { name: 'Daily' })).toBeNull();
  await act(async () => fireEvent.press(view.getByRole('tab', { name: 'Monthly' })));
  await act(async () => fireEvent.press(view.getByRole('button', { name: 'Apply' })));
  expect(view.getByTestId('granularity-value').props.children).toBe('month');
  expect(setWarDates).not.toHaveBeenCalled();
  expect(setDates).not.toHaveBeenCalled();

  await openSettings(view);
  await act(async () => fireEvent.press(view.getByRole('radio', { name: '1 Year' })));
  await act(async () => fireEvent.press(view.getByRole('button', { name: 'Apply' })));
  const next = statsPresetDates(365);
  expect(setWarDates).toHaveBeenCalledWith(next.start, next.end);
});

test('tapping the already-active date preset does not refetch', async () => {
  const { provider, setDates } = makeProvider(StatsSection.ranked);
  const view = await renderSettings(provider);
  await openSettings(view);
  await act(async () => fireEvent.press(view.getByRole('radio', { name: 'Last 30 days' })));
  await act(async () => fireEvent.press(view.getByRole('button', { name: 'Apply' })));
  expect(setDates).not.toHaveBeenCalled();
});

test.each([StatsSection.armies, StatsSection.items])(
  '%s shows Daily as its only interval without a redundant picker',
  async (section) => {
    const { provider } = makeProvider(section);
    const view = await renderSettings(provider);
    await openSettings(view);
    expect(view.getByText('Daily')).toBeTruthy();
    expect(view.queryByRole('tab', { name: 'Weekly' })).toBeNull();
    expect(view.queryByRole('tab', { name: 'Monthly' })).toBeNull();
  },
);

test('year and all-time War ranges replace Daily with Weekly and preserve Monthly', async () => {
  const { provider } = makeProvider(StatsSection.war);
  const view = await renderSettings(provider);
  await openSettings(view);
  await act(async () => fireEvent.press(view.getByRole('radio', { name: '1 Year' })));
  expect(view.queryByRole('tab', { name: 'Daily' })).toBeNull();
  expect(view.getByRole('tab', { name: 'Weekly' }).props.accessibilityState.selected).toBe(true);
  await act(async () => fireEvent.press(view.getByRole('tab', { name: 'Monthly' })));
  await act(async () => fireEvent.press(view.getByRole('radio', { name: 'All Time' })));
  expect(view.getByRole('tab', { name: 'Monthly' }).props.accessibilityState.selected).toBe(true);
  await act(async () => fireEvent.press(view.getByRole('button', { name: 'Apply' })));
  expect(view.getByTestId('granularity-value').props.children).toBe('month');
});

test('interval rules cover direct-linked long ranges and the exact one-year boundary', () => {
  expect(statsIntervalOptions('war', 364)).toEqual(['day', 'week', 'month']);
  expect(statsIntervalOptions('war', 365)).toEqual(['week', 'month']);
  expect(statsIntervalOptions('war', 5000)).toEqual(['week', 'month']);
  expect(statsIntervalOptions('items', 90)).toEqual(['day']);
  expect(statsIntervalOptions('armies', 90)).toEqual(['day']);
});

test('per-page intervals survive leaving the page and returning to Daily', async () => {
  const { provider } = makeProvider(StatsSection.ranked);
  Object.assign(provider, { chartGranularities: new Map([['ranked', 'month']]) });
  const ranked = await renderSettings(provider, true);
  expect(ranked.getByTestId('granularity-value').props.children).toBe('month');
  await ranked.unmount();
  provider.section = StatsSection.items;
  const troops = await renderSettings(provider, true);
  expect(troops.getByTestId('granularity-value').props.children).toBe('day');
  await troops.unmount();
  provider.section = StatsSection.ranked;
  const returned = await renderSettings(provider, true);
  expect(returned.getByTestId('granularity-value').props.children).toBe('month');
  await openSettings(returned);
  await act(async () => fireEvent.press(returned.getByRole('tab', { name: 'Daily' })));
  await act(async () => fireEvent.press(returned.getByRole('button', { name: 'Apply' })));
  expect(returned.getByTestId('granularity-value').props.children).toBe('day');
  expect(provider.chartGranularities.get(StatsSection.ranked)).toBe('day');
});
