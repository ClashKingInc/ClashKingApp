import { centeredContentPadding, resolveGridColumns } from './layout';

describe('responsive layout contracts', () => {
  it('centers against the actual content pane instead of the full desktop viewport', () => {
    expect(centeredContentPadding(1736, 1680)).toBe(28);
    expect(centeredContentPadding(936, 1200)).toBe(16);
    expect(centeredContentPadding(0, 1200, 12)).toBe(12);
  });

  it('keeps grid columns inside their configured bounds', () => {
    expect(resolveGridColumns({ width: 1000, minItemWidth: 300, maxColumns: 2 })).toBe(2);
    expect(resolveGridColumns({ width: 0, minItemWidth: 300, minColumns: 1 })).toBe(1);
  });
});
