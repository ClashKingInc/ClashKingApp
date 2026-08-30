export interface AuthUser {
  readonly userId: string;
  readonly username: string;
  readonly avatarUrl: string;
  readonly authMethods: readonly string[];
  readonly email: string | null;
}

export interface CocAccountLink {
  readonly playerTag: string;
  readonly isVerified: boolean;
  readonly hidden: boolean;
  readonly raw: Readonly<Record<string, unknown>>;
}

export function parseAuthUser(value: unknown): AuthUser {
  const json = expectRecord(value, 'user');
  const authMethods = Array.isArray(json.auth_methods)
    ? json.auth_methods.filter((method): method is string => typeof method === 'string')
    : [];
  return {
    userId: stringOrDefault(json.user_id, ''),
    username: stringOrNull(json.discord_username) ?? stringOrNull(json.username) ?? 'Unknown',
    avatarUrl: stringOrDefault(json.avatar_url, ''),
    authMethods,
    email: stringOrNull(json.email),
  };
}

export function parseCocAccountLink(value: unknown): CocAccountLink {
  const json = expectRecord(value, 'CoC account item');
  const playerTag = json.player_tag;
  if (typeof playerTag !== 'string' || playerTag.trim().length === 0) {
    throw new TypeError('Link account is missing player_tag');
  }
  if (typeof json.hidden !== 'boolean') {
    throw new TypeError('Link account hidden must be a bool');
  }
  if (json.is_verified !== undefined && typeof json.is_verified !== 'boolean') {
    throw new TypeError('Link account is_verified must be a bool');
  }
  return {
    playerTag,
    isVerified: json.is_verified ?? false,
    hidden: json.hidden,
    raw: { ...json, player_tag: playerTag, is_verified: json.is_verified ?? false },
  };
}

export function expectRecord(value: unknown, label: string): Record<string, unknown> {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    throw new TypeError(`Invalid ${label}`);
  }
  return value as Record<string, unknown>;
}

function stringOrDefault(value: unknown, fallback: string): string {
  return typeof value === 'string' ? value : fallback;
}

function stringOrNull(value: unknown): string | null {
  return typeof value === 'string' ? value : null;
}
