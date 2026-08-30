export type JsonRecord = Record<string, unknown>;
export const isRecord = (value: unknown): value is JsonRecord =>
  typeof value === 'object' && value !== null && !Array.isArray(value);
export const record = (value: unknown): JsonRecord => (isRecord(value) ? value : {});
export const records = (value: unknown): JsonRecord[] =>
  Array.isArray(value) ? value.filter(isRecord) : [];
export const string = (value: unknown, fallback = ''): string =>
  value == null ? fallback : String(value);
export const int = (value: unknown, fallback = 0): number =>
  typeof value === 'number' && Number.isFinite(value) ? Math.trunc(value) : fallback;
export const nullableInt = (value: unknown): number | null =>
  typeof value === 'number' && Number.isFinite(value) ? Math.trunc(value) : null;
export const number = (value: unknown, fallback = 0): number =>
  typeof value === 'number' && Number.isFinite(value) ? value : fallback;
export const nullableNumber = (value: unknown): number | null =>
  typeof value === 'number' && Number.isFinite(value) ? value : null;
export const stringList = (value: unknown): string[] =>
  Array.isArray(value) ? value.map(String) : [];
export const intMap = (value: unknown): Record<string, number> =>
  Object.fromEntries(Object.entries(record(value)).map(([key, item]) => [key, int(item)]));

export function apiDate(value: unknown): Date | null {
  if (typeof value !== 'string' || value.length === 0) return null;
  const match = /^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})(?:\.\d+)?Z$/.exec(value);
  const parsed = new Date(
    match ? `${match[1]}-${match[2]}-${match[3]}T${match[4]}:${match[5]}:${match[6]}Z` : value,
  );
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

export function normalizeWarTag(tag: string | null | undefined): string | null {
  const value = tag?.trim().toUpperCase() ?? '';
  if (!value) return null;
  return value.startsWith('#') ? value : `#${value}`;
}
