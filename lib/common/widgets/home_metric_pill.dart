import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:flutter/material.dart';

/// Home-card metric pill.
///
/// Shares its shell with the Player and Clan cards' chips (`_InfoChip` in
/// `players_page.dart`, `_ClanChipShell` in `clan_page.dart`): pill radius,
/// quiet `surface` fill, hairline `outlineVariant` border and a bare
/// game-asset image with no icon circle. Those cards sit one bottom-nav tap
/// away from the home dashboard, so the home cards have to read as the same
/// family.
///
/// Completion is carried by the value's own color rather than by any added
/// element. A progress bar, a proportional fill and a status dot were each
/// tried and dropped: `0/3999` already says "not done" and `2/2` already says
/// "done", so every extra device restated in a weaker form what the text was
/// already saying — and a badge that lights up on almost every row stops
/// being read at all.
class HomeMetricPill extends StatelessWidget {
  const HomeMetricPill({
    super.key,
    required this.label,
    required this.value,
    this.meta,
    this.progress,
    this.imageUrl,
    this.fallbackIcon,
    this.semanticLabel,
  });

  /// Two text lines plus padding. The home pagers need a deterministic height,
  /// so it's pinned rather than measured — keep card height math expressed via
  /// [gridHeight].
  ///
  /// Label and value are stacked rather than sharing a line because at two
  /// pills per row there isn't room for `image + label + value + meta`: the
  /// label was the one losing, ellipsising to "Clan Ga…" / "Build…".
  static const double defaultHeight = 44;

  /// Matches the Player/Clan cards' chip spacing.
  static const double gap = CKSpacing.sm - 2;

  /// Total height of [rows] stacked pills, gaps included.
  static double gridHeight(int rows) =>
      rows <= 0 ? 0 : rows * defaultHeight + (rows - 1) * gap;

  final String label;
  final String value;

  /// Detail shown right of the label (a projected duration...).
  final String? meta;

  /// 0..1, or null when the metric has no known limit. Only used to decide
  /// whether the value reads as settled; the ratio itself is already in
  /// [value].
  final double? progress;

  final String? imageUrl;
  final IconData? fallbackIcon;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progressValue = progress?.clamp(0.0, 1.0);
    final isComplete = progressValue != null && progressValue >= 1;

    return Semantics(
      label: semanticLabel ?? '$label: $value',
      excludeSemantics: true,
      child: SizedBox(
        height: defaultHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(CKRadius.pill),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.18),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(CKRadius.pill),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11),
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: 20,
                    child: imageUrl != null
                        ? MobileWebImage(
                            imageUrl: imageUrl!,
                            fit: BoxFit.contain,
                            errorWidget: (context, url, error) => Icon(
                              fallbackIcon ?? Icons.circle_rounded,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          )
                        : Icon(
                            fallbackIcon ?? Icons.circle_rounded,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                      height: 1,
                                    ),
                              ),
                            ),
                            if (meta != null) ...[
                              const SizedBox(width: 5),
                              Text(
                                meta!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w700,
                                      height: 1,
                                    ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: isComplete
                                    ? CKColors.donationGreen
                                    : colorScheme.onSurface,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                        ),
                      ],
                    ),
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
