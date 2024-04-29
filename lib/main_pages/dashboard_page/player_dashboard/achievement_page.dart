import 'dart:ui';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:clashkingapp/api/player_account_info.dart';
import 'package:clashkingapp/main_pages/war_and_league_page/war_in_war_and_league/war_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/components/filter_dropdown.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AchievementScreen extends StatefulWidget {
  final PlayerAccountInfo playerStats;

  AchievementScreen({super.key, required this.playerStats});

  @override
  AchievementScreenState createState() => AchievementScreenState();
}

class AchievementScreenState extends State<AchievementScreen>
    with SingleTickerProviderStateMixin {
  String currentFilter = 'All';
  String backgroundImageUrl =
      "https://clashkingfiles.b-cdn.net/landscape/achievement-landscape.png";
  int achievementCompleted = 0;
  int achievementTotal = 0;
  String achievementStringRatio = '';

  @override
  void initState() {
    super.initState();
    var filteredAchievements = widget.playerStats.achievements
        .where((achievement) => achievement.name != "Keep Your Account Safe!")
        .toList();
    achievementTotal = filteredAchievements.length;
    for (var achievement in filteredAchievements) {
      if (achievement.value >= achievement.target && achievement.stars == 3) {
        achievementCompleted++;
      } else if ((achievement.name == 'Dragon Slayer' ||
              achievement.name == 'Ungrateful Child') &&
          achievement.value >= 1) {
        achievementCompleted++;
      }
    }

    double ratio = achievementTotal > 0 ? (achievementCompleted / achievementTotal) * 100 : 0.0;
    achievementStringRatio = ratio == ratio.round() ? ratio.round().toString() : ratio.toStringAsFixed(2);
  }

  void updateFilter(String newFilter) {
    setState(() {
      currentFilter = newFilter;
    });
  }

  @override
  Widget build(BuildContext context) {
    Map<String, String> filterOptions = {
      AppLocalizations.of(context)?.all ?? 'All': 'All',
      AppLocalizations.of(context)?.homeBase ?? 'Home Base': 'home',
      AppLocalizations.of(context)?.builderBase ?? 'Builder Base' : 'builderBase',
      AppLocalizations.of(context)?.clanCapital ?? 'Clan Capital': 'clanCapital',
    };

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: <Widget>[
                    SizedBox(
                      height: 170,
                      width: double.infinity,
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.3),
                            BlendMode.darken,
                          ),
                          child: CachedNetworkImage(imageUrl: 
                            backgroundImageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 70,
                      child: Text(
                        AppLocalizations.of(context)?.achievements ?? 'Achievements',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    Positioned(
                      bottom: 26,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 30,
                            width: 200,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: achievementTotal > 0 ? achievementCompleted / achievementTotal : 0.0,
                                minHeight: 30,
                                backgroundColor: Color.fromRGBO(61, 60, 60, 1),
                                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.secondary),
                              ),
                            ),
                          ),
                          Center(
                            child: Text(
                              '${achievementCompleted.toString()}/${achievementTotal.toString()} - $achievementStringRatio%',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 30,
                      left: 10,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 32),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                FilterDropdown(
                  sortBy: currentFilter,
                  updateSortBy: updateFilter,
                  sortByOptions: filterOptions,
                ),
                SizedBox(height: 20),
                if (currentFilter == 'All' || currentFilter == 'home')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(AppLocalizations.of(context)?.homeBase ?? 'Home Base',
                            style: Theme.of(context).textTheme.headlineMedium),
                      ),
                      _buildAchievementsForVillage('home'),
                    ],
                  ),
                if (currentFilter == 'All' || currentFilter == 'builderBase')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 14),
                      Center(
                        child: Text(AppLocalizations.of(context)?.builderBase ?? 'Builder Base',
                            style: Theme.of(context).textTheme.headlineMedium),
                      ),
                      _buildAchievementsForVillage('builderBase'),
                    ],
                  ),
                if (currentFilter == 'All' || currentFilter == 'clanCapital')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 14),
                      Center(
                        child: Text(AppLocalizations.of(context)?.clanCapital ?? 'Clan capital',
                          style: Theme.of(context).textTheme.headlineMedium)
                      ),
                      _buildAchievementsForVillage('clanCapital'),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsForVillage(String village) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 20), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.playerStats.achievements
            .where((achievement) =>
                achievement.name != "Keep Your Account Safe!" &&
                achievement.village == village)
            .map((achievement) {
          int stars = achievement.stars;
          if ((achievement.name == 'Dragon Slayer' ||
                  achievement.name == 'Ungrateful Child') &&
              achievement.value >= 1) {
            stars += 2;
          }
          double progress =
              min(achievement.value / max(achievement.target, 1) * 100, 100);
          String progressStr = progress == progress.toInt()
              ? progress.toInt().toString()
              : progress.toStringAsFixed(2);
          String progressStringRatio =
              '${formatNumber(achievement.value)}/${achievement.target.toString().replaceAll(RegExp('000000\$'), 'M')} - $progressStr%';

          return Padding(padding : const EdgeInsets.only(bottom : 4),
          child : Card(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom : 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        achievement.name,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Spacer(),
                      ...generateStars(stars, 22)
                    ],
                  ),
                  Text(
                    achievement.info.replaceAll(RegExp('000000 '), 'M '),
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Stack(
                    children: [
                      SizedBox(
                        height: 20,
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            minHeight: 20,
                            backgroundColor: Color.fromRGBO(61, 60, 60, 1),
                            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.secondary),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          progressStringRatio,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
          ));
        }).toList(),
      ),
    );
  }

  String formatNumber(int number) {
    String numberStr = number.toString();
    if (numberStr.endsWith('000000')) {
      return numberStr.replaceAll(RegExp('000000\$'), 'M');
    } else {
      return NumberFormat("#,###")
          .format(number)
          .toString()
          .replaceAll(',', ' ');
    }
  }
}
