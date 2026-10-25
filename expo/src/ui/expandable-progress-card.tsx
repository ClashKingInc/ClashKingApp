import { useEffect, useState, type ReactNode } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import Reanimated, {
  Easing,
  useAnimatedStyle,
  useSharedValue,
  withTiming,
} from 'react-native-reanimated';
import { ChevronRight } from 'lucide-react-native';
import { CKText, MobileWebImage, Surface, colorWithAlpha, statColors, useCKTheme } from './index';
import { useCKAccessibility } from './accessibility';

/** Shared browsing shell. Keep its measured body mounted after first use so
 * rapid reversals continue from the current height instead of flashing a grid. */
export function ExpandableProgressCard({
  title,
  imageUrl,
  imageScale = 1,
  percent,
  open,
  onToggle,
  footer,
  trailing,
  headerAccessory,
  showProgress = true,
  compactHeader = false,
  children,
}: {
  title: string;
  imageUrl: string;
  imageScale?: number;
  percent: number;
  open: boolean;
  onToggle: () => void;
  footer?: ReactNode;
  trailing?: ReactNode;
  headerAccessory?: ReactNode;
  showProgress?: boolean;
  compactHeader?: boolean;
  children?: ReactNode;
}) {
  const theme = useCKTheme();
  const { reduceMotion } = useCKAccessibility();
  const [bodyHeight, setBodyHeight] = useState(0);
  const [hasOpened, setHasOpened] = useState(open);
  if (open && !hasOpened) setHasOpened(true);
  const height = useSharedValue(0);
  const rotation = useSharedValue(open ? 90 : 0);
  useEffect(() => {
    const config = { duration: reduceMotion ? 0 : 220, easing: Easing.out(Easing.cubic) };
    height.value = withTiming(open ? bodyHeight : 0, config);
    rotation.value = withTiming(open ? 90 : 0, config);
  }, [open, bodyHeight, reduceMotion, height, rotation]);
  const bodyStyle = useAnimatedStyle(() => ({ height: height.value }));
  const arrowStyle = useAnimatedStyle(() => ({ transform: [{ rotate: `${rotation.value}deg` }] }));
  const boundedPercent = Math.max(0, Math.min(100, percent));
  // Do not round unfinished sections up to 100%; completion text and color must agree.
  const displayedPercent =
    boundedPercent < 100 ? Math.min(99.9, Math.round(boundedPercent * 10) / 10) : 100;
  return (
    <Surface style={styles.card}>
      <View style={styles.top}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={title}
          accessibilityState={{ expanded: open }}
          onPress={onToggle}
          style={styles.trigger}
        >
          <MobileWebImage
            skeleton={false}
            imageUrl={imageUrl}
            style={[
              styles.image,
              compactHeader && styles.compactImage,
              { transform: [{ scale: imageScale }] },
            ]}
          />
          <CKText
            skeleton={false}
            role={compactHeader ? 'rowTitle' : 'titleSmall'}
            style={[styles.title, compactHeader && styles.compactTitle]}
          >
            {title}
          </CKText>
          {showProgress ? <CKText role="bodyMedium">{displayedPercent}%</CKText> : null}
          {headerAccessory}
          <Reanimated.View style={arrowStyle}>
            <ChevronRight size={20} color={theme.onSurfaceVariant} />
          </Reanimated.View>
        </Pressable>
        {trailing}
      </View>
      {showProgress ? (
        <View style={[styles.track, { backgroundColor: colorWithAlpha(theme.onSurface, 0.12) }]}>
          <View
            style={[
              styles.fill,
              {
                width: `${boundedPercent}%`,
                backgroundColor: boundedPercent >= 100 ? statColors.win : '#E8BC52',
              },
            ]}
          />
        </View>
      ) : null}
      {footer ? <View style={styles.footer}>{footer}</View> : null}
      <Reanimated.View
        pointerEvents={open ? 'auto' : 'none'}
        accessibilityElementsHidden={!open}
        importantForAccessibility={open ? 'auto' : 'no-hide-descendants'}
        style={[styles.body, bodyStyle]}
      >
        <View
          onLayout={(event) => setBodyHeight(event.nativeEvent.layout.height)}
          style={styles.measuredBody}
        >
          {hasOpened && children ? <View style={styles.content}>{children}</View> : null}
        </View>
      </Reanimated.View>
    </Surface>
  );
}

const styles = StyleSheet.create({
  card: { paddingHorizontal: 12, paddingVertical: 10, borderWidth: 0 },
  top: { flexDirection: 'row', alignItems: 'center' },
  trigger: { flex: 1, minHeight: 38, flexDirection: 'row', alignItems: 'center', gap: 8 },
  image: { width: 32, height: 32 },
  title: { flex: 1 },
  compactTitle: { flex: 0, flexShrink: 1, maxWidth: '36%' },
  compactImage: { width: 22, height: 22 },
  track: { height: 4, borderRadius: 4, overflow: 'hidden', marginTop: 4 },
  fill: { height: 4, borderRadius: 4, backgroundColor: '#E8BC52' },
  footer: { marginTop: 6, flexDirection: 'row', alignItems: 'center', flexWrap: 'wrap', gap: 8 },
  body: { overflow: 'hidden' },
  measuredBody: { position: 'absolute', left: 0, right: 0 },
  content: { paddingTop: 12 },
});
