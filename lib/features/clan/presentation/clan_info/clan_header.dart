import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/common/widgets/dialogs/open_clash_dialog.dart';
import 'package:clashkingapp/common/widgets/dialogs/snackbar.dart';
import 'package:clashkingapp/common/widgets/header_widgets.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/bookmark_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/clan/models/clan_league.dart';
import 'package:clashkingapp/features/war_cwl/presentation/cwl/cwl.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war/war.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war_stats/war_stats_page.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ClanInfoHeaderCard extends StatefulWidget {
  final Clan clanInfo;
  final bool showTopActions;

  const ClanInfoHeaderCard({
    super.key,
    required this.clanInfo,
    this.showTopActions = true,
  });

  @override
  State<ClanInfoHeaderCard> createState() => _ClanInfoHeaderCardState();
}

class _ClanInfoHeaderCardState extends State<ClanInfoHeaderCard> {
  bool _descriptionExpanded = false;

  Clan get clanInfo => widget.clanInfo;

  @override
  void didUpdateWidget(covariant ClanInfoHeaderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clanInfo.tag != widget.clanInfo.tag) {
      _descriptionExpanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildHero(context);
  }

  /// Hero header: backdrop image, floating actions, identity row, and clan
  /// summary content.
  Widget _buildHero(BuildContext context) {
    final imageHeight = MediaQuery.of(context).padding.top + 500;

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
                  imageUrl: ImageAssets.homeBaseBackground,
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
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
            SizedBox(height: MediaQuery.of(context).padding.top),
            if (widget.showTopActions)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildTopActions(context),
              )
            else
              const SizedBox(height: 42),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildIdentity(context),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 11, bottom: 8),
              child: _buildStatsPanel(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopActions(BuildContext context) {
    return ClanInfoHeaderActions(clanInfo: clanInfo);
  }

  Widget _buildIdentity(BuildContext context) {
    final location = clanInfo.location;
    final flagUrl = location?.countryCode != null
        ? ImageAssets.flag(location!.countryCode!)
        : null;
    final hasDescription = clanInfo.description.trim().isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CachedNetworkImage(
                  imageUrl: clanInfo.badgeUrls.large,
                  width: 94,
                  height: 94,
                  fit: BoxFit.contain,
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
                const SizedBox(height: 2),
                Text(
                  clanInfo.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  // Always white: sits on the darkened backdrop image.
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    height: 1.02,
                  ),
                ),
                const SizedBox(height: 2),
                _CopyableClanTag(tag: clanInfo.tag),
                if (location?.name != null ||
                    clanInfo.labels.isNotEmpty ||
                    hasDescription)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (location?.name != null) ...[
                        if (flagUrl != null) ...[
                          MobileWebImage(
                            imageUrl: flagUrl,
                            width: 16,
                            height: 16,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            location!.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  height: 1.05,
                                ),
                          ),
                        ),
                      ],
                      if (clanInfo.labels.isNotEmpty) ...[
                        Padding(
                          padding: EdgeInsets.only(
                            left: location?.name != null ? 7 : 0,
                            right: 7,
                          ),
                          child: Text(
                            '|',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.30),
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                        _ClanLabelIcons(labels: clanInfo.labels.take(3)),
                      ],
                      if (hasDescription) ...[
                        const SizedBox(width: 4),
                        _DescriptionToggleDots(
                          expanded: _descriptionExpanded,
                          onTap: () => setState(
                            () => _descriptionExpanded = !_descriptionExpanded,
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsPanel(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final warLeagueName = clanInfo.warLeague?.name ?? 'Unranked';
    final warLeagueUrl = ImageAssets.getWarLeagueImage(warLeagueName);
    final capitalLeague = clanInfo.capitalLeague;
    final capitalLeagueName = capitalLeague?.name ?? 'Unranked';
    final capitalLeagueUrl = capitalLeague == null
        ? ImageAssets.capitalTrophy
        : ImageAssets.getCapitalLeagueImage(capitalLeague.name);
    final typeLabel = switch (clanInfo.type) {
      'inviteOnly' => loc.clanInviteOnly,
      'open' => loc.clanOpened,
      'closed' => loc.generalClosed,
      _ => clanInfo.type,
    };
    final compactWarLeague = _compactLeagueName(warLeagueName);
    final compactCapitalLeague = _compactLeagueName(capitalLeagueName);
    final description = clanInfo.description.trim();
    const familyLabel = 'Family-friendly';

    return Column(
      children: [
        if (description.isNotEmpty && _descriptionExpanded) ...[
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 19),
            child: _ExpandableDescription(description: description),
          ),
          const SizedBox(height: 8),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _ClanChipRows(
            children: [
              _ClanQuickChip(
                value: _plainNumber(clanInfo.clanPoints),
                imageUrl: ImageAssets.trophies,
                tooltip: 'Clan points',
              ),
              _ClanQuickChip(
                value: '${clanInfo.members}/50',
                icon: Icons.groups_rounded,
                tooltip: 'Members',
              ),
              _ClanQuickChip(
                value: _plainNumber(clanInfo.clanBuilderBasePoints),
                imageUrl: ImageAssets.builderBaseTrophy,
                tooltip: 'Builder base points',
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _ClanChipRows(
            children: [
              _ClanQuickChip(
                value: compactWarLeague,
                imageUrl: warLeagueUrl,
                tooltip: 'CWL league: $warLeagueName',
                gradientColors: _leagueChipGradient(warLeagueName),
              ),
              _ClanQuickChip(
                value: _plainNumber(clanInfo.clanCapitalPoints),
                imageUrl: ImageAssets.capitalTrophy,
                tooltip: 'Clan Capital points',
              ),
              _ClanQuickChip(
                value: compactCapitalLeague,
                imageUrl: capitalLeagueUrl,
                tooltip: 'Clan Capital league: $capitalLeagueName',
                gradientColors: _leagueChipGradient(capitalLeagueName),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _ClanChipRows(
            children: [
              _ClanQuickChip(
                value: typeLabel,
                icon: Icons.mail_rounded,
                tooltip: 'Clan type',
              ),
              if (clanInfo.requiredTownhallLevel > 0)
                _ClanQuickChip(
                  value: '${clanInfo.requiredTownhallLevel}+ only',
                  imageUrl: ImageAssets.townHall(
                    clanInfo.requiredTownhallLevel,
                  ),
                  tooltip: 'Required Town Hall',
                ),
              if (clanInfo.isFamilyFriendly)
                const _ClanQuickChip(
                  value: familyLabel,
                  icon: Icons.family_restroom_rounded,
                  tooltip: familyLabel,
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _plainNumber(int value) => value.toString();

  String _compactLeagueName(String leagueName) {
    return leagueName
        .replaceAll(' League', '')
        .replaceAll('Unranked', 'Unranked')
        .trim();
  }

  List<Color> _leagueChipGradient(String leagueName) {
    final lower = leagueName.toLowerCase();
    final primary = switch (lower) {
      final name when name.contains('legend') => const Color(0xFF7A2DFF),
      final name when name.contains('titan') => const Color(0xFFFF5A45),
      final name when name.contains('champion') => const Color(0xFFE24B6B),
      final name when name.contains('master') => const Color(0xFFC6A46E),
      final name when name.contains('crystal') => const Color(0xFF9E54FF),
      final name when name.contains('gold') => const Color(0xFFE2AC32),
      final name when name.contains('silver') => const Color(0xFF9DA7B7),
      final name when name.contains('bronze') => const Color(0xFFB06934),
      _ => const Color(0xFF6B7280),
    };
    final accent = switch (lower) {
      final name when name.contains('legend') => const Color(0xFFFF42D6),
      final name when name.contains('titan') => const Color(0xFF2A1F25),
      final name when name.contains('champion') => const Color(0xFFFFB341),
      final name when name.contains('master') => const Color(0xFF2D2520),
      final name when name.contains('crystal') => const Color(0xFF382467),
      final name when name.contains('gold') => const Color(0xFF4A2D09),
      final name when name.contains('silver') => const Color(0xFF343A46),
      final name when name.contains('bronze') => const Color(0xFF3D2318),
      _ => const Color(0xFF20242A),
    };

    return [
      primary.withValues(alpha: 0.78),
      accent.withValues(alpha: 0.58),
      primary.withValues(alpha: 0.38),
    ];
  }
}

class ClanInfoHeaderActions extends StatelessWidget {
  final Clan clanInfo;

  const ClanInfoHeaderActions({super.key, required this.clanInfo});

  @override
  Widget build(BuildContext context) {
    final warCwl = clanInfo.warCwl;
    final hasCwl = warCwl?.leagueInfo?.clans.isNotEmpty == true;
    final hasDiscord =
        clanInfo.description.contains("discord.gg") ||
        clanInfo.description.contains("discord.com");

    return Row(
      children: [
        HeaderIconButton(
          icon: Icons.arrow_back_rounded,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onTap: () => Navigator.of(context).pop(),
          showBackground: false,
        ),
        const Spacer(),
        if (warCwl != null && (warCwl.isInCwl || hasCwl)) ...[
          HeaderIconButton(
            imageUrl: ImageAssets.cwlSwordsNoBorder,
            tooltip: AppLocalizations.of(context)!.cwlOngoing,
            onTap: () => _openCwl(context),
            showBackground: false,
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
            showBackground: false,
          ),
          const SizedBox(width: 8),
        ],
        if (hasDiscord) ...[
          HeaderIconButton(
            icon: Icons.discord,
            tooltip: 'Discord',
            onTap: () => _openDiscord(context),
            showBackground: false,
          ),
          const SizedBox(width: 8),
        ],
        HeaderIconButton(
          icon: Icons.bar_chart_rounded,
          tooltip: AppLocalizations.of(context)!.generalStats,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClanWarStatsScreen(clan: clanInfo),
            ),
          ),
          showBackground: false,
        ),
        const SizedBox(width: 8),
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
          showBackground: false,
        ),
        const SizedBox(width: 8),
        Consumer<BookmarkService>(
          builder: (context, bookmarks, child) {
            final bookmarked = bookmarks.isClanBookmarked(clanInfo.tag);
            return HeaderIconButton(
              icon: bookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              iconColor: bookmarked ? const Color(0xFF2F8CFF) : null,
              tooltip: bookmarked ? 'Remove bookmark' : 'Bookmark clan',
              onTap: () => bookmarks.toggleClan(clanInfo),
              showBackground: false,
            );
          },
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

class _CopyableClanTag extends StatelessWidget {
  final String tag;

  const _CopyableClanTag({required this.tag});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () {
        FlutterClipboard.copy(tag).then((_) {
          if (context.mounted) {
            showClipboardSnackbar(
              context,
              AppLocalizations.of(context)!.generalCopiedToClipboard,
            );
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Text(
          tag,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.62),
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.05,
          ),
        ),
      ),
    );
  }
}

class _ClanLabelIcons extends StatelessWidget {
  final Iterable<ClanLeague> labels;

  const _ClanLabelIcons({required this.labels});

  @override
  Widget build(BuildContext context) {
    final labelList = labels.toList(growable: false);
    if (labelList.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: labelList
          .map((label) {
            final imageUrl =
                label.smallIconUrl ?? label.mediumIconUrl ?? label.tinyIconUrl;
            return Padding(
              padding: const EdgeInsets.only(right: 3),
              child: Tooltip(
                message: label.name,
                child: imageUrl == null
                    ? Icon(
                        Icons.label_rounded,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.76),
                      )
                    : MobileWebImage(imageUrl: imageUrl, width: 16, height: 16),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _DescriptionToggleDots extends StatelessWidget {
  final bool expanded;
  final VoidCallback onTap;

  const _DescriptionToggleDots({required this.expanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: expanded ? 'Hide description' : 'Show description',
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
          child: Icon(
            Icons.more_horiz_rounded,
            size: 18,
            color: Colors.white.withValues(alpha: expanded ? 0.95 : 0.68),
          ),
        ),
      ),
    );
  }
}

class _ExpandableDescription extends StatelessWidget {
  final String description;

  const _ExpandableDescription({required this.description});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      height: 1.13,
    );

    return Text(
      description,
      textAlign: TextAlign.center,
      softWrap: true,
      style: textStyle,
    );
  }
}

class _ClanChipRows extends StatelessWidget {
  final List<_ClanQuickChip> children;

  const _ClanChipRows({required this.children});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 7.0;
        final widths = children
            .map((child) => child.estimatedWidth(context))
            .toList(growable: false);
        final rowPlans = _candidatePlans(children.length);

        for (final plan in rowPlans) {
          if (_planFits(plan, widths, spacing, constraints.maxWidth)) {
            return Column(children: _buildRows(plan, spacing));
          }
        }

        return Wrap(
          alignment: WrapAlignment.center,
          spacing: spacing,
          runSpacing: 7,
          children: children,
        );
      },
    );
  }

  List<List<int>> _candidatePlans(int count) {
    if (count >= 8) {
      final rows = <List<int>>[];
      for (var firstRow = 4; firstRow >= 2; firstRow--) {
        final plan = <int>[];
        var remaining = count;
        while (remaining > 0) {
          final row = remaining == 1 && plan.isNotEmpty
              ? 2
              : remaining >= firstRow
              ? firstRow
              : remaining;
          if (row == 2 && remaining == 1 && plan.isNotEmpty) {
            plan[plan.length - 1] -= 1;
            remaining += 1;
            continue;
          }
          plan.add(row);
          remaining -= row;
        }
        if (plan.every((row) => row > 1 || count == 1)) {
          rows.add(plan);
        }
      }
      return rows;
    }

    return switch (count) {
      7 => const [
        [4, 3],
        [3, 4],
        [3, 2, 2],
        [2, 3, 2],
      ],
      6 => const [
        [4, 2],
        [3, 3],
        [2, 2, 2],
      ],
      5 => const [
        [3, 2],
        [2, 3],
      ],
      4 => const [
        [4],
        [2, 2],
      ],
      3 => const [
        [3],
      ],
      2 => const [
        [2],
      ],
      _ => [
        [count],
      ],
    };
  }

  bool _planFits(
    List<int> plan,
    List<double> widths,
    double spacing,
    double maxWidth,
  ) {
    var start = 0;
    for (final rowLength in plan) {
      final rowWidth =
          widths.skip(start).take(rowLength).fold<double>(0, (a, b) => a + b) +
          spacing * (rowLength - 1);
      if (rowWidth > maxWidth) return false;
      start += rowLength;
    }
    return start == widths.length;
  }

  List<Widget> _buildRows(List<int> plan, double spacing) {
    final rows = <Widget>[];
    var start = 0;

    for (var i = 0; i < plan.length; i++) {
      final rowLength = plan[i];
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: children.skip(start).take(rowLength).expand((child) sync* {
            if (child != children[start]) {
              yield SizedBox(width: spacing);
            }
            yield child;
          }).toList(),
        ),
      );
      if (i != plan.length - 1) {
        rows.add(const SizedBox(height: 7));
      }
      start += rowLength;
    }

    return rows;
  }
}

class _ClanQuickChip extends StatelessWidget {
  final String value;
  final String? imageUrl;
  final IconData? icon;
  final String? tooltip;
  final List<Color>? gradientColors;

  const _ClanQuickChip({
    required this.value,
    this.imageUrl,
    this.icon,
    this.tooltip,
    this.gradientColors,
  });

  double estimatedWidth(BuildContext context) {
    final textStyle = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, height: 1);
    final painter = TextPainter(
      text: TextSpan(text: value, style: textStyle),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout();
    return 20 + 19 + 5 + painter.width;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = colorScheme.onSurface;

    final chipBody = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(999),
        border: gradientColors == null
            ? Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.18),
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageUrl != null && imageUrl!.isNotEmpty)
            MobileWebImage(imageUrl: imageUrl!, width: 19, height: 19)
          else
            Icon(icon ?? Icons.info_rounded, size: 19, color: foreground),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 132),
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );

    final chip = gradientColors == null
        ? chipBody
        : Container(
            padding: const EdgeInsets.all(1.2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors!,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: chipBody,
          );

    if (tooltip == null || tooltip!.isEmpty) return chip;
    return Tooltip(message: tooltip!, child: chip);
  }
}
