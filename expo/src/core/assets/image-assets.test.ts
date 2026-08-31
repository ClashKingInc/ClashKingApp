import { gameDataState, replaceGameDataSection } from '../game-data/game-data-state';
import { ImageAssets } from './image-assets';

afterEach(() => {
  replaceGameDataSection(gameDataState.playerLeagueData, {});
  replaceGameDataSection(gameDataState.leagueData, {});
  replaceGameDataSection(gameDataState.warLeagueData, {});
});

describe('ImageAssets', () => {
  it('builds direct player and Legend tier league URLs', () => {
    replaceGameDataSection(gameDataState.playerLeagueData, {
      leagues: { 'Dragon League 29': { name: 'Dragon League 29' } },
    });
    expect(ImageAssets.getLeagueImage('Dragon League 29')).toBe(
      'https://assets.clashk.ing/leagues/league-tier/dragon_league_29.png',
    );
    expect(ImageAssets.getLeagueImage('Unranked')).toBe(
      'https://assets.clashk.ing/leagues/league-tier/unranked.png',
    );
    expect(ImageAssets.getLeagueImage('Legend League I')).toBe(
      'https://assets.clashk.ing/leagues/league-tier/legend_league_1.png',
    );
    expect(ImageAssets.getLeagueImage('Legend III')).toBe(
      'https://assets.clashk.ing/leagues/league-tier/legend_league_3.png',
    );
  });

  it('uses CWL assets and never substitutes player-league icons', () => {
    replaceGameDataSection(gameDataState.warLeagueData, {
      leagues: {
        'Crystal League I': {
          name: 'Crystal League I',
          TID: { name: 'TID_LEAGUE_CRYSTAL1' },
        },
        'Titan League II': {
          name: 'Titan League II',
          TID: { name: 'TID_LEAGUE_HERO2' },
        },
      },
    });
    expect(ImageAssets.getWarLeagueImage('Crystal League I')).toBe(
      'https://assets.clashk.ing/leagues/cwl/crystal_league_1.png',
    );
    expect(ImageAssets.getWarLeagueImage('Titan League II')).toBe(
      'https://assets.clashk.ing/leagues/cwl/titan_league_2.png',
    );
    replaceGameDataSection(gameDataState.playerLeagueData, {
      leagues: { 'Goblin League I': { url: 'https://wrong.example/icon.png' } },
    });
    expect(ImageAssets.getWarLeagueImage('Goblin League I')).toBe(ImageAssets.defaultImage);
  });

  it('matches exact direct assets, slugs, badge tags, and invalid fallbacks', () => {
    expect(ImageAssets.getSpellImage('Lightning Spell')).toBe(
      'https://assets.clashk.ing/spells/lightning_spell.webp',
    );
    expect(ImageAssets.getTroopImage('P.E.K.K.A')).toBe(
      'https://assets.clashk.ing/troops/pekka/icon.webp',
    );
    expect(ImageAssets.getHomeVillageBuildingImage('Town Hall', 18)).toBe(
      'https://assets.clashk.ing/buildings/home-village/town_hall/level_18.webp',
    );
    expect(ImageAssets.getHeroImage('')).toBe(ImageAssets.defaultImage);
    expect(ImageAssets.getHomeVillageBuildingImage('Town Hall', 0)).toBe(ImageAssets.defaultImage);
    expect(ImageAssets.clanBadgeForTag(' #AbC ')).toBe('https://badges.clashk.ing/ABC');
  });
});
