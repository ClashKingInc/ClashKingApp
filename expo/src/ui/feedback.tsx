import { useContext, useEffect, type ReactNode } from 'react';
import {
  ActivityIndicator,
  Animated,
  Pressable,
  Platform,
  StyleSheet,
  View,
  type StyleProp,
  type ViewStyle,
  useWindowDimensions,
} from 'react-native';
import { SafeAreaInsetsContext } from 'react-native-safe-area-context';

import { ImageAssets } from '../core/assets/image-assets';
import { MobileWebImage } from './mobile-web-image';
import { CKText } from './text';
import { ckRadius, ckSpacing, colorWithAlpha } from './tokens';
import { useCKTheme } from './theme';
import { useSkeletonAppearance } from './skeleton-content';
import { useSkeletonMotion } from './skeleton-motion';

export function LoadingIndicator({ label }: { label?: string }) {
  const theme = useCKTheme();
  return (
    <View accessibilityRole="progressbar" accessibilityLabel={label} style={styles.loadingRow}>
      <ActivityIndicator color={theme.primary} />
      {label ? <CKText muted>{label}</CKText> : null}
    </View>
  );
}

export function Skeleton({
  width = '100%',
  height = 16,
  radius = ckRadius.control,
  style,
}: {
  width?: ViewStyle['width'];
  height?: ViewStyle['height'];
  radius?: number;
  style?: StyleProp<ViewStyle>;
}) {
  const theme = useCKTheme();
  const inherited = useSkeletonAppearance();
  const ownOpacity = useSkeletonMotion(!inherited.loading);
  const opacity = inherited.loading ? inherited.opacity : ownOpacity;

  return (
    <Animated.View
      accessibilityElementsHidden
      importantForAccessibility="no-hide-descendants"
      style={[
        {
          width,
          height,
          borderRadius: radius,
          backgroundColor: theme.surfaceContainerHighest,
          opacity,
        },
        style,
      ]}
    />
  );
}

type FeedbackStateProps = {
  title: string;
  body?: string;
  icon?: ReactNode;
  actionLabel?: string;
  onAction?: () => void;
  style?: StyleProp<ViewStyle>;
  showSticker?: boolean;
  stickerHeight?: number;
  stickerWidth?: number;
};

function FeedbackState({ title, body, icon, actionLabel, onAction, style }: FeedbackStateProps) {
  const theme = useCKTheme();
  return (
    <View
      accessibilityRole="summary"
      style={[
        styles.feedback,
        {
          backgroundColor: theme.card,
          borderColor: colorWithAlpha(theme.outlineVariant, 0.32),
        },
        style,
      ]}
    >
      {icon ? (
        <View
          style={[
            styles.iconCircle,
            { backgroundColor: colorWithAlpha(theme.surfaceContainerHighest, 0.45) },
          ]}
        >
          {icon}
        </View>
      ) : null}
      <View style={styles.feedbackCopy}>
        <CKText role="bodyMedium" style={styles.feedbackTitle}>
          {title}
        </CKText>
        {body ? (
          <CKText muted role="bodySmall" style={styles.feedbackBody}>
            {body}
          </CKText>
        ) : null}
        {actionLabel && onAction ? (
          <Pressable accessibilityRole="button" onPress={onAction} style={styles.action}>
            <CKText role="bodyMedium" style={{ color: theme.primary }}>
              {actionLabel}
            </CKText>
          </Pressable>
        ) : null}
      </View>
    </View>
  );
}

export function EmptyState({
  showSticker = true,
  stickerHeight = 112,
  stickerWidth = 96,
  style,
  title,
  body,
  icon,
  actionLabel,
  onAction,
}: FeedbackStateProps) {
  const theme = useCKTheme();
  return (
    <View testID="empty-state" accessibilityRole="summary" style={[styles.emptyState, style]}>
      {icon ??
        (showSticker ? (
          <MobileWebImage
            accessibilityIgnoresInvertColors
            contentFit="contain"
            imageUrl={ImageAssets.thinkingBuilder}
            style={{ width: stickerWidth, height: stickerHeight }}
            testID="empty-state-sticker"
          />
        ) : null)}
      <CKText role="bodyMedium" style={styles.emptyTitle}>
        {title}
      </CKText>
      {body ? (
        <CKText muted role="bodySmall" style={styles.emptyBody}>
          {body}
        </CKText>
      ) : null}
      {actionLabel && onAction ? (
        <Pressable accessibilityRole="button" onPress={onAction} style={styles.emptyAction}>
          <CKText role="bodyMedium" style={{ color: theme.primary }}>
            {actionLabel}
          </CKText>
        </Pressable>
      ) : null}
    </View>
  );
}

export function ErrorState(props: FeedbackStateProps) {
  const theme = useCKTheme();
  return (
    <FeedbackState
      {...props}
      style={[{ borderColor: colorWithAlpha(theme.error, 0.38) }, props.style]}
    />
  );
}

export function Snackbar({
  message,
  onDismiss,
  duration = 4000,
  avoidBottomNavigation = false,
}: {
  message?: string;
  onDismiss: () => void;
  duration?: number;
  avoidBottomNavigation?: boolean;
}) {
  const theme = useCKTheme();
  const insets = useContext(SafeAreaInsetsContext) ?? { top: 0, right: 0, bottom: 0, left: 0 };
  const { width } = useWindowDimensions();
  const bottom =
    avoidBottomNavigation && !(Platform.OS === 'web' && width >= 900)
      ? insets.bottom + 96
      : insets.bottom + ckSpacing.xl;
  useEffect(() => {
    if (!message || duration <= 0) return undefined;
    const timer = setTimeout(onDismiss, duration);
    return () => clearTimeout(timer);
  }, [duration, message, onDismiss]);
  if (!message) return null;
  return (
    <Pressable
      accessibilityLiveRegion="polite"
      accessibilityRole="alert"
      onPress={onDismiss}
      style={[
        styles.snackbar,
        {
          backgroundColor: theme.snackbar,
          borderColor: colorWithAlpha(theme.outlineVariant, 0.3),
          bottom,
        },
      ]}
    >
      <CKText>{message}</CKText>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  centered: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: ckSpacing.lg,
    padding: ckSpacing.xl,
  },
  skeletonDialog: {
    width: '100%',
    maxWidth: 264,
    marginHorizontal: 28,
    padding: 18,
    borderRadius: ckRadius.card,
    borderWidth: StyleSheet.hairlineWidth,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    shadowColor: '#000000',
    shadowOpacity: 0.18,
    shadowRadius: 24,
    shadowOffset: { width: 0, height: 12 },
    elevation: 8,
  },
  skeletonDialogCopy: { flex: 1, gap: 10 },
  loadingRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: ckSpacing.md,
    minHeight: 44,
  },
  feedback: {
    minHeight: 72,
    flexDirection: 'row',
    alignItems: 'center',
    gap: ckSpacing.md,
    padding: ckSpacing.lg,
    borderWidth: StyleSheet.hairlineWidth,
    borderRadius: ckRadius.tile,
  },
  iconCircle: {
    width: 38,
    height: 38,
    borderRadius: 19,
    alignItems: 'center',
    justifyContent: 'center',
  },
  feedbackCopy: {
    flex: 1,
    gap: 2,
  },
  feedbackTitle: { fontWeight: '900' },
  feedbackBody: { fontWeight: '600' },
  emptyState: {
    width: '100%',
    minHeight: 240,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 24,
    paddingVertical: 32,
    gap: 10,
  },
  emptyTitle: { textAlign: 'center', fontWeight: '800', maxWidth: 320 },
  emptyBody: { textAlign: 'center', maxWidth: 300 },
  emptyAction: {
    minHeight: 44,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 20,
    marginTop: 4,
  },
  action: {
    minHeight: 32,
    alignSelf: 'flex-start',
    justifyContent: 'center',
    marginTop: ckSpacing.sm,
  },
  snackbar: {
    position: 'absolute',
    left: ckSpacing.lg,
    right: ckSpacing.lg,
    minHeight: 48,
    justifyContent: 'center',
    paddingHorizontal: ckSpacing.lg,
    paddingVertical: ckSpacing.md,
    borderRadius: ckRadius.control,
    borderWidth: StyleSheet.hairlineWidth,
    shadowColor: '#000000',
    shadowOpacity: 0.18,
    shadowRadius: 12,
    shadowOffset: { width: 0, height: 5 },
    elevation: 8,
  },
});
