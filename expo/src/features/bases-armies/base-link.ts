export function townHallLevelFromBaseLink(baseLink: string): number | null {
  let layoutId: string | null = null;

  try {
    layoutId = new URL(baseLink).searchParams.get('id');
  } catch {
    const encoded = baseLink.match(/[?&]id=([^&]+)/i)?.[1];
    if (encoded !== undefined) {
      try {
        layoutId = decodeURIComponent(encoded);
      } catch {
        layoutId = encoded;
      }
    }
  }

  const match = /^TH(\d+)(?::|$)/i.exec(layoutId?.trim() ?? '');
  if (match === null) return null;

  const level = Number.parseInt(match[1]!, 10);
  return Number.isSafeInteger(level) && level > 0 ? level : null;
}
