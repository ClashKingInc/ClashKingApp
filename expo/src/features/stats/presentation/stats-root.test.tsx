import { StrictMode } from 'react';
import { act, fireEvent, render, waitFor } from '@testing-library/react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import {
  StatsDateRange,
  StatsLegendCohort,
  StatsLegendResponse,
  StatsMetrics,
  StatsPerformanceResponse,
  StatsPlayerCountsResponse,
} from '../models';
import { StatsRepository } from '../data';
import { StatsRoot } from './stats-root';

const mockRuntime = { contractApi: {} };
let mockLinkParams: Record<string, string> = {};
const actEnvironment = globalThis as typeof globalThis & { IS_REACT_ACT_ENVIRONMENT?: boolean };
const previousActEnvironment = actEnvironment.IS_REACT_ACT_ENVIRONMENT;
beforeAll(() => {
  actEnvironment.IS_REACT_ACT_ENVIRONMENT = true;
});
afterAll(() => {
  actEnvironment.IS_REACT_ACT_ENVIRONMENT = previousActEnvironment;
});

jest.mock('../../../core/app/runtime-context', () => ({
  useAppRuntime: () => mockRuntime,
}));

jest.mock('../../../ui/destination-stack', () => ({
  DestinationStack: ({
    focused,
    grid,
    detail,
    onCloseDetail,
  }: {
    focused: boolean;
    grid: React.ReactNode;
    detail: React.ReactNode;
    onCloseDetail: () => void;
  }) => {
    const { Text: MockText } = jest.requireActual('react-native');
    return (
      <>
        {focused ? detail : grid}
        <MockText testID="native-detail-back" onPress={onCloseDetail}>
          Native back
        </MockText>
      </>
    );
  },
}));

jest.mock('../../../core/deep-links/link-parameters', () => {
  const actual = jest.requireActual('../../../core/deep-links/link-parameters');
  return {
    ...actual,
    // The shell may reconstruct equivalent link context on every render.
    useLinkParameters: () => ({ ...mockLinkParams }),
  };
});

jest.mock('./stats-screen', () => {
  const { Text: MockText } = jest.requireActual('react-native');
  const labels: Record<string, string> = {
    war: 'War',
    armies: 'Armies',
    items: 'Troops',
    ranked: 'Ranked',
    cwl: 'CWL',
    players: 'Players',
    clans: 'Clans',
  };
  return {
    sectionLabel: (section: string) => labels[section] ?? section,
    sectionImage: () => '',
    StatsScreen: ({
      provider,
      revision,
      onBack,
    }: {
      provider: { currentState: { status: string }; section: string };
      revision: number;
      onBack: () => void;
    }) => (
      <>
        <MockText>{`${revision}:${provider.section}:${provider.currentState.status}`}</MockText>
        <MockText testID="focused-back" onPress={onBack}>
          back
        </MockText>
      </>
    ),
  };
});

afterEach(() => {
  mockLinkParams = {};
  jest.restoreAllMocks();
});

function response() {
  return new StatsPerformanceResponse(
    new StatsDateRange(new Date(2026, 7, 1), new Date(2026, 7, 30)),
    new StatsMetrics(true, 100, 2.4, 88, 0.02, 0.08, 0.3, 0.6, []),
    [],
  );
}

function renderRoot(strict = false, onBack = jest.fn()) {
  const content = (
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <StatsRoot onBack={onBack} />
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>
  );
  return render(strict ? <StrictMode>{content}</StrictMode> : content);
}

test('opens on the grid without fetching, then reuses the provider and War cache across selections', async () => {
  const loadWar = jest.spyOn(StatsRepository.prototype, 'loadWar').mockResolvedValue(response());
  const loadItems = jest
    .spyOn(StatsRepository.prototype, 'loadItems')
    .mockResolvedValue(new StatsLegendResponse(StatsLegendCohort.legend, []));
  const loadPlayers = jest
    .spyOn(StatsRepository.prototype, 'loadPlayerCounts')
    .mockResolvedValue(new StatsPlayerCountsResponse([], []));
  const onBack = jest.fn();
  const view = await renderRoot(false, onBack);

  expect(view.getByTestId('destination-grid-stats')).toBeTruthy();
  expect(view.getByTestId('destination-grid-battles')).toBeTruthy();
  expect(view.getByTestId('destination-grid-army')).toBeTruthy();
  expect(view.getByTestId('destination-grid-world')).toBeTruthy();
  expect(view.getByText('Battlelogs')).toBeTruthy();
  expect(view.getByText('Global Stats')).toBeTruthy();
  expect(view.getByRole('button', { name: 'War' })).toBeTruthy();
  expect(view.getByRole('button', { name: 'Troops' })).toBeTruthy();
  expect(loadWar).not.toHaveBeenCalled();
  expect(loadItems).not.toHaveBeenCalled();
  expect(loadPlayers).not.toHaveBeenCalled();

  fireEvent.press(view.getByRole('button', { name: 'War' }));
  expect(await waitFor(() => view.getByText(/^\d+:war:data$/))).toBeTruthy();
  expect(loadWar).toHaveBeenCalledTimes(1);
  await act(async () => {
    fireEvent.press(view.getByTestId('focused-back'));
  });
  expect(await waitFor(() => view.getByTestId('destination-grid-stats'))).toBeTruthy();
  expect(onBack).not.toHaveBeenCalled();

  fireEvent.press(view.getByRole('button', { name: 'Troops' }));
  expect(await waitFor(() => view.getByText(/^\d+:items:empty$/))).toBeTruthy();
  expect(loadItems).toHaveBeenCalledTimes(3);
  await act(async () => {
    fireEvent.press(view.getByTestId('focused-back'));
  });
  fireEvent.press(view.getByRole('button', { name: 'War' }));
  expect(await waitFor(() => view.getByText(/^\d+:war:data$/))).toBeTruthy();
  expect(loadWar).toHaveBeenCalledTimes(1);
});

test('opens a valid section deep link immediately and restarts after Strict Mode cleanup', async () => {
  mockLinkParams = { section: 'war' };
  let resolve!: (value: StatsPerformanceResponse) => void;
  const restarted = new Promise<StatsPerformanceResponse>((done) => (resolve = done));
  const loadWar = jest
    .spyOn(StatsRepository.prototype, 'loadWar')
    .mockReturnValueOnce(new Promise<never>(() => undefined))
    .mockReturnValueOnce(restarted);

  const view = await renderRoot(true);
  expect(view.queryByTestId('destination-grid-stats')).toBeNull();
  await waitFor(() => expect(loadWar).toHaveBeenCalledTimes(2));
  await act(async () => {
    resolve(response());
    await restarted;
  });
  expect(await waitFor(() => view.getByText(/^\d+:war:data$/))).toBeTruthy();
});

test('ignores an invalid section deep link and tolerates reconstructed equivalent params', async () => {
  mockLinkParams = { section: 'not-a-stat' };
  const loadWar = jest.spyOn(StatsRepository.prototype, 'loadWar').mockResolvedValue(response());
  const view = await renderRoot();
  expect(view.getByTestId('destination-grid-stats')).toBeTruthy();
  expect(loadWar).not.toHaveBeenCalled();
  fireEvent.press(view.getByRole('button', { name: 'War' }));
  expect(await waitFor(() => view.getByText(/^\d+:war:data$/))).toBeTruthy();
  expect(loadWar).toHaveBeenCalledTimes(1);
});

test('a native detail pop returns a section deep link to the grid without leaving Stats', async () => {
  mockLinkParams = { section: 'war' };
  jest.spyOn(StatsRepository.prototype, 'loadWar').mockResolvedValue(response());
  const onBack = jest.fn();
  const view = await renderRoot(false, onBack);
  expect(await waitFor(() => view.getByText(/^\d+:war:data$/))).toBeTruthy();
  fireEvent.press(view.getByTestId('native-detail-back'));
  expect(await waitFor(() => view.getByTestId('destination-grid-stats'))).toBeTruthy();
  expect(onBack).not.toHaveBeenCalled();
});
