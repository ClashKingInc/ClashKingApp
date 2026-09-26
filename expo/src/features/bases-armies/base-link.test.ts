import { townHallLevelFromBaseLink } from './base-link';

test.each([
  ['https://link.clashofclans.com/en?action=OpenLayout&id=TH17', 17],
  ['https://link.clashofclans.com/en?action=OpenLayout&id=TH16%3AHV%3AAAAA', 16],
  ['https://link.clashofclans.com/en?action=OpenLayout&id=th15:war', 15],
])('parses the Town Hall from a canonical base link', (link, expected) => {
  expect(townHallLevelFromBaseLink(link)).toBe(expected);
});

test.each([
  'https://link.clashofclans.com/en?action=OpenLayout',
  'https://link.clashofclans.com/en?action=CopyArmy&army=u1x1',
  'not-a-link?id=BH10',
])('returns null when a base link has no Town Hall layout id', (link) => {
  expect(townHallLevelFromBaseLink(link)).toBeNull();
});
