import 'package:clashkingapp/core/services/game_data_service.dart';

class ImageAssets {
  static const String baseUrl = "https://assets.clashk.ing";
  static const String defaultImage = "$baseUrl/icons/Icon_Unknown_Troop.png";

  // 👑 Logos
  static const String darkModeLogo =
      "$baseUrl/logos/crown-arrow-dark-bg/ClashKing-1.png";
  static const String lightModeLogo =
      "$baseUrl/logos/crown-arrow-white-bg/ClashKing-2.png";
  static const String darkModeTextLogo =
      "$baseUrl/logos/crown-arrow-dark-bg/CK-text-dark-bg.png";
  static const String lightModeTextLogo =
      "$baseUrl/logos/crown-arrow-white-bg/CK-text-white-bg.png";

  // 🏰 Town Hall & Builder Hall
  static String townHall(int level) =>
      getHomeVillageBuildingImage('Town Hall', level);
  static String builderHall(int level) =>
      getBuilderBaseBuildingImage('Builder Hall', level);

  // 🏆 League Icons
  static String getLeagueImage(String leagueName) {
    final normalized = leagueName.trim().toLowerCase();
    if (normalized == 'unranked') {
      return _buildAssetUrl(['leagues', 'league-tier', 'unranked.png']);
    }

    final legendTierFile = _legendLeagueTierFile(leagueName);
    if (legendTierFile != null) {
      return _buildAssetUrl(['leagues', 'league-tier', legendTierFile]);
    }

    final rawPlayerLeagues = GameDataService.playerLeagueData["leagues"];
    if (rawPlayerLeagues is Map && rawPlayerLeagues.containsKey(leagueName)) {
      return _buildAssetUrl([
        'leagues',
        'league-tier',
        '${_leagueFileSlug(leagueName)}.png',
      ]);
    }

    final rawLeagues = GameDataService.leagueData["leagues"];
    if (rawLeagues is Map) {
      final league = rawLeagues[leagueName];
      if (league is Map && league["url"] is String) {
        return league["url"] as String;
      }
      if (league is String) {
        return league;
      }
    }
    return defaultImage;
  }

  static String? _legendLeagueTierFile(String leagueName) {
    final normalized = leagueName.trim().toLowerCase();
    if (normalized == 'legend' || normalized == 'legend league') {
      return 'legend_league.png';
    }
    if (!normalized.startsWith('legend league ') &&
        !normalized.startsWith('legend ')) {
      return null;
    }

    final tier = normalized
        .replaceFirst('legend league ', '')
        .replaceFirst('legend ', '')
        .trim();
    final tierNumber = _leagueTierNumber(tier);
    if (tierNumber < 1 || tierNumber > 3) return null;
    return 'legend_league_$tierNumber.webp';
  }

  static String getWarLeagueImage(String leagueName) {
    final warLeague = _findLeague(GameDataService.warLeagueData, leagueName);
    final warLeagueUrl = _cwlLeagueIconUrl(warLeague, leagueName);
    if (warLeagueUrl != null) return warLeagueUrl;

    final league = _findLeague(GameDataService.leagueData, leagueName);
    final leagueUrl = _cwlLeagueIconUrl(league, leagueName);
    if (leagueUrl != null) return leagueUrl;

    return defaultImage;
  }

  static String getCapitalLeagueImage(String leagueName) {
    final normalized = leagueName.trim().toLowerCase();
    if (normalized.isEmpty || normalized == 'unranked') {
      return capitalTrophy;
    }

    final capitalLeagueFile = _numberedLeagueFileName(leagueName);
    if (capitalLeagueFile != null) {
      return _buildAssetUrl(['leagues', 'capital-leagues', capitalLeagueFile]);
    }

    return getLeagueImage(leagueName);
  }

  static String getBuilderBaseLeagueImage(dynamic league) {
    if (league is Map) {
      if (league['name'] is String) {
        return getBuilderBaseLeagueImage(league['name']);
      }
      final iconUrls = league['iconUrls'];
      if (iconUrls is Map && iconUrls['medium'] is String) {
        return iconUrls['medium'] as String;
      }
    }

    final name = league?.toString().trim() ?? '';
    if (name.isEmpty) return builderBaseStar;
    return _buildAssetUrl([
      'leagues',
      'builder-base',
      '${_leagueFileSlug(name)}.png',
    ]);
  }

  static int _leagueTierNumber(String value) {
    return switch (value) {
      'i' => 1,
      'ii' => 2,
      'iii' => 3,
      'iv' => 4,
      'v' => 5,
      _ => int.tryParse(value) ?? value.length,
    };
  }

  static dynamic _findLeague(Map<String, dynamic> source, String leagueName) {
    final leagues = source['leagues'];
    if (leagues is! Map) return null;
    return leagues[leagueName];
  }

  static String? _cwlLeagueIconUrl(dynamic league, String leagueName) {
    if (league is String) return league;

    final tid = league is Map && league['TID'] is Map
        ? (league['TID'] as Map)['name']?.toString()
        : null;
    final resolvedName = league is Map && league['name'] is String
        ? league['name'] as String
        : leagueName.trim();
    final fileName =
        _cwlLeagueFileName(tid) ?? _numberedLeagueFileName(resolvedName);
    if (fileName != null) {
      return _buildAssetUrl(['leagues', 'cwl', fileName]);
    }
    if (league is Map && league['url'] is String) {
      return league['url'] as String;
    }
    return null;
  }

  // 🏆 Wars & CWL & Trophies
  static const String warPreferenceIn = "$baseUrl/icons/Icon_HV_In.png";
  static const String warPreferenceOut = "$baseUrl/icons/Icon_HV_Out.png";
  static const String attackStar = "$baseUrl/icons/Icon_HV_Attack_Star.png";
  static const String war = "$baseUrl/icons/Icon_DC_War.png";
  static const String warClan = "$baseUrl/icons/Icon_HV_Clan_War.png";
  static const String builderBaseStar = "$baseUrl/icons/Icon_BB_Star.png";
  static const String builderBaseTrophy =
      "$baseUrl/bot/icons/versus_trophy.png";
  static const String sword = "$baseUrl/icons/Icon_HV_Sword.png";
  static const String swordGif = "$baseUrl/bot/icons/animated_clash_swords.gif";
  static const String brokenSword = "$baseUrl/bot/icons/broken_sword.png";
  static const String shield = "$baseUrl/icons/Icon_HV_Shield.png";
  static const String shieldWithArrow =
      "$baseUrl/icons/Icon_HV_Shield_Arrow.png";
  static const String xp = "$baseUrl/icons/Icon_HV_XP.png";
  static const String trophies = "$baseUrl/icons/Icon_HV_Trophy.png";
  static const String bestTrophies = "$baseUrl/icons/Icon_HV_Trophy_Best.png";
  static const String attacks = "$baseUrl/icons/Icon_HV_Attack.png";
  static const String hitrate = "$baseUrl/icons/Icon_DC_Hitrate.png";
  static const String podium = "$baseUrl/icons/Icon_HV_Podium.png";
  static const String clanCastle =
      "$baseUrl/buildings/home-village/clan_castle/level_1.webp";
  static const String cwlSwordsNoBorder =
      "$baseUrl/icons/Icon_DC_CWL_No_Border.png";

  // 🎖️ Legend League
  static const String legendStartFlag = "$baseUrl/icons/Icon_HV_Start_Flag.png";
  static const String legendBlazon =
      "$baseUrl/icons/Icon_HV_League_Legend_3.png";
  static const String legendBlazonNoPadding =
      "$baseUrl/icons/Icon_HV_League_Legend_3_No_Padding.png";
  static const String legendBlazonBorders =
      "$baseUrl/icons/Icon_HV_League_Legend_3_Border.png";
  static const String legendBlazonBordersNoPadding =
      "$baseUrl/icons/Icon_HV_League_Legend_3_Border_No_Padding.png";
  static String flag(String countryCode) =>
      "$baseUrl/country-flags/${countryCode.toLowerCase()}.png";
  static const String planet = "$baseUrl/icons/Icon_HV_Planet.png";

  // 🛡️ Clan
  static String clanBadge(String badgeUrl) =>
      badgeUrl.isNotEmpty ? badgeUrl : "$baseUrl/icons/default_clan_badge.png";
  static String getClanBadgeImage(String url) =>
      url.isNotEmpty ? url : defaultImage;
  static const String clanGamesMedals =
      "$baseUrl/icons/Icon_HV_Clan_Games_Medal.png";
  static const String raidMedal = "$baseUrl/bot/icons/raid_medal.png";

  // Icons
  static const String iconTick = "$baseUrl/icons/Icon_DC_Tick.png";
  static const String iconCross = "$baseUrl/icons/Icon_DC_Cross.png";
  static const String iconClock = "$baseUrl/bot/icons/clock.png";
  static const String iconBuilderPotion =
      "$baseUrl/icons/Magic_Item_Builder_Potion.png";
  static const String iconGoldPass = "$baseUrl/icons/Icon_HV_Gold_Pass.png";

  // ⭐ Clan Capital
  static const String capitalGold =
      "$baseUrl/icons/Icon_CC_Resource_Capital_Gold_small.png";
  static const String capitalTrophy =
      "$baseUrl/icons/Icon_CC_Resource_Capital_Trophy.png";
  static const String raidAttacks = "$baseUrl/icons/Icon_HV_Raid_Attack.png";
  static const String capitalThickSwords =
      "$baseUrl/bot/icons/thick_capital_sword.png";
  static const String capitalVacantHouse =
      "$baseUrl/capital-base/clan-houses/Building_CC_Vacant_House.png";
  static const String capitalClanHouse =
      "$baseUrl/capital-base/clan-houses/Building_CC_Clan_House.png";
  static String capitalHall(int level) =>
      "$baseUrl/capital-base/capital-hall-pics/Building_CC_Capital_Hall_level_$level.png";

  // ✨ Defaults
  static const String defaultProfile = "$baseUrl/icons/default_profile.png";

  // 🖼️ Backgrounds
  static const String homeBaseBackground =
      "$baseUrl/landscape/home-landscape.png";
  static const String builderBaseBackground =
      "$baseUrl/landscape/builder-landscape.png";
  static const String legendPageBackground =
      "$baseUrl/landscape/legend-landscape.png";
  static const String clanPageBackground =
      "$baseUrl/landscape/clan-landscape.png";
  static const String cwlPageBackground =
      "$baseUrl/landscape/cwl-landscape.png";
  static const String warPageBackground =
      "$baseUrl/landscape/war-landscape.jpg";
  static const String clanCapitalPageBackground =
      "$baseUrl/landscape/clan-capital-landscape.png";
  static const String playerWarStatsPageBackground =
      "$baseUrl/landscape/war-stats.png";
  static const String playerAchievementPageBackground =
      "$baseUrl/landscape/achievement-landscape.png";

  // 🎭 Heroes & Troops & Others
  static String getHeroImage(String heroName) {
    final slug = _assetSlug(heroName);
    if (slug.isEmpty) {
      return defaultImage;
    }
    return _buildAssetUrl(['heroes', slug, 'icon.webp']);
  }

  static String getBuilderBaseHeroImage(String heroName) {
    return getHeroImage(heroName);
  }

  static String getTroopImage(String troopName) {
    final slug = _assetSlug(troopName);
    if (slug.isEmpty) {
      return defaultImage;
    }
    return _buildAssetUrl(['troops', slug, 'icon.webp']);
  }

  static String getSuperTroopImage(String superTroopName) =>
      getTroopImage(superTroopName);
  static String getBuilderBaseTroopImage(String troopName) =>
      getTroopImage(troopName);

  static String getSiegeMachineImage(String siegeMachineName) =>
      getTroopImage(siegeMachineName);

  static String getSpellImage(String spellName) {
    final slug = _assetSlug(spellName);
    if (slug.isEmpty) {
      return defaultImage;
    }
    return _buildAssetUrl(['spells', '$slug.webp']);
  }

  static String getPetImage(String petName) {
    final slug = _assetSlug(petName);
    if (slug.isEmpty) {
      return defaultImage;
    }
    return _buildAssetUrl(['pets', slug, 'icon.webp']);
  }

  static String getGearImage(String gearName) {
    final slug = _assetSlug(gearName);
    if (slug.isEmpty) {
      return defaultImage;
    }
    return _buildAssetUrl(['equipment', '$slug.webp']);
  }

  static String getHomeVillageBuildingImage(String buildingName, int level) {
    return _leveledAssetUrl(['buildings', 'home-village'], buildingName, level);
  }

  static String getBuilderBaseBuildingImage(String buildingName, int level) {
    return _leveledAssetUrl(['buildings', 'builder-base'], buildingName, level);
  }

  static String getSeasonalDefenseImage(String defenseName, int level) {
    return _leveledAssetUrl(
      ['buildings', 'seasonal-defense'],
      defenseName,
      level,
    );
  }

  static String getHomeVillageTrapImage(String trapName, int level) {
    return _leveledAssetUrl(['traps', 'home-village'], trapName, level);
  }

  static String getBuilderBaseTrapImage(String trapName, int level) {
    return _leveledAssetUrl(['traps', 'builder-base'], trapName, level);
  }

  static String getHomeVillageDecorationImage(String decorationName) {
    return _namedAssetUrl(['decorations', 'home-village'], decorationName);
  }

  static String getBuilderBaseDecorationImage(String decorationName) {
    return _namedAssetUrl(['decorations', 'builder-base'], decorationName);
  }

  static String _assetSlug(String name) {
    return name.trim().toLowerCase().replaceAll(' ', '_').replaceAll('.', '');
  }

  static String _leagueFileSlug(String name) {
    final normalized = name.trim().toLowerCase();
    final romanSuffix = RegExp(r'\s+(i|ii|iii|iv|v)$').firstMatch(normalized);
    if (romanSuffix != null) {
      final suffix = romanSuffix.group(1)!;
      final prefix = normalized.substring(0, romanSuffix.start);
      return '${_assetSlug(prefix)}_${_leagueTierNumber(suffix)}';
    }
    return _assetSlug(name);
  }

  static String? _numberedLeagueFileName(String leagueName) {
    final slug = _leagueFileSlug(leagueName);
    if (slug.isEmpty) return null;
    if (slug == 'unranked') return 'unranked.png';
    if (slug == 'legend_league') return 'legend_league.png';
    final match = RegExp(r'^([a-z]+)_league(?:_\d+)?$').firstMatch(slug);
    if (match == null) {
      return null;
    }
    const knownFamilies = {
      'bronze',
      'silver',
      'gold',
      'crystal',
      'master',
      'champion',
      'titan',
    };
    if (!knownFamilies.contains(match.group(1))) return null;
    return '$slug.png';
  }

  static String? _cwlLeagueFileName(String? tid) {
    if (tid == null || tid.isEmpty) return null;
    if (tid == 'TID_LEAGUE_LEGENDARY') return 'legend_league.png';
    if (tid == 'TID_LEAGUE_UNRANKED') return 'unranked.png';

    final match = RegExp(r'^TID_LEAGUE_([A-Z]+)(\d)$').firstMatch(tid);
    if (match == null) return null;

    final rawFamily = match.group(1)!.toLowerCase();
    final family = switch (rawFamily) {
      'hero' || 'titanium' => 'titan',
      _ => rawFamily,
    };
    return '${family}_league_${match.group(2)}.png';
  }

  static String _leveledAssetUrl(List<String> prefix, String name, int level) {
    final slug = _assetSlug(name);
    if (slug.isEmpty || level <= 0) {
      return defaultImage;
    }
    return _buildAssetUrl([...prefix, slug, 'level_$level.webp']);
  }

  static String _namedAssetUrl(List<String> prefix, String name) {
    final slug = _assetSlug(name);
    if (slug.isEmpty) {
      return defaultImage;
    }
    return _buildAssetUrl([...prefix, '$slug.webp']);
  }

  static String _buildAssetUrl(List<String> segments) {
    final encodedSegments = segments
        .map(Uri.encodeComponent)
        .join('/')
        .replaceAll('%2F', '/');
    return '$baseUrl/$encodedSegments';
  }

  // Stickers
  static const String villager = "$baseUrl/stickers/villager_clapping.webp";
  static const String goblin = "$baseUrl/stickers/crying_goblin.webp";
  static const String builderWave = "$baseUrl/stickers/builder_wave.webp";
  static const String thinkingBarbarianKing =
      "$baseUrl/stickers/thinking_bk.webp";
  static const String sleepingApprenticeBuilder =
      "$baseUrl/stickers/builder_wave.webp";
}
