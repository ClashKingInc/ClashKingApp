import 'dart:async';

import 'package:clashkingapp/common/widgets/dialogs/snackbar.dart';
import 'package:clashkingapp/common/widgets/header_widgets.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/clan/presentation/clan_info/clan_page.dart';
import 'package:clashkingapp/features/war_cwl/data/war_functions.dart'
    show timeLeft;
import 'package:clashkingapp/features/war_cwl/models/war_clan.dart';
import 'package:clashkingapp/features/war_cwl/models/war_info.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WarHeader extends StatefulWidget {
  final WarInfo warInfo;
  final int? cwlRoundNumber;
  final VoidCallback? onOpenCwl;

  const WarHeader({
    super.key,
    required this.warInfo,
    this.cwlRoundNumber,
    this.onOpenCwl,
  });

  @override
  State<WarHeader> createState() => _WarHeaderState();
}

class _WarHeaderState extends State<WarHeader> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isDesktopWeb = kIsWeb && media.size.width >= 900;
    final imageHeight = media.padding.top + (isDesktopWeb ? 340 : 500);
    final loc = AppLocalizations.of(context)!;
    final roundLabel = widget.cwlRoundNumber == null
        ? null
        : loc.cwlRoundNumber(widget.cwlRoundNumber!);

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
                  imageUrl: ImageAssets.warPageBackground,
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                  errorWidget: (context, url, error) =>
                      ColoredBox(color: Theme.of(context).colorScheme.surface),
                ),
              ),
              // Fixed black, not colorScheme.surface: keeps darkening the
              // photo toward the bottom in both themes — surface flips to
              // near-white in light mode, which un-darkens the image.
              // Lower peak alpha in light mode: still dark enough for
              // white text, but not dark mode's near-black wash.
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: HeaderIconButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                        onTap: () => Navigator.of(context).pop(),
                        showBackground: false,
                      ),
                    ),
                    if (roundLabel != null)
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width - 128,
                          ),
                          child: _RoundPill(
                            label: roundLabel,
                            onTap:
                                widget.onOpenCwl ??
                                () => Navigator.of(context).maybePop(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (isDesktopWeb)
              SizedBox(
                height: 214,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _WarIdentityPanel(
                      warInfo: widget.warInfo,
                      onOpenClan: _openClan,
                    ),
                  ),
                ),
              )
            else ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _WarIdentityPanel(
                  warInfo: widget.warInfo,
                  onOpenClan: _openClan,
                ),
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _openClan(BuildContext context, WarClan clan) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final Clan clanInfo = await ClanService().loadClanData(clan.tag);
    if (!context.mounted) return;
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClanInfoScreen(clanInfo: clanInfo),
      ),
    );
  }
}

class _WarIdentityPanel extends StatelessWidget {
  final WarInfo warInfo;
  final Future<void> Function(BuildContext context, WarClan clan) onOpenClan;

  const _WarIdentityPanel({required this.warInfo, required this.onOpenClan});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _WarScoreboardPanel(
                    warInfo: warInfo,
                    onOpenClan: onOpenClan,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WarScoreboardPanel extends StatelessWidget {
  final WarInfo warInfo;
  final Future<void> Function(BuildContext context, WarClan clan) onOpenClan;

  const _WarScoreboardPanel({required this.warInfo, required this.onOpenClan});

  @override
  Widget build(BuildContext context) {
    final isDesktopWeb = kIsWeb && MediaQuery.sizeOf(context).width >= 900;
    final clan = warInfo.clan;
    final opponent = warInfo.opponent;
    final score = '${clan?.stars ?? 0} - ${opponent?.stars ?? 0}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: timeLeft(
            warInfo,
            context,
            Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
        ),
        SizedBox(height: isDesktopWeb ? 10 : 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _WarBattleSide(
                clan: clan,
                isLeading: _leadingSide == _WarSide.clan,
                onTap: clan == null ? null : () => onOpenClan(context, clan),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isDesktopWeb ? 18 : 10),
              child: _WarScoreCore(score: score, desktop: isDesktopWeb),
            ),
            Expanded(
              child: _WarBattleSide(
                clan: opponent,
                isLeading: _leadingSide == _WarSide.opponent,
                onTap: opponent == null
                    ? null
                    : () => onOpenClan(context, opponent),
              ),
            ),
          ],
        ),
      ],
    );
  }

  _WarSide? get _leadingSide {
    final clan = warInfo.clan;
    final opponent = warInfo.opponent;
    if (clan == null || opponent == null) return null;
    if (clan.stars != opponent.stars) {
      return clan.stars > opponent.stars ? _WarSide.clan : _WarSide.opponent;
    }
    if (clan.destructionPercentage == opponent.destructionPercentage) {
      return null;
    }
    return clan.destructionPercentage > opponent.destructionPercentage
        ? _WarSide.clan
        : _WarSide.opponent;
  }
}

enum _WarSide { clan, opponent }

class _WarBattleSide extends StatelessWidget {
  final WarClan? clan;
  final bool isLeading;
  final VoidCallback? onTap;

  const _WarBattleSide({
    required this.clan,
    required this.isLeading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktopWeb = kIsWeb && MediaQuery.sizeOf(context).width >= 900;
    final badgeSize = isDesktopWeb
        ? (isLeading ? 116.0 : 108.0)
        : (isLeading ? 76.0 : 70.0);
    final imagePadding = isDesktopWeb ? 2.0 : 3.0;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: badgeSize,
          height: badgeSize,
          child: Padding(
            padding: EdgeInsets.all(imagePadding),
            child: MobileWebImage(imageUrl: clan?.badgeUrls.large ?? ''),
          ),
        ),
        SizedBox(height: isDesktopWeb ? 7 : 5),
        Text(
          clan?.name ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontSize: isDesktopWeb ? 16 : null,
            fontWeight: isLeading ? FontWeight.w900 : FontWeight.w700,
            height: 1.02,
          ),
        ),
        if ((clan?.tag ?? '').isNotEmpty) ...[
          const SizedBox(height: 2),
          _CopyableWarClanTag(tag: clan!.tag),
        ],
      ],
    );

    if (onTap == null) return content;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      splashFactory: NoSplash.splashFactory,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: content,
      ),
    );
  }
}

class _CopyableWarClanTag extends StatelessWidget {
  final String tag;

  const _CopyableWarClanTag({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tag,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          copyTextToClipboard(tag).then((_) {
            if (!context.mounted) return;
            showClipboardSnackbar(
              context,
              AppLocalizations.of(context)!.generalCopiedToClipboard,
            );
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          child: Text(
            tag,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.62),
              fontWeight: FontWeight.w600,
              height: 1.05,
            ),
          ),
        ),
      ),
    );
  }
}

class _WarScoreCore extends StatelessWidget {
  final String score;
  final bool desktop;

  const _WarScoreCore({required this.score, required this.desktop});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MobileWebImage(
          imageUrl: ImageAssets.war,
          width: desktop ? 38 : 32,
          height: desktop ? 38 : 32,
        ),
        SizedBox(height: desktop ? 8 : 6),
        Text(
          score,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontSize: desktop ? 34 : 30,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _RoundPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _RoundPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.58),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.32),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MobileWebImage(
                    imageUrl: ImageAssets.cwlSwordsNoBorder,
                    width: 19,
                    height: 19,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
