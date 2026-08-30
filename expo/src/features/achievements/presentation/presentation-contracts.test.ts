import { ACHIEVEMENT_COPY_KEYS, achievementColumnCount } from './contracts';

test('matches Flutter responsive collection breakpoints', () => {
  expect(achievementColumnCount(519)).toBe(2);
  expect(achievementColumnCount(520)).toBe(3);
  expect(achievementColumnCount(759)).toBe(3);
  expect(achievementColumnCount(760)).toBe(4);
  expect(achievementColumnCount(1120)).toBe(4);
});

test('maps every API identifier to the same Flutter localization keys', () => {
  expect(ACHIEVEMENT_COPY_KEYS).toEqual({
    townhall_18: {
      name: 'achievementTownhall18Name',
      description: 'achievementTownhall18Requirement',
    },
    war_warrior: {
      name: 'achievementWarWarriorName',
      description: 'achievementWarWarriorRequirement',
    },
    mr_legend: {
      name: 'achievementMrLegendName',
      description: 'achievementMrLegendDescription',
    },
    defense_doesnt_matter: {
      name: 'achievementDefenseDoesntMatterName',
      description: 'achievementDefenseDoesntMatterDescription',
    },
  });
});
