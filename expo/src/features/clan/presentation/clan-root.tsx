import * as Clipboard from 'expo-clipboard';
import { useEffect, useMemo, useState } from 'react';
import { Linking, View } from 'react-native';

import { defaultIsNetworkError } from '../../../core/app/startup-coordinator';
import { useAppRuntime } from '../../../core/app/runtime-context';
import { useI18n } from '../../../i18n';
import { ClashHandoffDialog, Snackbar } from '../../../ui';
import type { Player } from '../../player/models/player';
import type { WarCwl, WarInfo } from '../../war/models';
import type { Clan } from '../models';
import { ClanInfoScreen } from './clan-info-screen';
import type { ClanInfoPresentationActions } from './clan-info-contracts';
import {
  buildClanInfoPresentationModel,
  buildClansPresentationModel,
  clanInfoStateKey,
  clanGameUrl,
  loadClanJoinLeave,
  loadClanWarLog,
  loadClanWarStats,
  loadMoreClanJoinLeave,
} from './clan-root-state';
import { ClansScreen } from './clans-screen';
import type { ClansPresentationActions } from './contracts';

export interface ClanNavigationActions {
  readonly openPlayer: (player: Player) => void;
  readonly openWar: (clan: Clan, war: WarCwl) => void;
  readonly openHistoricalWar: (war: WarInfo) => void;
  readonly openCwl: (clan: Clan, war: WarCwl) => void;
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
  readonly onOpenClan?: (clan: Clan) => void;
}) {
  const runtime = useAppRuntime();
  const { t } = useI18n();
  const [revision, setRevision] = useState(0);
  const [selectedClan, setSelectedClan] = useState<Clan>();
  const [snackbar, setSnackbar] = useState<string>();

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

  const model = buildClansPresentationModel({
    profiles: runtime.players.profiles,
    bookmarks: runtime.bookmarks.clans,
    clans: runtime.clans.clans,
    lastRefresh: runtime.accounts.lastRefresh,
  });
  const actions: ClansPresentationActions = {
    refresh: () => runtime.accountBootstrap.refresh(),
    isNetworkError: defaultIsNetworkError,
    openNetworkError: navigation.openNetworkError ?? (() => setSnackbar(t('errorNetworkTitle'))),
    showMessage: setSnackbar,
    hydrateBookmarkedClans: (tags) => runtime.clans.loadAllClanData(tags, { notify: true }),
    loadClan: (tag) => runtime.clans.getClanAndWarData(tag),
    openClan: onOpenClan ?? setSelectedClan,
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
  const { locale } = useI18n();
  const [revision, setRevision] = useState(0);
  const [snackbar, setSnackbar] = useState<string>();
  const [handoffUrl, setHandoffUrl] = useState<string>();

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
      goBack,
      copyClanTag: async (tag) => {
        await Clipboard.setStringAsync(tag);
      },
      toggleClanBookmark: (nextClan) => runtime.bookmarks.toggleClan(nextClan),
      openClanInGame: (nextClan) => setHandoffUrl(clanGameUrl(nextClan.tag, locale)),
      openDiscord: (inviteCode) => Linking.openURL(`https://discord.gg/${inviteCode}`),
      openWar: (nextClan) => {
        const nextWar = runtime.wars.getWarCwlByTag(nextClan.tag);
        if (nextWar) navigation.openWar(nextClan, nextWar);
      },
      openHistoricalWar: navigation.openHistoricalWar,
      openCwl: (nextClan) => {
        const nextWar = runtime.wars.getWarCwlByTag(nextClan.tag);
        if (nextWar?.leagueInfo?.clans.length) navigation.openCwl(nextClan, nextWar);
      },
      openCapital: navigation.openCapital,
      showMessage: setSnackbar,
      loadPlayer: (tag) => runtime.players.getPlayerAndClanData(tag),
      openPlayer: navigation.openPlayer,
      loadJoinLeave: (nextClan) => loadClanJoinLeave(runtime.clans, nextClan),
      loadMoreJoinLeave: (nextClan, current) =>
        loadMoreClanJoinLeave(runtime.clans, nextClan, current),
      loadWarLog: (nextClan) => loadClanWarLog(runtime.clans, nextClan),
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
    [goBack, locale, navigation, runtime],
  );

  return (
    <View style={{ flex: 1 }}>
      <ClanInfoScreen key={clanInfoStateKey(currentClan.tag)} model={model} actions={actions} />
      <Snackbar avoidBottomNavigation message={snackbar} onDismiss={() => setSnackbar(undefined)} />
      <ClashHandoffDialog
        visible={handoffUrl !== undefined}
        onCancel={() => setHandoffUrl(undefined)}
        onConfirm={() => {
          const url = handoffUrl;
          setHandoffUrl(undefined);
          if (url) void Linking.openURL(url);
        }}
      />
    </View>
  );
}
