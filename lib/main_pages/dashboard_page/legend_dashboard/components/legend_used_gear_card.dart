import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:clashkingapp/classes/data/heroes_data_manager.dart';
import 'package:clashkingapp/classes/profile/legend/legend_league.dart';
import 'package:clashkingapp/classes/profile/description/equipment.dart';
import 'package:clashkingapp/classes/profile/description/hero.dart'
    as profile_hero;

class LegendUsedGearCard extends StatelessWidget {
  const LegendUsedGearCard(
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
    print(gearCounts);
    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                  AppLocalizations.of(context)?.heroesEquipments ??
                      "Heroes Equipments",
                  style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 10),
              ...gearCounts.entries.map((entry) {
                var heroLevel = heroes
                    .firstWhere(
                      (hero) => hero.name == entry.key,
                    )
                    .level;

                return Column(
                  children: [
                    Row(
                      children: [
                        CachedNetworkImage(
                            imageUrl: HeroesDataManager()
                                    .getHeroInfo(entry.key)["url"] ??
                                'https://clashkingfiles.b-cdn.net/icons/Unknown_person.jpg',
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover),
                        Text(heroLevel.toString()),
                        ...entry.value.keys.map(
                          (key) {
                            var gearLevel = gears
                                .firstWhere(
                                  (gear) => gear.name == entry.value[key]!.name,
                                )
                                .level;
                            return Row(
                              children: [
                                SizedBox(width: 8),
                                CachedNetworkImage(
                                    imageUrl: entry.value[key]!.url,
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.cover),
                                Text(gearLevel.toString())
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                  ],
                );
              }),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
