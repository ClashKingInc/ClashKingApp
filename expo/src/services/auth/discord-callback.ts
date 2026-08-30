export const DISCORD_NATIVE_REDIRECT_URI = 'clashking://com.clashking.clashkingapp/oauth';

export function isDiscordNativeCallbackUrl(url: string): boolean {
  try {
    const callback = new URL(url);
    return (
      callback.protocol === 'clashking:' &&
      callback.hostname === 'com.clashking.clashkingapp' &&
      callback.pathname === '/oauth'
    );
  } catch {
    return false;
  }
}
