export type AnnouncementNavigationDecision = 'navigate' | 'prevent';

export interface AnnouncementWebViewProps {
  readonly html?: string | null;
  readonly url?: string | null;
  readonly fileUri?: string | null;
  readonly trustedStory?: boolean;
  readonly onStoryMessage?: (message: string) => void;
  readonly onPageFinished?: (url: string) => void;
  readonly pageFinishedJavaScript?: string;
  readonly showLoadingProgress?: boolean;
}

export function announcementNavigationDecision({
  requestedUrl,
  initialUrl,
  loadsLocalFile = false,
}: {
  requestedUrl: string;
  initialUrl?: string | null;
  loadsLocalFile?: boolean;
}): AnnouncementNavigationDecision {
  const requested = parseUrl(requestedUrl);
  if (requested === null) return 'prevent';
  if (requested.protocol === 'about:' || requested.protocol === 'data:') return 'navigate';
  if (loadsLocalFile && requested.protocol === 'file:') return 'navigate';

  const initial = parseUrl(initialUrl ?? '');
  if (
    requested.protocol === 'https:' &&
    initial?.protocol === 'https:' &&
    requested.origin === initial.origin
  ) {
    return 'navigate';
  }
  return 'prevent';
}

export function announcementStoryMessageFromNavigation({
  requestedUrl,
  isTrustedLocalStory,
}: {
  requestedUrl: string;
  isTrustedLocalStory: boolean;
}): string | null {
  if (!isTrustedLocalStory) return null;
  const requested = parseUrl(requestedUrl);
  if (requested?.protocol !== 'clashking-story:' || requested.hostname !== 'message') return null;
  return requested.searchParams.get('payload');
}

export type AnnouncementStoryMessageType = 'ready' | 'close' | 'complete';

export function parseAnnouncementStoryMessage(
  rawMessage: string,
): AnnouncementStoryMessageType | null {
  try {
    const message = JSON.parse(rawMessage) as unknown;
    if (typeof message !== 'object' || message === null || Array.isArray(message)) return null;
    const type = (message as { type?: unknown }).type;
    return type === 'ready' || type === 'close' || type === 'complete' ? type : null;
  } catch {
    return null;
  }
}

export const ANNOUNCEMENT_STORY_BRIDGE_JAVASCRIPT = `
window.AnnouncementStory = Object.freeze({
  postMessage: function(message) {
    window.ReactNativeWebView.postMessage(String(message));
  }
});
true;
`;

function parseUrl(value: string): URL | null {
  try {
    return new URL(value);
  } catch {
    return null;
  }
}
