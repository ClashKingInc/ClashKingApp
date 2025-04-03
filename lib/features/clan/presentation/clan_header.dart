import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/common/widgets/dialogs/open_clash_dialog.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ClanInfoHeaderCard extends StatelessWidget {
  final Clan clanInfo;

  const ClanInfoHeaderCard({super.key, required this.clanInfo});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    String? extractDiscordCode(String description) {
      final cleaned = description.replaceAll(RegExp(r'[\s\n\r]'), ' ');
      final RegExp discordPattern = RegExp(
        r"(?:https?:\/\/)?(?:discord\.com\/invite\/|discord\.gg\/)([a-zA-Z0-9]+)",
      );
      final match = discordPattern.firstMatch(cleaned);
      return match?.group(1); // juste le code
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            SizedBox(
              height: 180,
              width: double.infinity,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.black.withAlpha(160),
                    BlendMode.darken,
                  ),
                  child: CachedNetworkImage(
                    imageUrl: ImageAssets.clanPageBackground,
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
                    size: 32, color: Theme.of(context).colorScheme.onPrimary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              bottom: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.bar_chart_rounded,
                        color: Colors.white, size: 28),
                    onPressed: () {
                      // showDialog(...); à implémenter si besoin
                    },
                  ),
                  const SizedBox(width: 12),
                  CachedNetworkImage(
                    imageUrl: clanInfo.badgeUrls.large,
                    width: 100,
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.sports_esports_rounded,
                        color: Colors.white, size: 28),
                    onPressed: () {
                      final lang = Localizations.localeOf(context).languageCode;
                      final url = Uri.https('link.clashofclans.com', '/$lang', {
                        'action': 'OpenClanProfile',
                        'tag': clanInfo.tag,
                      });
                      showDialog(
                          context: context,
                          builder: (_) => OpenClashDialog(url: url));
                    },
                  ),
                  if (clanInfo.description.contains("discord.gg") ||
                      clanInfo.description.contains("discord.com"))
                    IconButton(
                      icon: const Icon(Icons.discord,
                          color: Colors.white, size: 28),
                      onPressed: () async {
                        try {
                          final code = extractDiscordCode(clanInfo.description);
                          if (code != null) {
                            final url = Uri.parse('https://discord.gg/$code');
                            if (!await launchUrl(url) && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(loc.cantOpenLink)),
                              );
                            }
                          }
                        } catch (e, st) {
                          Sentry.captureException(e, stackTrace: st);
                        }
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            Text(clanInfo.name, style: Theme.of(context).textTheme.titleLarge),
            GestureDetector(
              onTap: () {
                FlutterClipboard.copy(clanInfo.tag).then((_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Center(child: Text(loc.copiedToClipboard)),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                });
              },
              child: Text(
                clanInfo.tag,
                style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: [
                if (clanInfo.warLeague != null)
                  Chip(
                    avatar: CachedNetworkImage(
                      imageUrl: clanInfo.warLeague!.smallIconUrl ??
                          ImageAssets.defaultImage,
                      width: 20,
                    ),
                    label: Text(clanInfo.warLeague!.name),
                  ),
                if (clanInfo.location?.name != null &&
                    clanInfo.location!.countryCode != null)
                  Chip(
                    avatar: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      child: CachedNetworkImage(
                        imageUrl:
                            ImageAssets.flag(clanInfo.location!.countryCode!),
                        width: 20,
                      ),
                    ),
                    label: Text(clanInfo.location!.name),
                  ),
                Chip(
                  avatar: const Icon(Icons.groups, size: 16),
                  label: Text("${clanInfo.members}/50"),
                ),
                Chip(
                  avatar: CachedNetworkImage(
                      imageUrl: ImageAssets.trophies, width: 20),
                  label:
                      Text(NumberFormat('#,###').format(clanInfo.clanPoints)),
                ),
                Chip(
                  avatar: CachedNetworkImage(
                      imageUrl: ImageAssets.attacks, width: 20),
                  label: Text(
                      NumberFormat('#,###').format(clanInfo.clanCapitalPoints)),
                ),
                if (clanInfo.requiredTownhallLevel > 0)
                  Chip(
                    avatar: CachedNetworkImage(
                        imageUrl: ImageAssets.townHall(
                            clanInfo.requiredTownhallLevel),
                        width: 20),
                    label: Text(clanInfo.requiredTownhallLevel.toString()),
                  ),
                  Chip(
                    avatar: const Icon(Icons.mail, size: 16),
                    label: Text(() {
                      switch (clanInfo.type) {
                        case 'inviteOnly':
                          return loc.inviteOnly;
                        case 'open':
                          return loc.opened;
                        case 'closed':
                          return loc.closed;
                        default:
                          return clanInfo.type;
                      }
                    }()),
                  ),
                  Chip(
                    avatar: CachedNetworkImage(
                      imageUrl:
                          "https://assets.clashk.ing/icons/Icon_DC_War.png",
                      width: 20,
                    ),
                    label: Text(() {
                      switch (clanInfo.warFrequency) {
                        case 'always':
                          return loc.always;
                        case 'never':
                          return loc.never;
                        case 'oncePerWeek':
                          return loc.oncePerWeek;
                        case 'moreThanOncePerWeek':
                          return loc.twicePerWeek;
                        case 'lessThanOncePerWeek':
                          return loc.rarely;
                        default:
                          return loc.unknown;
                      }
                    }()),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                clanInfo.description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 7,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ],
    );
  }
}
