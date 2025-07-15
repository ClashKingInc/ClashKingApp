import 'dart:ui';
import 'dart:math';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:intl/intl.dart';
import 'package:clashkingapp/core/functions/war_functions.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/common/widgets/buttons/chip.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:scrollable_tab_view/scrollable_tab_view.dart';

class PlayerAchievementScreen extends StatefulWidget {
  final Player player;

  PlayerAchievementScreen({super.key, required this.player});

  @override
  PlayerAchievementScreenState createState() => PlayerAchievementScreenState();
}

class PlayerAchievementScreenState extends State<PlayerAchievementScreen>
    with SingleTickerProviderStateMixin {
  String currentFilter = 'All';
  int achievementCompleted = 0;
  int achievementTotal = 0;
  String achievementStringRatio = '';
  
  // Progress per village
  int homeCompleted = 0;
  int homeTotal = 0;
  int builderCompleted = 0;
  int builderTotal = 0;
  int capitalCompleted = 0;
  int capitalTotal = 0;

  @override
  void initState() {
    super.initState();
    var filteredAchievements = widget.player.achievements
        .where((achievement) => achievement.name != "Keep Your Account Safe!")
        .toList();
    achievementTotal = filteredAchievements.length;
    
    // Calculate progress per village
    _calculateProgressPerVillage(filteredAchievements);
    
    for (var achievement in filteredAchievements) {
      if (achievement.value >= achievement.target && achievement.stars == 3) {
        achievementCompleted++;
      } else if ((achievement.name == 'Dragon Slayer' ||
              achievement.name == 'Ungrateful Child') &&
          achievement.value >= 1) {
        achievementCompleted++;
      }
    }

    double ratio = achievementTotal > 0
        ? (achievementCompleted / achievementTotal) * 100
        : 0.0;
    achievementStringRatio = ratio == ratio.round()
        ? ratio.round().toString()
        : ratio.toStringAsFixed(2);
  }

  void updateFilter(String newFilter) {
    setState(() {
      currentFilter = newFilter;
    });
  }
  
  void _calculateProgressPerVillage(List<dynamic> achievements) {
    for (var achievement in achievements) {
      bool isCompleted = (achievement.value >= achievement.target && achievement.stars == 3) ||
          ((achievement.name == 'Dragon Slayer' || achievement.name == 'Ungrateful Child') &&
              achievement.value >= 1);
      
      switch (achievement.village) {
        case 'home':
          homeTotal++;
          if (isCompleted) homeCompleted++;
          break;
        case 'builderBase':
          builderTotal++;
          if (isCompleted) builderCompleted++;
          break;
        case 'clanCapital':
          capitalTotal++;
          if (isCompleted) capitalCompleted++;
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            ScrollableTab(
              tabBarDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              ),
              labelColor: Theme.of(context).colorScheme.onSurface,
              labelPadding: EdgeInsets.zero,
              labelStyle: Theme.of(context).textTheme.bodyLarge,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
              tabs: [
                Tab(text: AppLocalizations.of(context)?.gameBaseHome ?? 'Home Village'),
                Tab(text: AppLocalizations.of(context)?.generalOthers ?? 'Others'),
              ],
              children: [
                _buildTabContent('home'),
                _buildTabContent('others'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        SizedBox(
          height: 240,
          width: double.infinity,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.7),
                BlendMode.darken,
              ),
              child: MobileWebImage(
                imageUrl: ImageAssets.playerAchievementPageBackground,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Positioned(
          top: 40,
          left: 10,
          child: IconButton(
            icon: Icon(Icons.arrow_back,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 32),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        Positioned(
          top: 26,
          bottom: 0,
          left: 10,
          right: 10,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Center(
                child: Column(
                  children: [
                    Text(
                      AppLocalizations.of(context)?.gameAchievements ?? 'Achievements',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: Colors.white),
                    ),
                    SizedBox(height: 16),
                    Container(
                      width: 250,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Column(
                        children: [
                          Container(
                            height: 8,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: achievementTotal > 0 
                                    ? achievementCompleted / achievementTotal 
                                    : 0.0,
                                minHeight: 8,
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${achievementCompleted.toString()}/${achievementTotal.toString()} ${AppLocalizations.of(context)?.generalCompleted ?? 'completed'} • $achievementStringRatio%',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildAchievementChips(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(String category) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: _buildAchievementsForCategory(category),
      ),
    );
  }

  List<Widget> _buildAchievementsForCategory(String category) {
    List<dynamic> filteredAchievements;
    
    if (category == 'home') {
      filteredAchievements = widget.player.achievements
          .where((achievement) =>
              achievement.name != "Keep Your Account Safe!" &&
              achievement.village == 'home')
          .toList();
    } else {
      // Others = Builder Base + Clan Capital
      filteredAchievements = widget.player.achievements
          .where((achievement) =>
              achievement.name != "Keep Your Account Safe!" &&
              (achievement.village == 'builderBase' || achievement.village == 'clanCapital'))
          .toList();
    }
    
    return filteredAchievements.map((achievement) {
          int stars = achievement.stars;
          if ((achievement.name == 'Dragon Slayer' ||
                  achievement.name == 'Ungrateful Child') &&
              achievement.value >= 1) {
            stars += 2;
          }
          double progress = min<double>(
              (achievement.value.toDouble() / max<double>(achievement.target.toDouble(), 1.0)) * 100, 
              100.0
          );
          String progressStr = progress == progress.toInt()
              ? progress.toInt().toString()
              : progress.toStringAsFixed(2);
          String progressStringRatio =
              '${formatNumber(achievement.value)}/${achievement.target.toString().replaceAll(RegExp('000000\$'), 'M')} - $progressStr%';

          return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: progress >= 100 
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                        : Theme.of(context).colorScheme.surface,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                achievement.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Row(
                              children: generateStars(stars, 20).map((star) {
                                return Container(
                                  margin: EdgeInsets.only(left: 2),
                                  child: star,
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          achievement.info.replaceAll(RegExp('000000 '), 'M '),
                          style: TextStyle(
                            fontSize: 13, 
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              progressStringRatio,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress / 100,
                          minHeight: 6,
                          backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress >= 100 
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ));
        }).toList();
  }

  Widget _buildAchievementChips(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        ImageChip(
          imageUrl: ImageAssets.townHall(widget.player.townHallLevel),
          label: '$homeCompleted/$homeTotal',
          textColor: Colors.white,
          edgeColor: Colors.white,
        ),
        ImageChip(
          imageUrl: ImageAssets.builderHall(widget.player.builderHallLevel),
          label: '$builderCompleted/$builderTotal',
          textColor: Colors.white,
          edgeColor: Colors.white,
        ),
        ImageChip(
          imageUrl: ImageAssets.capitalGold,
          label: '$capitalCompleted/$capitalTotal',
          textColor: Colors.white,
          edgeColor: Colors.white,
        ),
      ],
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
