import type { RuntimePlatform } from '../storage/auth-storage';

export interface AuthRefreshLock {
  run<T>(operation: () => Promise<T>): Promise<T | null>;
}

export class NativeAuthRefreshLock implements AuthRefreshLock {
  constructor(private readonly platform: RuntimePlatform) {}

  async run<T>(operation: () => Promise<T>): Promise<T | null> {
    if (this.platform !== 'ios') return operation();
    try {
      const { default: ClashKingNative } = await import('@clashking/native');
      const acquired = await ClashKingNative.acquireSharedAuthRefreshLock(12);
      if (!acquired) return null;
    } catch {
      return null;
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
