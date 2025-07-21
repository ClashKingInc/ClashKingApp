import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/common/widgets/buttons/chip.dart';
import 'package:clashkingapp/common/widgets/buttons/war_button.dart';
import 'package:clashkingapp/common/widgets/dialogs/snackbar.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/common/widgets/dialogs/open_clash_dialog.dart';
import 'package:clashkingapp/features/war_cwl/presentation/cwl/cwl.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war/war.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war_stats/war_stats_page.dart';
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
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: <Widget>[
              _buildBackgroundImage(),
              _buildBackButton(context),
              _buildClanBadge(),
              _buildAction(context),
            ],
          ),
          SizedBox(height: 46),
          _buildClanTitleSection(context, loc),
          const SizedBox(height: 12),
          _buildClanChips(context, loc),
          const SizedBox(height: 8),
          _buildDescription(context),
          const SizedBox(height: 16),
          _buildWarButtons(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage() {
    return SizedBox(
      height: 190,
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
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Positioned(
      top: 40,
      left: 10,
      child: IconButton(
        icon: Icon(Icons.arrow_back,
            size: 32, color: Theme.of(context).colorScheme.onPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildClanBadge() {
    return Positioned(
      bottom: -52,
      child: CachedNetworkImage(
        errorWidget: (context, url, error) => Icon(Icons.error),
        imageUrl: clanInfo.badgeUrls.large,
        width: 150,
      ),
    );
  }

  Widget _buildClanTitleSection(BuildContext context, AppLocalizations loc) {
    return Column(
      children: [
        Text(clanInfo.name, style: Theme.of(context).textTheme.titleLarge),
        GestureDetector(
          onTap: () {
            FlutterClipboard.copy(clanInfo.tag).then((_) {
              if (context.mounted) {
                showClipboardSnackbar(
                  context,
                  AppLocalizations.of(context)!.generalCopiedToClipboard,
                );
              }
            });
          },
          child: Text(
            clanInfo.tag,
            style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
          ),
        ),
      ],
    );
  }

  Widget _buildClanChips(BuildContext context, AppLocalizations loc) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: [
        if (clanInfo.warLeague != null)
          ImageChip(
            context: context,
            imageUrl:
                ImageAssets.leagues[clanInfo.warLeague?.name ?? "Unranked"]!,
            label: clanInfo.warLeague!.name,
          ),
        if (clanInfo.location?.name != null &&
            clanInfo.location!.countryCode != null)
          ImageChip(
            context: context,
            imageUrl: ImageAssets.flag(clanInfo.location!.countryCode!),
            label: clanInfo.location!.name,
          ),
        IconChip(
            icon: Icons.groups,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface,
            label: "${clanInfo.members}/50"),
        ImageChip(
          context: context,
          imageUrl: ImageAssets.trophies,
          label: NumberFormat('#,###').format(clanInfo.clanPoints),
        ),
        ImageChip(
          context: context,
          imageUrl: ImageAssets.capitalTrophy,
          label: NumberFormat('#,###').format(clanInfo.clanCapitalPoints),
        ),
        if (clanInfo.requiredTownhallLevel > 0)
          ImageChip(
            context: context,
            imageUrl: ImageAssets.townHall(clanInfo.requiredTownhallLevel),
            label: clanInfo.requiredTownhallLevel.toString(),
          ),
        IconChip(
          icon: Icons.mail,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface,
          label: () {
            switch (clanInfo.type) {
              case 'inviteOnly':
                return loc.clanInviteOnly;
              case 'open':
                return loc.clanOpened;
              case 'closed':
                return loc.clanClosed;
              default:
                return clanInfo.type;
            }
          }(),
        ),
        ImageChip(
          context: context,
          imageUrl: ImageAssets.war,
          label: () {
            switch (clanInfo.warFrequency) {
              case 'always':
                return loc.clanWarFrequencyAlways;
              case 'never':
                return loc.clanWarFrequencyNever;
              case 'oncePerWeek':
                return loc.clanWarFrequencyOncePerWeek;
              case 'moreThanOncePerWeek':
                return loc.clanWarFrequencyMoreThanOncePerWeek;
              case 'lessThanOncePerWeek':
                return loc.clanWarFrequencyRarely;
              default:
                return loc.clanWarFrequencyUnknown;
            }
          }(),
        ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        clanInfo.description,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
        maxLines: 7,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildWarButtons(BuildContext context) {
    return Column(
      children: [
        if (clanInfo.warCwl != null && clanInfo.warCwl!.isInWar)
          _buildWarButton(context),
        if (clanInfo.warCwl != null && clanInfo.warCwl!.isInCwl) ...[
          _buildCwlButton(context),
          const SizedBox(height: 16),
        ]
      ],
    );
  }

  Widget _buildWarButton(BuildContext context) {
    return buildWarButton(context, onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WarScreen(war: clanInfo.warCwl!.warInfo),
        ),
      );
    },
        label: clanInfo.warCwl!.warInfo.state == "preparation"
            ? AppLocalizations.of(context)!.warPreparation
            : clanInfo.warCwl!.warInfo.state == "inWar"
                ? AppLocalizations.of(context)!.warOngoing
                : AppLocalizations.of(context)!.warEnded);
  }

  Widget _buildCwlButton(BuildContext context) {
    return buildWarButton(
      context,
      onTap: () {
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
      label: AppLocalizations.of(context)!.cwlOngoing,
    );
  }

  String? extractDiscordCode(String description) {
    final cleaned = description.replaceAll(RegExp(r'[\s\n\r]'), ' ');
    final RegExp discordPattern = RegExp(
      r"(?:https?:\/\/)?(?:discord\.com\/invite\/|discord\.gg\/)([a-zA-Z0-9]+)",
    );
    final match = discordPattern.firstMatch(cleaned);
    return match?.group(1);
  }

  Widget _buildAction(BuildContext context) {
    return Positioned(
      top: 40,
      right: 10,
      child: Row(
        children: [
          if (clanInfo.description.contains("discord.gg") ||
              clanInfo.description.contains("discord.com"))
            IconButton(
              icon: const Icon(Icons.discord, color: Colors.white, size: 28),
              onPressed: () async {
                try {
                  final code = extractDiscordCode(clanInfo.description);
                  if (code != null) {
                    final url = Uri.parse('https://discord.gg/\$code');
                    if (!await launchUrl(url) && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(AppLocalizations.of(context)!
                                .errorCannotOpenLink)),
                      );
                    }
                  }
                } catch (e, st) {
                  Sentry.captureException(e, stackTrace: st);
                }
              },
            ),
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
                  context: context, builder: (_) => OpenClashDialog(url: url));
            },
          ),
          IconButton(
            icon: Icon(Icons.more_vert_rounded,
                color: Theme.of(context).colorScheme.onPrimary, size: 32),
            onPressed: () {
              showMenu(
                context: context,
                position: RelativeRect.fromLTRB(100, 100, 0, 0),
                items: [
                  PopupMenuItem(
                    value: 'Stats',
                    child: Row(
                      children: [
                        MobileWebImage(
                            imageUrl: clanInfo.badgeUrls.small, width: 20),
                        SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.generalStats),
                      ],
                    ),
                  ),
                ],
              ).then((value) {
                if (value == 'Stats') {
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ClanWarStatsScreen(clan: clanInfo),
                      ),
                    );
                  }
                }
              });
            },
          ),
        ],
      ),
    );
  }
}
