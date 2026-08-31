import { ckSpacing } from './tokens';

export function centeredContentPadding(
  availableWidth: number,
  maxContentWidth: number,
  minimum = 16,
): number {
  if (!Number.isFinite(availableWidth) || availableWidth <= 0) return minimum;
  return Math.max(minimum, (availableWidth - maxContentWidth) / 2);
}

export function resolveGridColumns({
  width,
  minItemWidth,
  minColumns = 1,
  maxColumns = 4,
  gap = ckSpacing.md,
}: {
  width: number;
  minItemWidth: number;
  minColumns?: number;
  maxColumns?: number;
  gap?: number;
}): number {
  if (!Number.isFinite(width) || width <= 0 || minItemWidth <= 0) return minColumns;
  const columns = Math.floor((width + gap) / (minItemWidth + gap));
  return Math.max(minColumns, Math.min(maxColumns, columns));
}
