import { useCallback, useEffect, useMemo, useState } from 'react';

import { useAppRuntime } from '../../../core/app/runtime-context';
import { canonicalTag } from '../../../core/domain/tags';
import type { Player } from '../../player/models';
import { WarMemberPresence } from '../../war/models';
import { buildTodoScreenModel, type TodoAccountFilter } from '../data';
import { TodoScreen } from './todo-screen';

export interface TodoRootProps {
  readonly onBack: () => void;
  readonly openPlayer: (player: Player) => void;
}

export function TodoRoot({ onBack, openPlayer }: TodoRootProps) {
  const runtime = useAppRuntime();
  const [revision, setRevision] = useState(0);
  const [query, setQuery] = useState('');
  const [filter, setFilter] = useState<TodoAccountFilter>('all');
  const [now, setNow] = useState(() => new Date());
  useEffect(() => {
    const changed = () => setRevision((value) => value + 1);
    const unsubscribers = [
      runtime.accounts.subscribe(changed),
      runtime.players.subscribe(changed),
      runtime.bookmarks.subscribe(changed),
      runtime.playerCardPreferences.subscribe(changed),
      runtime.wars.subscribe(changed),
    ];
    return () => unsubscribers.forEach((unsubscribe) => unsubscribe());
  }, [runtime]);
  useEffect(() => {
    const timer = setInterval(() => setNow(new Date()), 60_000);
    return () => clearInterval(timer);
  }, []);
  const linkedTags = useMemo(
    () =>
      new Set(runtime.accounts.verifiedAccounts.map((account) => canonicalTag(account.playerTag))),
    // Service revision invalidates the service-owned array.
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [runtime, revision],
  );
  const bookmarkedTags = useMemo(
    () => new Set(runtime.bookmarks.players.map((bookmark) => canonicalTag(bookmark.tag))),
    // Service revision invalidates the service-owned array.
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [runtime, revision],
  );
  const presenceFor = useCallback(
    (player: Player) => {
      const clan = player.clan;
      const clanTag =
        typeof clan === 'object' && clan !== null && 'tag' in clan && typeof clan.tag === 'string'
          ? clan.tag
          : '';
      if (!clanTag) return WarMemberPresence.empty();
      return (
        runtime.wars.getWarCwlByTag(clanTag)?.getMemberPresence(player.tag, clanTag) ??
        WarMemberPresence.empty()
      );
    },
    [runtime],
  );
  const model = useMemo(
    () =>
      buildTodoScreenModel({
        players: runtime.players.profiles.filter((player) =>
          linkedTags.has(canonicalTag(player.tag)),
        ),
        linkedTags,
        bookmarkedTags,
        isShown: (tag) => runtime.playerCardPreferences.isShownInTodoPage(tag),
        presenceFor,
        query,
        filter,
        now,
      }),
    // Revision invalidates the service-owned profiles and preferences.
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [bookmarkedTags, filter, linkedTags, now, presenceFor, query, revision, runtime],
  );
  const loadTimers = useCallback((tag: string) => runtime.players.loadPlayerTimers(tag), [runtime]);
  return (
    <TodoScreen
      model={model}
      query={query}
      filter={filter}
      isBookmarked={(tag) => bookmarkedTags.has(canonicalTag(tag))}
      presenceFor={presenceFor}
      loadTimers={loadTimers}
      onQueryChange={setQuery}
      onFilterChange={setFilter}
      onBack={onBack}
      openPlayer={openPlayer}
      now={now}
    />
  );
}
