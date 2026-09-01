import type { DiscordOAuthRuntime } from './discord-oauth';

interface DiscordAuthMessage {
  readonly type?: unknown;
  readonly code?: unknown;
  readonly state?: unknown;
  readonly error?: unknown;
  readonly error_description?: unknown;
}

export class PlatformDiscordOAuthRuntime implements DiscordOAuthRuntime {
  private preparedPopup: Window | null = null;

  prepareAuthorization(): void {
    this.cancelPreparedAuthorization();
    const popup = window.open('', 'discordLogin', 'popup=yes,width=520,height=760');
    if (popup === null) {
      throw new Error('The Discord login popup was blocked.');
    }
    this.preparedPopup = popup;
  }

  cancelPreparedAuthorization(): void {
    if (this.preparedPopup !== null && !this.preparedPopup.closed) {
      this.preparedPopup.close();
    }
    this.preparedPopup = null;
  }

  authorize(
    authorizationUrl: string,
    _redirectUri: string,
    expectedState: string,
  ): Promise<string | null> {
    const preparedPopup = this.preparedPopup;
    this.preparedPopup = null;
    const popup =
      preparedPopup ??
      window.open(authorizationUrl, 'discordLogin', 'popup=yes,width=520,height=760');
    if (popup === null) {
      throw new Error('The Discord login popup was blocked.');
    }
    if (preparedPopup !== null) {
      if (popup.closed) throw new Error('The Discord login popup was closed.');
      popup.location.href = authorizationUrl;
    }

    return new Promise<string | null>((resolve, reject) => {
      let settled = false;
      let closePoll: number | undefined;
      let timeout: number | undefined;
      const finish = (value: string | null, error?: unknown) => {
        if (settled) return;
        settled = true;
        window.removeEventListener('message', onMessage);
        if (closePoll !== undefined) clearInterval(closePoll);
        if (timeout !== undefined) clearTimeout(timeout);
        if (!popup.closed) popup.close();
        if (error === undefined) resolve(value);
        else reject(error);
      };
      const onMessage = (event: MessageEvent<unknown>) => {
        if (event.origin !== window.location.origin || event.source !== popup) {
          return;
        }
        if (!isRecord(event.data)) return;
        const message = event.data as DiscordAuthMessage;
        if (message.type !== 'discord-auth') return;
        const state = String(message.state ?? '');
        if (state !== expectedState) {
          finish(null, new Error('Discord OAuth state did not match this login.'));
          return;
        }
        const error = message.error == null ? null : String(message.error);
        const callback = new URL('/auth/callback', window.location.origin);
        callback.searchParams.set('state', state);
        if (error !== null && error.length > 0) {
          callback.searchParams.set('error', error);
          if (message.error_description !== undefined) {
            callback.searchParams.set('error_description', String(message.error_description));
          }
          finish(callback.toString());
          return;
        }
        const code = String(message.code ?? '');
        if (code.length === 0) return;
        callback.searchParams.set('code', code);
        finish(callback.toString());
      };
      window.addEventListener('message', onMessage);
      closePoll = window.setInterval(() => {
        if (popup.closed) finish(null);
      }, 250);
      timeout = window.setTimeout(
        () => finish(null, new Error('Discord OAuth timed out.')),
        120_000,
      );
    });
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}
