import * as Clipboard from 'expo-clipboard';
import { File, Paths } from 'expo-file-system';
import * as Linking from 'expo-linking';
import * as Sharing from 'expo-sharing';
import { useMemo, useState, useEffect } from 'react';
import { Platform, View } from 'react-native';

import { useAppRuntime } from '../../../core/app/runtime-context';
import { defaultIsNetworkError } from '../../../core/app/startup-coordinator';
import { canonicalTag } from '../../../core/domain/tags';
import { StartupErrorScreen } from '../../../core/app/startup-feedback';
import { useI18n } from '../../../i18n';
import { Snackbar } from '../../../ui';
import { WarCwlService } from '../data';
import type { WarCwl, WarInfo } from '../models';
import type { WarPresentationActions, WarPresentationModel } from './contracts';
import { CwlScreen } from './cwl-screen';
import { WarCwlPresentationRoot } from './war-cwl-screen';
import { WarDetailScreen } from './war-detail-screen';
import { extraWarClanTags, hiddenWarPlayerTags, hydratedClanValues } from './war-root-state';

export interface WarCwlRootProps {
  readonly openClan: (tag: string) => void;
  readonly openPlayer: (tag: string) => void;
  readonly onOpenWar?: (
    war: WarInfo,
    roundNumber: number | null,
    cwl?: { readonly summary: WarCwl; readonly clanTag: string; readonly warLeagueName?: string },
  ) => void;
  readonly onOpenCwl?: (summary: WarCwl, clanTag: string, warLeagueName?: string) => void;
}

export function WarCwlRoot(props: WarCwlRootProps) {
  const runtime = useAppRuntime();
  const { t } = useI18n();
  const [serviceRevision, setServiceRevision] = useState(0);
  const [snackbar, setSnackbar] = useState<string>();
  const [networkRetry, setNetworkRetry] = useState<(() => Promise<void>) | undefined>();
  const [retrying, setRetrying] = useState(false);

  useEffect(() => {
    const changed = () => setServiceRevision((value) => value + 1);
    const unsubscribe = [
      runtime.accounts.subscribe(changed),
      runtime.players.subscribe(changed),
      runtime.bookmarks.subscribe(changed),
      runtime.playerCardPreferences.subscribe(changed),
      runtime.clans.subscribe(changed),
      runtime.wars.subscribe(changed),
    ];
    return () => unsubscribe.forEach((remove) => remove());
  }, [runtime]);

  const ownedPlayerTags = runtime.accounts.accounts.map((account) => account.playerTag);
  const additionalClanTags = extraWarClanTags(
    runtime.players.profiles,
    ownedPlayerTags,
    runtime.bookmarks.players,
    runtime.bookmarks.clans,
    runtime.playerCardPreferences,
  );
  const model = useMemo<WarPresentationModel>(
    () => ({
      profiles: runtime.players.profiles,
      ownedPlayerTags,
      bookmarkedPlayers: runtime.bookmarks.players,
      bookmarkedClans: runtime.bookmarks.clans,
      hydratedBookmarkedClans: hydratedClanValues(runtime.clans.clans),
      summaries: runtime.wars.summaries,
      hiddenPlayerTags: hiddenWarPlayerTags(
        runtime.players.profiles,
        runtime.bookmarks.players,
        runtime.playerCardPreferences,
      ),
      ...(runtime.accounts.lastRefresh ? { lastRefresh: runtime.accounts.lastRefresh } : {}),
    }),
    // Service revision intentionally invalidates stable service-owned arrays and maps.
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [runtime, serviceRevision],
  );
  const actions = useMemo<WarPresentationActions>(
    () => ({
      refresh: async () => {
        await runtime.accountBootstrap.refresh();
        if (additionalClanTags.length) {
          await runtime.wars.loadAllWarData(additionalClanTags, {
            notify: true,
            throwOnError: true,
          });
        }
      },
      hydrateBookmarkedPlayers: (tags) => runtime.players.hydrateBookmarkedPlayers(tags),
      loadWarSummaries: (tags) =>
        runtime.wars.loadAllWarData(tags, { notify: true, throwOnError: false }),
      isNetworkError: defaultIsNetworkError,
      openNetworkError: (retry) => setNetworkRetry(() => retry),
      showMessage: setSnackbar,
      openClan: props.openClan,
      openPlayer: props.openPlayer,
      copyText: async (value) => {
        await Clipboard.setStringAsync(value);
      },
      exportCwl: async (clanTag) => {
        setSnackbar(t('downloadInProgress'));
        try {
          const path = await downloadCwlExport(runtime.configuration.apiV2Url, clanTag);
          setSnackbar(t('downloadSuccess', { path }));
        } catch {
          setSnackbar(t('downloadError'));
        }
      },
      fetchPreviousWar: (clanTag, before) =>
        WarCwlService.fetchWarDataFromTime(runtime.api, clanTag, before),
    }),
    [additionalClanTags, props, runtime, t],
  );

  if (networkRetry) {
    return (
      <StartupErrorScreen
        avatarUrl={runtime.auth.state.currentUser?.avatarUrl ?? null}
        isNetworkError
        retrying={retrying}
        onJoinDiscord={() => void Linking.openURL('https://discord.gg/clashking')}
        onLogout={() => void runtime.auth.signOut()}
        onRetry={() => {
          if (retrying) return;
          setRetrying(true);
          setTimeout(() => {
            void networkRetry()
              .then(() => setNetworkRetry(undefined))
              .catch(() => undefined)
              .finally(() => setRetrying(false));
          }, 300);
        }}
        userName={runtime.auth.state.currentUser?.username ?? null}
      />
    );
  }

  return (
    <View style={{ flex: 1 }}>
      <WarCwlPresentationRoot
        model={model}
        actions={actions}
        onOpenWar={props.onOpenWar}
        onOpenCwl={props.onOpenCwl}
      />
      <Snackbar avoidBottomNavigation message={snackbar} onDismiss={() => setSnackbar(undefined)} />
    </View>
  );
}

export interface WarInfoRootProps {
  readonly war: WarInfo;
  readonly roundNumber?: number | null;
  readonly onBack: () => void;
  readonly openClan: (tag: string) => void;
  readonly openPlayer: (tag: string) => void;
  readonly onOpenCwl?: () => void;
}

/** A shell-owned war detail route, used when Flutter would push above the current page. */
export function WarInfoRoot({
  war,
  roundNumber,
  onBack,
  openClan,
  openPlayer,
  onOpenCwl,
}: WarInfoRootProps) {
  const { actions, snackbar, dismissSnackbar, ownedPlayerTags } = useStandaloneWarActions(
    openClan,
    openPlayer,
  );
  return (
    <View style={{ flex: 1 }}>
      <WarDetailScreen
        war={war}
        linkedPlayerTags={ownedPlayerTags}
        cwlRoundNumber={roundNumber}
        actions={actions}
        onBack={onBack}
        onOpenCwl={onOpenCwl}
      />
      <Snackbar avoidBottomNavigation message={snackbar} onDismiss={dismissSnackbar} />
    </View>
  );
}

export interface CwlInfoRootProps {
  readonly summary: WarCwl;
  readonly clanTag: string;
  readonly warLeagueName?: string;
  readonly onBack: () => void;
  readonly onOpenWar: (war: WarInfo, roundNumber: number) => void;
  readonly openClan: (tag: string) => void;
  readonly openPlayer: (tag: string) => void;
}

/** A shell-owned CWL route that keeps nested war navigation on the same app stack. */
export function CwlInfoRoot({
  summary,
  clanTag,
  warLeagueName,
  onBack,
  onOpenWar,
  openClan,
  openPlayer,
}: CwlInfoRootProps) {
  const { actions, snackbar, dismissSnackbar } = useStandaloneWarActions(openClan, openPlayer);
  return (
    <View style={{ flex: 1 }}>
      <CwlScreen
        summary={summary}
        clanTag={clanTag}
        warLeagueName={warLeagueName}
        actions={actions}
        onBack={onBack}
        onOpenWar={onOpenWar}
      />
      <Snackbar avoidBottomNavigation message={snackbar} onDismiss={dismissSnackbar} />
    </View>
  );
}

function useStandaloneWarActions(
  openClan: (tag: string) => void,
  openPlayer: (tag: string) => void,
): {
  readonly actions: WarPresentationActions;
  readonly snackbar: string | undefined;
  readonly dismissSnackbar: () => void;
  readonly ownedPlayerTags: readonly string[];
} {
  const runtime = useAppRuntime();
  const { t } = useI18n();
  const [snackbar, setSnackbar] = useState<string>();
  const actions = useMemo<WarPresentationActions>(
    () => ({
      refresh: () => runtime.accountBootstrap.refresh(),
      hydrateBookmarkedPlayers: (tags) => runtime.players.hydrateBookmarkedPlayers(tags),
      loadWarSummaries: (tags) =>
        runtime.wars.loadAllWarData(tags, { notify: true, throwOnError: false }),
      isNetworkError: defaultIsNetworkError,
      openNetworkError: () => setSnackbar(t('errorNetworkTitle')),
      showMessage: setSnackbar,
      openClan,
      openPlayer,
      copyText: async (value) => {
        await Clipboard.setStringAsync(value);
      },
      exportCwl: async (tag) => {
        setSnackbar(t('downloadInProgress'));
        try {
          const path = await downloadCwlExport(runtime.configuration.apiV2Url, tag);
          setSnackbar(t('downloadSuccess', { path }));
        } catch {
          setSnackbar(t('downloadError'));
        }
      },
      fetchPreviousWar: (tag, before) =>
        WarCwlService.fetchWarDataFromTime(runtime.api, tag, before),
    }),
    [openClan, openPlayer, runtime, t],
  );
  return {
    actions,
    snackbar,
    dismissSnackbar: () => setSnackbar(undefined),
    ownedPlayerTags: runtime.accounts.accounts.map((account) => account.playerTag),
  };
}

export async function downloadCwlExport(apiV2Url: string, clanTag: string): Promise<string> {
  const tag = clanTag.replaceAll('#', '!');
  const fileName = `cwl_summary_${canonicalTag(clanTag).replaceAll('#', '')}.xlsx`;
  const url = `${apiV2Url.replace(/\/$/, '')}/exports/war/cwl-summary?tag=${encodeURIComponent(tag)}`;
  if (Platform.OS === 'web') {
    const response = await fetch(url);
    if (!response.ok) throw new Error(`Download failed (${response.status})`);
    const blobUrl = URL.createObjectURL(await response.blob());
    const anchor = document.createElement('a');
    anchor.href = blobUrl;
    anchor.download = fileName;
    anchor.click();
    URL.revokeObjectURL(blobUrl);
    return fileName;
  }
  const destination = new File(Paths.cache, fileName);
  const file = await File.downloadFileAsync(url, destination, { idempotent: true });
  if (await Sharing.isAvailableAsync()) {
    await Sharing.shareAsync(file.uri, {
      mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      dialogTitle: fileName,
    });
  }
  return file.uri;
}
