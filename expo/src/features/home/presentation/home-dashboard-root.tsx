import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { View } from 'react-native';

import { canonicalTag } from '../../../core/domain/tags';
import { APP_FEATURE_FLAGS } from '../../../core/feature-flags/feature-flags';
import { useAppRuntime, useAppState } from '../../../core/app/runtime-context';
import { useI18n } from '../../../i18n';
import { Snackbar } from '../../../ui';
import type { RankedLeagueData } from '../../player/models/player-ranked';
import type { UpgradeTrackerSnapshot } from '../../upgrade-tracker/models';
import {
  buildHomeRankedModel,
  buildHomeTodoModel,
  buildHomeUpgradeModel,
  type AppAnnouncement,
} from '../data';
import { loadHomeUpgradeSnapshots } from '../data/home-upgrade-loader';
import type { HomeAnnouncement, HomeDashboardActions, HomeDashboardModel } from './contracts';
import { DashboardScreen } from './dashboard-screen';

export interface HomeDashboardRootProps {
  readonly openManageAccounts: () => void;
  readonly openAnnouncement: (announcement: AppAnnouncement) => void;
  readonly openTodo: () => void;
  readonly openRanked: (playerTag: string) => void;
  readonly openUpgradeTracker: (playerTag: string) => void;
}

export function HomeDashboardRoot(props: HomeDashboardRootProps) {
  const runtime = useAppRuntime();
  const appState = useAppState();
  const { t, locale } = useI18n();
  const [serviceRevision, setServiceRevision] = useState(0);
  const [refreshGeneration, setRefreshGeneration] = useState(0);
  const [rankedState, setRankedState] = useState<{
    readonly signature: string;
    readonly data: ReadonlyMap<string, RankedLeagueData>;
  }>({ signature: '', data: new Map() });
  const [upgradeState, setUpgradeState] = useState<{
    readonly signature: string;
    readonly data: ReadonlyMap<string, UpgradeTrackerSnapshot | null>;
  }>({ signature: '', data: new Map() });
  const [announcements, setAnnouncements] = useState<readonly AppAnnouncement[]>([]);
  const [snackbar, setSnackbar] = useState<string>();
  const rankedRefreshGeneration = useRef(0);
  const upgradeRefreshGeneration = useRef(0);

  useEffect(() => {
    const changed = () => setServiceRevision((value) => value + 1);
    const unsubscribe = [
      runtime.accounts.subscribe(changed),
      runtime.players.subscribe(changed),
      runtime.playerCardPreferences.subscribe(changed),
      runtime.wars.subscribe(changed),
    ];
    return () => unsubscribe.forEach((remove) => remove());
  }, [runtime]);

  const linkedPlayers = useMemo(() => {
    const byTag = new Map(
      runtime.players.profiles.map((player) => [canonicalTag(player.tag), player]),
    );
    return runtime.accounts.verifiedAccounts.flatMap((account) => {
      const player = byTag.get(canonicalTag(account.playerTag));
      return player ? [player] : [];
    });
    // Service revision intentionally invalidates stable service-owned arrays.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [runtime, serviceRevision]);
  const todoPlayers = useMemo(
    () =>
      linkedPlayers.filter((player) => runtime.playerCardPreferences.isShownInTodoPage(player.tag)),
    [linkedPlayers, runtime],
  );
  const rankedPlayers = useMemo(
    () =>
      linkedPlayers.filter((player) =>
        runtime.playerCardPreferences.isRankedShownOnHome(player.tag),
      ),
    [linkedPlayers, runtime],
  );
  const upgradeEnabled = appState.features[APP_FEATURE_FLAGS.upgradeTracker];
  const upgradePlayers = useMemo(
    () =>
      upgradeEnabled
        ? linkedPlayers.filter((player) =>
            runtime.playerCardPreferences.isUpgradeTrackerShownOnHome(player.tag),
          )
        : [],
    [linkedPlayers, runtime, upgradeEnabled],
  );
  const linkedSignature = linkedPlayers.map((player) => canonicalTag(player.tag)).join('|');
  const rankedSignature = rankedPlayers.map((player) => canonicalTag(player.tag)).join('|');
  const upgradeSignature = upgradePlayers.map((player) => canonicalTag(player.tag)).join('|');
  const rankedLoadSignature = `${rankedSignature}@${refreshGeneration}`;
  const upgradeLoadSignature = `${linkedSignature}:${upgradeSignature}@${refreshGeneration}`;
  const rankedLoading = rankedPlayers.length > 0 && rankedState.signature !== rankedLoadSignature;
  const upgradeLoading =
    upgradePlayers.length > 0 && upgradeState.signature !== upgradeLoadSignature;

  useEffect(() => {
    let current = true;
    const forceRefresh = refreshGeneration !== rankedRefreshGeneration.current;
    rankedRefreshGeneration.current = refreshGeneration;
    void (async () => {
      const next = new Map<string, RankedLeagueData>();
      for (const player of rankedPlayers) {
        try {
          next.set(
            canonicalTag(player.tag),
            await runtime.players.loadRankedLeagueData(player.tag, forceRefresh),
          );
        } catch {
          // Home is best-effort; the full Ranked page owns surfaced failures.
        }
      }
      if (current) {
        setRankedState({ signature: rankedLoadSignature, data: next });
      }
    })();
    return () => {
      current = false;
    };
  }, [rankedLoadSignature, rankedPlayers, refreshGeneration, runtime]);

  useEffect(() => {
    let current = true;
    const forceRefresh = refreshGeneration !== upgradeRefreshGeneration.current;
    upgradeRefreshGeneration.current = refreshGeneration;
    void (async () => {
      const all = await loadHomeUpgradeSnapshots(
        linkedPlayers,
        (tag, refresh) => runtime.upgrades.load(tag, refresh),
        forceRefresh,
      );
      if (!current) return;
      setUpgradeState({ signature: upgradeLoadSignature, data: all });
      const snapshots = [...all.values()].filter(
        (snapshot): snapshot is UpgradeTrackerSnapshot => snapshot !== null,
      );
      void runtime.upgradeWidgets
        .sync(snapshots, {
          selectedTag: runtime.accounts.selectedTag,
          linkedAccounts: runtime.accounts.verifiedAccounts.map((account) => ({
            tag: account.playerTag,
            name: account.raw.player_name ?? account.raw.name,
            townHallLevel: account.raw.town_hall_level ?? account.raw.townHallLevel,
            builderHallLevel: account.raw.builder_hall_level ?? account.raw.builderHallLevel,
          })),
        })
        .catch(() => {
          // Widget storage cannot make Home unavailable.
        });
    })();
    return () => {
      current = false;
    };
  }, [linkedPlayers, refreshGeneration, runtime, upgradeLoadSignature]);

  useEffect(() => {
    let current = true;
    void runtime.announcements.getActiveAnnouncements().then((items) => {
      if (current) setAnnouncements(items);
    });
    return () => {
      current = false;
    };
  }, [appState.locale, runtime]);

  const model = useMemo<HomeDashboardModel>(
    () => ({
      loading: runtime.players.isLoading,
      linkedAccountCount: linkedPlayers.length,
      ...(runtime.accounts.lastRefresh ? { lastRefresh: runtime.accounts.lastRefresh } : {}),
      announcements: announcements.map(homeAnnouncement),
      ...(todoPlayers.length
        ? { todo: buildHomeTodoModel(todoPlayers, runtime.wars, t, locale) }
        : {}),
      ...(rankedPlayers.length
        ? { ranked: buildHomeRankedModel(rankedPlayers, rankedState.data, rankedLoading) }
        : {}),
      ...(upgradeEnabled && upgradePlayers.length
        ? {
            upgrade: buildHomeUpgradeModel(upgradePlayers, upgradeState.data, t, {
              loading: upgradeLoading,
            }),
          }
        : {}),
      upgradeTrackerEnabled: upgradeEnabled,
    }),
    [
      announcements,
      linkedPlayers,
      locale,
      rankedLoading,
      rankedPlayers,
      rankedState.data,
      runtime,
      t,
      todoPlayers,
      upgradeEnabled,
      upgradeLoading,
      upgradePlayers,
      upgradeState.data,
    ],
  );

  const refresh = useCallback(async () => {
    await runtime.accountBootstrap.refresh();
    setRefreshGeneration((value) => value + 1);
  }, [runtime]);
  const actions = useMemo<HomeDashboardActions>(
    () => ({
      refresh,
      showRefreshError: setSnackbar,
      openManageAccounts: props.openManageAccounts,
      openAnnouncement: (announcement) => {
        const source = announcements.find((item) => item.id === announcement.id);
        if (source) props.openAnnouncement(source);
      },
      openTodo: props.openTodo,
      openRanked: props.openRanked,
      openUpgradeTracker: props.openUpgradeTracker,
    }),
    [announcements, props, refresh],
  );

  return (
    <View style={{ flex: 1 }}>
      <DashboardScreen model={model} actions={actions} />
      <Snackbar avoidBottomNavigation message={snackbar} onDismiss={() => setSnackbar(undefined)} />
    </View>
  );
}

function homeAnnouncement(item: AppAnnouncement): HomeAnnouncement {
  return {
    id: item.id,
    title: item.title,
    subtitle: item.subtitle,
    ...(item.bannerImageUrl ? { imageUrl: item.bannerImageUrl } : {}),
    ...(item.storyUrl ? { storyUrl: item.storyUrl } : {}),
    ...(item.body ? { html: item.body } : {}),
    ...(item.htmlUrl ? { htmlUrl: item.htmlUrl } : {}),
    ...(item.startsAt ? { startsAt: item.startsAt } : {}),
  };
}
