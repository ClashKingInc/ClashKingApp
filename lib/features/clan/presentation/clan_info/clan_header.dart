import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/common/widgets/dialogs/open_clash_dialog.dart';
import 'package:clashkingapp/common/widgets/dialogs/snackbar.dart';
import 'package:clashkingapp/common/widgets/header_widgets.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/native_liquid_glass.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/bookmark_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/war_cwl/presentation/cwl/cwl.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war/war.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war_stats/war_stats_page.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ClanInfoHeaderCard extends StatelessWidget {
  final Clan clanInfo;
  final bool showTopActions;

  const ClanInfoHeaderCard({
    super.key,
    required this.clanInfo,
    this.showTopActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return _buildHero(context);
  }

  /// Hero header: backdrop image with scrim, floating actions, identity
  /// row and a content-sized stats card straddling the image edge — same
  /// pattern as the player page.
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
                  Colors.black.withValues(alpha: 0.47),
                  BlendMode.darken,
                ),
                child: CachedNetworkImage(
                  imageUrl: ImageAssets.clanPageBackground,
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
                      ).colorScheme.surface.withValues(alpha: 0.30),
                      Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.70),
                      Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.96),
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
            if (showTopActions)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildTopActions(context),
              )
            else
              const SizedBox(height: 42),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildIdentity(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 7, 16, 0),
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
    final description = clanInfo.description.trim();
    final location = clanInfo.location;
    final flagUrl = location?.countryCode != null
        ? ImageAssets.flag(location!.countryCode!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 82,
              child: CachedNetworkImage(
                imageUrl: clanInfo.badgeUrls.large,
                width: 76,
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
                    // Always white: sits on the darkened backdrop image.
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    children: [
                      Flexible(child: _CopyableClanTag(tag: clanInfo.tag)),
                      if (location?.name != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          child: Text(
                            '|',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.30),
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                        if (flagUrl != null) ...[
                          MobileWebImage(
                            imageUrl: flagUrl,
                            width: 17,
                            height: 17,
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
                                  color: Colors.white.withValues(alpha: 0.68),
                                  fontWeight: FontWeight.w500,
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
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 3, 3, 3),
            child: Text(
              description,
              softWrap: true,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.84),
                fontWeight: FontWeight.w600,
                height: 1.13,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatsPanel(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final warLeagueName = clanInfo.warLeague?.name ?? 'Unranked';
    final warLeagueUrl = ImageAssets.getWarLeagueImage(warLeagueName);
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ClanWarLeagueTile(
          leagueName: warLeagueName,
          leagueUrl: warLeagueUrl,
          warFrequencyLabel: warFrequencyLabel,
          wins: clanInfo.warWins,
          ties: clanInfo.warTies,
          losses: clanInfo.warLosses,
          streak: clanInfo.warWinStreak,
          isPublic: clanInfo.isWarLogPublic,
        ),
        const SizedBox(height: 7),
        _ClanChipRows(
          children: [
            _ClanQuickChip(
              value: _plainNumber(clanInfo.clanPoints),
              imageUrl: ImageAssets.trophies,
            ),
            _ClanQuickChip(
              value: _plainNumber(clanInfo.clanBuilderBasePoints),
              imageUrl: ImageAssets.builderBaseTrophy,
            ),
            _ClanQuickChip(
              value: _plainNumber(clanInfo.clanCapitalPoints),
              imageUrl: ImageAssets.capitalTrophy,
            ),
            _ClanQuickChip(
              value: '${clanInfo.members}/50',
              icon: Icons.groups_rounded,
            ),
            _ClanQuickChip(value: typeLabel, icon: Icons.mail_rounded),
            if (clanInfo.requiredTownhallLevel > 0)
              _ClanQuickChip(
                value: '${clanInfo.requiredTownhallLevel}+',
                imageUrl: ImageAssets.townHall(clanInfo.requiredTownhallLevel),
              ),
          ],
        ),
        const SizedBox(height: 7),
      ],
    );
  }

  String _plainNumber(int value) => value.toString();
}

class ClanInfoHeaderActions extends StatelessWidget {
  final Clan clanInfo;

  const ClanInfoHeaderActions({super.key, required this.clanInfo});

  @override
  Widget build(BuildContext context) {
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
          icon: Icons.bar_chart_rounded,
          tooltip: AppLocalizations.of(context)!.generalStats,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClanWarStatsScreen(clan: clanInfo),
            ),
          ),
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

class _ClanWarLeagueTile extends StatefulWidget {
  final String leagueName;
  final String leagueUrl;
  final String warFrequencyLabel;
  final int wins;
  final int ties;
  final int losses;
  final int streak;
  final bool isPublic;

  const _ClanWarLeagueTile({
    required this.leagueName,
    required this.leagueUrl,
    required this.warFrequencyLabel,
    required this.wins,
    required this.ties,
    required this.losses,
    required this.streak,
    required this.isPublic,
  });

  @override
  State<_ClanWarLeagueTile> createState() => _ClanWarLeagueTileState();
}

class _ClanWarLeagueTileState extends State<_ClanWarLeagueTile> {
  static final Map<String, Color> _tintCache = {};
  Color? _tint;

  @override
  void initState() {
    super.initState();
    _loadTint();
  }

  @override
  void didUpdateWidget(covariant _ClanWarLeagueTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.leagueUrl != widget.leagueUrl) {
      _loadTint();
    }
  }

  Future<void> _loadTint() async {
    final leagueUrl = widget.leagueUrl;
    if (leagueUrl.isEmpty) {
      if (mounted) setState(() => _tint = null);
      return;
    }

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
      final tint = await _cwlDominantTint(imageInfo.image);
      if (tint == null) return;

      _tintCache[leagueUrl] = tint;
      if (mounted && widget.leagueUrl == leagueUrl) {
        setState(() => _tint = tint);
      }
    } catch (_) {
      // Keep the glass neutral if the remote badge cannot be sampled.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: 75,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const NativeLiquidGlassBar(
              height: 75,
              cornerRadius: 18,
              opacity: 0.72,
              borderOpacity: 0.22,
              shadowOpacity: 0.22,
            ),
            if (_tint != null)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _tint!.withValues(alpha: 0.24),
                      _tint!.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(11),
              child: Row(
                children: [
                  MobileWebImage(
                    imageUrl: widget.leagueUrl,
                    width: 46,
                    height: 46,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.leagueName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.warFrequencyLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _TinyWarMetric(
                            icon: Icons.check_rounded,
                            value: widget.wins.toString(),
                            color: Colors.green,
                            tooltip: 'War wins',
                          ),
                          if (widget.isPublic) ...[
                            const SizedBox(width: 8),
                            _TinyWarMetric(
                              icon: Icons.remove_rounded,
                              value: widget.ties.toString(),
                              color: Colors.blue,
                              tooltip: 'War ties',
                            ),
                            const SizedBox(width: 8),
                            _TinyWarMetric(
                              icon: Icons.close_rounded,
                              value: widget.losses.toString(),
                              color: Colors.redAccent,
                              tooltip: 'War losses',
                            ),
                          ],
                          const SizedBox(width: 8),
                          _TinyWarMetric(
                            icon: Icons.local_fire_department_rounded,
                            value: widget.streak.toString(),
                            color: const Color(0xFFE35D4F),
                            tooltip: 'War win streak',
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TinyWarMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  final String tooltip;

  const _TinyWarMetric({
    required this.icon,
    required this.value,
    required this.color,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

Future<Color?> _cwlDominantTint(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (data == null) return null;

  final buckets = <int, _ColorBucket>{};
  const sampleStride = 4;
  for (var y = 0; y < image.height; y += sampleStride) {
    for (var x = 0; x < image.width; x += sampleStride) {
      final index = (y * image.width + x) * 4;
      final r = data.getUint8(index);
      final g = data.getUint8(index + 1);
      final b = data.getUint8(index + 2);
      final a = data.getUint8(index + 3);
      if (a < 96) continue;

      final color = Color.fromARGB(a, r, g, b);
      final hsl = HSLColor.fromColor(color);
      if (hsl.lightness < 0.12 || hsl.lightness > 0.92) continue;
      if (hsl.saturation < 0.24) continue;

      final key = (r ~/ 24) << 16 | (g ~/ 24) << 8 | (b ~/ 24);
      final bucket = buckets.putIfAbsent(key, _ColorBucket.new);
      bucket
        ..count += 1
        ..red += r
        ..green += g
        ..blue += b
        ..score += hsl.saturation * (1 - (hsl.lightness - 0.55).abs())
        ..goldTrimSamples += _isGoldTrim(hsl) ? 1 : 0;
    }
  }

  if (buckets.isEmpty) return null;
  final nonGold = buckets.values.where((bucket) => !bucket.isMostlyGoldTrim);
  final candidates = nonGold.isEmpty ? buckets.values : nonGold;
  final best = candidates.reduce(
    (a, b) => a.weightedScore >= b.weightedScore ? a : b,
  );
  return Color.fromARGB(
    255,
    best.red ~/ best.count,
    best.green ~/ best.count,
    best.blue ~/ best.count,
  );
}

bool _isGoldTrim(HSLColor color) {
  return color.hue >= 36 &&
      color.hue <= 58 &&
      color.saturation >= 0.38 &&
      color.lightness >= 0.42;
}

class _ColorBucket {
  int count = 0;
  int red = 0;
  int green = 0;
  int blue = 0;
  int goldTrimSamples = 0;
  double score = 0;

  bool get isMostlyGoldTrim => goldTrimSamples / count > 0.55;
  double get weightedScore => count * score;
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
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Text(
          tag,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.62),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
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

  const _ClanQuickChip({required this.value, this.imageUrl, this.icon});

  double estimatedWidth(BuildContext context) {
    final textStyle = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, height: 1);
    final painter = TextPainter(
      text: TextSpan(text: value, style: textStyle),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout();
    return 18 + 19 + 5 + painter.width;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageUrl != null)
            MobileWebImage(imageUrl: imageUrl!, width: 19, height: 19)
          else
            Icon(icon, size: 19, color: foreground),
          const SizedBox(width: 5),
          Text(
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
        ],
      ),
    );
  }
}
