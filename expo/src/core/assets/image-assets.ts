import { gameDataState, isRecord, type JsonRecord } from '../game-data/game-data-state';

export class ImageAssets {
  static readonly baseUrl = 'https://assets.clashk.ing';
  static readonly clanBadgeBaseUrl = 'https://badges.clashk.ing';
  static readonly defaultImage = `${ImageAssets.baseUrl}/icons/Icon_Unknown_Troop.png`;
  static readonly thinkingBuilder = `${ImageAssets.baseUrl}/stickers/thinking_bk.webp`;
  static readonly goldPass = `${ImageAssets.baseUrl}/icons/Icon_HV_Gold_Pass.png`;

  static readonly darkModeLogo = `${ImageAssets.baseUrl}/logos/crown-arrow-dark-bg/ClashKing-1.png`;
  static readonly lightModeLogo = `${ImageAssets.baseUrl}/logos/crown-arrow-white-bg/ClashKing-2.png`;
  static readonly fallbackLogo = ImageAssets.darkModeLogo;
  static readonly darkModeTextLogo = `${ImageAssets.baseUrl}/logos/crown-arrow-dark-bg/CK-text-dark-bg.png`;
  static readonly lightModeTextLogo = `${ImageAssets.baseUrl}/logos/crown-arrow-white-bg/CK-text-white-bg.png`;

  static townHall(level: number): string {
    return ImageAssets.getHomeVillageBuildingImage('Town Hall', level);
  }

  static builderHall(level: number): string {
    return ImageAssets.getBuilderBaseBuildingImage('Builder Hall', level);
  }

  static getLeagueImage(leagueName: string): string {
    const normalized = leagueName.trim().toLowerCase();
    if (normalized === 'unranked') {
      return buildAssetUrl(['leagues', 'league-tier', 'unranked.png']);
    }
    const legendTierFile = legendLeagueTierFile(leagueName);
    if (legendTierFile) {
      return buildAssetUrl(['leagues', 'league-tier', legendTierFile]);
    }
    const playerLeagues = recordAt(gameDataState.playerLeagueData, 'leagues');
    if (playerLeagues && Object.hasOwn(playerLeagues, leagueName)) {
      return buildAssetUrl(['leagues', 'league-tier', `${leagueFileSlug(leagueName)}.png`]);
    }
    const leagues = recordAt(gameDataState.leagueData, 'leagues');
    const league = leagues?.[leagueName];
    if (isRecord(league) && typeof league.url === 'string') return league.url;
    if (typeof league === 'string') return league;
    return ImageAssets.defaultImage;
  }

  static getWarLeagueImage(leagueName: string): string {
    const warLeague = findLeague(gameDataState.warLeagueData, leagueName);
    const warLeagueUrl = cwlLeagueIconUrl(warLeague, leagueName);
    if (warLeagueUrl) return warLeagueUrl;
    const league = findLeague(gameDataState.leagueData, leagueName);
    return cwlLeagueIconUrl(league, leagueName) ?? ImageAssets.defaultImage;
  }

  static getCapitalLeagueImage(leagueName: string): string {
    const normalized = leagueName.trim().toLowerCase();
    if (!normalized || normalized === 'unranked') return ImageAssets.capitalTrophy;
    const file = numberedLeagueFileName(leagueName);
    return file
      ? buildAssetUrl(['leagues', 'capital-leagues', file])
      : ImageAssets.getLeagueImage(leagueName);
  }

  static getBuilderBaseLeagueImage(league: unknown): string {
    if (isRecord(league)) {
      if (typeof league.name === 'string')
        return ImageAssets.getBuilderBaseLeagueImage(league.name);
      const iconUrls = league.iconUrls;
      if (isRecord(iconUrls) && typeof iconUrls.medium === 'string') return iconUrls.medium;
    }
    const name = league === undefined || league === null ? '' : String(league).trim();
    return name
      ? buildAssetUrl(['leagues', 'builder-base', `${leagueFileSlug(name)}.png`])
      : ImageAssets.builderBaseStar;
  }

  static readonly warPreferenceIn = `${ImageAssets.baseUrl}/icons/Icon_HV_In.png`;
  static readonly warPreferenceOut = `${ImageAssets.baseUrl}/icons/Icon_HV_Out.png`;
  static readonly attackStar = `${ImageAssets.baseUrl}/icons/Icon_HV_Attack_Star.png`;
  static readonly emptyStar = `${ImageAssets.baseUrl}/icons/Icon_BB_Empty_Star.png`;
  static readonly war = `${ImageAssets.baseUrl}/icons/Icon_DC_War.png`;
  static readonly warClan = `${ImageAssets.baseUrl}/icons/Icon_HV_Clan_War.png`;
  static readonly builderBaseStar = `${ImageAssets.baseUrl}/icons/Icon_BB_Star.png`;
  static readonly builderBaseTrophy = `${ImageAssets.baseUrl}/bot/icons/versus_trophy.png`;
  static readonly sword = `${ImageAssets.baseUrl}/icons/Icon_HV_Sword.png`;
  static readonly swordGif = `${ImageAssets.baseUrl}/bot/icons/animated_clash_swords.gif`;
  static readonly brokenSword = `${ImageAssets.baseUrl}/bot/icons/broken_sword.png`;
  static readonly shield = `${ImageAssets.baseUrl}/icons/Icon_HV_Shield.png`;
  static readonly shieldWithArrow = `${ImageAssets.baseUrl}/icons/Icon_HV_Shield_Arrow.png`;
  static readonly xp = `${ImageAssets.baseUrl}/icons/Icon_HV_XP.png`;
  static readonly trophies = `${ImageAssets.baseUrl}/icons/Icon_HV_Trophy.png`;
  static readonly bestTrophies = `${ImageAssets.baseUrl}/icons/Icon_HV_Trophy_Best.png`;
  static readonly attacks = `${ImageAssets.baseUrl}/icons/Icon_HV_Attack.png`;
  static readonly attacksNoShield = `${ImageAssets.baseUrl}/icons/Icon_HV_Attacks_No_Shield.png`;
  static readonly hitrate = `${ImageAssets.baseUrl}/icons/Icon_DC_Hitrate.png`;
  static readonly podium = `${ImageAssets.baseUrl}/icons/Icon_HV_Podium.png`;
  static readonly clanCastle = `${ImageAssets.baseUrl}/buildings/home-village/clan_castle/level_1.webp`;
  static readonly cwlSwordsNoBorder = `${ImageAssets.baseUrl}/icons/Icon_DC_CWL_No_Border.png`;
  static readonly activeDailyLabel = `${ImageAssets.baseUrl}/player_labels/active_daily.webp`;

  static readonly legendStartFlag = `${ImageAssets.baseUrl}/icons/Icon_HV_Start_Flag.png`;
  static readonly legendBlazon = `${ImageAssets.baseUrl}/icons/Icon_HV_League_Legend_3.png`;
  static readonly legendBlazonNoPadding = `${ImageAssets.baseUrl}/icons/Icon_HV_League_Legend_3_No_Padding.png`;
  static readonly legendBlazonBorders = `${ImageAssets.baseUrl}/icons/Icon_HV_League_Legend_3_Border.png`;
  static readonly legendBlazonBordersNoPadding = `${ImageAssets.baseUrl}/icons/Icon_HV_League_Legend_3_Border_No_Padding.png`;
  static readonly legendLeagueOne = `${ImageAssets.baseUrl}/leagues/league-tier/legend_league_1.png`;
  static readonly legendLeagueTwo = `${ImageAssets.baseUrl}/leagues/league-tier/legend_league_2.png`;
  static readonly legendLeagueThree = `${ImageAssets.baseUrl}/leagues/league-tier/legend_league_3.png`;

  static flag(countryCode: string): string {
    return `${ImageAssets.baseUrl}/country-flags/${countryCode.toLowerCase()}.png`;
  }

  static readonly planet = `${ImageAssets.baseUrl}/icons/Icon_HV_Planet.png`;

  static clanBadgeForTag(tag: string): string {
    const trimmed = tag.trim();
    const normalized = (trimmed.startsWith('#') ? trimmed.slice(1) : trimmed).toUpperCase();
    return normalized ? `${ImageAssets.clanBadgeBaseUrl}/${encodeURIComponent(normalized)}` : '';
  }

  static clanBadge(badgeUrl: string): string {
    return badgeUrl || `${ImageAssets.baseUrl}/icons/default_clan_badge.png`;
  }

  static getClanBadgeImage(url: string): string {
    return url || ImageAssets.defaultImage;
  }

  static readonly clanGamesMedals = `${ImageAssets.baseUrl}/icons/Icon_HV_Clan_Games_Medal.png`;
  static readonly raidMedal = `${ImageAssets.baseUrl}/bot/icons/raid_medal.png`;
  static readonly iconTick = `${ImageAssets.baseUrl}/icons/Icon_DC_Tick.png`;
  static readonly iconCross = `${ImageAssets.baseUrl}/icons/Icon_DC_Cross.png`;
  static readonly iconClock = `${ImageAssets.baseUrl}/bot/icons/clock.png`;
  static readonly iconBuilderPotion = `${ImageAssets.baseUrl}/icons/Magic_Item_Builder_Potion.png`;
  static readonly builderPotion = `${ImageAssets.baseUrl}/magic_items/builder_potion.webp`;
  static readonly hammerOfBuilding = `${ImageAssets.baseUrl}/magic_items/hammer_of_building.webp`;
  static readonly lootCart = `${ImageAssets.baseUrl}/obstacles/home-village/loot_cart.webp`;
  static readonly gold = `${ImageAssets.baseUrl}/resources/gold.webp`;
  static readonly elixir = `${ImageAssets.baseUrl}/resources/elixir.webp`;
  static readonly darkElixir = `${ImageAssets.baseUrl}/resources/dark_elixir.webp`;
  static readonly researchPotion = `${ImageAssets.baseUrl}/magic_items/research_potion.webp`;
  static readonly petPotion = `${ImageAssets.baseUrl}/magic_items/pet_potion.webp`;
  static readonly clockTowerPotion = `${ImageAssets.baseUrl}/magic_items/clock_tower_potion.webp`;
  static readonly iconGoldPass = `${ImageAssets.baseUrl}/icons/Icon_HV_Gold_Pass.png`;

  static readonly capitalGold = `${ImageAssets.baseUrl}/icons/Icon_CC_Resource_Capital_Gold_small.png`;
  static readonly capitalTrophy = `${ImageAssets.baseUrl}/icons/Icon_CC_Resource_Capital_Trophy.png`;
  static readonly raidAttacks = `${ImageAssets.baseUrl}/icons/Icon_HV_Raid_Attack.png`;
  static readonly capitalThickSwords = `${ImageAssets.baseUrl}/bot/icons/thick_capital_sword.png`;
  static readonly capitalVacantHouse = `${ImageAssets.baseUrl}/capital-base/clan-houses/Building_CC_Vacant_House.png`;
  static readonly capitalClanHouse = `${ImageAssets.baseUrl}/capital-base/clan-houses/Building_CC_Clan_House.png`;

  static capitalHall(level: number): string {
    return `${ImageAssets.baseUrl}/capital-base/capital-hall-pics/Building_CC_Capital_Hall_level_${level}.png`;
  }

  static readonly defaultProfile = `${ImageAssets.baseUrl}/icons/default_profile.png`;
  static readonly homeBaseBackground = `${ImageAssets.baseUrl}/landscape/home-landscape.png`;
  static readonly builderBaseBackground = `${ImageAssets.baseUrl}/landscape/builder-landscape.png`;
  static readonly legendPageBackground = `${ImageAssets.baseUrl}/landscape/legend-landscape.png`;
  static readonly clanPageBackground = `${ImageAssets.baseUrl}/landscape/clan-landscape.png`;
  static readonly cwlPageBackground = `${ImageAssets.baseUrl}/landscape/cwl-landscape.png`;
  static readonly warPageBackground = `${ImageAssets.baseUrl}/landscape/war-landscape.jpg`;
  static readonly clanCapitalPageBackground = `${ImageAssets.baseUrl}/landscape/clan-capital-landscape.png`;
  static readonly playerWarStatsPageBackground = `${ImageAssets.baseUrl}/landscape/war-stats.png`;
  static readonly playerAchievementPageBackground = `${ImageAssets.baseUrl}/landscape/achievement-landscape.png`;

  static getHeroImage(name: string): string {
    return iconAsset(['heroes'], name);
  }

  static getBuilderBaseHeroImage(name: string): string {
    return ImageAssets.getHeroImage(name);
  }

  static getTroopImage(name: string): string {
    return iconAsset(['troops'], name);
  }

  static getSuperTroopImage(name: string): string {
    return ImageAssets.getTroopImage(name);
  }

  static getBuilderBaseTroopImage(name: string): string {
    return ImageAssets.getTroopImage(name);
  }

  static getSiegeMachineImage(name: string): string {
    return ImageAssets.getTroopImage(name);
  }

  static getSpellImage(name: string): string {
    return namedAsset(['spells'], name);
  }

  static getPetImage(name: string): string {
    return iconAsset(['pets'], name);
  }

  static getGuardianImage(name: string): string {
    return iconAsset(['guardians'], name);
  }

  static getGearImage(name: string): string {
    return namedAsset(['equipment'], name);
  }

  static getHelperImage(name: string): string {
    return namedAsset(['helpers'], name);
  }

  static getHomeVillageBuildingImage(name: string, level: number): string {
    return leveledAsset(['buildings', 'home-village'], name, level);
  }

  static getBuilderBaseBuildingImage(name: string, level: number): string {
    return leveledAsset(['buildings', 'builder-base'], name, level);
  }

  static getSeasonalDefenseImage(name: string, level: number): string {
    return leveledAsset(['buildings', 'seasonal-defense'], name, level);
  }

  static getHomeVillageTrapImage(name: string, level: number): string {
    return leveledAsset(['traps', 'home-village'], name, level);
  }

  static getBuilderBaseTrapImage(name: string, level: number): string {
    return leveledAsset(['traps', 'builder-base'], name, level);
  }

  static getHomeVillageDecorationImage(name: string): string {
    return namedAsset(['decorations', 'home-village'], name);
  }

  static getBuilderBaseDecorationImage(name: string): string {
    return namedAsset(['decorations', 'builder-base'], name);
  }

  static readonly villager = `${ImageAssets.baseUrl}/stickers/villager_clapping.webp`;
  static readonly goblin = `${ImageAssets.baseUrl}/stickers/crying_goblin.webp`;
  static readonly builderWave = `${ImageAssets.baseUrl}/stickers/builder_wave.webp`;
  static readonly thinkingBarbarianKing = `${ImageAssets.baseUrl}/stickers/thinking_bk.webp`;
  static readonly sleepingApprenticeBuilder = `${ImageAssets.baseUrl}/stickers/builder_wave.webp`;
}

function recordAt(source: JsonRecord, key: string): JsonRecord | undefined {
  const value = source[key];
  return isRecord(value) ? value : undefined;
}

function findLeague(source: JsonRecord, name: string): unknown {
  return recordAt(source, 'leagues')?.[name];
}

function legendLeagueTierFile(name: string): string | undefined {
  const normalized = name.trim().toLowerCase();
  if (normalized === 'legend' || normalized === 'legend league') return 'legend_league.png';
  if (!normalized.startsWith('legend league ') && !normalized.startsWith('legend ')) {
    return undefined;
  }
  const tier = normalized.replace('legend league ', '').replace('legend ', '').trim();
  const tierNumber = leagueTierNumber(tier);
  return tierNumber >= 1 && tierNumber <= 3 ? `legend_league_${tierNumber}.png` : undefined;
}

function leagueTierNumber(value: string): number {
  const roman: Readonly<Record<string, number>> = { i: 1, ii: 2, iii: 3, iv: 4, v: 5 };
  const parsed = Number.parseInt(value, 10);
  return roman[value] ?? (Number.isNaN(parsed) ? value.length : parsed);
}

function cwlLeagueIconUrl(league: unknown, leagueName: string): string | undefined {
  if (typeof league === 'string') return league;
  const tidRecord = isRecord(league) && isRecord(league.TID) ? league.TID : undefined;
  const tid = tidRecord?.name === undefined ? undefined : String(tidRecord.name);
  const resolvedName =
    isRecord(league) && typeof league.name === 'string' ? league.name : leagueName.trim();
  const fileName = cwlLeagueFileName(tid) ?? numberedLeagueFileName(resolvedName);
  if (fileName) return buildAssetUrl(['leagues', 'cwl', fileName]);
  return isRecord(league) && typeof league.url === 'string' ? league.url : undefined;
}

function assetSlug(name: string): string {
  return name.trim().toLowerCase().replaceAll(' ', '_').replaceAll('.', '');
}

function leagueFileSlug(name: string): string {
  const normalized = name.trim().toLowerCase();
  const match = /\s+(i|ii|iii|iv|v)$/.exec(normalized);
  return match
    ? `${assetSlug(normalized.slice(0, match.index))}_${leagueTierNumber(match[1]!)}`
    : assetSlug(name);
}

function numberedLeagueFileName(name: string): string | undefined {
  const slug = leagueFileSlug(name);
  if (!slug) return undefined;
  if (slug === 'unranked') return 'unranked.png';
  if (slug === 'legend_league') return 'legend_league.png';
  const match = /^([a-z]+)_league(?:_\d+)?$/.exec(slug);
  if (!match) return undefined;
  const known = new Set(['bronze', 'silver', 'gold', 'crystal', 'master', 'champion', 'titan']);
  return known.has(match[1]!) ? `${slug}.png` : undefined;
}

function cwlLeagueFileName(tid?: string): string | undefined {
  if (!tid) return undefined;
  if (tid === 'TID_LEAGUE_LEGENDARY') return 'legend_league.png';
  if (tid === 'TID_LEAGUE_UNRANKED') return 'unranked.png';
  const match = /^TID_LEAGUE_([A-Z]+)(\d)$/.exec(tid);
  if (!match) return undefined;
  const rawFamily = match[1]!.toLowerCase();
  const family = rawFamily === 'hero' || rawFamily === 'titanium' ? 'titan' : rawFamily;
  return `${family}_league_${match[2]}.png`;
}

function iconAsset(prefix: readonly string[], name: string): string {
  const slug = assetSlug(name);
  return slug ? buildAssetUrl([...prefix, slug, 'icon.webp']) : ImageAssets.defaultImage;
}

function namedAsset(prefix: readonly string[], name: string): string {
  const slug = assetSlug(name);
  return slug ? buildAssetUrl([...prefix, `${slug}.webp`]) : ImageAssets.defaultImage;
}

function leveledAsset(prefix: readonly string[], name: string, level: number): string {
  const slug = assetSlug(name);
  return slug && level > 0
    ? buildAssetUrl([...prefix, slug, `level_${level}.webp`])
    : ImageAssets.defaultImage;
}

function buildAssetUrl(segments: readonly string[]): string {
  const encoded = segments.map(encodeURIComponent).join('/').replaceAll('%2F', '/');
  return `${ImageAssets.baseUrl}/${encoded}`;
}
