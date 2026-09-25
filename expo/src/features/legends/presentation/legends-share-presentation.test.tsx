import { render } from '@testing-library/react-native';

import { I18nProvider } from '../../../i18n';
import { PlayerLegendLeagueData } from '../../player/models';
import {
  PlayerBattlelogArmyCatalog,
  PlayerBattlelogArmyItem,
} from '../../player/models/player-battlelog';
import { popularLegendItems } from './legend-army';
import { LegendsShareModal } from './legends-share';

afterEach(() => jest.restoreAllMocks());

test('keeps season favorites image-only while retaining accessible item labels', async () => {
  jest
    .spyOn(PlayerBattlelogArmyCatalog, 'resolve')
    .mockImplementation(
      (code) =>
        new PlayerBattlelogArmyItem(
          code,
          `Name ${code}`,
          `https://assets.clashk.ing/test/${code}.png`,
          code === 'u_2' ? 30 : 1,
          false,
        ),
    );
  const shareCode = 'u20x1-1x2-1x4000051s2x1';
  const favorites = popularLegendItems([shareCode]);
  const data = new PlayerLegendLeagueData(
    '#P1',
    'Player',
    18,
    5600,
    5900,
    null,
    [],
    '2026-09-21',
    null,
    null,
    [],
    [shareCode],
    '2026-08-31T05:00:00.000Z',
    '2026-09-28T05:00:00.000Z',
    {
      attacks: 24,
      defenses: 21,
      attackTriples: 8,
      defenseTriples: 3,
      averageOffense: 26.4,
      averageDefense: -18.7,
    },
  );

  const view = await render(
    <I18nProvider locale="en">
      <LegendsShareModal data={data} visible onClose={jest.fn()} />
    </I18nProvider>,
  );

  expect(favorites).toHaveLength(3);
  for (const { category, item } of favorites) {
    const localizedCategory =
      category === 'Troop' ? 'Troop' : category === 'Spell' ? 'Spell' : 'Siege Machines';
    expect(view.getByLabelText(`${localizedCategory}: ${item.name}`)).toBeTruthy();
    expect(view.queryByText(item.name)).toBeNull();
    expect(view.queryByText(localizedCategory)).toBeNull();
  }
  expect(view.getByText('Avg. Offense')).toBeTruthy();
  expect(view.getByText('Avg. Defense')).toBeTruthy();
});
