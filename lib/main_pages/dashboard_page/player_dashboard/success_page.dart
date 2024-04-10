import 'package:clashkingapp/api/player_account_info.dart';
import 'package:flutter/material.dart';
//import 'package:flutter_gen/gen_l10n/app_localizations.dart';
//import 'package:clipboard/clipboard.dart';
import 'dart:ui';

class SuccessScreen extends StatefulWidget {
  final PlayerAccountInfo playerStats;

  SuccessScreen({super.key, required this.playerStats});
  
  @override
  SuccessScreenState createState() => SuccessScreenState();
}

class SuccessScreenState extends State<SuccessScreen>
    with SingleTickerProviderStateMixin {
  String backgroundImageUrl =
      "https://clashkingfiles.b-cdn.net/landscape/achievement-landscape.png";
  int successCompleted = 0;
  int successTotal = 0;

  @override
  void initState() {
    super.initState();
    successTotal = widget.playerStats.achievements.length;
    successCompleted = widget.playerStats.achievements
        .where((achievement) =>
            achievement.value >= achievement.target && achievement.stars == 3)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    successTotal = widget.playerStats.achievements.length;
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
                              Colors.black.withOpacity(0.3), // Adjust opacity as needed
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
                          'Achievements : ${successCompleted.toString()}/${successTotal.toString()}',
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
                    children: widget.playerStats.achievements.map((achievement) {
                      successCompleted += (achievement.value >= achievement.target && achievement.stars == 3) ? 1 : 0;
                      return ListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(achievement.name),
                            Text('Progression : ${achievement.value.toString()}/${achievement.target.toString()}'),
                            Text(achievement.info),
                            Row(
                              children: _buildStars(achievement.stars),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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