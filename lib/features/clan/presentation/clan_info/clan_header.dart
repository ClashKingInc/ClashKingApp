import 'package:clashkingapp/common/widgets/dialogs/open_clash_dialog.dart';
import 'package:clashkingapp/common/widgets/dialogs/snackbar.dart';
import 'package:clashkingapp/common/widgets/header_widgets.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/bookmark_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/clan/models/clan_league.dart';
import 'package:clashkingapp/features/clan/presentation/clan_capital/clan_capital_page.dart';
import 'package:clashkingapp/features/war_cwl/presentation/cwl/cwl.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war/war.dart';
import 'package:flutter/foundation.dart';
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
    final media = MediaQuery.of(context);
    final isDesktopWeb = kIsWeb && media.size.width >= 900;
    final imageHeight = media.padding.top + (isDesktopWeb ? 292 : 500);
    final headerMaxWidth = isDesktopWeb ? 1120.0 : double.infinity;

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
                child: MobileWebImage(
                  imageUrl: ImageAssets.homeBaseBackground,
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                  errorWidget: (context, url, error) =>
                      ColoredBox(color: Theme.of(context).colorScheme.surface),
                ),
              ),
              // Fixed black, not colorScheme.surface: this scrim's job is
              // to keep darkening the photo toward the bottom so the
              // white-on-photo identity text stays legible. surface flips
              // to near-white in light mode, which un-darkens the image
              // instead — the opposite of what this gradient is for. The
              // peak alpha is lower in light mode: still dark enough for
              // white text, but not the near-black wash dark mode uses.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: Theme.of(context).brightness == Brightness.dark
                        ? const [
                            Color.fromRGBO(0, 0, 0, 0.36),
                            Color.fromRGBO(0, 0, 0, 0.64),
                            Color.fromRGBO(0, 0, 0, 0.92),
                          ]
                        : const [
                            Color.fromRGBO(0, 0, 0, 0.20),
                            Color.fromRGBO(0, 0, 0, 0.40),
                            Color.fromRGBO(0, 0, 0, 0.65),
                          ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            SizedBox(height: media.padding.top),
            if (widget.showTopActions)
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: headerMaxWidth),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktopWeb ? 20 : 12,
                    ),
                    child: _buildTopActions(context),
                  ),
                ),
              )
            else
              const SizedBox(height: 48),
            if (isDesktopWeb)
              _DesktopClanHeaderPanel(
                descriptionExpanded: _descriptionExpanded,
                onDescriptionToggle: () => setState(
                  () => _descriptionExpanded = !_descriptionExpanded,
                ),
                maxWidth: headerMaxWidth,
              )
            else ...[
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
          ],
        ),
      ],
    );
  }

  Widget _buildTopActions(BuildContext context) {
    return ClanInfoHeaderActions(clanInfo: clanInfo);
  }

  Widget _buildIdentity(
    BuildContext context, {
    bool compact = false,
    bool horizontal = false,
    VoidCallback? onDescriptionToggle,
  }) {
    final location = clanInfo.location;
    final flagUrl = location?.countryCode != null
        ? ImageAssets.flag(location!.countryCode!)
        : null;
    final hasDescription = clanInfo.description.trim().isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktopHorizontal = compact && horizontal;
        final badgeSize = desktopHorizontal ? 104.0 : (compact ? 82.0 : 94.0);
        final badge = MobileWebImage(
          imageUrl: clanInfo.badgeUrls.large,
          width: badgeSize,
          height: badgeSize,
          fit: BoxFit.contain,
          errorWidget: (context, url, error) => const Icon(Icons.error),
        );
        final name = Text(
          clanInfo.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: horizontal ? TextAlign.start : TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontSize: desktopHorizontal ? 26 : (compact ? 24 : 26),
            fontWeight: FontWeight.w700,
            height: 1.02,
          ),
        );
        final meta = _ClanMetaLine(
          locationName: location?.name,
          flagUrl: flagUrl,
          labels: clanInfo.labels.take(3),
          hasDescription: hasDescription,
          expanded: _descriptionExpanded,
          alignment: horizontal
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          onDescriptionToggle:
              onDescriptionToggle ??
              () =>
                  setState(() => _descriptionExpanded = !_descriptionExpanded),
        );

        if (horizontal) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              badge,
              SizedBox(width: desktopHorizontal ? 18 : 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    name,
                    const SizedBox(height: 3),
                    _CopyableClanTag(
                      tag: clanInfo.tag,
                      alignment: TextAlign.start,
                    ),
                    if (location?.name != null ||
                        clanInfo.labels.isNotEmpty ||
                        hasDescription)
                      meta,
                    if (_descriptionExpanded && hasDescription) ...[
                      const SizedBox(height: 6),
                      _ExpandableDescription(
                        description: clanInfo.description.trim(),
                        textAlign: TextAlign.start,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                badge,
                const SizedBox(height: 2),
                name,
                const SizedBox(height: 2),
                _CopyableClanTag(tag: clanInfo.tag),
                if (location?.name != null ||
                    clanInfo.labels.isNotEmpty ||
                    hasDescription)
                  meta,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsPanel(BuildContext context, {bool compact = false}) {
    final description = clanInfo.description.trim();

    return Column(
      mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
      children: [
        if (description.isNotEmpty && _descriptionExpanded) ...[
          Padding(
            padding: EdgeInsets.only(
              left: compact ? 0 : 20,
              right: compact ? 0 : 19,
            ),
            child: _ExpandableDescription(description: description),
          ),
          const SizedBox(height: 8),
        ],
        _buildLeagueTiles(context, compact: compact),
        const SizedBox(height: 8),
        _buildQuickStats(context, compact: compact),
      ],
    );
  }

  Widget _buildLeagueTiles(BuildContext context, {bool compact = false}) {
    final loc = AppLocalizations.of(context)!;
    final warLeagueName = clanInfo.warLeague?.name ?? 'Unranked';
    final warLeagueUrl = ImageAssets.getWarLeagueImage(warLeagueName);
    final capitalLeague = clanInfo.capitalLeague;
    final capitalLeagueName = capitalLeague?.name ?? 'Unranked';
    final capitalLeagueUrl = capitalLeague == null
        ? ImageAssets.capitalTrophy
        : ImageAssets.getCapitalLeagueImage(capitalLeague.name);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: CompactLeagueTile(
              leagueName: _compactLeagueName(warLeagueName),
              subtitle: loc.cwlTitle,
              leagueUrl: warLeagueUrl,
              onTap: clanInfo.warCwl?.leagueInfo?.clans.isNotEmpty == true
                  ? () => openClanCwl(context, clanInfo)
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CompactLeagueTile(
              leagueName: _compactLeagueName(capitalLeagueName),
              subtitle: _plainNumber(clanInfo.clanCapitalPoints),
              subtitleIconUrl: ImageAssets.capitalTrophy,
              leagueUrl: capitalLeagueUrl,
              onTap: () => openClanCapital(context, clanInfo),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(
    BuildContext context, {
    bool compact = false,
    bool combineRows = false,
  }) {
    final loc = AppLocalizations.of(context)!;
    final typeLabel = switch (clanInfo.type) {
      'inviteOnly' => loc.clanInviteOnly,
      'open' => loc.clanOpened,
      'closed' => loc.generalClosed,
      _ => clanInfo.type,
    };
    const familyLabel = 'Family-friendly';
    final primaryChips = [
      _ClanQuickChip(
        value: _plainNumber(clanInfo.clanPoints),
        imageUrl: ImageAssets.trophies,
        tooltip: loc.clanPointsTitle,
      ),
      _ClanQuickChip(
        value: '${clanInfo.members}/50',
        icon: Icons.groups_rounded,
        tooltip: loc.clanMembers,
      ),
      _ClanQuickChip(
        value: _plainNumber(clanInfo.clanBuilderBasePoints),
        imageUrl: ImageAssets.builderBaseTrophy,
        tooltip: loc.clanBuilderBasePoints,
      ),
    ];
    final secondaryChips = [
      _ClanQuickChip(
        value: typeLabel,
        icon: Icons.mail_rounded,
        tooltip: loc.clanType,
      ),
      if (clanInfo.requiredTownhallLevel > 0)
        _ClanQuickChip(
          value: loc.clanRequiredTownHallOnly(clanInfo.requiredTownhallLevel),
          imageUrl: ImageAssets.townHall(clanInfo.requiredTownhallLevel),
          tooltip: loc.clanRequiredTownHall,
        ),
      if (clanInfo.isFamilyFriendly)
        const _ClanQuickChip(
          value: familyLabel,
          icon: Icons.family_restroom_rounded,
          tooltip: familyLabel,
        ),
    ];

    if (combineRows) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 7,
        runSpacing: 7,
        children: [...primaryChips, ...secondaryChips],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 16),
          child: _ClanChipRows(children: primaryChips),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 16),
          child: _ClanChipRows(children: secondaryChips),
        ),
      ],
    );
  }

  String _plainNumber(int value) => value.toString();

  String _compactLeagueName(String leagueName) {
    return leagueName.replaceAll(' League', '').trim();
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
          iconColor: Colors.white,
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
            iconColor: Colors.white,
            tooltip: AppLocalizations.of(context)!.generalDiscord,
            onTap: () => _openDiscord(context),
            showBackground: false,
          ),
          const SizedBox(width: 8),
        ],
        HeaderIconButton(
          icon: Icons.open_in_new_rounded,
          iconColor: Colors.white,
          tooltip: AppLocalizations.of(context)!.playerOpenInGame,
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
              iconColor: bookmarked ? const Color(0xFF2F8CFF) : Colors.white,
              tooltip: bookmarked ? 'Remove bookmark' : 'Bookmark clan',
              onTap: () => bookmarks.toggleClan(clanInfo),
              showBackground: false,
            );
          },
        ),
      ],
    );
  }

  void _openCwl(BuildContext context) => openClanCwl(context, clanInfo);

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

class _DesktopClanHeaderPanel extends StatelessWidget {
  final bool descriptionExpanded;
  final VoidCallback onDescriptionToggle;
  final double maxWidth;

  const _DesktopClanHeaderPanel({
    required this.descriptionExpanded,
    required this.onDescriptionToggle,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_ClanInfoHeaderCardState>();
    if (state == null) return const SizedBox.shrink();

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(
          height: descriptionExpanded ? 230 : 166,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 370),
                          child: state._buildIdentity(
                            context,
                            compact: true,
                            horizontal: true,
                            onDescriptionToggle: onDescriptionToggle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 52),
                    Expanded(
                      flex: 6,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 590),
                          child: state._buildLeagueTiles(
                            context,
                            compact: true,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: state._buildQuickStats(
                    context,
                    compact: true,
                    combineRows: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CopyableClanTag extends StatelessWidget {
  final String tag;
  final TextAlign alignment;

  const _CopyableClanTag({
    required this.tag,
    this.alignment = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () {
        copyTextToClipboard(tag).then((_) {
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
          textAlign: alignment,
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

class _ClanMetaLine extends StatelessWidget {
  final String? locationName;
  final String? flagUrl;
  final Iterable<ClanLeague> labels;
  final bool hasDescription;
  final bool expanded;
  final MainAxisAlignment alignment;
  final VoidCallback onDescriptionToggle;

  const _ClanMetaLine({
    required this.locationName,
    required this.flagUrl,
    required this.labels,
    required this.hasDescription,
    required this.expanded,
    required this.alignment,
    required this.onDescriptionToggle,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocation = locationName != null && locationName!.isNotEmpty;
    final labelList = labels.toList(growable: false);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: [
        if (hasLocation) ...[
          if (flagUrl != null) ...[
            MobileWebImage(imageUrl: flagUrl!, width: 16, height: 16),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              locationName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.05,
              ),
            ),
          ),
        ],
        if (labelList.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.only(left: hasLocation ? 7 : 0, right: 7),
            child: Text(
              '|',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.30),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          _ClanLabelIcons(labels: labelList),
        ],
        if (hasDescription) ...[
          const SizedBox(width: 4),
          _DescriptionToggleDots(
            expanded: expanded,
            onTap: onDescriptionToggle,
          ),
        ],
      ],
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
  final TextAlign textAlign;

  const _ExpandableDescription({
    required this.description,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      height: 1.13,
    );

    return Text(
      description,
      textAlign: textAlign,
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

  const _ClanQuickChip({
    required this.value,
    this.imageUrl,
    this.icon,
    this.tooltip,
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

    if (tooltip == null || tooltip!.isEmpty) return chipBody;
    return Tooltip(message: tooltip!, child: chipBody);
  }
}

void openClanCwl(BuildContext context, Clan clanInfo) {
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
        warLeagueName: clanInfo.warLeague?.name,
      ),
    ),
  );
}

void openClanCapital(BuildContext context, Clan clanInfo) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ClanCapitalScreen(clanInfo: clanInfo),
    ),
  );
}
