import { parseAppLink } from './app-link';
import type { DeepLinkRuntime } from './contracts';

let pending: string | null = null;
const listeners = new Set<(url: string) => void>();
export function queueAppLink(url: string): boolean {
  if (!parseAppLink(url)) return false;
  if (listeners.size) listeners.forEach((listener) => listener(url));
  else pending = url;
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
