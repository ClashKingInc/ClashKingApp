import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/classes/data/heroes_data_manager.dart';
import 'package:clashkingapp/classes/profile/description/equipment.dart';
import 'package:clashkingapp/classes/profile/description/hero.dart'
    as profile_hero;
import 'package:clashkingapp/classes/profile/legend/legend_hero_gear.dart';

class LegendUsedGear extends StatelessWidget {
  const LegendUsedGear(
      {super.key,
      required this.context,
      required this.gearCounts,
      required this.gears,
      required this.heroes});

  final BuildContext context;
  final Map<String, Map<String, GearDetails>> gearCounts;
  final List<Equipment> gears;
  final List<profile_hero.Hero> heroes;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child:
      Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
            AppLocalizations.of(context)?.heroesEquipments ??
                "Heroes Equipments",
            style: Theme.of(context).textTheme.bodyMedium),
        ...gearCounts.entries.map((entry) {
          var hero = heroes.firstWhere((hero) => hero.name == entry.key);
          var heroLevel = hero.level;
          var isHeroMaxLevel = heroLevel ==
              heroes.firstWhere((hero) => hero.name == entry.key).maxLevel;

          return Column(
            children: [
              SizedBox(height: 10),
              Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isHeroMaxLevel
                                ? Color(0xFFD4AF37)
                                : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: CachedNetworkImage(
                            imageUrl: HeroesDataManager()
                                    .getHeroInfo(entry.key)["url"] ??
                                'https://assets.clashk.ing/icons/Unknown_person.jpg',
                            width: 25,
                            height: 25,
                            fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: 1,
                        bottom: 1,
                        child: Container(
                          padding: EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: isHeroMaxLevel
                                ? Color(0xFFD4AF37)
                                : Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            heroLevel.toString(),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall!
                                .copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 16),
                  ...entry.value.keys.map((key) {
                    var gear = gears.firstWhere(
                        (gear) => gear.name == entry.value[key]!.name);
                    var gearLevel = gear.level;
                    var isGearMaxLevel = gearLevel ==
                        gears
                            .firstWhere(
                                (gear) => gear.name == entry.value[key]!.name)
                            .maxLevel;

                    return Row(
                      children: [
                        Stack(
                          children: [
                            CachedNetworkImage(
                                imageUrl: entry.value[key]!.url,
                                width: 25,
                                height: 25,
                                fit: BoxFit.cover),
                            Positioned(
                              right: 1,
                              bottom: 1,
                              child: Container(
                                padding: EdgeInsets.all(1),
                                decoration: BoxDecoration(
                                  color: isGearMaxLevel
                                      ? Color(0xFFD4AF37)
                                      : Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  gearLevel.toString(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall!
                                      .copyWith(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 16),
                      ],
                    );
                  }),
                ],
              ),
            ],
          );
        }),
      ],
    ));
  }
}
