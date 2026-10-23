import * as Clipboard from 'expo-clipboard';
import { useEffect, useMemo, useState } from 'react';
import { Linking, View } from 'react-native';

import { defaultIsNetworkError } from '../../../core/app/startup-coordinator';
import { useAppRuntime } from '../../../core/app/runtime-context';
import { useI18n } from '../../../i18n';
import { ClashHandoffDialog, ConfirmationDialog, Snackbar } from '../../../ui';
import type { ClanNotificationControls } from './clan-notification-options';
import type { ClanNotificationSettings } from '../../notifications/data/notification-preferences-service';
import { useClashGameHandoff } from '../../../ui/use-clash-game-handoff';
import type { Player } from '../../player/models/player';
import type { WarCwl, WarInfo } from '../../war/models';
import type { Clan } from '../models';
import { ClanInfoScreen } from './clan-info-screen';
import type { ClanInfoPresentationActions } from './clan-info-contracts';
import {
  buildClanInfoPresentationModel,
  buildClansPresentationModel,
  accountTagsForClanOrder,
  clanInfoStateKey,
  clanGameUrl,
  loadClanJoinLeave,
  loadClanWarLog,
  loadClanWarStats,
  loadMoreClanJoinLeave,
  ownedClanProfiles,
} from './clan-root-state';
import { ClansScreen } from './clans-screen';
import type { ClansPresentationActions } from './contracts';
import type { ClanSpringOrigin } from './clan-spring-transition';

export interface ClanNavigationActions {
  readonly openPlayer: (player: Player) => void;
  readonly openWar: (clan: Clan, war: WarCwl) => void;
  readonly openHistoricalWar: (war: WarInfo) => void;
  readonly openCwl: (clan: Clan, war: WarCwl) => void;
  readonly openHistoricalCwl: (clan: Clan, season: string, leagueName?: string) => void;
  readonly openCapital: (clan: Clan) => void;
  readonly openNetworkError?: (retry: () => Promise<void>) => void;
}

/** Live replacement for Flutter's primary Clans page and its pushed detail page. */
export function ClanRoot({
  navigation,
  onOpenClan,
}: {
  readonly navigation: ClanNavigationActions;
  /** Lets the app shell present detail as a pushed route that hides mobile chrome. */
  readonly onOpenClan?: (clan: Clan, origin?: ClanSpringOrigin) => void;
}) {
  const runtime = useAppRuntime();
  const { t } = useI18n();
  const [revision, setRevision] = useState(0);
  const [selectedClan, setSelectedClan] = useState<Clan>();
  const [snackbar, setSnackbar] = useState<string>();
  const notifications = useClanNotificationControls(runtime, setSnackbar);

  useEffect(() => {
    const changed = () => setRevision((value) => value + 1);
    const unsubscribe = [
      runtime.accounts.subscribe(changed),
      runtime.players.subscribe(changed),
      runtime.bookmarks.subscribe(changed),
      runtime.clans.subscribe(changed),
      runtime.wars.subscribe(changed),
    ];
    return () => unsubscribe.forEach((remove) => remove());
  }, [runtime]);

  const clan = selectedClan ? (runtime.clans.getClanByTag(selectedClan.tag) ?? selectedClan) : null;
  if (clan) {
    return (
      <ClanInfoRoot clan={clan} goBack={() => setSelectedClan(undefined)} navigation={navigation} />
    );
  }

  const model = {
    ...buildClansPresentationModel({
      profiles: ownedClanProfiles(
        runtime.players.profiles,
        runtime.accounts.accounts.map((account) => account.playerTag),
      ),
      bookmarks: runtime.bookmarks.clans,
      clans: runtime.clans.clans,
      lastRefresh: runtime.accounts.lastRefresh,
    }),
    notifications,
  };
  const actions: ClansPresentationActions = {
    refresh: () => runtime.accountBootstrap.refresh(),
    isNetworkError: defaultIsNetworkError,
    openNetworkError: navigation.openNetworkError ?? (() => setSnackbar(t('errorNetworkTitle'))),
    showMessage: setSnackbar,
    hydrateBookmarkedClans: (tags) => runtime.clans.loadAllClanData(tags, { notify: true }),
    loadClan: (tag) => runtime.clans.getClanAndWarData(tag),
    openClan: onOpenClan ?? setSelectedClan,
    reorderLinkedClans: async (orderedTags) => {
      const accounts = runtime.accounts.accounts.map((account) => account.playerTag);
      const order = accountTagsForClanOrder(orderedTags, accounts, runtime.players.profiles);
      if (!(await runtime.accounts.updateAccountOrder(order)))
        throw new Error('Couldn’t update clan order.');
    },
    reorderBookmarkedClans: (orderedTags) => runtime.bookmarks.reorderClans(orderedTags),
  };

  // The revision is consumed through service-owned collections above.
  void revision;
  return (
    <View style={{ flex: 1 }}>
      <ClansScreen model={model} actions={actions} />
      <Snackbar avoidBottomNavigation message={snackbar} onDismiss={() => setSnackbar(undefined)} />
    </View>
  );
}

/** Detail adapter is exported so player/search/deep-link navigation can open a clan directly. */
export function ClanInfoRoot({
  clan,
  goBack,
  navigation,
}: {
  readonly clan: Clan;
  readonly goBack: () => void;
  readonly navigation: ClanNavigationActions;
}) {
  const runtime = useAppRuntime();
  const { locale, t } = useI18n();
  const [revision, setRevision] = useState(0);
  const [snackbar, setSnackbar] = useState<string>();
  const notifications = useClanNotificationControls(runtime, setSnackbar);
  const [removeBookmark, setRemoveBookmark] = useState<string>();
  const handoff = useClashGameHandoff((url) => {
    void Linking.openURL(url).catch(() => setSnackbar(t('deepLinkFailedToOpenClan')));
  });
  const requestGameHandoff = handoff.request;

  useEffect(() => {
    const changed = () => setRevision((value) => value + 1);
    const unsubscribe = [
      runtime.accounts.subscribe(changed),
      runtime.bookmarks.subscribe(changed),
      runtime.clans.subscribe(changed),
      runtime.wars.subscribe(changed),
    ];
    return () => unsubscribe.forEach((remove) => remove());
  }, [runtime]);

  const currentClan = runtime.clans.getClanByTag(clan.tag) ?? clan;
  const war = runtime.wars.getWarCwlByTag(currentClan.tag);
  const model = useMemo(
    () =>
      buildClanInfoPresentationModel({
        clan: currentClan,
        bookmarked: runtime.bookmarks.isClanBookmarked(currentClan.tag),
        accounts: runtime.accounts.accounts,
        war,
      }),
    // Revision intentionally invalidates stable service-owned objects.
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [clan, revision, runtime],
  );
  const actions = useMemo<ClanInfoPresentationActions>(
    () => ({
      loadCurrentRankings: (tag) => runtime.clans.getCurrentRankings(tag),
      loadCompetitiveDay: (nextClan, day) => runtime.clans.getCompetitiveDay(nextClan, day),
      goBack,
      copyClanTag: async (tag) => {
        await Clipboard.setStringAsync(tag);
      },
      toggleClanBookmark: async (nextClan) => {
        const followed = runtime.notificationPreferences.clans?.clans.find(
          (item) => item.tag === nextClan.tag,
        );
        if (followed?.warEnabled || followed?.raidEnabled) {
          setRemoveBookmark(nextClan.tag);
          return;
        }
        try {
          await runtime.bookmarks.toggleClan(nextClan);
        } catch {
          setSnackbar(t('generalFailed'));
        }
      },
      openClanInGame: (nextClan) => requestGameHandoff(clanGameUrl(nextClan.tag, locale)),
      openDiscord: (inviteCode) => Linking.openURL(`https://discord.gg/${inviteCode}`),
      openWar: (nextClan) => {
        const nextWar = runtime.wars.getWarCwlByTag(nextClan.tag);
        if (nextWar) navigation.openWar(nextClan, nextWar);
      },
      openHistoricalWar: navigation.openHistoricalWar,
      openHistoricalCwl: navigation.openHistoricalCwl,
      openCwl: (nextClan) => {
        const nextWar = runtime.wars.getWarCwlByTag(nextClan.tag);
        if (nextWar?.leagueInfo?.clans.length) {
          navigation.openCwl(nextClan, nextWar);
          return;
        }
        // An archived season remains accessible outside CWL week. Do not make
        // this tile depend on live group hydration (or silently ignore taps).
        void runtime.clans
          .getCwlRankingHistory(nextClan.tag)
          .then((history) => {
            const latest = history[0];
            if (latest)
              navigation.openHistoricalCwl(nextClan, latest.season, latest.league ?? undefined);
            else setSnackbar(t('cwlHistoryEmptyTitle'));
          })
          .catch(() => setSnackbar(t('errorNetworkTitle')));
      },
      openCapital: navigation.openCapital,
      showMessage: setSnackbar,
      loadPlayer: (tag) => runtime.players.getPlayerAndClanData(tag),
      openPlayer: navigation.openPlayer,
      loadJoinLeave: (nextClan) => loadClanJoinLeave(runtime.clans, nextClan),
      loadMoreJoinLeave: (nextClan, current) =>
        loadMoreClanJoinLeave(runtime.clans, nextClan, current),
      loadWarLog: (nextClan) => loadClanWarLog(runtime.clans, nextClan),
      loadWarLogDetails: (nextClan, log) => runtime.clans.loadWarLogDetails(nextClan, log),
      loadWarStats: (nextClan, filter) => loadClanWarStats(runtime.clans, nextClan, filter),
      loadCwlHistory: (tag) => runtime.clans.getCwlRankingHistory(tag),
      loadLeaderboardSummary: (tag, type) =>
        runtime.clans.getClanLeaderboardHistorySummary(tag, type),
      loadLeaderboardHistory: (tag, type, after, before) =>
        runtime.clans.getClanLeaderboardHistory(tag, type, { after, before }),
      loadLegendSummary: (tag) => runtime.clans.getClanLegendHistorySummary(tag),
      loadLegendHistory: (tag, after, before) =>
        runtime.clans.getClanLegendHistory(tag, { after, before }),
      loadRecords: (tag) => runtime.clans.getClanRecords(tag),
      loadProfileHistory: (tag) => runtime.clans.getClanProfileHistory(tag),
    }),
    [goBack, locale, navigation, requestGameHandoff, runtime, t],
  );

  return (
    <View style={{ flex: 1 }}>
      <ClanInfoScreen
        key={clanInfoStateKey(currentClan.tag)}
        model={{ ...model, notifications }}
        actions={actions}
      />
      <ConfirmationDialog
        visible={removeBookmark !== undefined}
        title={t('generalRemoveBookmark')}
        message={t('clanNotificationRemoveConfirmation')}
        confirmLabel={t('generalRemoveBookmark')}
        onCancel={() => setRemoveBookmark(undefined)}
        onConfirm={() => {
          const tag = removeBookmark;
          setRemoveBookmark(undefined);
          if (tag)
            void runtime.notificationPreferences
              .removeClanBookmark(tag)
              .then(() => runtime.bookmarks.load())
              .catch(() => setSnackbar(t('generalFailed')));
        }}
      />
      <Snackbar avoidBottomNavigation message={snackbar} onDismiss={() => setSnackbar(undefined)} />
      <ClashHandoffDialog
        visible={handoff.visible}
        onCancel={handoff.cancel}
        onConfirm={handoff.confirm}
        allowRemember
      />
    </View>
  );
}

function useClanNotificationControls(
  runtime: ReturnType<typeof useAppRuntime>,
  showMessage: (message: string) => void,
): ClanNotificationControls {
  const [settings, setSettings] = useState<ClanNotificationSettings>();
  useEffect(() => {
    let mounted = true;
    const remove = runtime.notificationPreferences.subscribeClans(() => {
      if (mounted) setSettings(runtime.notificationPreferences.clans);
    });
    void runtime.notificationPreferences
      .loadClans()
      .then(() => {
        if (mounted) setSettings(runtime.notificationPreferences.clans);
      })
      .catch(() => undefined);
    return () => {
      mounted = false;
      remove();
    };
  }, [runtime]);
  return {
    settings,
    showMessage,
    setEnabled: async (tag, type, enabled) => {
      await runtime.notificationPreferences.setClanEnabled(tag, type, enabled);
      await runtime.bookmarks.load();
    },
  };
}
