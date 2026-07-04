import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/common/widgets/dialogs/open_clash_dialog.dart';
import 'package:clashkingapp/common/widgets/dialogs/snackbar.dart';
import 'package:clashkingapp/common/widgets/header_widgets.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/bookmark_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/war_cwl/presentation/cwl/cwl.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war/war.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ClanInfoHeaderCard extends StatelessWidget {
  final Clan clanInfo;

  const ClanInfoHeaderCard({super.key, required this.clanInfo});

  @override
  Widget build(BuildContext context) {
    return _buildHero(context);
  }

  /// Hero header: backdrop image with scrim, floating actions, identity
  /// row and a content-sized stats card straddling the image edge — same
  /// pattern as the player page.
  Widget _buildHero(BuildContext context) {
    // The stats card height varies (chips + description), so the image
    // stops at a fixed distance from the top instead of tracking the
    // column bottom: it ends partway through the card.
    final imageHeight = MediaQuery.of(context).padding.top + 280;

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: imageHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.50),
                  BlendMode.darken,
                ),
                child: CachedNetworkImage(
                  imageUrl: ImageAssets.clanPageBackground,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) =>
                      ColoredBox(color: Theme.of(context).colorScheme.surface),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.36),
                      Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.64),
                      Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.92),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildTopActions(context),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildIdentity(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  _ClanLeagueSummaryTile(clanInfo: clanInfo),
                  const SizedBox(height: 8),
                  _buildStatsPanel(context),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopActions(BuildContext context) {
    final warCwl = clanInfo.warCwl;
    final hasDiscord =
        clanInfo.description.contains("discord.gg") ||
        clanInfo.description.contains("discord.com");

    return Row(
      children: [
        HeaderIconButton(
          icon: Icons.arrow_back_rounded,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onTap: () => Navigator.of(context).pop(),
        ),
        const Spacer(),
        // One war entry point: CWL wins over regular war since the CWL
        // screen also exposes the current round's war.
        if (warCwl != null && warCwl.isInCwl) ...[
          HeaderIconButton(
            imageUrl: ImageAssets.cwlSwordsNoBorder,
            tooltip: AppLocalizations.of(context)!.cwlOngoing,
            onTap: () => _openCwl(context),
          ),
          const SizedBox(width: 8),
        ] else if (warCwl != null && warCwl.isInWar) ...[
          HeaderIconButton(
            imageUrl: ImageAssets.war,
            tooltip: AppLocalizations.of(context)!.warOngoing,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WarScreen(war: warCwl.warInfo),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (hasDiscord) ...[
          HeaderIconButton(
            icon: Icons.discord,
            tooltip: 'Discord',
            onTap: () => _openDiscord(context),
          ),
          const SizedBox(width: 8),
        ],
        HeaderIconButton(
          icon: Icons.open_in_new_rounded,
          tooltip: 'Open in game',
          onTap: () {
            final lang = Localizations.localeOf(context).languageCode;
            final url = Uri.https('link.clashofclans.com', '/$lang', {
              'action': 'OpenClanProfile',
              'tag': clanInfo.tag,
            });
            showDialog(
              context: context,
              builder: (_) => OpenClashDialog(url: url),
            );
          },
        ),
        const SizedBox(width: 8),
        Consumer<BookmarkService>(
          builder: (context, bookmarks, child) {
            final bookmarked = bookmarks.isClanBookmarked(clanInfo.tag);
            return HeaderIconButton(
              icon: bookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              tooltip: bookmarked ? 'Remove bookmark' : 'Bookmark clan',
              onTap: () => bookmarks.toggleClan(clanInfo),
            );
          },
        ),
      ],
    );
  }

  Widget _buildIdentity(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: CachedNetworkImage(
            imageUrl: clanInfo.badgeUrls.large,
            width: 56,
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                clanInfo.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () {
                      FlutterClipboard.copy(clanInfo.tag).then((_) {
                        if (context.mounted) {
                          showClipboardSnackbar(
                            context,
                            AppLocalizations.of(
                              context,
                            )!.generalCopiedToClipboard,
                          );
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text(
                        clanInfo.tag,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.62),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (clanInfo.location?.name != null) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.32),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (clanInfo.location?.countryCode != null) ...[
                              MobileWebImage(
                                imageUrl: ImageAssets.flag(
                                  clanInfo.location!.countryCode!,
                                ),
                                width: 13,
                                height: 13,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Flexible(
                              child: Text(
                                clanInfo.location!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsPanel(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat('#,###', locale);
    final typeLabel = switch (clanInfo.type) {
      'inviteOnly' => loc.clanInviteOnly,
      'open' => loc.clanOpened,
      'closed' => loc.generalClosed,
      _ => clanInfo.type,
    };
    final warFrequencyLabel = switch (clanInfo.warFrequency) {
      'always' => loc.clanWarFrequencyAlways,
      'never' => loc.clanWarFrequencyNever,
      'oncePerWeek' => loc.clanWarFrequencyOncePerWeek,
      'moreThanOncePerWeek' => loc.clanWarFrequencyMoreThanOncePerWeek,
      'lessThanOncePerWeek' => loc.clanWarFrequencyRarely,
      _ => loc.generalUnknown,
    };

    return Stack(
      children: [
        const Positioned.fill(
          child: HeaderPanelBackground(height: 240, cornerRadius: 28),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Same icon + label + colored value language as the metric
              // bars, laid out two per row at equal width so a variable
              // chip count (some are conditional) doesn't wrap raggedly.
              MetricChipGrid(
                columns: 3,
                chips: [
                  // Already covered by the W·T·L summary above when the war
                  // log is public — only show it here as a standalone stat
                  // when that fuller summary isn't available.
                  if (!clanInfo.isWarLogPublic)
                    MetricChip(
                      label: loc.clanWarWinsTitle,
                      value: formatter.format(clanInfo.warWins),
                      imageUrl: ImageAssets.war,
                      color: const Color(0xFFE8A524),
                    ),
                  MetricChip(
                    label: loc.clanWinStreakTitle,
                    value: formatter.format(clanInfo.warWinStreak),
                    icon: Icons.local_fire_department_rounded,
                    color: const Color(0xFFE35D4F),
                  ),
                  MetricChip(
                    label: loc.playerCapitalTitle,
                    value: formatter.format(clanInfo.clanCapitalPoints),
                    imageUrl: ImageAssets.capitalTrophy,
                    color: const Color(0xFF8D63D9),
                  ),
                  MetricChip(
                    label: loc.clanBuilderBaseTitle,
                    value: formatter.format(clanInfo.clanBuilderBasePoints),
                    imageUrl: ImageAssets.builderBaseStar,
                    color: const Color(0xFF2A9FD6),
                  ),
                  if (clanInfo.requiredTrophies > 0)
                    MetricChip(
                      label: loc.clanMinTrophiesTitle,
                      value: NumberFormat.compact().format(
                        clanInfo.requiredTrophies,
                      ),
                      imageUrl: ImageAssets.trophies,
                    ),
                  MetricChip(
                    label: loc.clanWarFrequencyTitle,
                    value: warFrequencyLabel,
                    icon: Icons.event_repeat_rounded,
                  ),
                  if (clanInfo.requiredTownhallLevel > 0)
                    MetricChip(
                      label: loc.clanMinTownHallTitle,
                      value: '${clanInfo.requiredTownhallLevel}+',
                      imageUrl: ImageAssets.townHall(
                        clanInfo.requiredTownhallLevel,
                      ),
                    ),
                  MetricChip(
                    label: loc.clanTypeTitle,
                    value: typeLabel,
                    icon: Icons.mail_rounded,
                  ),
                ],
              ),
              if (clanInfo.description.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    clanInfo.description,
                    textAlign: TextAlign.start,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _openCwl(BuildContext context) {
    final warCwl = clanInfo.warCwl;
    final leagueInfo = warCwl?.leagueInfo;
    if (warCwl == null || leagueInfo == null || leagueInfo.clans.isEmpty) {
      return;
    }
    final cwlClanInfo = leagueInfo.clans.firstWhere(
      (clan) => clan.tag == clanInfo.tag,
      orElse: () => leagueInfo.clans.first,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CwlScreen(
          warCwl: warCwl,
          clanTag: clanInfo.tag,
          clanInfo: cwlClanInfo,
        ),
      ),
    );
  }

  Future<void> _openDiscord(BuildContext context) async {
    try {
      final code = _extractDiscordCode(clanInfo.description);
      if (code == null) return;
      final url = Uri.parse('https://discord.gg/$code');
      if (!await launchUrl(url) && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorCannotOpenLink),
          ),
        );
      }
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
    }
  }

  String? _extractDiscordCode(String description) {
    final cleaned = description.replaceAll(RegExp(r'[\s\n\r]'), ' ');
    final RegExp discordPattern = RegExp(
      r"(?:https?:\/\/)?(?:discord\.com\/invite\/|discord\.gg\/)([a-zA-Z0-9]+)",
    );
    final match = discordPattern.firstMatch(cleaned);
    return match?.group(1);
  }
}

/// Featured league tile — same recipe as the player header's
/// `_LeagueSummaryTile`: a floating glass card tinted with the dominant
/// color sampled from the war league badge, war points as the headline
/// number, members/W-T-L as the secondary metric.
class _ClanLeagueSummaryTile extends StatefulWidget {
  final Clan clanInfo;

  const _ClanLeagueSummaryTile({required this.clanInfo});

  @override
  State<_ClanLeagueSummaryTile> createState() => _ClanLeagueSummaryTileState();
}

class _ClanLeagueSummaryTileState extends State<_ClanLeagueSummaryTile> {
  static final Map<String, Color> _tintCache = {};
  Color? _tint;

  String get _leagueUrl => ImageAssets.getWarLeagueImage(
    widget.clanInfo.warLeague?.name ?? 'Unranked',
  );

  @override
  void initState() {
    super.initState();
    _loadTint();
  }

  @override
  void didUpdateWidget(covariant _ClanLeagueSummaryTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clanInfo.warLeague?.name != widget.clanInfo.warLeague?.name) {
      _loadTint();
    }
  }

  Future<void> _loadTint() async {
    final leagueUrl = _leagueUrl;

    final cachedTint = _tintCache[leagueUrl];
    if (cachedTint != null) {
      if (mounted) setState(() => _tint = cachedTint);
      return;
    }

    if (mounted) setState(() => _tint = null);

    try {
      final provider = CachedNetworkImageProvider(leagueUrl);
      final stream = provider.resolve(ImageConfiguration.empty);
      late final ImageStreamListener listener;
      final completer = Completer<ImageInfo>();

      listener = ImageStreamListener(
        (imageInfo, synchronousCall) {
          if (!completer.isCompleted) completer.complete(imageInfo);
          stream.removeListener(listener);
        },
        onError: (error, stackTrace) {
          if (!completer.isCompleted) {
            completer.completeError(error, stackTrace);
          }
          stream.removeListener(listener);
        },
      );
      stream.addListener(listener);

      final imageInfo = await completer.future;
      final tint = await dominantTintFromImage(imageInfo.image);
      if (tint == null) return;

      _tintCache[leagueUrl] = tint;
      if (mounted && _leagueUrl == leagueUrl) {
        setState(() => _tint = tint);
      }
    } catch (_) {
      // Keep the glass neutral if the remote badge cannot be sampled.
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat('#,###', locale);
    final clanInfo = widget.clanInfo;
    final warLeagueName = clanInfo.warLeague?.name ?? 'Unranked';

    return GlassPanel(
      width: double.infinity,
      height: 75,
      borderRadius: 16,
      padding: const EdgeInsets.all(12),
      tint: _tint,
      child: Row(
        children: [
          MobileWebImage(imageUrl: _leagueUrl, width: 46, height: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  warLeagueName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatter.format(clanInfo.clanPoints),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.groups_rounded,
                    size: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${clanInfo.members}/50',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (clanInfo.isWarLogPublic) ...[
                const SizedBox(height: 4),
                Text(
                  '${clanInfo.warWins}W · ${clanInfo.warTies}T · ${clanInfo.warLosses}L',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.58),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
