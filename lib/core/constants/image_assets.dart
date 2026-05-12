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

  // 🏆 Wars & CWL & Trophies
  static const String warPreferenceIn = "$baseUrl/icons/Icon_HV_In.png";
  static const String warPreferenceOut = "$baseUrl/icons/Icon_HV_Out.png";
  static const String attackStar = "$baseUrl/icons/Icon_HV_Attack_Star.png";
  static const String war = "$baseUrl/icons/Icon_DC_War.png";
  static const String warClan = "$baseUrl/icons/Icon_HV_Clan_War.png";
  static const String builderBaseStar = "$baseUrl/icons/Icon_BB_Star.png";
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

  static const Map<String, String> _assetSlugOverrides = {
    'Baby Dragon 2': 'baby_dragon',
  };

  // 🎭 Heroes & Troops & Others
  static String getHeroImage(String heroName) {
    if (heroName.isEmpty) {
      return defaultImage;
    }
    return _buildAssetUrl([
      'home-base',
      'hero-pics',
      'Icon_HV_Hero_${_titleUnderscoreName(heroName)}.png',
    ]);
  }

  static String getBuilderBaseHeroImage(String heroName) {
    if (heroName.isEmpty) {
      return defaultImage;
    }
    return _buildAssetUrl([
      'builder-base',
      'hero-pics',
      'Icon_BB_Hero_${_titleUnderscoreName(heroName)}.png',
    ]);
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
    final override = _assetSlugOverrides[name];
    if (override != null) {
      return override;
    }

    final lower = name.trim().toLowerCase();
    if (lower.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();
    var previousWasSeparator = false;

    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      final isAlphaNumeric =
          (rune >= 48 && rune <= 57) || (rune >= 97 && rune <= 122);

      if (isAlphaNumeric || char == '\'') {
        buffer.write(char);
        previousWasSeparator = false;
        continue;
      }

      if (char == '.' || char == ',') {
        continue;
      }

      if (!previousWasSeparator) {
        buffer.write('_');
        previousWasSeparator = true;
      }
    }

    final slug = buffer.toString().replaceAll(RegExp(r'_+'), '_');
    return slug.replaceAll(RegExp(r'^_+|_+$'), '');
  }

  static String _titleUnderscoreName(String name) {
    final parts = name
        .trim()
        .replaceAll('.', '')
        .split(RegExp(r'[\s_-]+'))
        .where((part) => part.isNotEmpty)
        .toList();

    return parts.map((part) {
      if (part.length == 1) {
        return part.toUpperCase();
      }
      return '${part[0].toUpperCase()}${part.substring(1)}';
    }).join('_');
  }

  static String _buildAssetUrl(List<String> segments) {
    final encodedSegments =
        segments.map(Uri.encodeComponent).join('/').replaceAll('%2F', '/');
    return '$baseUrl/$encodedSegments';
  }

  // Stickers
  static const String villager = "$baseUrl/stickers/Villager_HV_Villager_7.png";
  static const String goblin = "$baseUrl/stickers/Troop_HV_Goblin.png";
  static const String sleepingApprenticeBuilder =
      "$baseUrl/stickers/Apprentice_Builder_Sleeping.png";
}
