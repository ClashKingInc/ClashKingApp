import type { RuntimePlatform } from '../storage/auth-storage';
import { TransportError } from '@clashking/api-client';

export interface AuthRefreshLock {
  run<T>(operation: () => Promise<T>): Promise<T>;
}

/** Web Locks coordinate tabs on this origin; the API cookie is shared across
 * origins too, so callers must still recover from a server rotation race. */
export function withWebAuthRefreshLock<T>(apiUrl: string, operation: () => Promise<T>): Promise<T> {
  const locks = typeof navigator === 'undefined' ? undefined : navigator.locks;
  return locks ? locks.request(`clashking.auth.refresh:${apiUrl}`, operation) : operation();
}

export class NativeAuthRefreshLock implements AuthRefreshLock {
  constructor(private readonly platform: RuntimePlatform) {}

  async run<T>(operation: () => Promise<T>): Promise<T> {
    if (this.platform !== 'ios') return operation();
    try {
      const { default: ClashKingNative } = await import('@clashking/native');
      const acquired = await ClashKingNative.acquireSharedAuthRefreshLock(12);
      if (!acquired) throw new Error('Shared authentication lock is busy.');
    } catch (cause) {
      // A busy/unavailable bridge says nothing about the saved refresh token.
      // Returning null here would turn a transient lock failure into sign-out.
      throw new TransportError({
        cause,
        message: 'Shared authentication lock is unavailable. Retry authentication.',
      });
    }

    try {
      return await operation();
    } finally {
      try {
        const { default: ClashKingNative } = await import('@clashking/native');
        await ClashKingNative.releaseSharedAuthRefreshLock();
      } catch {
        // The operation has already completed. A release failure is reported by
        // the native module and must not replace its result.
      }
    }
  }
}

export class NoopAuthRefreshLock implements AuthRefreshLock {
  run<T>(operation: () => Promise<T>): Promise<T> {
    return operation();
  }
}
