export type DeepLinkFeedback =
  'comingSoon' | 'unknown' | 'invalidPlayer' | 'invalidClan' | 'failedPlayer' | 'failedClan';

export interface DeepLinkHandlerOptions<Player, Clan> {
  readonly isReady: () => boolean;
  readonly isAuthenticated: () => boolean;
  readonly loadPlayer: (tag: string) => Promise<Player>;
  readonly loadClan: (tag: string) => Promise<Clan>;
  readonly openPlayer: (player: Player) => void | Promise<void>;
  readonly openClan: (clan: Clan) => void | Promise<void>;
  readonly showLoading: (loading: boolean) => void | Promise<void>;
  readonly showFeedback: (feedback: DeepLinkFeedback) => void | Promise<void>;
  readonly reportError?: (operation: string, error: unknown) => void | Promise<void>;
  readonly log?: (message: string) => void;
}

export interface DeepLinkRuntime {
  getInitialUrl(): Promise<string | null>;
  subscribe(listener: (url: string) => void): () => void;
}
