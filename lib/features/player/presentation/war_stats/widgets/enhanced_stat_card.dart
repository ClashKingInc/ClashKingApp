import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/features/player/presentation/war_stats/widgets/performance_indicator.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/icons/build_stars.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';

/// An enhanced stat card with visual indicators and performance coloring
class EnhancedStatCard extends StatelessWidget {
  final String title;
  final double stars;
  final double destruction;
  final int count;
  final int? missed;
  final bool isAttack;
  final VoidCallback? onTap;
  final Map<String, int>? starsBreakdown;

  const EnhancedStatCard({
    super.key,
    required this.title,
    required this.stars,
    required this.destruction,
    required this.count,
    this.missed,
    required this.isAttack,
    this.onTap,
    this.starsBreakdown,
  });

  Color _getCardColor() {
    final starPerformance = (stars / 3.0).clamp(0.0, 1.0);
    final destructionPerformance = (destruction / 100.0).clamp(0.0, 1.0);

    // For defense, invert the performance logic (lower is better)
    final avgPerformance = isAttack
        ? (starPerformance + destructionPerformance) / 2
        : 1.0 - (starPerformance + destructionPerformance) / 2;

    if (avgPerformance >= 0.8) return Colors.green.withValues(alpha: 0.1);
    if (avgPerformance >= 0.6) return Colors.orange.withValues(alpha: 0.1);
    if (avgPerformance >= 0.4) return Colors.amber.withValues(alpha: 0.1);
    return Colors.red.withValues(alpha: 0.1);
  }

  Color _getBorderColor() {
    final starPerformance = (stars / 3.0).clamp(0.0, 1.0);
    final destructionPerformance = (destruction / 100.0).clamp(0.0, 1.0);

    // For defense, invert the performance logic (lower is better)
    final avgPerformance = isAttack
        ? (starPerformance + destructionPerformance) / 2
        : 1.0 - (starPerformance + destructionPerformance) / 2;

    if (avgPerformance >= 0.8) return Colors.green.withValues(alpha: 0.3);
    if (avgPerformance >= 0.6) return Colors.orange.withValues(alpha: 0.3);
    if (avgPerformance >= 0.4) return Colors.amber.withValues(alpha: 0.3);
    return Colors.red.withValues(alpha: 0.3);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _getCardColor(),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _getBorderColor(), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title with icon
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Performance indicators
            Column(
              children: [
                // Top Row - Stars and Count
                Row(
                  children: [
                    // Stars
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          buildStarsIcon(stars.round()),
                          const SizedBox(height: 4),
                          Text(
                            stars.toStringAsFixed(2),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                        ],
                      ),
                    ),

                    // Count
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          MobileWebImage(
                            imageUrl: isAttack
                                ? ImageAssets.sword
                                : ImageAssets.shield,
                            width: 16,
                            height: 16,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            count.toString(),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Middle - Destruction Bar
                PerformanceIndicator(
                  value: destruction,
                  maxValue: 100,
                  label: AppLocalizations.of(context)!.warDestructionTitle,
                  showPercentage: true,
                ),

                // Bottom - Stars Breakdown
                if (starsBreakdown != null) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStarBreakdownItem(
                            context, '0', starsBreakdown!['0'] ?? 0),
                        _buildStarBreakdownItem(
                            context, '1', starsBreakdown!['1'] ?? 0),
                        _buildStarBreakdownItem(
                            context, '2', starsBreakdown!['2'] ?? 0),
                        _buildStarBreakdownItem(
                            context, '3', starsBreakdown!['3'] ?? 0),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            // Missed attacks/defenses if applicable
            if (missed != null && missed! > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border:
                      Border.all(color: Theme.of(context).colorScheme.primary),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MobileWebImage(
                        imageUrl: ImageAssets.brokenSword,
                        width: 16,
                        height: 16),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)!.warStatusMissedInfo(
                        missed ?? 0,
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStarBreakdownItem(
      BuildContext context, String starCount, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Fixed width for stars - ensures consistent alignment
        SizedBox(
          width: 50,
          child: Center(
            child: buildStarsIcon(int.parse(starCount)),
          ),
        ),
        // Fixed width for count - ensures consistent alignment
        SizedBox(
          width: 30,
          child: Center(
            child: Text(
              count.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getStarCountColor(starCount),
                fontSize: 11,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStarCountColor(String starCount) {
    if (isAttack) {
      // For attacks: higher stars = better (green)
      switch (starCount) {
        case '3':
          return Colors.green[600]!;
        case '2':
          return Colors.orange[600]!;
        case '1':
          return Colors.amber[600]!;
        case '0':
          return Colors.red[600]!;
        default:
          return Colors.grey[600]!;
      }
    } else {
      // For defenses: lower stars = better (green)
      switch (starCount) {
        case '3':
          return Colors.red[600]!;
        case '2':
          return Colors.orange[600]!;
        case '1':
          return Colors.amber[600]!;
        case '0':
          return Colors.green[600]!;
        default:
          return Colors.grey[600]!;
      }
    }
  }
}
