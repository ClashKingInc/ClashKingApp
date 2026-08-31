export type JsonRecord = Record<string, unknown>;

export const isRecord = (value: unknown): value is JsonRecord =>
  typeof value === 'object' && value !== null && !Array.isArray(value);

export const record = (value: unknown): JsonRecord => (isRecord(value) ? value : {});
export const records = (value: unknown): JsonRecord[] =>
  Array.isArray(value) ? value.filter(isRecord) : [];
export const string = (value: unknown, fallback = ''): string =>
  value == null ? fallback : String(value);
export const nullableString = (value: unknown): string | null =>
  value == null ? null : String(value);
export const int = (value: unknown, fallback = 0): number =>
  typeof value === 'number' && Number.isFinite(value) ? Math.trunc(value) : fallback;
export const nullableInt = (value: unknown): number | null =>
  typeof value === 'number' && Number.isFinite(value) ? Math.trunc(value) : null;
export const number = (value: unknown, fallback = 0): number =>
  typeof value === 'number' && Number.isFinite(value) ? value : fallback;
export const bool = (value: unknown, fallback = false): boolean =>
  typeof value === 'boolean' ? value : fallback;

export function dateOrEpoch(value: unknown): Date {
  const parsed = new Date(string(value));
  return Number.isNaN(parsed.getTime()) ? new Date(0) : parsed;
}

export function apiDateOrEpoch(value: unknown): Date {
  const raw = string(value);
  const match = /^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})(?:\.\d+)?Z$/.exec(raw);
  return dateOrEpoch(
    match ? `${match[1]}-${match[2]}-${match[3]}T${match[4]}:${match[5]}:${match[6]}Z` : raw,
  );
}

export function roundTo(value: number, fractionDigits: number): number {
  return Number(value.toFixed(fractionDigits));
}
