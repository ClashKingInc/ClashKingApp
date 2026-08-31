export function retainRecentSections<T extends string>(
  retained: readonly T[],
  active: T,
  limit = 2,
): readonly T[] {
  return [active, ...retained.filter((key) => key !== active)].slice(0, Math.max(1, limit));
}
