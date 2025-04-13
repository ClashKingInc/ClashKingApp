import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/common/widgets/buttons/chip.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/common/widgets/dialogs/open_clash_dialog.dart';
import 'package:clashkingapp/features/war_cwl/presentation/cwl/cwl.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war/war.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shimmer/shimmer.dart';
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
                    errorWidget: (context, url, error) => Icon(Icons.error),
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
                    errorWidget: (context, url, error) => Icon(Icons.error),
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
                  ImageChip(
                    imageUrl: ImageAssets
                        .leagues[clanInfo.warLeague?.name ?? "Unranked"]!,
                    label: clanInfo.warLeague!.name,
                  ),
                if (clanInfo.location?.name != null &&
                    clanInfo.location!.countryCode != null)
                  ImageChip(
                    imageUrl: ImageAssets.flag(clanInfo.location!.countryCode!),
                    label: clanInfo.location!.name,
                  ),
                IconChip(
                    icon: Icons.groups,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                    label: "${clanInfo.members}/50"),
                ImageChip(
                  imageUrl: ImageAssets.trophies,
                  label: NumberFormat('#,###').format(clanInfo.clanPoints),
                ),
                ImageChip(
                  imageUrl: ImageAssets.attacks,
                  label:
                      NumberFormat('#,###').format(clanInfo.clanCapitalPoints),
                ),
                if (clanInfo.requiredTownhallLevel > 0)
                  ImageChip(
                    imageUrl:
                        ImageAssets.townHall(clanInfo.requiredTownhallLevel),
                    label: clanInfo.requiredTownhallLevel.toString(),
                  ),
                IconChip(
                  icon: Icons.mail,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                  label: () {
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
                  }(),
                ),
                ImageChip(
                  imageUrl: ImageAssets.war,
                  label: () {
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
                  }(),
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
            if (clanInfo.warCwl != null && clanInfo.warCwl!.isInWar)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  shadowColor: Theme.of(context).colorScheme.secondary,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WarScreen(
                        war: clanInfo.warCwl!.warInfo,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CachedNetworkImage(
                        placeholder: (context, url) =>
                            CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                        width: 20,
                        imageUrl:
                            "https://assets.clashk.ing/icons/Icon_DC_War.png",
                      ),
                      SizedBox(width: 8),
                      Shimmer.fromColors(
                        period: Duration(seconds: 3),
                        baseColor: Colors.white,
                        highlightColor: Colors.white.withValues(alpha: 0.4),
                        child: Text(AppLocalizations.of(context)!.ongoingWar,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
              ),
            if (clanInfo.warCwl != null && clanInfo.warCwl!.isInCwl)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  shadowColor: Theme.of(context).colorScheme.secondary,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CwlScreen(
                        warCwl: clanInfo.warCwl!,
                        clanTag: clanInfo.tag,
                        clanInfo: clanInfo.warCwl!.leagueInfo!.clans.firstWhere(
                          (clan) => clan.tag == clanInfo.tag,
                        ),
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CachedNetworkImage(
                        placeholder: (context, url) =>
                            CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                        width: 20,
                        imageUrl:
                            "https://assets.clashk.ing/icons/Icon_DC_War.png",
                      ),
                      SizedBox(width: 8),
                      Shimmer.fromColors(
                        period: Duration(seconds: 3),
                        baseColor: Colors.white,
                        highlightColor: Colors.white.withValues(alpha: 0.4),
                        child: Text(AppLocalizations.of(context)!.ongoingCwl,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
              ),
            if (clanInfo.warCwl != null && clanInfo.warCwl!.isInCwl)
              const SizedBox(height: 16),
          ],
        ),
      ],
    );
  }
}
