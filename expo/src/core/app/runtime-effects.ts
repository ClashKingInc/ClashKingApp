import type { SupportedPushRoute } from '../../features/notifications/push';

export type RuntimeRoute = SupportedPushRoute | `/posts/${string}`;

export function supportCreatorUrl(locale: string): string {
  const language = locale.split('_', 1)[0]!.toLowerCase();
  return `https://link.clashofclans.com/${language}?action=SupportCreator&id=Clashking`;
}

export class RuntimeEffects {
  private routeHandler: ((route: RuntimeRoute) => void | Promise<void>) | null = null;
  private readonly pendingRoutes: {
    readonly route: RuntimeRoute;
    readonly resolve: () => void;
    readonly reject: (error: unknown) => void;
  }[] = [];

  bindRouteHandler(handler: (route: RuntimeRoute) => void | Promise<void>): () => void {
    this.routeHandler = handler;
    void this.flushPendingRoutes(handler);
    return () => {
      if (this.routeHandler === handler) this.routeHandler = null;
    };
  }

  openRoute(route: RuntimeRoute): void | Promise<void> {
    if (this.routeHandler !== null) return this.routeHandler(route);
    return new Promise<void>((resolve, reject) => {
      this.pendingRoutes.push({ route, resolve, reject });
    });
  }

  clearPendingRoutes(): void {
    for (const pending of this.pendingRoutes.splice(0)) pending.resolve();
  }

  private async flushPendingRoutes(
    handler: (route: RuntimeRoute) => void | Promise<void>,
  ): Promise<void> {
    for (const pending of this.pendingRoutes.splice(0)) {
      try {
        await handler(pending.route);
        pending.resolve();
      } catch (error) {
        pending.reject(error);
      }
    }
  }
}
