import 'package:clashkingapp/core/services/game_data_service.dart';

class ImageAssets {
  static const String baseUrl = "https://assets.clashk.ing";
  static const String defaultImage =
      "$baseUrl/default-pics/Icon_Unknown_Troop.png";

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
      "$baseUrl/home-base/town-hall-pics/town-hall-$level.png";
  static String builderHall(int level) =>
      "$baseUrl/builder-base/builder-hall-pics/Building_BB_Builder_Hall_level_$level.png";

  // 🏆 League Icons
  static String getLeagueImage(String leagueName) {
    final legendTierFile = _legendLeagueTierFile(leagueName);
    if (legendTierFile != null) {
      return _buildAssetUrl(['home-base', 'league-tier-icons', legendTierFile]);
    }

    final rawPlayerLeagues = GameDataService.playerLeagueData["leagues"];
    if (rawPlayerLeagues is Map && rawPlayerLeagues.containsKey(leagueName)) {
      return _buildAssetUrl([
        'home-base',
        'league-tier-icons',
        '${_titleUnderscoreName(leagueName)}.png',
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
      return 'Legend_League.png';
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
    return 'Legend_League_$tierNumber.webp';
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

    const filesByFamily = {
      'bronze': 'Icon_HV_League_Bronze_2.png',
      'silver': 'Icon_HV_League_Silver_2.png',
      'gold': 'Icon_HV_League_Gold_2.png',
      'crystal': 'Icon_HV_League_Crystal_2.png',
      'master': 'Icon_HV_League_Master_2.png',
      'champion': 'Icon_HV_League_Champion.png',
      'titan': 'Icon_HV_League_Titan_1.png',
      'legend': 'Icon_HV_League_Legend_4.png',
    };

    for (final entry in filesByFamily.entries) {
      if (normalized.contains(entry.key)) {
        return _buildAssetUrl(['home-base', 'league-icons', entry.value]);
      }
    }

    return getLeagueImage(leagueName);
  }

  static String getBuilderBaseLeagueImage(dynamic league) {
    if (league is Map) {
      final iconUrls = league['iconUrls'];
      if (iconUrls is Map && iconUrls['medium'] is String) {
        return iconUrls['medium'] as String;
      }
      if (league['name'] is String) {
        return getBuilderBaseLeagueImage(league['name']);
      }
    }

    final name = league?.toString().trim() ?? '';
    if (name.isEmpty) return builderBaseStar;

    final parts = name.toLowerCase().split(RegExp(r'\s+'));
    if (parts.length < 2) return builderBaseStar;

    final material = parts[0];
    if (material == 'legend') {
      return '$baseUrl/bot/builder-base-leagues/legend_league.png';
    }

    if (material == 'diamond') {
      return '$baseUrl/bot/builder-base-leagues/diamond_league_1.png';
    }

    if (parts.length < 3) {
      return '$baseUrl/builder-base/league-icons/Icon_BB_League_${_titleUnderscoreName(material)}.png';
    }

    final tier = _leagueTierNumber(parts[2]);
    final prefixedAsset = _builderBaseLeaguePrefixedAsset(material, tier);
    if (prefixedAsset) {
      return '$baseUrl/bot/builder-base-leagues/builder_base_${material}_league_$tier.png';
    }

    return '$baseUrl/bot/builder-base-leagues/${material}_league_$tier.png';
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

  static bool _builderBaseLeaguePrefixedAsset(String material, int tier) {
    return material == 'clay' ||
        material == 'brass' ||
        (material == 'copper' && tier <= 2);
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
    const cwlFiles = {
      'TID_LEAGUE_BRONZE1': 'Icon_HV_CWL_Bronze_1.png',
      'TID_LEAGUE_BRONZE2': 'Icon_HV_CWL_Bronze_2.png',
      'TID_LEAGUE_BRONZE3': 'Icon_HV_CWL_Bronze_3.png',
      'TID_LEAGUE_SILVER1': 'Icon_HV_CWL_Silver_1.png',
      'TID_LEAGUE_SILVER2': 'Icon_HV_CWL_Silver_12.png',
      'TID_LEAGUE_SILVER3': 'Icon_HV_CWL_Silver_13.png',
      'TID_LEAGUE_GOLD1': 'Icon_HV_CWL_Gold_1.png',
      'TID_LEAGUE_GOLD2': 'Icon_HV_CWL_Gold_2.png',
      'TID_LEAGUE_GOLD3': 'Icon_HV_CWL_Gold_3.png',
      'TID_LEAGUE_CRYSTAL1': 'Icon_HV_CWL_Crystal_1.png',
      'TID_LEAGUE_CRYSTAL2': 'Icon_HV_CWL_Crystal_2.png',
      'TID_LEAGUE_CRYSTAL3': 'Icon_HV_CWL_Crystal_3.png',
      'TID_LEAGUE_MASTER1': 'Icon_HV_CWL_Master_1.png',
      'TID_LEAGUE_MASTER2': 'Icon_HV_CWL_Master_2.png',
      'TID_LEAGUE_MASTER3': 'Icon_HV_CWL_Master_3.png',
      'TID_LEAGUE_CHAMPION1': 'Icon_HV_CWL_Champion_1.png',
      'TID_LEAGUE_CHAMPION2': 'Icon_HV_CWL_Champion_2.png',
      'TID_LEAGUE_CHAMPION3': 'Icon_HV_CWL_Champion_3.png',
      'TID_LEAGUE_HERO1': 'Icon_HV_CWL_Titan_1.png',
      'TID_LEAGUE_HERO2': 'Icon_HV_CWL_Titan_2.png',
      'TID_LEAGUE_HERO3': 'Icon_HV_CWL_Titan_3.png',
      'TID_LEAGUE_TITANIUM1': 'Icon_HV_CWL_Titan_1.png',
      'TID_LEAGUE_TITANIUM2': 'Icon_HV_CWL_Titan_2.png',
      'TID_LEAGUE_TITANIUM3': 'Icon_HV_CWL_Titan_3.png',
      'TID_LEAGUE_LEGENDARY': 'Icon_HV_CWL_Legend.png',
      'Bronze League I': 'Icon_HV_CWL_Bronze_1.png',
      'Bronze League II': 'Icon_HV_CWL_Bronze_2.png',
      'Bronze League III': 'Icon_HV_CWL_Bronze_3.png',
      'Silver League I': 'Icon_HV_CWL_Silver_1.png',
      'Silver League II': 'Icon_HV_CWL_Silver_12.png',
      'Silver League III': 'Icon_HV_CWL_Silver_13.png',
      'Gold League I': 'Icon_HV_CWL_Gold_1.png',
      'Gold League II': 'Icon_HV_CWL_Gold_2.png',
      'Gold League III': 'Icon_HV_CWL_Gold_3.png',
      'Crystal League I': 'Icon_HV_CWL_Crystal_1.png',
      'Crystal League II': 'Icon_HV_CWL_Crystal_2.png',
      'Crystal League III': 'Icon_HV_CWL_Crystal_3.png',
      'Master League I': 'Icon_HV_CWL_Master_1.png',
      'Master League II': 'Icon_HV_CWL_Master_2.png',
      'Master League III': 'Icon_HV_CWL_Master_3.png',
      'Champion League I': 'Icon_HV_CWL_Champion_1.png',
      'Champion League II': 'Icon_HV_CWL_Champion_2.png',
      'Champion League III': 'Icon_HV_CWL_Champion_3.png',
      'Titan League I': 'Icon_HV_CWL_Titan_1.png',
      'Titan League II': 'Icon_HV_CWL_Titan_2.png',
      'Titan League III': 'Icon_HV_CWL_Titan_3.png',
      'Legend League': 'Icon_HV_CWL_Legend.png',
      'Unranked': 'Icon_HV_CWL_Unranked.png',
    };
    final fileName = cwlFiles[tid] ?? cwlFiles[resolvedName];
    if (fileName != null) {
      return '$baseUrl/home-base/league-icons/$fileName';
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
      "$baseUrl/builder-base/building-pics/Building_HV_Clan_Castle_level_2_3.png";
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

  static String _assetSlug(String name) {
    return name.trim().toLowerCase().replaceAll(' ', '_').replaceAll('.', '');
  }

  static String _titleUnderscoreName(String name) {
    final parts = name
        .trim()
        .replaceAll('.', '')
        .split(RegExp(r'[\s_-]+'))
        .where((part) => part.isNotEmpty)
        .toList();

    return parts
        .map((part) {
          if (part.length == 1) {
            return part.toUpperCase();
          }
          return '${part[0].toUpperCase()}${part.substring(1)}';
        })
        .join('_');
  }

  static String _buildAssetUrl(List<String> segments) {
    final encodedSegments = segments
        .map(Uri.encodeComponent)
        .join('/')
        .replaceAll('%2F', '/');
    return '$baseUrl/$encodedSegments';
  }

  // Stickers
  static const String villager = "$baseUrl/stickers/Villager_HV_Villager_7.png";
  static const String goblin = "$baseUrl/stickers/Troop_HV_Goblin.png";
  static const String sleepingApprenticeBuilder =
      "$baseUrl/stickers/Apprentice_Builder_Sleeping.png";
}
