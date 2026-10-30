import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useLinkParameters, linkChoice } from '../../core/deep-links/link-parameters';
import { Keyboard, Platform, View } from 'react-native';

import { useAppRuntime } from '../../core/app/runtime-context';
import { useI18n } from '../../i18n';
import { PageLoading, Snackbar } from '../../ui';
import { Clan } from '../clan/models';
import type { Player } from '../player/models/player';
import {
  emptyClanSearchFilters,
  emptyPlayerSearchFilters,
  normalizeClanSearchFilters,
  playerTownHallLevels,
  type ClanSearchFilters,
  type JsonRecord,
  type PlayerSearchFilters,
  type RecentSearchItem,
  type SearchLeague,
  type SearchLocation,
  type SearchMode,
} from './models';
import { SearchScreen } from './search-screen';
import { SearchService } from './search-service';
import {
  SEARCH_DEBOUNCE_MS,
  beginSearch,
  changeSearchMode,
  completeSearch,
  failSearch,
  initialSearchRequestState,
  invalidateSearch,
  type SearchRequestState,
} from './search-state';

export interface SearchRootProps {
  readonly onOpenDestination?: (request: {
    kind: 'player' | 'clan';
    seed: JsonRecord;
    load: () => Promise<SearchDestinationResult>;
  }) => void;
  readonly initialQuery?: string;
  readonly overlay?: boolean;
  readonly autofocus?: boolean;
  readonly onCancel?: () => void;
  readonly onOpenPlayer: (player: Player) => void;
  readonly onOpenClan: (clan: Clan) => void;
}

export type SearchDestinationResult =
  | { readonly kind: 'player'; readonly player: Player }
  | { readonly kind: 'clan'; readonly clan: Clan };

/** Live replacement for Flutter's utility-page and global-overlay SearchPage variants. */
export function SearchRoot({
  initialQuery,
  overlay = false,
  autofocus = false,
  onCancel,
  onOpenPlayer,
  onOpenClan,
  onOpenDestination,
}: SearchRootProps) {
  const runtime = useAppRuntime();
  const { t } = useI18n();
  const service = useMemo(() => new SearchService(runtime.contractApi), [runtime.contractApi]);
  const link = useLinkParameters();
  const [query, setQuery] = useState(initialQuery ?? link.q ?? '');
  const [mode, setMode] = useState<SearchMode>(
    linkChoice(link.type, ['players', 'clans'], 'players'),
  );
  const [filtersExpanded, setFiltersExpanded] = useState(false);
  const [playerFilters, setPlayerFiltersState] = useState(emptyPlayerSearchFilters);
  const [clanFilters, setClanFiltersState] = useState(emptyClanSearchFilters);
  const [requestState, setRequestState] = useState(initialSearchRequestState);
  const requestRef = useRef<SearchRequestState>(initialSearchRequestState);
  const [recents, setRecents] = useState<readonly RecentSearchItem[]>([]);
  const [locations, setLocations] = useState<readonly SearchLocation[]>([]);
  const [leagues, setLeagues] = useState<readonly SearchLeague[]>([]);
  const [opening, setOpening] = useState(false);
  const mounted = useRef(true);
  useEffect(() => {
    mounted.current = true;
    return () => {
      mounted.current = false;
    };
  }, []);
  const [snackbar, setSnackbar] = useState<string>();
  const userId = runtime.auth.state.currentUser?.userId.trim() || null;

  const publishRequest = useCallback((next: SearchRequestState) => {
    requestRef.current = next;
    setRequestState(next);
  }, []);

  const loadRecents = useCallback(async () => {
    const expectedUserId = runtime.auth.state.currentUser?.userId.trim() || null;
    const items = await service.loadRecents(expectedUserId);
    if ((runtime.auth.state.currentUser?.userId.trim() || null) === expectedUserId)
      setRecents(items);
  }, [runtime.auth, service]);

  useEffect(() => {
    void service.loadRecents(userId).then((items) => {
      if ((runtime.auth.state.currentUser?.userId.trim() || null) === userId) setRecents(items);
    });
    return runtime.auth.subscribe(() => void loadRecents());
  }, [loadRecents, runtime.auth, service, userId]);

  useEffect(() => {
    if (!filtersExpanded) return undefined;
    let active = true;
    const loadFilters =
      mode === 'clans'
        ? service.loadLocations().then((nextLocations) => {
            if (active) setLocations(nextLocations);
          })
        : service.loadLeagues().then((nextLeagues) => {
            if (active) setLeagues(nextLeagues);
          });
    void loadFilters.catch(() => {
      if (!active) return;
      if (mode === 'clans') setLocations([]);
      else setLeagues([]);
    });
    return () => {
      active = false;
    };
  }, [filtersExpanded, mode, service]);

  const runSearch = useCallback(async () => {
    const started = beginSearch(requestRef.current, query);
    publishRequest(started.state);
    if (!started.shouldSearch) return;
    const version = started.state.version;
    try {
      // Browsers must not send the legacy native tracking header: it is not
      // CORS-allowed. The authenticated API already knows the caller's identity.
      const trackingHeaders =
        userId && Platform.OS !== 'web' ? { 'x-ck-user-id': userId } : undefined;
      const directTag = query.trim().toUpperCase().replace(/O/g, '0');
      if (mode === 'players' && /^#?[0289PYLQGRJCUV]{3,}$/.test(directTag)) {
        const player = await runtime.players.getPlayerAndClanData(directTag, trackingHeaders);
        publishRequest(
          completeSearch(requestRef.current, version, [
            {
              tag: player.tag,
              name: player.name,
              townHallLevel: player.townHallLevel,
              trophies: player.trophies,
            },
          ]),
        );
        return;
      }
      const results =
        mode === 'players'
          ? await runtime.players.searchPlayers(query.trim(), {
              leagueIds: playerFilters.leagueIds,
              townHallLevels: playerTownHallLevels(playerFilters),
              extraHeaders: trackingHeaders,
            })
          : await service.searchClans(query.trim(), normalizeClanSearchFilters(clanFilters));
      publishRequest(completeSearch(requestRef.current, version, results));
    } catch {
      publishRequest(failSearch(requestRef.current, version));
    }
  }, [clanFilters, mode, playerFilters, publishRequest, query, runtime.players, service, userId]);

  useEffect(() => {
    const timer = setTimeout(() => void runSearch(), SEARCH_DEBOUNCE_MS);
    return () => clearTimeout(timer);
  }, [runSearch]);

  const changeMode = (next: SearchMode) => {
    if (next === mode) return;
    setMode(next);
    setFiltersExpanded(false);
    publishRequest(changeSearchMode(requestRef.current, next));
  };
  const changePlayerFilters = (next: PlayerSearchFilters) => {
    setPlayerFiltersState(next);
    publishRequest(invalidateSearch(requestRef.current));
  };
  const changeClanFilters = (next: ClanSearchFilters) => {
    setClanFiltersState(normalizeClanSearchFilters(next));
    publishRequest(invalidateSearch(requestRef.current));
  };
  const changeQuery = (next: string) => {
    setQuery(next);
    if (!next.length) {
      publishRequest({
        ...requestRef.current,
        version: requestRef.current.version + 1,
        results: [],
        isSearching: false,
        hasSearched: false,
        lastQuery: '',
      });
    }
  };

  const openResult = async (result: JsonRecord, type: SearchMode) => {
    if (opening) return;
    const tag = typeof result.tag === 'string' ? result.tag : '';
    Keyboard.dismiss();
    const load = async (): Promise<SearchDestinationResult> => {
      const trackingHeaders =
        userId && Platform.OS !== 'web' ? { 'x-ck-user-id': userId } : undefined;
      if (type === 'players') {
        const player = await runtime.players.getPlayerAndClanData(tag, trackingHeaders);
        void loadRecents();
        return { kind: 'player', player };
      } else {
        let clan: Clan;
        try {
          clan = await runtime.clans.getClanAndWarData(tag, { extraHeaders: trackingHeaders });
        } catch {
          try {
            clan = Clan.fromJson(await service.loadClanFallback(tag, trackingHeaders));
          } catch {
            // Search already returned enough identity data to open a useful clan detail shell.
            // This keeps web navigation responsive when the follow-up proxy request is blocked.
            clan = Clan.fromJson(result);
          }
          void runtime.clans.loadJoinLeaveForClan(clan);
        }
        void loadRecents();
        return { kind: 'clan', clan };
      }
    };
    if (onOpenDestination) {
      onOpenDestination({ kind: type === 'players' ? 'player' : 'clan', seed: result, load });
      return;
    }
    // Standalone consumers without shell navigation retain their existing handoff.
    setOpening(true);
    try {
      const destination = await load();
      if (!mounted.current) return;
      if (destination.kind === 'player') onOpenPlayer(destination.player);
      else onOpenClan(destination.clan);
    } catch {
      if (!mounted.current) return;
      setSnackbar(
        type === 'players' ? t('searchErrorPlayerLoadFailed') : t('searchErrorClanLoadFailed'),
      );
    } finally {
      setOpening(false);
    }
  };
  const openRecent = (item: RecentSearchItem) =>
    openResult({ tag: item.tag, name: item.name }, item.type === 'player' ? 'players' : 'clans');

  return (
    <View style={{ flex: 1 }}>
      <SearchScreen
        overlay={overlay}
        autofocus={autofocus}
        query={query}
        mode={mode}
        filtersExpanded={filtersExpanded}
        playerFilters={playerFilters}
        clanFilters={clanFilters}
        results={requestState.results}
        recents={recents}
        locations={locations}
        leagues={leagues}
        isSearching={requestState.isSearching}
        hasSearched={requestState.hasSearched}
        onQueryChange={changeQuery}
        onSubmit={() => void runSearch()}
        onModeChange={changeMode}
        onFiltersExpandedChange={setFiltersExpanded}
        onPlayerFiltersChange={changePlayerFilters}
        onClanFiltersChange={changeClanFilters}
        onOpenResult={openResult}
        onOpenRecent={(item) => void openRecent(item)}
        onCancel={onCancel}
      />
      <PageLoading visible={opening} />
      <Snackbar message={snackbar} onDismiss={() => setSnackbar(undefined)} />
    </View>
  );
}
