export type JsonRecord = Record<string, unknown>;
export const isRecord = (value: unknown): value is JsonRecord =>
  typeof value === 'object' && value !== null && !Array.isArray(value);
export const record = (value: unknown): JsonRecord => (isRecord(value) ? value : {});
export const records = (value: unknown): JsonRecord[] =>
  Array.isArray(value) ? value.filter(isRecord) : [];
export const strings = (value: unknown): string[] =>
  Array.isArray(value) ? value.map(String) : [];
export const int = (value: unknown, fallback = 0): number =>
  typeof value === 'number' && Number.isFinite(value) ? Math.trunc(value) : fallback;
export function nullableInt(value: unknown): number | null {
  if (value == null) return null;
  const parsed = typeof value === 'number' ? Math.trunc(value) : Number.parseInt(String(value), 10);
  return Number.isNaN(parsed) ? null : parsed;
}
export const number = (value: unknown, fallback = 0): number =>
  typeof value === 'number' && Number.isFinite(value) ? value : fallback;
export const string = (value: unknown, fallback = ''): string =>
  value == null ? fallback : String(value);
export const nullableString = (value: unknown): string | null =>
  value == null ? null : String(value);
export const bool = (value: unknown, fallback = false): boolean =>
  typeof value === 'boolean' ? value : fallback;
export function date(value: unknown): Date | null {
  if (value == null || String(value).length === 0) return null;
  const parsed = new Date(String(value));
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}
export function apiDate(value: unknown): Date | null {
  const raw = nullableString(value);
  if (!raw) return null;
  const normalized = raw.replace(/^(\d{8}T\d{6})\.000Z$/, '$1Z');
  const match = /^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})Z$/.exec(normalized);
  return date(
    match ? `${match[1]}-${match[2]}-${match[3]}T${match[4]}:${match[5]}:${match[6]}Z` : normalized,
  );
}
export function intMap(value: unknown): Record<string, number> {
  return Object.fromEntries(Object.entries(record(value)).map(([key, item]) => [key, int(item)]));
}
export function nestedIntMap(value: unknown): Record<string, Record<string, number>> {
  return Object.fromEntries(
    Object.entries(record(value)).map(([key, item]) => [key, intMap(item)]),
  );
}
