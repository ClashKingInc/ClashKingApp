import { townHallDisplayColor } from './town-hall-colors';

test('Town Hall colors are stable per level and distinct for recent levels', () => {
  expect(townHallDisplayColor(10)).toBe('#B6473B');
  expect(townHallDisplayColor(18)).toBe('#85B8D6');
  expect(townHallDisplayColor(17)).not.toBe(townHallDisplayColor(18));
  expect(townHallDisplayColor(99)).toBe('#8A8F98');
});
