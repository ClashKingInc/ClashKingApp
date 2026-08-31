import { useContext, useEffect, useState, type ReactNode } from 'react';
import {
  ActivityIndicator,
  Animated,
  Easing,
  Modal,
  Pressable,
  Platform,
  StyleSheet,
  View,
  type StyleProp,
  type ViewStyle,
  useWindowDimensions,
} from 'react-native';
import { SafeAreaInsetsContext } from 'react-native-safe-area-context';

import { useCKAccessibility } from './accessibility';
import { ImageAssets } from '../core/assets/image-assets';
import { MobileWebImage } from './mobile-web-image';
import { CKText } from './text';
import { ckRadius, ckSpacing, colorWithAlpha } from './tokens';
import { useCKTheme } from './theme';

export function LoadingIndicator({ label }: { label?: string }) {
  const theme = useCKTheme();
  return (
    <View accessibilityRole="progressbar" accessibilityLabel={label} style={styles.loadingRow}>
      <ActivityIndicator color={theme.primary} />
      {label ? <CKText muted>{label}</CKText> : null}
    </View>
  );
}

export function LoadingScreen({ label, mark }: { label?: string; mark?: ReactNode }) {
  return (
    <View style={styles.centered}>
      {mark}
      <LoadingIndicator label={label} />
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
  height?: number;
  radius?: number;
  style?: StyleProp<ViewStyle>;
}) {
  const theme = useCKTheme();
  const { reduceMotion } = useCKAccessibility();
  const [opacity] = useState(() => new Animated.Value(0.42));

  useEffect(() => {
    if (reduceMotion) {
      opacity.setValue(0.62);
      return;
    }
    const animation = Animated.loop(
      Animated.sequence([
        Animated.timing(opacity, {
          toValue: 0.82,
          duration: 900,
          easing: Easing.inOut(Easing.ease),
          useNativeDriver: true,
        }),
        Animated.timing(opacity, {
          toValue: 0.42,
          duration: 900,
          easing: Easing.inOut(Easing.ease),
          useNativeDriver: true,
        }),
      ]),
    );
    animation.start();
    return () => animation.stop();
  }, [opacity, reduceMotion]);

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

export function SkeletonLoadingDialog({ visible }: { visible: boolean }) {
  const theme = useCKTheme();
  return (
    <Modal visible={visible} transparent animationType="fade">
      <View
        style={styles.skeletonDialogOverlay}
        accessibilityViewIsModal
        testID="skeleton-loading-dialog"
      >
        <View
          style={[
            styles.skeletonDialog,
            {
              backgroundColor: theme.surface,
              borderColor: colorWithAlpha(theme.outlineVariant, 0.36),
            },
          ]}
        >
          <Skeleton width={48} height={48} radius={ckRadius.control} />
          <View style={styles.skeletonDialogCopy}>
            <Skeleton height={16} radius={ckSpacing.xs} />
            <Skeleton width={140} height={12} radius={ckSpacing.xs} />
          </View>
        </View>
      </View>
    </Modal>
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
  stickerHeight = 170,
  stickerWidth = 140,
  style,
  ...props
}: FeedbackStateProps) {
  return (
    <View style={[styles.emptyState, style]}>
      <FeedbackState {...props} />
      {showSticker ? (
        <MobileWebImage
          accessibilityIgnoresInvertColors
          contentFit="contain"
          imageUrl={ImageAssets.thinkingBuilder}
          style={{ width: stickerWidth, height: stickerHeight, marginTop: 18 }}
          testID="empty-state-sticker"
        />
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
      : ckSpacing.xl;
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
  skeletonDialogOverlay: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#00000052',
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
  emptyState: { width: '100%', alignItems: 'center' },
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
