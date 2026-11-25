export interface StoredAuthSession {
  readonly accessToken: string | null;
  readonly refreshToken: string | null;
  readonly deviceId: string | null;
}

export const EMPTY_AUTH_SESSION: StoredAuthSession = {
  accessToken: null,
  refreshToken: null,
  deviceId: null,
};

/** Malformed values decode empty; invalid individual fields decode as null. */
export function tryParseStoredAuthSession(value: string | null): StoredAuthSession {
  if (value === null || value.length === 0) return EMPTY_AUTH_SESSION;
  try {
    const decoded: unknown = JSON.parse(value);
    if (!isRecord(decoded)) return EMPTY_AUTH_SESSION;
    return {
      accessToken: nonEmptyStringOrNull(decoded.access_token),
      refreshToken: nonEmptyStringOrNull(decoded.refresh_token),
      deviceId: nonEmptyStringOrNull(decoded.device_id),
    };
  } catch {
    return EMPTY_AUTH_SESSION;
  }
}

export function serializeStoredAuthSession(session: StoredAuthSession): string {
  return JSON.stringify({
    access_token: session.accessToken,
    refresh_token: session.refreshToken,
    ...(session.deviceId === null ? {} : { device_id: session.deviceId }),
  });
}

/** Read the device claim signed into an existing ClashKing JWT without verifying it. */
export function jwtDeviceId(token: string | null): string | null {
  if (token === null || token.length === 0) return null;
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return null;
    const normalized = parts[1]!.replaceAll('-', '+').replaceAll('_', '/');
    const padded = normalized.padEnd(normalized.length + ((4 - (normalized.length % 4)) % 4), '=');
    const binary = globalThis.atob(padded);
    const bytes = Uint8Array.from(binary, (character) => character.charCodeAt(0));
    const decoded: unknown = JSON.parse(new TextDecoder().decode(bytes));
    return isRecord(decoded) ? nonEmptyStringOrNull(decoded.device) : null;
  } catch {
    return null;
  }
}

function nonEmptyStringOrNull(value: unknown): string | null {
  return typeof value === 'string' && value.length > 0 ? value : null;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}
