import 'dart:math' as math;

import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/features/achievements/models/achievement.dart';
import 'package:clashkingapp/features/achievements/presentation/achievement_model_viewer.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AchievementProfile {
  const AchievementProfile({required this.name, required this.avatarUrl});

  final String name;
  final String avatarUrl;
}

class AchievementModelRequest {
  const AchievementModelRequest({
    required this.achievement,
    required this.semanticLabel,
    required this.interactive,
    required this.playUnlockAnimation,
  });

  final Achievement achievement;
  final String semanticLabel;
  final bool interactive;
  final bool playUnlockAnimation;
}

typedef AchievementModelBuilder =
    Widget Function(BuildContext context, AchievementModelRequest request);

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({
    super.key,
    this.profileOverride,
    this.achievements = mockAchievements,
    this.modelBuilder = _defaultModelBuilder,
  });

  final AchievementProfile? profileOverride;
  final List<Achievement> achievements;
  final AchievementModelBuilder modelBuilder;

  static Widget _defaultModelBuilder(
    BuildContext context,
    AchievementModelRequest request,
  ) {
    return AchievementModelViewer(
      modelUrl: request.achievement.modelUrl,
      semanticLabel: request.semanticLabel,
      locked: !request.achievement.isUnlocked,
      interactive: request.interactive,
      playUnlockAnimation: request.playUnlockAnimation,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = profileOverride ?? _profileFromAuth(context, l10n);
    final earned = achievements.where((item) => item.isUnlocked).length;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.achievementsTitle)),
      body: LayoutBuilder(
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
                  CKSpacing.lg,
                  horizontalPadding,
                  CKSpacing.md,
                ),
                sliver: SliverToBoxAdapter(
                  child: _ProfilePanel(
                    profile: profile,
                    summary:
                        '$earned/${achievements.length} ${l10n.generalCompleted}',
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
                    final achievement = achievements[index];
                    final copy = _localizedCopy(l10n, achievement.id);
                    return _AchievementTile(
                      achievement: achievement,
                      copy: copy,
                      modelBuilder: modelBuilder,
                      onTap: () => _openAchievement(
                        context,
                        achievement: achievement,
                        copy: copy,
                      ),
                    );
                  }, childCount: achievements.length),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  AchievementProfile _profileFromAuth(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final user = context.watch<AuthService>().currentUser;
    return AchievementProfile(
      name: user?.username ?? l10n.appTitle,
      avatarUrl: user?.avatarUrl ?? '',
    );
  }

  Future<void> _openAchievement(
    BuildContext context, {
    required Achievement achievement,
    required _AchievementCopy copy,
  }) {
    final reduceMotion = CKMotion.animationsDisabled(context);
    return showDialog<void>(
      context: context,
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.72),
      builder: (dialogContext) {
        final compact = MediaQuery.sizeOf(dialogContext).width < 700;
        final detail = _AchievementDetail(
          achievement: achievement,
          copy: copy,
          modelBuilder: modelBuilder,
          playUnlockAnimation: achievement.isUnlocked && !reduceMotion,
        );
        if (compact) return Dialog.fullscreen(child: detail);
        return Dialog(
          insetPadding: const EdgeInsets.all(CKSpacing.xl),
          backgroundColor: Theme.of(dialogContext).colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CKRadius.card),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 780),
            child: detail,
          ),
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

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({required this.profile, required this.summary});

  final AchievementProfile profile;
  final String summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return CKSectionPanel(
      key: const ValueKey('achievements-profile'),
      padding: const EdgeInsets.all(CKSpacing.lg),
      child: Row(
        children: [
          Semantics(
            image: true,
            label: profile.name,
            child: ClipOval(
              child: SizedBox.square(
                dimension: 64,
                child: MobileWebImage(
                  imageUrl: profile.avatarUrl,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => ColoredBox(
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.person_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 34,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: CKSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CKTypography.of(context, CKTextRole.screenTitle),
                ),
                const SizedBox(height: CKSpacing.xs),
                Text(
                  summary,
                  style: CKTypography.of(
                    context,
                    CKTextRole.body,
                  ).copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
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
    final status = achievement.isUnlocked
        ? achievement.isRepeatable
              ? '${achievement.earnedCount}× · ${l10n.achievementRepeatable}'
              : l10n.achievementUnlocked
        : l10n.widgetLocked;

    return CKCollectionTile(
      key: ValueKey('achievement-${achievement.id.name}'),
      label: copy.name,
      subtitle: status,
      owned: achievement.isUnlocked,
      semanticLabel: '${copy.name}, $status',
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
                playUnlockAnimation: false,
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
    required this.playUnlockAnimation,
  });

  final Achievement achievement;
  final _AchievementCopy copy;
  final AchievementModelBuilder modelBuilder;
  final bool playUnlockAnimation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final status = achievement.isUnlocked
        ? l10n.achievementUnlocked
        : l10n.widgetLocked;
    final statusColor = achievement.isUnlocked
        ? CKColors.donationGreen
        : colorScheme.onSurfaceVariant;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(copy.name),
        actions: [
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
          const SizedBox(width: CKSpacing.sm),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          CKSpacing.lg,
          CKSpacing.sm,
          CKSpacing.lg,
          CKSpacing.xxl,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 340,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(CKRadius.card),
                    child: ColoredBox(
                      color: colorScheme.surfaceContainerHighest,
                      child: modelBuilder(
                        context,
                        AchievementModelRequest(
                          achievement: achievement,
                          semanticLabel:
                              '${copy.name}. ${l10n.achievementRotateHint}',
                          interactive: true,
                          playUnlockAnimation: playUnlockAnimation,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: CKSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.threed_rotation_rounded,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: CKSpacing.sm),
                    Flexible(
                      child: Text(
                        l10n.achievementRotateHint,
                        textAlign: TextAlign.center,
                        style: CKTypography.of(
                          context,
                          CKTextRole.metadata,
                        ).copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: CKSpacing.xl),
                Text(
                  copy.name,
                  textAlign: TextAlign.center,
                  style: CKTypography.of(context, CKTextRole.screenTitle),
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
                const SizedBox(height: CKSpacing.xl),
                CKSectionPanel(
                  padding: const EdgeInsets.symmetric(horizontal: CKSpacing.lg),
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.flag_outlined,
                        label: l10n.achievementRequirementLabel,
                        value: copy.requirement,
                      ),
                      Divider(
                        height: 1,
                        color: colorScheme.outlineVariant.withValues(
                          alpha: CKOpacity.border,
                        ),
                      ),
                      _DetailRow(
                        icon: achievement.isUnlocked
                            ? Icons.check_circle_rounded
                            : Icons.lock_rounded,
                        iconColor: statusColor,
                        label: l10n.achievementStatusLabel,
                        value: status,
                        valueColor: statusColor,
                      ),
                      Divider(
                        height: 1,
                        color: colorScheme.outlineVariant.withValues(
                          alpha: CKOpacity.border,
                        ),
                      ),
                      _DetailRow(
                        icon: Icons.workspace_premium_outlined,
                        label: l10n.achievementEarnedLabel,
                        value: '${achievement.earnedCount}×',
                        trailing: achievement.isRepeatable
                            ? _RepeatablePill(label: l10n.achievementRepeatable)
                            : null,
                      ),
                    ],
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.valueColor,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final Color? valueColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CKSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 22,
            color: iconColor ?? colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: CKSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: CKTypography.of(
                    context,
                    CKTextRole.metadata,
                  ).copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: CKSpacing.xs),
                Text(
                  value,
                  style: CKTypography.of(
                    context,
                    CKTextRole.rowTitle,
                  ).copyWith(color: valueColor ?? colorScheme.onSurface),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: CKSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _RepeatablePill extends StatelessWidget {
  const _RepeatablePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(
        horizontal: CKSpacing.sm,
        vertical: CKSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(CKRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.replay_rounded, size: 15, color: colorScheme.onSurface),
          const SizedBox(width: CKSpacing.xs),
          Text(label, style: CKTypography.of(context, CKTextRole.compactLabel)),
        ],
      ),
    );
  }
}

class _AchievementCopy {
  const _AchievementCopy({
    required this.name,
    required this.description,
    required this.requirement,
  });

  final String name;
  final String description;
  final String requirement;
}

_AchievementCopy _localizedCopy(AppLocalizations l10n, AchievementId id) {
  return switch (id) {
    AchievementId.downhill18 => _AchievementCopy(
      name: l10n.achievementDownhill18Name,
      description: l10n.achievementDownhill18Description,
      requirement: l10n.achievementDownhill18Requirement,
    ),
    AchievementId.warWarrior => _AchievementCopy(
      name: l10n.achievementWarWarriorName,
      description: l10n.achievementWarWarriorDescription,
      requirement: l10n.achievementWarWarriorRequirement,
    ),
    AchievementId.mrLegend => _AchievementCopy(
      name: l10n.achievementMrLegendName,
      description: l10n.achievementMrLegendDescription,
      requirement: l10n.achievementMrLegendRequirement,
    ),
    AchievementId.defenseDoesntMatter => _AchievementCopy(
      name: l10n.achievementDefenseDoesntMatterName,
      description: l10n.achievementDefenseDoesntMatterDescription,
      requirement: l10n.achievementDefenseDoesntMatterRequirement,
    ),
  };
}
