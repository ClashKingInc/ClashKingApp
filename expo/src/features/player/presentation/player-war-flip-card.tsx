import { useEffect, useState, type ReactNode } from 'react';
import { StyleSheet, View } from 'react-native';
import Reanimated, {
  Easing,
  useAnimatedStyle,
  useSharedValue,
  withSpring,
  withTiming,
} from 'react-native-reanimated';
import { BarChart3, RotateCcw } from 'lucide-react-native';
import { DashboardCardFrame } from '../../../ui/dashboard-card';
import { useI18n } from '../../../i18n';
import { CKText, useCKAccessibility, useCKTheme } from '../../../ui';

/** Both faces stay measured and mounted: reversing a flip preserves chart state and starts at the current angle. */
export function PlayerWarFlipCard({
  title,
  warCountLabel,
  accent,
  front,
  children,
}: {
  title: string;
  warCountLabel: string;
  accent: string;
  front: ReactNode;
  children: ReactNode;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const { reduceMotion } = useCKAccessibility();
  const [flipped, setFlipped] = useState(false);
  const [sizes, setSizes] = useState({ front: 0, back: 0 });
  const progress = useSharedValue(0);
  const height = useSharedValue(0);
  useEffect(() => {
    progress.value = reduceMotion
      ? Number(flipped)
      : withSpring(Number(flipped), { duration: 340, dampingRatio: 1 });
    const target = flipped ? sizes.back : sizes.front;
    if (target > 0)
      height.value =
        !height.value || reduceMotion
          ? target
          : withTiming(target, { duration: 260, easing: Easing.inOut(Easing.cubic) });
  }, [flipped, sizes, reduceMotion, progress, height]);
  const layout = useAnimatedStyle(() => ({ height: height.value || sizes.front || undefined }));
  const frontStyle = useAnimatedStyle(() => ({
    opacity: progress.value < 0.5 ? 1 : 0,
    transform: [{ perspective: 1200 }, { rotateY: `${progress.value * 180}deg` }],
  }));
  const backStyle = useAnimatedStyle(() => ({
    opacity: progress.value >= 0.5 ? 1 : 0,
    transform: [{ perspective: 1200 }, { rotateY: `${(progress.value - 1) * 180}deg` }],
  }));
  const measure = (side: 'front' | 'back', value: number) =>
    setSizes((old) =>
      Math.abs(old[side] - value) < 1 ? old : { ...old, [side]: Math.ceil(value) },
    );
  const footer = (back: boolean) => (
    <View style={styles.footer}>
      <CKText muted role="metadata">
        {warCountLabel}
      </CKText>
      <View style={styles.hint}>
        {!back ? <BarChart3 size={16} color={accent} /> : null}
        <CKText muted role="metadata">
          {t(back ? 'generalSummary' : 'generalCharts')}
        </CKText>
        <RotateCcw size={16} color={theme.onSurfaceVariant} />
      </View>
    </View>
  );
  return (
    <Reanimated.View style={layout} testID="player-war-flip-card">
      <Reanimated.View
        style={[styles.face, !sizes.front && styles.initialFace, frontStyle]}
        pointerEvents={flipped ? 'none' : 'auto'}
        accessibilityElementsHidden={flipped}
        importantForAccessibility={flipped ? 'no-hide-descendants' : 'auto'}
      >
        <DashboardCardFrame
          onLayout={(event) => measure('front', event.nativeEvent.layout.height)}
          onPress={() => setFlipped(true)}
          actionHint={t('tooltipShowChart')}
        >
          <View style={styles.content}>
            {front}
            {footer(false)}
          </View>
        </DashboardCardFrame>
      </Reanimated.View>
      <Reanimated.View
        style={[styles.face, backStyle]}
        pointerEvents={flipped ? 'auto' : 'none'}
        accessibilityElementsHidden={!flipped}
        importantForAccessibility={!flipped ? 'no-hide-descendants' : 'auto'}
      >
        <DashboardCardFrame
          onLayout={(event) => measure('back', event.nativeEvent.layout.height)}
          onPress={() => setFlipped(false)}
          actionHint={t('generalSummary')}
        >
          <View style={[styles.content, styles.chartContent]}>
            <View style={styles.backHeading}>
              <CKText role="rowTitle" style={{ flex: 1 }}>
                {title}
              </CKText>
            </View>
            {children}
            {footer(true)}
          </View>
        </DashboardCardFrame>
      </Reanimated.View>
    </Reanimated.View>
  );
}
const styles = StyleSheet.create({
  initialFace: { position: 'relative' },
  face: { position: 'absolute', top: 0, left: 0, right: 0, backfaceVisibility: 'hidden' },
  content: { gap: 8 },
  chartContent: { gap: 4 },
  footer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 10,
    paddingTop: 2,
  },
  hint: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'flex-end',
    gap: 7,
    paddingTop: 0,
  },
  backHeading: { flexDirection: 'row', alignItems: 'center', gap: 8, minHeight: 28 },
});
