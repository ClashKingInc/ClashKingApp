import 'dart:math' as math;

import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:clashkingapp/features/achievements/data/achievements_repository.dart';
import 'package:clashkingapp/features/achievements/models/achievement.dart';
import 'package:clashkingapp/features/achievements/presentation/achievement_model_viewer.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AchievementModelRequest {
  const AchievementModelRequest({
    required this.achievement,
    required this.semanticLabel,
    required this.interactive,
    required this.enableIdleRotation,
  });

  final Achievement achievement;
  final String semanticLabel;
  final bool interactive;
  final bool enableIdleRotation;
}

typedef AchievementModelBuilder =
    Widget Function(BuildContext context, AchievementModelRequest request);

Widget _defaultAchievementModelBuilder(
  BuildContext context,
  AchievementModelRequest request,
) {
  return AchievementModelViewer(
    modelUrl: request.achievement.modelUrl,
    semanticLabel: request.semanticLabel,
    locked: !request.achievement.isUnlocked,
    interactive: request.interactive,
    enableIdleRotation: request.enableIdleRotation,
  );
}

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({
    super.key,
    this.achievements,
    this.modelBuilder = _defaultAchievementModelBuilder,
  });

  final List<Achievement>? achievements;
  final AchievementModelBuilder modelBuilder;

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  @override
  void initState() {
    super.initState();
    if (widget.achievements == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<AchievementsRepository>().check().catchError((_) {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repository = widget.achievements == null
        ? context.watch<AchievementsRepository>()
        : null;
    final visibleAchievements = widget.achievements ?? repository!.achievements;
    final earned = visibleAchievements.where((item) => item.isUnlocked).length;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = ((constraints.maxWidth - 1120) / 2)
                .clamp(CKSpacing.lg, double.infinity)
                .toDouble();
            final collectionWidth = math
                .min(constraints.maxWidth - horizontalPadding * 2, 1120)
                .toDouble();
            final columns = achievementColumnCount(collectionWidth);

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    CKSpacing.md,
                    horizontalPadding,
                    CKSpacing.lg,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _CollectionHeader(
                      title: l10n.achievementsTitle,
                      summary: l10n.achievementSummary(
                        earned.toString(),
                        visibleAchievements.length.toString(),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    CKSpacing.sm,
                    horizontalPadding,
                    CKSpacing.xxl,
                  ),
                  sliver: SliverGrid(
                    key: const ValueKey('achievements-grid'),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisExtent: 220,
                      mainAxisSpacing: CKSpacing.lg,
                      crossAxisSpacing: CKSpacing.lg,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final achievement = visibleAchievements[index];
                      final copy = _localizedCopy(l10n, achievement.id);
                      return _AchievementTile(
                        achievement: achievement,
                        copy: copy,
                        modelBuilder: widget.modelBuilder,
                        onTap: () => _openAchievement(
                          context,
                          achievement: achievement,
                          copy: copy,
                        ),
                      );
                    }, childCount: visibleAchievements.length),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openAchievement(
    BuildContext context, {
    required Achievement achievement,
    required _AchievementCopy copy,
  }) {
    final reduceMotion = CKMotion.animationsDisabled(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.72),
      constraints: const BoxConstraints(maxWidth: 720),
      builder: (sheetContext) {
        return _AchievementDetail(
          achievement: achievement,
          copy: copy,
          modelBuilder: widget.modelBuilder,
          enableIdleRotation: !reduceMotion,
        );
      },
    );
  }
}

int achievementColumnCount(double width) {
  if (width < 520) return 2;
  if (width < 760) return 3;
  return 4;
}

class _CollectionHeader extends StatelessWidget {
  const _CollectionHeader({required this.title, required this.summary});

  final String title;
  final String summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canPop = Navigator.of(context).canPop();
    return Row(
      key: const ValueKey('achievements-header'),
      children: [
        if (canPop) ...[
          SizedBox.square(
            dimension: 48,
            child: IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const BackButtonIcon(),
            ),
          ),
          const SizedBox(width: CKSpacing.md),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CKTypography.of(context, CKTextRole.screenTitle),
              ),
              const SizedBox(height: CKSpacing.xs),
              Text(
                summary,
                style: CKTypography.of(
                  context,
                  CKTextRole.metadata,
                ).copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.achievement,
    required this.copy,
    required this.modelBuilder,
    required this.onTap,
  });

  final Achievement achievement;
  final _AchievementCopy copy;
  final AchievementModelBuilder modelBuilder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final subtitle = !achievement.isUnlocked
        ? l10n.widgetLocked
        : '×${achievement.earnedCount}';

    return CKCollectionTile(
      key: ValueKey('achievement-${achievement.id.name}'),
      label: copy.name,
      subtitle: subtitle,
      owned: achievement.isUnlocked,
      semanticLabel: '${copy.name}, $subtitle',
      onTap: onTap,
      image: Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            child: modelBuilder(
              context,
              AchievementModelRequest(
                achievement: achievement,
                semanticLabel: copy.name,
                interactive: false,
                enableIdleRotation: false,
              ),
            ),
          ),
          if (!achievement.isUnlocked)
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: Container(
                margin: const EdgeInsets.all(CKSpacing.sm),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_rounded,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AchievementDetail extends StatelessWidget {
  const _AchievementDetail({
    required this.achievement,
    required this.copy,
    required this.modelBuilder,
    required this.enableIdleRotation,
  });

  final Achievement achievement;
  final _AchievementCopy copy;
  final AchievementModelBuilder modelBuilder;
  final bool enableIdleRotation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    const sheetRadius = BorderRadius.vertical(
      top: Radius.circular(CKRadius.card),
    );
    final sheetHeight = math.min(
      MediaQuery.sizeOf(context).height * 0.82,
      680.0,
    );
    return SizedBox(
      key: const ValueKey('achievement-detail-sheet'),
      height: sheetHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: sheetRadius,
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant.withValues(
                alpha: CKOpacity.borderStrong,
              ),
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: sheetRadius,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              CKSpacing.lg,
              CKSpacing.sm,
              CKSpacing.lg,
              MediaQuery.paddingOf(context).bottom + CKSpacing.xl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 48,
                      child: Align(
                        alignment: AlignmentDirectional.topEnd,
                        child: IconButton(
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).closeButtonTooltip,
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            SizedBox(
                              height: math.min(320, sheetHeight * 0.42),
                              child: modelBuilder(
                                context,
                                AchievementModelRequest(
                                  achievement: achievement,
                                  semanticLabel: copy.name,
                                  interactive: true,
                                  enableIdleRotation: enableIdleRotation,
                                ),
                              ),
                            ),
                            const SizedBox(height: CKSpacing.lg),
                            Text(
                              copy.name,
                              textAlign: TextAlign.center,
                              style: CKTypography.of(
                                context,
                                CKTextRole.screenTitle,
                              ),
                            ),
                            const SizedBox(height: CKSpacing.sm),
                            Text(
                              copy.description,
                              textAlign: TextAlign.center,
                              style: CKTypography.of(
                                context,
                                CKTextRole.body,
                              ).copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: CKSpacing.md),
                            Text(
                              l10n.achievementEarnedCount(
                                achievement.earnedCount.toString(),
                              ),
                              textAlign: TextAlign.center,
                              style: CKTypography.of(
                                context,
                                CKTextRole.metadata,
                              ).copyWith(color: colorScheme.onSurface),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AchievementCopy {
  const _AchievementCopy({required this.name, required this.description});

  final String name;
  final String description;
}

_AchievementCopy _localizedCopy(AppLocalizations l10n, AchievementId id) {
  return switch (id) {
    AchievementId.townhall18 => _AchievementCopy(
      name: l10n.achievementTownhall18Name,
      description: l10n.achievementTownhall18Requirement,
    ),
    AchievementId.warWarrior => _AchievementCopy(
      name: l10n.achievementWarWarriorName,
      description: l10n.achievementWarWarriorRequirement,
    ),
    AchievementId.mrLegend => _AchievementCopy(
      name: l10n.achievementMrLegendName,
      description: l10n.achievementMrLegendDescription,
    ),
    AchievementId.defenseDoesntMatter => _AchievementCopy(
      name: l10n.achievementDefenseDoesntMatterName,
      description: l10n.achievementDefenseDoesntMatterDescription,
    ),
  };
}
