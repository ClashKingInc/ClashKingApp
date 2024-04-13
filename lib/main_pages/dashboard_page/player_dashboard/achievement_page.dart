import 'package:clashkingapp/api/player_account_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
//import 'package:clipboard/clipboard.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'dart:math';

class AchievementScreen extends StatefulWidget {
  final PlayerAccountInfo playerStats;

  AchievementScreen({super.key, required this.playerStats});
  
  @override
  AchievementScreenState createState() => AchievementScreenState();
}

class AchievementScreenState extends State<AchievementScreen>
    with SingleTickerProviderStateMixin {
  String backgroundImageUrl =
      "https://clashkingfiles.b-cdn.net/landscape/achievement-landscape.png";
  int achievementCompleted = 0;
  int achievementTotal = 0;

  @override
  void initState() {
    super.initState();
    var filteredAchievements = widget.playerStats.achievements
        .where((achievement) => achievement.name != "Keep Your Account Safe!")
        .toList();
    achievementTotal = filteredAchievements.length;
    filteredAchievements.forEach((achievement) {
      if (achievement.value >= achievement.target && achievement.stars == 3) {
        achievementCompleted++;
      } else if ((achievement.name == 'Dragon Slayer' || achievement.name == 'Ungrateful Child') && achievement.value >= 1) {
        achievementCompleted++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: <Widget>[
                      SizedBox(
                        height: 190,
                        width: double.infinity,
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                          child: ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(0.3),
                              BlendMode.darken,
                            ),
                            child: Image.network(
                              backgroundImageUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        child: Text(
                          'Achievements : ${achievementCompleted.toString()}/${achievementTotal.toString()}',
                          style: Theme.of(context).textTheme.headlineMedium,
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
                  SizedBox(height: 80),
                  Column(
                    children: [
                      Text(AppLocalizations.of(context)?.homeBase ?? 'Home Base', style: Theme.of(context).textTheme.headlineMedium),
                      _buildAchievementsForVillage('home'),
                      Text(AppLocalizations.of(context)?.builderBase ?? 'Builder Base', style: Theme.of(context).textTheme.headlineMedium),
                      _buildAchievementsForVillage('builderBase'),
                      Text(AppLocalizations.of(context)?.clanCapital ?? 'Clan capital', style: Theme.of(context).textTheme.headlineMedium),
                      _buildAchievementsForVillage('clanCapital'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsForVillage(String village) {
    return Column(
      children: widget.playerStats.achievements
        .where((achievement) => achievement.name != "Keep Your Account Safe!" && achievement.village == village)
        .map((achievement) {
          int stars = achievement.stars;
          if ((achievement.name == 'Dragon Slayer' || achievement.name == 'Ungrateful Child') && achievement.value >= 1) {
            stars += 2;
          }
          double progress = min(achievement.value / achievement.target * 100, 100);
          String progressStr = progress == progress.toInt() ? progress.toInt().toString() : progress.toStringAsFixed(2);

          return ListTile(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(achievement.name),
                Text(achievement.info.replaceAll(RegExp('000000 '), 'M '), style: TextStyle(fontSize: 12)),
                Text('Progression : ${formatNumber(achievement.value)}/${achievement.target.toString().replaceAll(RegExp('000000\$'), 'M')} - $progressStr%'),
                Row(
                  children: _buildStars(stars),
                ),
              ],
            ),
          );
        }
      ).toList(),
    );
  }

  String formatNumber(int number) {
    String numberStr = number.toString();
    if (numberStr.endsWith('000000')) {
      return numberStr.replaceAll(RegExp('000000\$'), 'M');
    } else {
      return NumberFormat("#,###").format(number).toString().replaceAll(',', ' ');
    }
  }

  List<Widget> _buildStars(int count) {
    return List<Widget>.generate(
      count,
      (index) => Image.network(
        'https://clashkingfiles.b-cdn.net/icons/Icon_BB_Star.png',
        width: 22.0,
        height: 22.0,
      ),
    );
  }
}