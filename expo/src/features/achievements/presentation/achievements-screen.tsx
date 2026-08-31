import { useCallback, useEffect, useState, useSyncExternalStore, type ComponentType } from 'react';
import {
  Modal,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  View,
  useWindowDimensions,
} from 'react-native';
import { ArrowLeft, ArrowRight, Lock, X } from 'lucide-react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';

import { materialBackLabel, materialCloseLabel, useI18n } from '../../../i18n';
import {
  CKText,
  ckOpacity,
  ckRadius,
  ckSpacing,
  colorWithAlpha,
  useCKAccessibility,
  useCKTheme,
} from '../../../ui';
import type { AchievementsRepository, AchievementsSnapshot } from '../data';
import { isAchievementUnlocked, type Achievement } from '../models';
import {
  AchievementModelViewer,
  type AchievementModelViewerProps,
} from './achievement-model-viewer';
import { ACHIEVEMENT_COPY_KEYS, achievementColumnCount } from './contracts';

const EMPTY_SNAPSHOT: AchievementsSnapshot = Object.freeze({
  achievements: Object.freeze([]),
  isRefreshing: false,
});

export interface AchievementsScreenProps {
  readonly repository?: AchievementsRepository;
  readonly achievements?: readonly Achievement[];
  readonly onBack?: () => void;
  readonly modelRenderer?: ComponentType<AchievementModelViewerProps>;
}

export function AchievementsScreen({
  repository,
  achievements,
  onBack,
  modelRenderer: ModelRenderer = AchievementModelViewer,
}: AchievementsScreenProps) {
  const { t, isRtl, locale } = useI18n();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  const { reduceMotion } = useCKAccessibility();
  const { width, height } = useWindowDimensions();
  const snapshot = useAchievementsSnapshot(repository);
  const visibleAchievements = achievements ?? snapshot.achievements;
  const [selected, setSelected] = useState<Achievement>();
  const horizontalPadding = Math.max(ckSpacing.lg, (width - 1120) / 2);
  const collectionWidth = Math.min(width - horizontalPadding * 2, 1120);
  const columns = achievementColumnCount(collectionWidth);
  const tileWidth = (collectionWidth - ckSpacing.lg * (columns - 1)) / columns;
  const earned = visibleAchievements.filter(isAchievementUnlocked).length;

  useEffect(() => {
    if (achievements === undefined && repository !== undefined) {
      void repository.check().catch(() => undefined);
    }
  }, [achievements, repository]);

  return (
    <SafeAreaView
      edges={['top', 'left', 'right']}
      style={[styles.safeArea, { backgroundColor: theme.background }]}
    >
      <ScrollView
        alwaysBounceVertical
        contentContainerStyle={{
          paddingHorizontal: horizontalPadding,
          paddingTop: ckSpacing.md,
          paddingBottom: ckSpacing.xxl,
        }}
      >
        <View style={styles.header} testID="achievements-header">
          {onBack ? (
            <Pressable
              accessibilityLabel={materialBackLabel(locale)}
              accessibilityRole="button"
              hitSlop={8}
              onPress={onBack}
              style={[styles.headerAction, isRtl ? styles.backActionRtl : styles.backAction]}
              testID="achievements-back"
            >
              {isRtl ? (
                <ArrowRight color={theme.onSurface} size={24} />
              ) : (
                <ArrowLeft color={theme.onSurface} size={24} />
              )}
            </Pressable>
          ) : null}
          <View style={styles.headerCopy}>
            <CKText numberOfLines={1} role="screenTitle">
              {t('achievementsTitle')}
            </CKText>
            <CKText muted role="metadata">
              {t('achievementSummary', {
                earned: String(earned),
                total: String(visibleAchievements.length),
              })}
            </CKText>
          </View>
        </View>
        <View style={styles.grid} testID={`achievements-grid-${columns}`}>
          {visibleAchievements.map((achievement) => {
            const keys = ACHIEVEMENT_COPY_KEYS[achievement.id];
            const name = t(keys.name);
            const subtitle = isAchievementUnlocked(achievement)
              ? `×${achievement.earnedCount}`
              : t('widgetLocked');
            return (
              <AchievementTile
                key={achievement.id}
                achievement={achievement}
                modelRenderer={ModelRenderer}
                name={name}
                onPress={() => setSelected(achievement)}
                subtitle={subtitle}
                width={tileWidth}
              />
            );
          })}
        </View>
      </ScrollView>
      <AchievementDetail
        achievement={selected}
        enableIdleRotation={!reduceMotion}
        modelRenderer={ModelRenderer}
        onClose={() => setSelected(undefined)}
        sheetHeight={Math.min(height * 0.82, 680)}
        bottomInset={insets.bottom}
      />
    </SafeAreaView>
  );
}

function AchievementTile({
  achievement,
  modelRenderer: ModelRenderer,
  name,
  onPress,
  subtitle,
  width,
}: {
  achievement: Achievement;
  modelRenderer: ComponentType<AchievementModelViewerProps>;
  name: string;
  onPress: () => void;
  subtitle: string;
  width: number;
}) {
  const theme = useCKTheme();
  const unlocked = isAchievementUnlocked(achievement);
  return (
    <Pressable
      accessibilityLabel={`${name}, ${subtitle}`}
      accessibilityRole="button"
      onPress={onPress}
      style={({ pressed }) => [
        styles.tile,
        { width, opacity: pressed && Platform.OS !== 'web' ? 0.82 : 1 },
      ]}
      testID={`achievement-${achievement.id}`}
    >
      <View
        accessibilityElementsHidden
        importantForAccessibility="no-hide-descendants"
        style={styles.tileBody}
      >
        <View style={[styles.artwork, !unlocked && styles.lockedArtwork]}>
          <ModelRenderer
            achievement={achievement}
            enableIdleRotation={false}
            interactive={false}
            semanticLabel={name}
          />
          {!unlocked ? (
            <View style={[styles.lock, { backgroundColor: colorWithAlpha(theme.surface, 0.9) }]}>
              <Lock color={theme.onSurfaceVariant} size={18} />
            </View>
          ) : null}
        </View>
        <CKText
          numberOfLines={2}
          role="compactLabel"
          style={[styles.tileLabel, { color: unlocked ? theme.onSurface : theme.onSurfaceVariant }]}
        >
          {name}
        </CKText>
        <CKText muted numberOfLines={1} role="metadata" style={styles.tileSubtitle}>
          {subtitle}
        </CKText>
      </View>
    </Pressable>
  );
}

function AchievementDetail({
  achievement,
  bottomInset,
  enableIdleRotation,
  modelRenderer: ModelRenderer,
  onClose,
  sheetHeight,
}: {
  achievement?: Achievement;
  bottomInset: number;
  enableIdleRotation: boolean;
  modelRenderer: ComponentType<AchievementModelViewerProps>;
  onClose: () => void;
  sheetHeight: number;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  if (!achievement) return null;
  const keys = ACHIEVEMENT_COPY_KEYS[achievement.id];
  const name = t(keys.name);
  return (
    <Modal
      animationType={enableIdleRotation ? 'slide' : 'none'}
      onRequestClose={onClose}
      presentationStyle="overFullScreen"
      transparent
      visible
    >
      <Pressable
        accessibilityViewIsModal
        onPress={onClose}
        style={[styles.scrim, { backgroundColor: colorWithAlpha('#000000', 0.72) }]}
      >
        <Pressable
          onPress={(event) => event.stopPropagation()}
          style={[
            styles.sheet,
            {
              height: sheetHeight,
              backgroundColor: theme.surface,
              borderColor: colorWithAlpha(theme.outlineVariant, ckOpacity.borderStrong),
              paddingBottom: bottomInset + ckSpacing.xl,
            },
          ]}
          testID="achievement-detail-sheet"
        >
          <View style={styles.closeRow}>
            <Pressable
              accessibilityLabel={materialCloseLabel(locale)}
              accessibilityRole="button"
              hitSlop={8}
              onPress={onClose}
              style={styles.headerAction}
              testID="achievement-detail-close"
            >
              <X color={theme.onSurface} size={24} />
            </Pressable>
          </View>
          <ScrollView contentContainerStyle={styles.detailContent}>
            <View style={{ height: Math.min(320, sheetHeight * 0.42), width: '100%' }}>
              <ModelRenderer
                achievement={achievement}
                enableIdleRotation={enableIdleRotation}
                interactive
                semanticLabel={name}
              />
            </View>
            <CKText role="screenTitle" style={styles.detailText}>
              {name}
            </CKText>
            <CKText muted role="body" style={styles.description}>
              {t(keys.description)}
            </CKText>
            <CKText role="metadata" style={styles.earnedCount}>
              {t('achievementEarnedCount', { count: String(achievement.earnedCount) })}
            </CKText>
          </ScrollView>
        </Pressable>
      </Pressable>
    </Modal>
  );
}

function useAchievementsSnapshot(repository?: AchievementsRepository): AchievementsSnapshot {
  const subscribe = useCallback(
    (listener: () => void) => repository?.subscribe(listener) ?? (() => undefined),
    [repository],
  );
  const getSnapshot = useCallback(() => repository?.snapshot ?? EMPTY_SNAPSHOT, [repository]);
  return useSyncExternalStore(subscribe, getSnapshot, getSnapshot);
}

const styles = StyleSheet.create({
  safeArea: { flex: 1 },
  header: {
    minHeight: 48,
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: ckSpacing.xl,
  },
  headerAction: {
    width: 48,
    height: 48,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 24,
  },
  backAction: { marginRight: ckSpacing.md },
  backActionRtl: { marginLeft: ckSpacing.md },
  headerCopy: { flex: 1, gap: ckSpacing.xs },
  grid: { flexDirection: 'row', flexWrap: 'wrap', gap: ckSpacing.lg },
  tile: { height: 220, borderRadius: ckRadius.tile, overflow: 'hidden' },
  tileBody: { flex: 1, padding: ckSpacing.xs, alignItems: 'stretch' },
  artwork: { flex: 1, overflow: 'hidden' },
  lockedArtwork: { opacity: 0.48 },
  lock: {
    position: 'absolute',
    top: ckSpacing.sm,
    right: ckSpacing.sm,
    width: 34,
    height: 34,
    borderRadius: 17,
    alignItems: 'center',
    justifyContent: 'center',
  },
  tileLabel: { marginTop: ckSpacing.sm, textAlign: 'center' },
  tileSubtitle: { marginTop: ckSpacing.xs, textAlign: 'center' },
  scrim: { flex: 1, alignItems: 'center', justifyContent: 'flex-end' },
  sheet: {
    width: '100%',
    maxWidth: 720,
    paddingTop: ckSpacing.sm,
    paddingHorizontal: ckSpacing.lg,
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopLeftRadius: ckRadius.card,
    borderTopRightRadius: ckRadius.card,
    overflow: 'hidden',
  },
  closeRow: { height: 48, alignItems: 'flex-end' },
  detailContent: {
    width: '100%',
    maxWidth: 640,
    alignSelf: 'center',
    alignItems: 'center',
  },
  detailText: { marginTop: ckSpacing.lg, textAlign: 'center' },
  description: { marginTop: ckSpacing.sm, textAlign: 'center' },
  earnedCount: { marginTop: ckSpacing.md, textAlign: 'center' },
});
