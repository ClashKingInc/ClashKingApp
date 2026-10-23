export function playerGameUrl(playerTag: string, locale: string): string {
  const language = locale.split(/[-_]/)[0]?.toLowerCase() || 'en';
  const query = new URLSearchParams({ action: 'OpenPlayerProfile', tag: playerTag });
  return `https://link.clashofclans.com/${language}?${query.toString()}`;
}
