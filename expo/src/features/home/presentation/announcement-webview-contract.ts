export type AnnouncementNavigationDecision = 'navigate' | 'prevent';

export function externalArticleLink(
  request: { url: string; navigationType: string; isTopFrame?: boolean },
  options: { trustedStory: boolean; platform: string; initialUrl?: string | null },
): string | null {
  if (options.trustedStory || request.isTopFrame === false) return null;
  const clicked =
    request.navigationType === 'click' ||
    (options.platform === 'android' && !options.initialUrl && request.navigationType === 'other');
  const url = parseUrl(request.url);
  return clicked && url?.protocol === 'https:' && !url.username && !url.password ? url.href : null;
}

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
  const initial = parseUrl(initialUrl ?? '');
  // Same-document anchors are fine, but a trusted story must not navigate to
  // another file in the app sandbox after Android file access is enabled.
  if (loadsLocalFile && requested.protocol === 'file:' && initial?.protocol === 'file:') {
    return requested.pathname === initial.pathname ? 'navigate' : 'prevent';
  }
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

// Stories are fixed-size interactive canvases, unlike zoomable article content.
// Install before content and again after load for both cached and older stories.
export const ANNOUNCEMENT_STORY_VIEWPORT_JAVASCRIPT = `
(function() {
  function lockViewport() {
    var viewport = document.querySelector('meta[name="viewport"]');
    if (!viewport && document.head) {
      viewport = document.createElement('meta');
      viewport.name = 'viewport';
      document.head.appendChild(viewport);
    }
    if (viewport) viewport.content = 'width=device-width, initial-scale=1, minimum-scale=1, maximum-scale=1, user-scalable=no';
    if (document.documentElement) {
      document.documentElement.style.touchAction = 'pan-x pan-y';
      document.documentElement.style.setProperty('-webkit-text-size-adjust', '100%');
      document.documentElement.style.setProperty('text-size-adjust', '100%');
    }
  }
  lockViewport();
  if (!window.__clashkingStoryViewportLocked) {
    window.__clashkingStoryViewportLocked = true;
    document.addEventListener('DOMContentLoaded', lockViewport, { once: true });
    ['gesturestart', 'gesturechange', 'gestureend', 'dblclick'].forEach(function(type) {
      document.addEventListener(type, function(event) { event.preventDefault(); }, { passive: false });
    });
    document.addEventListener('touchmove', function(event) {
      if (event.touches && event.touches.length > 1) event.preventDefault();
    }, { passive: false });
  }
  // Older story files have fixed 1080px composition coordinates. Fit the
  // content group inside that canvas after fonts/images load; clipping the
  // WebView or shrinking text alone loses footnotes and breaks the artwork.
  if (!window.__clashkingStoryContentFit) {
    window.__clashkingStoryContentFit = true;
    var queued = false;
    var observed = new WeakSet();
    function scheduleFit() {
      if (queued) return;
      queued = true;
      requestAnimationFrame(function() {
        queued = false;
        document.querySelectorAll('[data-content]').forEach(function(content) {
          var canvas = content.parentElement;
          if (!canvas || !canvas.clientHeight || !content.offsetHeight) return;
          if (resizeObserver && !observed.has(content)) {
            observed.add(content);
            resizeObserver.observe(content);
          }
          var available = canvas.clientHeight - content.offsetTop - 32;
          if (available <= 0) return;
          var scale = Math.min(1, available / content.offsetHeight);
          var transform = scale < 1 ? 'scale(' + scale + ')' : '';
          if (content.style.transform !== transform) {
            content.style.transformOrigin = 'top center';
            content.style.transform = transform;
          }
        });
      });
    }
    var resizeObserver = typeof ResizeObserver === 'function' ? new ResizeObserver(scheduleFit) : null;
    function observeContent() {
      if (!document.body) return;
      // Observe page replacement, not animation style changes on every frame.
      new MutationObserver(scheduleFit).observe(document.body, { childList: true, subtree: true });
      scheduleFit();
    }
    if (document.body) observeContent();
    else document.addEventListener('DOMContentLoaded', observeContent, { once: true });
    window.addEventListener('resize', scheduleFit);
    window.addEventListener('load', scheduleFit);
    if (document.fonts) document.fonts.ready.then(scheduleFit);
  }
})();
true;
`;

function parseUrl(value: string): URL | null {
  try {
    return new URL(value);
  } catch {
    return null;
  }
}
