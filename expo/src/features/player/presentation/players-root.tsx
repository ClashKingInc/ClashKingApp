import { useEffect, useMemo, useState } from 'react';
import { View } from 'react-native';

import type { NotificationPreferences } from '../../../core/dto/notification-preferences';
import { canonicalTag } from '../../../core/domain/tags';
import { APP_FEATURE_FLAGS } from '../../../core/feature-flags/feature-flags';
import { useAppRuntime, useAppState } from '../../../core/app/runtime-context';
import { Snackbar } from '../../../ui';
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
  const appState = useAppState();
  const [serviceRevision, setServiceRevision] = useState(0);
  const [notificationPreferences, setNotificationPreferences] = useState<NotificationPreferences>();
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

  useEffect(() => {
    let current = true;
    void runtime.notificationPreferences
      .load()
      .then((preferences) => {
        if (current) setNotificationPreferences(preferences);
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
        .filter((account) => account.active)
        .map((account) => canonicalTag(account.playerTag)),
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
      notificationsEnabled: notificationPreferences?.notificationsEnabled === true,
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
      setCardOption: (playerTag, option, enabled) =>
        setPlayerCardOption(runtime, playerTag, option, enabled),
    }),
    [props, runtime, updatingNotificationTags],
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
  option: Exclude<PlayerCardOption, 'notifications' | 'hidden'>,
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
