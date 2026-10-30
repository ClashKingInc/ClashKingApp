/** Display colors echo the Town Hall artwork; these are not game-data fields. */
const townHallColors: Readonly<Record<number, string>> = {
  1: '#B88D60',
  2: '#B58550',
  3: '#A67549',
  4: '#97765C',
  5: '#A98058',
  6: '#A76C4A',
  7: '#6E6662',
  8: '#55565B',
  9: '#49464C',
  10: '#B6473B',
  11: '#D8D3D0',
  12: '#497FB1',
  13: '#3B8793',
  14: '#508366',
  15: '#705789',
  16: '#BA9650',
  17: '#344E70',
  18: '#85B8D6',
};

export function townHallDisplayColor(level: number): string {
  return townHallColors[level] ?? '#8A8F98';
}
