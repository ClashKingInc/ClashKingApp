import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { View } from 'react-native';

import { canonicalTag } from '../../../core/domain/tags';
import { mapWithConcurrencyLimit } from '../../../core/utils/bounded-concurrency';
import { APP_FEATURE_FLAGS } from '../../../core/feature-flags/feature-flags';
import { useAppRuntime, useAppState } from '../../../core/app/runtime-context';
import { useI18n } from '../../../i18n';
import { Snackbar } from '../../../ui';
import type { RankedLeagueData } from '../../player/models/player-ranked';
import { currentLegendDay, type PlayerLegendLeagueData } from '../../player/models/player-legend';
import type { UpgradeTrackerSnapshot } from '../../upgrade-tracker/models';
import {
  buildHomeRankedModel,
  buildHomeTodoModel,
  buildHomeUpgradeModel,
  type AppAnnouncement,
} from '../data';
import { loadHomeUpgradeSnapshots } from '../data/home-upgrade-loader';
import { homeAccountIdentity } from '../data/home-dashboard-model';
import {
  type HomeAnnouncement,
  type HomeCardId,
  type HomeDashboardActions,
  type HomeDashboardModel,
} from './contracts';
import { DashboardScreen } from './dashboard-screen';
import { useHomeLayout } from './home-layout';
import { UpgradeImportModal } from '../../upgrade-tracker/presentation/upgrade-tracker-screen';

export interface HomeDashboardRootProps {
  readonly active?: boolean;
  readonly onReady?: () => void;
  readonly openManageAccounts: () => void;
  readonly openAnnouncement: (announcement: AppAnnouncement) => void;
  readonly openTodo: () => void;
  readonly openRanked: (playerTag: string) => void;
  readonly openLegends: (playerTag: string) => void;
  readonly openUpgradeTracker: (playerTag: string) => void;
}

export function HomeDashboardRoot(props: HomeDashboardRootProps) {
  const { onReady } = props;
  const runtime = useAppRuntime();
  const appState = useAppState();
  const { t, locale } = useI18n();
  const [serviceRevision, setServiceRevision] = useState(0);
  const [refreshGeneration, setRefreshGeneration] = useState(0);
  const [rankedState, setRankedState] = useState<{
    readonly signature: string;
    readonly data: ReadonlyMap<string, RankedLeagueData>;
    readonly legends: ReadonlyMap<string, PlayerLegendLeagueData>;
  }>({ signature: '', data: new Map(), legends: new Map() });
  const [upgradeState, setUpgradeState] = useState<{
    readonly signature: string;
    readonly data: ReadonlyMap<string, UpgradeTrackerSnapshot | null>;
  }>({ signature: '', data: new Map() });
  const [announcements, setAnnouncements] = useState<readonly AppAnnouncement[]>([]);
  const [snackbar, setSnackbar] = useState<string>();
  const [importOpen, setImportOpen] = useState(false);
  const layout = useHomeLayout(setSnackbar, refreshGeneration);
  const cardOrder = useMemo(
    () => layout.items.map((item) => item.kind as HomeCardId),
    [layout.items],
  );
  const rankedRefreshGeneration = useRef(0);
  const upgradeRefreshGeneration = useRef(0);

  useEffect(() => {
    const changed = () => setServiceRevision((value) => value + 1);
    const unsubscribe = [
      runtime.accounts.subscribe(changed),
      runtime.bookmarks.subscribe(changed),
      runtime.players.subscribe(changed),
      runtime.playerCardPreferences.subscribe(changed),
      runtime.wars.subscribe(changed),
    ];
    return () => unsubscribe.forEach((remove) => remove());
  }, [runtime]);

  const verifiedTags = useMemo(
    () => runtime.accounts.verifiedAccounts.map((account) => account.playerTag),
    // Service revision intentionally invalidates stable service-owned arrays.
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [runtime, serviceRevision],
  );
  const homeIncludedTags = useMemo(
    () =>
      runtime.playerCardPreferences.homeIncludedTags(verifiedTags, runtime.accounts.selectedTag),
    // Preference changes publish a service revision.
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [runtime, verifiedTags, serviceRevision],
  );
  useEffect(() => {
    if (!runtime.playerCardPreferences.loaded || verifiedTags.length === 0) return;
    void runtime.playerCardPreferences
      .reconcileHomeIncluded(verifiedTags, runtime.accounts.selectedTag)
      .catch(() => undefined);
  }, [runtime, verifiedTags]);

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
      linkedPlayers.filter(
        (player) =>
          homeIncludedTags.includes(canonicalTag(player.tag).slice(1)) &&
          runtime.playerCardPreferences.isShownInTodoPage(player.tag),
      ),
    [linkedPlayers, runtime, homeIncludedTags],
  );
  // The Home inclusion picker only scopes To-do and farming. League summaries
  // always include eligible verified links; Upgrade retains its own switch.
  const rankedPlayers = linkedPlayers;
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
  const rankedSignature = rankedPlayers.map((player) => canonicalTag(player.tag)).join('|');
  const upgradeSignature = upgradePlayers.map((player) => canonicalTag(player.tag)).join('|');
  const rankedLoadSignature = `${rankedSignature}@${refreshGeneration}`;
  const upgradeLoadSignature = `${upgradeSignature}@${refreshGeneration}`;
  const upgradeLoadPlayers = useMemo(
    () =>
      upgradeSignature
        .split('|')
        .filter(Boolean)
        .map((tag) => ({ tag })),
    [upgradeSignature],
  );
  const rankedLoading = rankedPlayers.length > 0 && rankedState.signature !== rankedLoadSignature;
  const upgradeLoading =
    upgradePlayers.length > 0 && upgradeState.signature !== upgradeLoadSignature;
  useEffect(() => {
    if (!runtime.players.isLoading && !rankedLoading && !upgradeLoading) onReady?.();
  }, [runtime, serviceRevision, rankedLoading, upgradeLoading, onReady]);

  useEffect(() => {
    let current = true;
    const forceRefresh = refreshGeneration !== rankedRefreshGeneration.current;
    rankedRefreshGeneration.current = refreshGeneration;
    void (async () => {
      const next = new Map<string, RankedLeagueData>();
      const legends = new Map<string, PlayerLegendLeagueData>();
      await mapWithConcurrencyLimit(rankedPlayers, async (player) => {
        try {
          if (player.isLegendLeague) {
            legends.set(
              canonicalTag(player.tag),
              await runtime.players.loadLegendLeagueData(
                player.tag,
                forceRefresh,
                currentLegendDay(),
              ),
            );
            return;
          }
          next.set(
            canonicalTag(player.tag),
            await runtime.players.loadRankedLeagueData(player.tag, forceRefresh, false, 'home'),
          );
        } catch {
          // Home is best-effort; the full Ranked page owns surfaced failures.
        }
      });
      if (current) {
        setRankedState({ signature: rankedLoadSignature, data: next, legends });
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
        upgradeLoadPlayers,
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
  }, [upgradeLoadPlayers, refreshGeneration, runtime, upgradeLoadSignature]);

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
      selectedAccountTag: runtime.accounts.selectedTag,
      linkedAccountCount: runtime.accounts.verifiedAccounts.length,
      ...(runtime.accounts.lastRefresh ? { lastRefresh: runtime.accounts.lastRefresh } : {}),
      announcements: announcements.map(homeAnnouncement),
      ...(todoPlayers.length
        ? { todo: buildHomeTodoModel(todoPlayers, runtime.wars, t, locale) }
        : {}),
      ...(rankedPlayers.length
        ? {
            ranked: buildHomeRankedModel(
              rankedPlayers,
              rankedState.data,
              rankedLoading,
              rankedState.legends,
            ),
          }
        : {}),
      ...(upgradeEnabled && upgradePlayers.length
        ? {
            upgrade: buildHomeUpgradeModel(upgradePlayers, upgradeState.data, t, {
              loading: upgradeLoading,
            }),
          }
        : {}),
      upgradeTrackerEnabled: upgradeEnabled,
      cardOrder,
      activityAccounts: homeIncludedTags.map((tag) => {
        const player = runtime.players.profiles.find(
          (entry) => canonicalTag(entry.tag) === canonicalTag(tag),
        );
        return player
          ? homeAccountIdentity(player)
          : {
              tag: canonicalTag(tag),
              name: tag,
              subtitle: tag,
              imageUrl: '',
            };
      }),
    }),
    [
      announcements,
      cardOrder,
      homeIncludedTags,
      locale,
      rankedLoading,
      rankedPlayers,
      rankedState.data,
      rankedState.legends,
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
      openRanked: (tag) =>
        rankedPlayers.find((player) => canonicalTag(player.tag) === canonicalTag(tag))
          ?.isLegendLeague
          ? props.openLegends(tag)
          : props.openRanked(tag),
      openUpgradeTracker: props.openUpgradeTracker,
      openUpgradeImport: () => setImportOpen(true),
      selectAccount: (tag) => {
        void runtime.accounts.setSelectedTag(tag);
      },
      reorderCards: (order) => {
        const byId = new Map(layout.items.map((item) => [item.kind, item]));
        const ordered = order.flatMap((id) => (byId.has(id) ? [byId.get(id)!] : []));
        return layout.change([
          ...ordered,
          ...layout.items.filter((item) => !ordered.includes(item)),
        ]);
      },
      moveCard: layout.move,
    }),
    [announcements, props, refresh, runtime.accounts, layout, rankedPlayers],
  );

  return (
    <View style={{ flex: 1 }}>
      <DashboardScreen model={model} actions={actions} />
      <UpgradeImportModal
        visible={importOpen}
        onClose={() => setImportOpen(false)}
        onImport={async (json) => {
          try {
            runtime.upgrades.configureRemote({
              accountId: runtime.auth.state.currentUser?.userId ?? null,
              verifiedPlayerTags: verifiedTags,
            });
            // Keep the repository's verified-account gate; the selected Home
            // account must never override the tag embedded in the imported JSON.
            const snapshot = await runtime.upgrades.importSnapshotBytes(
              new TextEncoder().encode(json),
              {
                allowedTags: new Set(verifiedTags),
                linkedTags: new Set(runtime.accounts.accounts.map((account) => account.playerTag)),
                linkedNamesByTag: Object.fromEntries(
                  runtime.players.profiles.map((player) => [player.tag, player.name]),
                ),
              },
            );
            setImportOpen(false);
            setRefreshGeneration((value) => value + 1);
            setSnackbar(t('upgradeTrackerImportSuccess', { player: snapshot.name }));
          } catch (cause) {
            setSnackbar(
              t('upgradeTrackerImportFailed', {
                error: cause instanceof Error ? cause.message : String(cause),
              }),
            );
          }
        }}
      />
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
