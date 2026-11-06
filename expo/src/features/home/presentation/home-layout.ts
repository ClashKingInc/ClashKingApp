import { useCallback, useEffect, useRef, useState } from 'react';
import { Effect } from 'effect';
import {
  HomeLayoutGetEndpoint,
  HomeLayoutPutEndpoint,
  type HomeLayoutItem,
} from '@clashking/api-contracts/expo';
import { useAppRuntime } from '../../../core/app/runtime-context';
import { useI18n } from '../../../i18n';
export type HomeItem = typeof HomeLayoutItem.Type;
export const initialHomeItems = (): HomeItem[] =>
  ['todo', 'ranked', 'upgrade', 'activity'].map((kind) => ({
    id: kind,
    kind: kind as HomeItem['kind'],
    size: 'wide',
    entityTag: null,
  }));
function readItems(raw: string | null): HomeItem[] | null {
  if (!raw) return null;
  try {
    const value: unknown = JSON.parse(raw);
    if (!Array.isArray(value) || value.length > 30) return null;
    const items = value.filter((v): v is HomeItem =>
      Boolean(
        v &&
        typeof v === 'object' &&
        v.id === v.kind &&
        ['todo', 'ranked', 'upgrade', 'activity'].includes(v.kind) &&
        v.size === 'wide' &&
        v.entityTag === null,
      ),
    );
    if (new Set(items.map((i) => i.id)).size !== items.length) return null;
    const missing = initialHomeItems().filter(i => !items.some(v => v.id === i.id));
    return [...items, ...missing];
  } catch {
    return null;
  }
}

export function useHomeLayout(onError: (message: string) => void, refreshKey = 0) {
  const runtime = useAppRuntime(),
    { t } = useI18n();
  const [userId, setUserId] = useState(runtime.auth.state.currentUser?.userId ?? 'guest');
  const userIdentity = useRef(userId);
  const [items, setItems] = useState<readonly HomeItem[]>(initialHomeItems);
  const current = useRef(items),
    revision = useRef(0),
    generation = useRef(0),
    queue = useRef(Promise.resolve()),
    ready = useRef(false);
  useEffect(
    () =>
      runtime.auth.subscribe((state) => {
        const next = state.currentUser?.userId ?? 'guest';
        if (next === userIdentity.current) return;
        userIdentity.current = next;
        generation.current++;
        setItems(initialHomeItems());
        setUserId(next);
      }),
    [runtime.auth],
  );
  const storageKey = `home_widgets_v1:${userId}`;
  useEffect(() => {
    let alive = true;
    const run = ++generation.current;
    ready.current = false;
    revision.current = 0;
    void (async () => {
      const local = readItems(await runtime.preferences.getString(storageKey));
      let next = local ?? initialHomeItems();
      if (!local) {
        try {
          const old = JSON.parse(
            (await runtime.preferences.getString('home_card_order_v1')) ?? '[]',
          ) as unknown;
          if (Array.isArray(old)) {
            next.sort(
              (a, b) =>
                (old.indexOf(a.id) < 0 ? 99 : old.indexOf(a.id)) -
                (old.indexOf(b.id) < 0 ? 99 : old.indexOf(b.id)),
            );
          }
        } catch {
          /* Leave the original order intact when an old preference is malformed. */
        }
      }
      if (userId !== 'guest') {
        try {
          const saved = await Effect.runPromise(
            runtime.contractApi.execute(HomeLayoutGetEndpoint, { path: {}, query: {}, body: {} }),
          );
          if (saved.revision > 0)
            next = readItems(JSON.stringify(saved.items)) ?? initialHomeItems();
          if (alive && run === generation.current) revision.current = saved.revision;
        } catch {
          /* Offline/local layouts remain usable; edits report failed cloud saves. */
        }
      }
      if (alive && run === generation.current) {
        current.current = next;
        setItems(next);
        ready.current = true;
      }
    })().catch(() => {
      if (alive) {
        ready.current = true;
        onError(t('homeWidgetsSaveError'));
      }
    });
    return () => {
      alive = false;
    };
  }, [runtime, storageKey, userId, onError, t, refreshKey]);
  const change = useCallback(
    (next: readonly HomeItem[]) => {
      if (!ready.current || next.length > 30) return false;
      current.current = next;
      setItems(next);
      void runtime.preferences.setString(storageKey, JSON.stringify(next));
      if (userId === 'guest') return true;
      const run = generation.current;
      queue.current = queue.current
        .catch(() => undefined)
        .then(async () => {
          if (run !== generation.current) return;
          try {
            const bearerToken = await runtime.tokens.getAccessToken();
            if (run !== generation.current || !bearerToken) return;
            const result = await Effect.runPromise(
              runtime.contractApi.execute(
                HomeLayoutPutEndpoint,
                { path: {}, query: {}, body: { revision: revision.current, items: next } },
                { auth: { bearerToken } },
              ),
            );
            if (run === generation.current) revision.current = result.revision;
          } catch {
            if (run !== generation.current) return;
            // A revision conflict must never turn a stale queued reorder into a blind
            // overwrite. Drop queued edits, then reload the server's winning layout.
            const recovery = ++generation.current;
            onError(t('homeWidgetsSaveError'));
            try {
              const saved = await Effect.runPromise(
                runtime.contractApi.execute(HomeLayoutGetEndpoint, {
                  path: {},
                  query: {},
                  body: {},
                }),
              );
              if (recovery !== generation.current || userIdentity.current !== userId) return;
              revision.current = saved.revision;
              if (saved.revision > 0) {
                current.current = saved.items;
                setItems(saved.items);
                await runtime.preferences.setString(storageKey, JSON.stringify(saved.items));
              }
            } catch {
              /* Preserve the local layout until a later explicit edit/retry. */
            }
          }
        });
      return true;
    },
    [runtime, storageKey, userId, onError, t],
  );
  return {
    items,
    change,
    move: (id: string, delta: number) => {
      const next = [...current.current],
        from = next.findIndex((i) => i.id === id),
        to = from + delta;
      if (from < 0 || to < 0 || to >= next.length) return;
      [next[from], next[to]] = [next[to]!, next[from]!];
      change(next);
    },
  };
}
