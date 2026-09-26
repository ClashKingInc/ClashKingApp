import { useEffect, useMemo, useState } from 'react';
import { Platform, View } from 'react-native';

import type { NotificationPreferences } from '../../../core/dto/notification-preferences';
import { canonicalTag } from '../../../core/domain/tags';
import { APP_FEATURE_FLAGS } from '../../../core/feature-flags/feature-flags';
import { useAppRuntime, useAppState } from '../../../core/app/runtime-context';
import { Snackbar } from '../../../ui';
import { useI18n } from '../../../i18n';
import { HomeAccountLimitError } from '../data/player-card-preferences';
import type { Player } from '../models/player';
import type {
  PlayerCardOption,
  PlayersPresentationActions,
  PlayersPresentationModel,
} from './contracts';
import { PlayersScreen } from './players-screen';
import { withUpdatedNotificationAccount } from './players-root-state';

export interface PlayersRootProps {
  readonly openManageAccounts: () => void;
  readonly openPlayer: (player: Player) => void;
  readonly openGameSettings: () => void;
}

/** Connects the reviewed Flutter Players page presentation to live app services. */
export function PlayersRoot(props: PlayersRootProps) {
  const runtime = useAppRuntime();
  const { t } = useI18n();
  const appState = useAppState();
  const [serviceRevision, setServiceRevision] = useState(0);
  const [notificationPreferences, setNotificationPreferences] = useState<NotificationPreferences>();
  const [deviceNotificationsEnabled, setDeviceNotificationsEnabled] = useState(false);
  const [updatingNotificationTags, setUpdatingNotificationTags] = useState<ReadonlySet<string>>(
    () => new Set(),
  );
  const [snackbar, setSnackbar] = useState<string>();

  useEffect(() => {
    const changed = () => setServiceRevision((value) => value + 1);
    const unsubscribe = [
      runtime.accounts.subscribe(changed),
      runtime.players.subscribe(changed),
      runtime.bookmarks.subscribe(changed),
      runtime.playerCardPreferences.subscribe(changed),
    ];
    return () => unsubscribe.forEach((remove) => remove());
  }, [runtime]);

  const verifiedTags = runtime.accounts.verifiedAccounts.map((account) => account.playerTag);
  const verifiedSignature = verifiedTags.map(canonicalTag).join('|');
  const preferencesLoaded = runtime.playerCardPreferences.loaded;
  useEffect(() => {
    if (!preferencesLoaded || verifiedTags.length === 0) return;
    void runtime.playerCardPreferences
      .reconcileHomeIncluded(verifiedTags, runtime.accounts.selectedTag)
      .catch(() => undefined);
    // The signature tracks service-owned account arrays without looping on preference notifications.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [runtime, verifiedSignature, preferencesLoaded]);

  useEffect(() => {
    if (Platform.OS === 'web') return;
    let current = true;
    void Promise.all([
      runtime.notificationPreferences.load(),
      runtime.push.areNotificationsEnabled(),
    ])
      .then(([preferences, enabled]) => {
        if (current) {
          setNotificationPreferences(preferences);
          setDeviceNotificationsEnabled(enabled);
        }
      })
      .catch(() => {
        // Flutter keeps per-account controls unavailable when the authenticated
        // server contract cannot be loaded. This currently includes the known
        // deferred raid-reminder backend mismatch.
      });
    return () => {
      current = false;
    };
  }, [runtime]);

  const model = useMemo<PlayersPresentationModel>(() => {
    const optionsByTag = Object.fromEntries(
      runtime.accounts.accounts.map((account) => [
        canonicalTag(account.playerTag),
        runtime.playerCardPreferences.optionsFor(account.playerTag),
      ]),
    );
    const notificationAccountTags = new Set(
      (notificationPreferences?.accounts ?? [])
        .filter((account) => account.enabled)
        .map((account) => canonicalTag(account.tag)),
    );
    return {
      profiles: runtime.players.profiles,
      accountLinks: runtime.accounts.accounts,
      bookmarks: runtime.bookmarks.players.map((bookmark) => ({
        tag: bookmark.tag,
        name: bookmark.name,
        townHallLevel: bookmark.townHallLevel,
        townHallPic: bookmark.townHallPic,
        clanName: bookmark.clanName,
        trophies: bookmark.trophies,
        league: bookmark.league,
        leagueUrl: bookmark.leagueUrl,
      })),
      optionsByTag,
      homeIncludedAccountTags: new Set(
        runtime.playerCardPreferences.homeIncludedTags(verifiedTags, runtime.accounts.selectedTag),
      ),
      notificationsEnabled: Platform.OS !== 'web' && deviceNotificationsEnabled,
      notificationAccountTags,
      updatingNotificationTags,
      ...(runtime.accounts.lastRefresh ? { lastRefresh: runtime.accounts.lastRefresh } : {}),
      featureFlags: {
        upgradeTracker: appState.features[APP_FEATURE_FLAGS.upgradeTracker],
        rankedLeague: true,
      },
    };
    // Service revision intentionally invalidates stable service-owned arrays.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [
    appState.features,
    deviceNotificationsEnabled,
    notificationPreferences,
    runtime,
    serviceRevision,
    updatingNotificationTags,
  ]);

  const actions = useMemo<PlayersPresentationActions>(
    () => ({
      refresh: () => runtime.accountBootstrap.refresh(),
      showMessage: setSnackbar,
      openManageAccounts: props.openManageAccounts,
      openPlayer: props.openPlayer,
      hydrateBookmarkedPlayers: (tags) => runtime.players.hydrateBookmarkedPlayers(tags),
      loadBookmarkedPlayer: (tag) => runtime.players.getPlayerAndClanData(tag),
      verifyAccount: (playerTag, apiToken) => runtime.accounts.verifyAccount(playerTag, apiToken),
      refreshAccounts: async () => {
        await runtime.accounts.fetchAccounts();
      },
      openGameSettings: props.openGameSettings,
      reorderLinkedPlayers: async (orderedTags) => {
        const saved = await runtime.accounts.updateAccountOrder(orderedTags);
        if (!saved) throw new Error('Couldn’t update linked-account order.');
      },
      reorderBookmarkedPlayers: (orderedTags) => runtime.bookmarks.reorderPlayers(orderedTags),
      setAccountNotifications: async (playerTag, enabled) => {
        const normalized = canonicalTag(playerTag);
        if (updatingNotificationTags.has(normalized)) return;
        setUpdatingNotificationTags((current) => new Set(current).add(normalized));
        try {
          const updated = await runtime.notificationPreferences.setAccountEnabled(
            playerTag,
            enabled,
          );
          setNotificationPreferences((current) =>
            current === undefined ? current : withUpdatedNotificationAccount(current, updated),
          );
        } finally {
          setUpdatingNotificationTags((current) => {
            const next = new Set(current);
            next.delete(normalized);
            return next;
          });
        }
      },
      setAccountHidden: (playerTag, hidden) =>
        runtime.accounts.updateAccountHidden(playerTag, hidden),
      setCardOption: async (playerTag, option, enabled) => {
        if (option !== 'home') return setPlayerCardOption(runtime, playerTag, option, enabled);
        try {
          await runtime.playerCardPreferences.setShownOnHome(
            playerTag,
            enabled,
            runtime.accounts.verifiedAccounts.map((account) => account.playerTag),
            runtime.accounts.selectedTag,
          );
        } catch (error) {
          if (error instanceof HomeAccountLimitError) {
            setSnackbar(t('homeIncludedAccountsLimit'));
            return;
          }
          throw error;
        }
      },
    }),
    [props, runtime, t, updatingNotificationTags],
  );

  return (
    <View style={{ flex: 1 }}>
      <PlayersScreen model={model} actions={actions} />
      <Snackbar avoidBottomNavigation message={snackbar} onDismiss={() => setSnackbar(undefined)} />
    </View>
  );
}

function setPlayerCardOption(
  runtime: ReturnType<typeof useAppRuntime>,
  playerTag: string,
  option: Exclude<PlayerCardOption, 'notifications' | 'hidden' | 'home'>,
  enabled: boolean,
): Promise<void> {
  switch (option) {
    case 'todo':
      return runtime.playerCardPreferences.setShowInTodoPage(playerTag, enabled);
    case 'upgrade':
      return runtime.playerCardPreferences.setShowUpgradeTrackerOnHome(playerTag, enabled);
    case 'ranked':
      return runtime.playerCardPreferences.setShowRankedOnHome(playerTag, enabled);
    case 'war':
      return runtime.playerCardPreferences.setShowInWarTab(playerTag, enabled);
  }
}
