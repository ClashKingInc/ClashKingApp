import {
  clanSearchQuerySuffix,
  decodeRecentSearches,
  decodeSearchLeagues,
  decodeSearchLocations,
  emptyClanSearchFilters,
  isClanSearchFiltersEmpty,
  playerTownHallLevels,
} from './models';

describe('search models', () => {
  it('uses current clan query names, omits unset filters, and drops the removed points filter', () => {
    expect(
      clanSearchQuerySuffix({
        ...emptyClanSearchFilters,
        warFrequency: 'always',
        locationId: 32000006,
        minMembers: 20,
        maxMembers: 45,
        minClanPoints: 30000,
        minClanLevel: 10,
      }),
    ).toBe('&warFrequency=always&locationId=32000006&minMembers=20&maxMembers=45&minClanLevel=10');
    expect(clanSearchQuerySuffix(emptyClanSearchFilters)).toBe('');
    expect(isClanSearchFiltersEmpty({ ...emptyClanSearchFilters, minClanPoints: 30000 })).toBe(
      true,
    );
  });

  it('expands the inclusive TH range with Flutter defaults', () => {
    expect(
      playerTownHallLevels({ leagueIds: [], minTownHallLevel: 16, maxTownHallLevel: 18 }),
    ).toEqual([16, 17, 18]);
    expect(
      playerTownHallLevels({ leagueIds: [], minTownHallLevel: null, maxTownHallLevel: null }),
    ).toEqual([]);
    expect(
      playerTownHallLevels({ leagueIds: [], minTownHallLevel: 18, maxTownHallLevel: 17 }),
    ).toEqual([]);
  });

  it('merges recent players and clans, sorts newest first, rejects empty tags, and caps ten', () => {
    const players = Array.from({ length: 11 }, (_, index) => ({
      tag: index === 4 ? '' : `#P${index}`,
      name: `Player ${index}`,
      townHallLevel: 17,
      created_at: new Date(2026, 0, index + 1).toISOString(),
      clan: { name: 'Clan' },
      league: { name: 'Legend League' },
    }));
    const result = decodeRecentSearches({
      players,
      clans: [
        {
          tag: '#C',
          name: 'Clan',
          members: 49,
          badgeUrls: { large: 'badge' },
          created_at: '2026-02-01T00:00:00.000Z',
        },
      ],
    });
    expect(result).toHaveLength(10);
    expect(result[0]).toMatchObject({ type: 'clan', tag: '#C', members: 49, imageUrl: 'badge' });
    expect(result.some((item) => item.tag === '')).toBe(false);
  });

  it('prefers the smallest recent-search clan badge supplied by the API', () => {
    const [clan] = decodeRecentSearches({
      clans: [
        {
          tag: '#C',
          name: 'Clan',
          badgeUrls: { small: 'small', medium: 'medium', large: 'large' },
          created_at: '2026-02-01T00:00:00.000Z',
        },
      ],
    });
    expect(clan?.imageUrl).toBe('small');
  });

  it('keeps only real country locations and valid named league tiers', () => {
    expect(
      decodeSearchLocations({
        items: [
          { id: 2, name: ' United States ', isCountry: true, countryCode: ' us ' },
          { id: 1, name: 'Europe', isCountry: false, countryCode: 'EU' },
          { id: 3, name: 'Invalid', isCountry: true, countryCode: 'USA' },
        ],
      }),
    ).toEqual([{ id: 2, name: 'United States', countryCode: 'US' }]);
    expect(
      decodeSearchLeagues({
        items: [
          { id: 1, name: 'Bronze' },
          { id: 3, name: 'Legend' },
          { id: 0, name: '' },
        ],
      }),
    ).toEqual([
      { id: 3, name: 'Legend' },
      { id: 1, name: 'Bronze' },
    ]);
  });
});
