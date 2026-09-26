import { act, fireEvent, render, waitFor, within } from '@testing-library/react-native';
import { Dimensions, StyleSheet } from 'react-native';

import { DestinationGrid } from './destination-grid';

const originalWindow = Dimensions.get('window');
const items = [
  { key: 'war', label: 'War statistics', imageUrl: 'war.png', onPress: jest.fn() },
  { key: 'items', label: 'Troops and equipment combinations', onPress: jest.fn() },
  { key: 'players', label: 'Players', onPress: jest.fn() },
  { key: 'clans', label: 'Clans', onPress: jest.fn() },
];

afterEach(() => jest.clearAllMocks());
afterAll(() => Dimensions.set({ window: originalWindow }));

async function renderAt(width: number, fontScale = 1) {
  Dimensions.set({ window: { ...originalWindow, width, fontScale } });
  const screen = await render(
    <DestinationGrid groups={[{ key: 'stats', title: 'Statistics', items }]} />,
  );
  const grid = screen.getByTestId('destination-grid-stats');
  const contentWidth = width - 32;
  await act(async () => {
    fireEvent(grid, 'layout', { nativeEvent: { layout: { width: contentWidth } } });
  });
  await waitFor(() => expect(typeof firstTileWidth(grid)).toBe('number'));
  return { screen, grid, contentWidth };
}

function firstTileWidth(grid: ReturnType<Awaited<ReturnType<typeof render>>['getByTestId']>) {
  const first = grid.children[0];
  if (!first || typeof first === 'string') throw new Error('Grid tile was not rendered');
  return StyleSheet.flatten(first.props.style).width;
}

test.each([320, 390])('uses two complete columns on a %ipx phone', async (width) => {
  const { screen, grid, contentWidth } = await renderAt(width);
  expect(grid.children).toHaveLength(items.length);
  const tileWidth = firstTileWidth(grid);
  expect(typeof tileWidth).toBe('number');
  expect(tileWidth).toBeGreaterThan(120);
  expect(tileWidth).toBeLessThan(contentWidth / 2);
  expect(screen.getByRole('button', { name: 'Troops and equipment combinations' })).toBeTruthy();
  expect(screen.getByText('Troops and equipment combinations').props.numberOfLines).toBeUndefined();
});

test('expands to four columns on wide screens', async () => {
  const wide = await renderAt(1024);
  const wideWidth = firstTileWidth(wide.grid);
  expect(wideWidth).toBeLessThan(wide.contentWidth / 3);
});

test('can fill the final row so grouped destinations do not leave an orphan half-card', async () => {
  const screen = await render(
    <DestinationGrid groups={[{ key: 'battle', fillLastRow: true, items: items.slice(0, 3) }]} />,
  );
  const grid = screen.getByTestId('destination-grid-battle');
  for (const child of grid.children) {
    if (typeof child !== 'string') expect(child).toHaveStyle({ flexGrow: 1 });
  }
  expect(within(grid).getAllByRole('button')).toHaveLength(3);
});

test('uses the known container width before the first layout instead of flashing one column', async () => {
  const screen = await render(
    <DestinationGrid initialWidth={358} groups={[{ key: 'stats', items }]} />,
  );
  expect(firstTileWidth(screen.getByTestId('destination-grid-stats'))).toBe(173);
});

test('gives large-font labels a full-width tile instead of truncating them', async () => {
  const largeText = await renderAt(320, 1.8);
  const tileWidth = firstTileWidth(largeText.grid);
  expect(tileWidth).toBe(largeText.contentWidth);
  expect(
    largeText.screen.getByText('Troops and equipment combinations').props.numberOfLines,
  ).toBeUndefined();
});

test('exposes each destination as an accessible button and invokes its callback', async () => {
  const { screen, grid } = await renderAt(390);
  expect(within(grid).getAllByRole('button')).toHaveLength(items.length);
  fireEvent.press(screen.getByRole('button', { name: 'War statistics' }));
  expect(items[0]!.onPress).toHaveBeenCalledTimes(1);
  expect(items[1]!.onPress).not.toHaveBeenCalled();
});

test('keeps navigation compact with unframed artwork beside wrapping labels', async () => {
  const { screen } = await renderAt(390);
  const tile = screen.getByTestId('destination-war');
  const style = StyleSheet.flatten(tile.props.style);
  expect(style.minHeight).toBe(84);
  expect(style.flexDirection).toBe('row');
  expect(style.alignItems).toBe('center');
  const art = screen.getByTestId('destination-art-war');
  expect(StyleSheet.flatten(art.props.style)).toMatchObject({ width: 44, height: 44 });
  // Resolve the percentage SVG viewport inside an unpadded absolute-fill layer,
  // not against the tile's padded content box (which leaves hard bottom/right seams).
  expect(screen.getByTestId('destination-tint-war')).toHaveStyle({
    position: 'absolute',
    top: 0,
    right: 0,
    bottom: 0,
    left: 0,
  });
  // Five rows, two section headings, gaps and navigation fit a standard phone;
  // larger accessibility text can grow naturally and scroll instead of clipping.
  expect(5 * style.minHeight + 3 * 12 + 2 * (28 + 12) + 16 + 48 + 12).toBeLessThan(700);
});
