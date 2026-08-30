import { act, render, waitFor } from '@testing-library/react-native';

import { I18nProvider } from '../../../i18n';
import {
  UpgradeBoosts,
  UpgradePlanGoal,
  UpgradePlanPreferences,
  type UpgradeTrackerSnapshot,
} from '../models';
import { UpgradeTrackerFormatError } from '../data';
import type { UpgradeTrackerScreenProps } from './upgrade-tracker-screen';
import { UpgradeTrackerRoot } from './upgrade-tracker-root';

let mockRuntime: ReturnType<typeof runtimeFixture>;
let mockScreenProps: UpgradeTrackerScreenProps;

jest.mock('../../../core/app/runtime-context', () => ({
  useAppRuntime: () => mockRuntime,
}));

jest.mock('./upgrade-tracker-screen', () => ({
  UpgradeTrackerScreen: (props: UpgradeTrackerScreenProps) => {
    mockScreenProps = props;
    return null;
  },
}));

function deferred<T>() {
  let resolve!: (value: T) => void;
  const promise = new Promise<T>((next) => {
    resolve = next;
  });
  return { promise, resolve };
}

function snapshot(tag: string, name: string) {
  return {
    tag,
    name,
    boosts: new UpgradeBoosts(),
  } as UpgradeTrackerSnapshot;
}

function runtimeFixture() {
  return {
    auth: { state: { currentUser: { userId: 'user-1' } } },
    accounts: {
      selectedTag: '#BBB',
      verifiedAccounts: [
        {
          playerTag: '#AAA',
          isVerified: true,
          hidden: false,
          raw: { name: 'Raw Alpha', town_hall_level: 16 },
        },
        {
          playerTag: '#BBB',
          isVerified: true,
          hidden: false,
          raw: { name: 'Raw Beta', builder_hall_level: 10 },
        },
      ],
    },
    players: { profiles: [] },
    upgrades: null,
    upgradeWidgets: null,
  } as const;
}

function renderRoot(repository: Record<string, jest.Mock>, widgetSync: Record<string, jest.Mock>) {
  return render(
    <I18nProvider locale="en">
      <UpgradeTrackerRoot
        initialTag="#AAA"
        onBack={jest.fn()}
        repository={repository as never}
        widgetSync={widgetSync as never}
      />
    </I18nProvider>,
  );
}

describe('UpgradeTrackerRoot parity state coordination', () => {
  beforeEach(() => {
    mockRuntime = runtimeFixture();
  });

  it('ignores stale preferences after the selected account changes', async () => {
    const alphaPreferences = deferred<Record<string, unknown> | null>();
    const repository = {
      configureRemote: jest.fn(),
      savedSnapshotAccounts: jest.fn(async () => []),
      peekCached: jest.fn(() => null),
      load: jest.fn(async (tag: string) =>
        tag === '#AAA' ? snapshot('#AAA', 'Alpha') : snapshot('#BBB', 'Beta'),
      ),
      loadPlanPreferences: jest.fn((tag: string) =>
        tag === '#AAA'
          ? alphaPreferences.promise
          : Promise.resolve({
              gold_pass_percent: 20,
              heuristics: { home_goal: UpgradePlanGoal.rushNextHall },
            }),
      ),
      loadSavedSnapshots: jest.fn(async () => []),
    };
    const widgetSync = { sync: jest.fn(async () => undefined) };
    await renderRoot(repository, widgetSync);

    await waitFor(() => expect(repository.loadPlanPreferences).toHaveBeenCalledWith('#AAA'));
    await act(async () => mockScreenProps.onSelectAccount('#BBB'));
    await waitFor(() => expect(mockScreenProps.snapshot?.tag).toBe('#BBB'));
    expect(mockScreenProps.goldPassPercent).toBe(20);
    expect(mockScreenProps.preferences.homeGoal).toBe(UpgradePlanGoal.rushNextHall);

    await act(async () => {
      alphaPreferences.resolve({
        gold_pass_percent: 10,
        heuristics: { home_goal: UpgradePlanGoal.catchUp },
      });
      await alphaPreferences.promise;
    });

    expect(mockScreenProps.snapshot?.tag).toBe('#BBB');
    expect(mockScreenProps.goldPassPercent).toBe(20);
    expect(mockScreenProps.preferences.homeGoal).toBe(UpgradePlanGoal.rushNextHall);
  });

  it('keeps valid tracker data when best-effort widget synchronization fails', async () => {
    const repository = {
      configureRemote: jest.fn(),
      savedSnapshotAccounts: jest.fn(async () => []),
      peekCached: jest.fn(() => null),
      load: jest.fn(async () => snapshot('#AAA', 'Alpha')),
      loadPlanPreferences: jest.fn(async () => null),
      loadSavedSnapshots: jest.fn(async () => [snapshot('#AAA', 'Alpha')]),
    };
    const widgetSync = {
      sync: jest.fn(async () => Promise.reject(new Error('native unavailable'))),
    };
    await renderRoot(repository, widgetSync);

    await waitFor(() => expect(widgetSync.sync).toHaveBeenCalled());
    await act(async () => Promise.resolve());

    expect(mockScreenProps.error).toBeNull();
    expect(mockScreenProps.loading).toBe(false);
    expect(mockScreenProps.snapshot?.tag).toBe('#AAA');
    const syncOptions = (widgetSync.sync as jest.Mock).mock.calls[0]?.[1] as
      { selectedTag?: string | null } | undefined;
    expect(syncOptions?.selectedTag).toBe('#BBB');
  });

  it('uses linked account metadata when a player profile has not loaded yet', async () => {
    const repository = {
      configureRemote: jest.fn(),
      savedSnapshotAccounts: jest.fn(async () => []),
      peekCached: jest.fn(() => null),
      load: jest.fn(async () => null),
      loadPlanPreferences: jest.fn(async () => null),
      loadSavedSnapshots: jest.fn(async () => []),
    };
    await renderRoot(repository, { sync: jest.fn(async () => undefined) });

    await waitFor(() => expect(mockScreenProps.loading).toBe(false));
    expect(mockScreenProps.accounts).toEqual([
      expect.objectContaining({ name: 'Raw Alpha', townHallLevel: 16 }),
      expect.objectContaining({ name: 'Raw Beta', builderHallLevel: 10 }),
    ]);
    expect(mockScreenProps.preferences).toBeInstanceOf(UpgradePlanPreferences);
  });

  it('shows a localized friendly message for invalid account JSON', async () => {
    const repository = {
      configureRemote: jest.fn(),
      savedSnapshotAccounts: jest.fn(async () => []),
      peekCached: jest.fn(() => null),
      load: jest.fn(async () => null),
      loadPlanPreferences: jest.fn(async () => null),
      loadSavedSnapshots: jest.fn(async () => []),
      importSnapshotBytes: jest.fn(async () => {
        throw new UpgradeTrackerFormatError('Unexpected token at position 4');
      }),
    };
    const screen = await renderRoot(repository, { sync: jest.fn(async () => undefined) });
    await waitFor(() => expect(mockScreenProps.loading).toBe(false));

    await act(async () => {
      await expect(mockScreenProps.onImport('{bad json')).rejects.toThrow(
        'Account data could not be read',
      );
    });

    expect(screen.getByText('Account data could not be read')).toBeTruthy();
    expect(screen.queryByText(/Unexpected token/)).toBeNull();
  });
});
