import { Platform } from 'react-native';

export function recordBrowserPath(path: string): void {
  if (Platform.OS !== 'web' || typeof window === 'undefined') return;
  if (window.location.pathname + window.location.search === path) return;
  window.history.replaceState({ ...window.history.state, clashKing: true }, '');
  window.history.pushState({ clashKing: true }, '', path);
}

export function backThroughBrowserHistory(): boolean {
  if (Platform.OS !== 'web' || typeof window === 'undefined') return false;
  if (window.history.state?.clashKing) window.history.back();
  else {
    window.history.replaceState(null, '', '/');
    window.dispatchEvent(new PopStateEvent('popstate'));
  }
  return true;
}
