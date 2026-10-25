import { parseAppLink } from './app-link';
import type { DeepLinkRuntime } from './contracts';

let pending: string | null = null;
const listeners = new Set<(url: string) => void>();
export function pendingAppLink() {
  return pending === null ? null : parseAppLink(pending);
}
export function queueAppLink(url: string): boolean {
  if (!parseAppLink(url)) return false;
  // Internal links may be relative, but the shared handler constructs a URL.
  // Normalize at the inbox boundary so every player/clan row can use the same path.
  const absolute = url.startsWith('/') ? new URL(url, 'https://app.clashk.ing').href : url;
  if (listeners.size) listeners.forEach((listener) => listener(absolute));
  else pending = absolute;
  return true;
}
export const appLinkInbox: DeepLinkRuntime = {
  async getInitialUrl() {
    const url = pending;
    pending = null;
    return url;
  },
  subscribe(listener) {
    listeners.add(listener);
    return () => {
      listeners.delete(listener);
    };
  },
};
