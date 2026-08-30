import { BookmarkedClan, BookmarkedPlayer } from '../../../core/bookmarks';
import { Player } from '../../player/models/player';
import { extraWarClanTags, hiddenWarPlayerTags } from './war-root-state';

const player = (tag: string, clanTag: string) => {
  const value = Player.empty();
  value.tag = tag;
  value.clanTag = clanTag;
  return value;
};

describe('WarCwlRoot state adapters', () => {
  const preferences = {
    isShownInWarTab: (tag: string) => tag !== '#HIDDEN',
  };

  test('marks linked and bookmarked opt-outs as hidden', () => {
    expect(
      hiddenWarPlayerTags(
        [player('#HIDDEN', '#LINKED')],
        [new BookmarkedPlayer('#VISIBLE', '', 0, '', '', '', 0, '', '')],
        preferences as never,
      ),
    ).toEqual(new Set(['#HIDDEN']));
  });

  test('loads only extra visible bookmarked clan wars', () => {
    expect(
      extraWarClanTags(
        [player('#OWNED', '#LINKED'), player('#BOOK', '#HYDRATED')],
        ['#OWNED'],
        [new BookmarkedPlayer('#BOOK', '', 0, '', '#STALE', '', 0, '', '')],
        [new BookmarkedClan('#LINKED', '', '', 0, 0), new BookmarkedClan('#OTHER', '', '', 0, 0)],
        preferences as never,
      ),
    ).toEqual(['#OTHER', '#HYDRATED']);
  });
});
