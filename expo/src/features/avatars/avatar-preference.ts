import { useCallback, useEffect, useSyncExternalStore } from 'react';
import { AppState } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Effect } from 'effect';
import { GetAccountAvatarEndpoint, SetAccountAvatarEndpoint } from '@clashking/api-contracts/expo';
import { useAppRuntime } from '../../core/app/runtime-context';
import catalog from './catalog.json';

type State = { chosen: boolean; id: string; ready: boolean; failed: boolean; revision: number };
const initial: State = { chosen: false, id: 'barbarian', ready: false, failed: false, revision: 0 };
const states = new Map<string, State>();
const pending = new Map<string, Promise<void>>();
const listeners = new Set<() => void>();
const notify = () => listeners.forEach((listener) => listener());
export function useAvatarPreference() {
  const runtime = useAppRuntime();
  const userId = useSyncExternalStore(
    (listener) => runtime.auth.subscribe(listener),
    () => runtime.auth.state.currentUser?.userId ?? '',
  );
  const state = useSyncExternalStore(
    (listener) => {
      listeners.add(listener);
      return () => {
        listeners.delete(listener);
      };
    },
    () => states.get(userId) ?? initial,
  );
  const reload = useCallback((): Promise<void> => {
    if (!userId) return Promise.resolve();
    const running = pending.get(userId);
    if (running) return running;
    const before = states.get(userId) ?? initial;
    if (before.failed) {
      states.set(userId, { ...before, failed: false });
      notify();
    }
    const cacheKey = `account-avatar:${userId}`;
    // The cached value is display-only. Picking still waits for the account
    // read, and Continue only succeeds after an acknowledged server write.
    void AsyncStorage.getItem(cacheKey)
      .then((cached) => {
        if (!states.get(userId)?.ready && catalog.some((a) => a.id === cached)) {
          states.set(userId, { ...(states.get(userId) ?? initial), id: cached! });
          notify();
        }
      })
      .catch(() => {});
    const task = Effect.runPromise(
      runtime.contractApi.execute(GetAccountAvatarEndpoint, {
        path: {},
        query: {},
        body: {},
      }),
    )
      .then((result) => {
        // A read started before a successful save cannot replace that new choice.
        if ((states.get(userId) ?? initial).revision !== before.revision) return;
        states.set(userId, {
          id: result.avatar_id ?? 'barbarian',
          chosen: result.avatar_id !== null,
          ready: true,
          failed: false,
          revision: before.revision,
        });
        notify();
        void AsyncStorage.setItem(cacheKey, result.avatar_id ?? 'barbarian').catch(() => {});
      })
      .catch(() => {
        states.set(userId, { ...(states.get(userId) ?? initial), failed: true });
        notify();
      })
      .finally(() => {
        pending.delete(userId);
      });
    pending.set(userId, task);
    return task;
  }, [runtime, userId]);
  useEffect(() => {
    void reload();
    // Read again after returning from another device/session. No background polling.
    const subscription = AppState.addEventListener('change', (next) => {
      if (next === 'active') void reload();
    });
    return () => subscription.remove();
  }, [reload]);
  const save = async (id: string) => {
    const avatar = catalog.find((a) => a.id === id);
    if (!userId || !avatar) throw new Error('Invalid avatar selection');
    const response = await Effect.runPromise(
      runtime.contractApi.execute(SetAccountAvatarEndpoint, {
        path: {},
        query: {},
        body: { avatar_id: avatar.id as typeof SetAccountAvatarEndpoint.body.Type.avatar_id },
      }),
    );
    states.set(userId, {
      id: response.avatar_id ?? 'barbarian',
      chosen: response.avatar_id !== null,
      ready: true,
      failed: false,
      revision: (states.get(userId)?.revision ?? 0) + 1,
    });
    notify();
    void AsyncStorage.setItem(`account-avatar:${userId}`, response.avatar_id ?? 'barbarian').catch(
      () => {},
    );
  };
  return { ...state, save, reload };
}
