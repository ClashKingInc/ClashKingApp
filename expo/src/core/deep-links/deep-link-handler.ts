import type { DeepLinkHandlerOptions } from './contracts';

export type DeepLinkRoute = 'oauth' | 'player' | 'clan' | 'war' | string;

export function extractDeepLinkRoute(uri: URL): DeepLinkRoute {
  const rawFirstPath = uri.pathname.split('/').filter(Boolean)[0];
  const firstPath = rawFirstPath === undefined ? undefined : safeDecode(rawFirstPath).toLowerCase();
  return firstPath ?? uri.hostname.toLowerCase();
}

export function extractNormalizedDeepLinkTag(uri: URL): string | null {
  const raw =
    uri.searchParams.get('tag') ??
    uri.searchParams.get('player_tag') ??
    uri.searchParams.get('clan_tag');
  if (raw === null) return null;
  const trimmed = raw.trim().replaceAll(' ', '').replace('!', '#');
  if (!trimmed) return null;
  return (trimmed.startsWith('#') ? trimmed : `#${trimmed}`).toUpperCase();
}

function safeDecode(value: string): string {
  try {
    return decodeURIComponent(value);
  } catch {
    return value;
  }
}

export class DeepLinkHandler<Player, Clan> {
  private pendingUrl: string | null = null;
  private handling = false;

  constructor(private readonly options: DeepLinkHandlerOptions<Player, Clan>) {}

  get pendingDeepLink(): string | null {
    return this.pendingUrl;
  }

  queueDeepLink(url: string): void {
    this.pendingUrl = url;
    this.options.log?.(`Queued deep link: ${url}`);
  }

  async tryHandlePendingDeepLink(): Promise<void> {
    if (this.pendingUrl === null || this.handling || !this.options.isReady()) return;
    const captured = this.pendingUrl;
    let uri: URL;
    try {
      uri = new URL(captured);
    } catch (error) {
      await this.report('deep_link.parse', error);
      if (this.pendingUrl === captured) this.pendingUrl = null;
      return;
    }
    this.handling = true;
    try {
      const handled = await this.dispatch(uri);
      if (handled && this.pendingUrl === captured) this.pendingUrl = null;
    } finally {
      this.handling = false;
    }
  }

  private async dispatch(uri: URL): Promise<boolean> {
    const route = extractDeepLinkRoute(uri);
    if (route === 'oauth') return true;
    if (!this.options.isAuthenticated()) return false;
    switch (route) {
      case 'player':
        await this.openPlayer(uri);
        return true;
      case 'clan':
        await this.openClan(uri);
        return true;
      case 'war':
        await this.options.showFeedback('comingSoon');
        return true;
      default:
        await this.options.showFeedback('unknown');
        return true;
    }
  }

  private async openPlayer(uri: URL): Promise<void> {
    const tag = extractNormalizedDeepLinkTag(uri);
    if (tag === null) {
      await this.options.showFeedback('invalidPlayer');
      return;
    }
    await this.options.showLoading(true);
    try {
      const player = await this.options.loadPlayer(tag);
      await this.options.showLoading(false);
      if (this.options.isReady()) await this.options.openPlayer(player);
    } catch (error) {
      await this.options.showLoading(false);
      await this.report('deep_link.player', error);
      if (this.options.isReady()) await this.options.showFeedback('failedPlayer');
    }
  }

  private async openClan(uri: URL): Promise<void> {
    const tag = extractNormalizedDeepLinkTag(uri);
    if (tag === null) {
      await this.options.showFeedback('invalidClan');
      return;
    }
    await this.options.showLoading(true);
    try {
      const clan = await this.options.loadClan(tag);
      await this.options.showLoading(false);
      if (this.options.isReady()) await this.options.openClan(clan);
    } catch (error) {
      await this.options.showLoading(false);
      await this.report('deep_link.clan', error);
      if (this.options.isReady()) await this.options.showFeedback('failedClan');
    }
  }

  private async report(operation: string, error: unknown): Promise<void> {
    try {
      await this.options.reportError?.(operation, error);
    } catch {
      // Observability cannot change queue semantics.
    }
  }
}
