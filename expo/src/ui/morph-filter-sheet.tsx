import { useEffect, useRef, useState, type ReactNode } from 'react';
import { Animated, Modal, Pressable, ScrollView, StyleSheet, View } from 'react-native';
import Reanimated, { useSharedValue, useAnimatedStyle, withSpring } from 'react-native-reanimated';
import { ChevronLeft, Check, X } from '@/ui/icons';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { materialBackLabel, useI18n } from '../i18n';
import { CKText } from './text';
import { MobileWebImage } from './mobile-web-image';
import { GlassSurface } from './glass';
import { useCKTheme } from './theme';
import { useCKAccessibility } from './accessibility';
import { useAdaptiveLayout } from './adaptive-layout';
import { ReservedRegionLayout } from './reserved-region-layout';
import { modalOrientations } from './modal-orientations';

export type FilterChoicePage = {
  title: string;
  value: string;
  options: readonly { value: string; label: string; imageUrl?: string | null; icon?: ReactNode }[];
  onChange: (value: string) => void;
};
/** The shared search filter surface: one measured, morphing sheet for overview and choices. */
export function MorphFilterSheet({
  title,
  children,
  onClose,
  onReset,
  onApply,
  applyLabel,
}: {
  title: string;
  children: (open: (page: FilterChoicePage) => void) => ReactNode;
  onClose: () => void;
  onReset: () => void;
  onApply: () => void;
  applyLabel: string;
}) {
  const { t, isRtl, locale } = useI18n();
  const theme = useCKTheme();
  const layout = useAdaptiveLayout();
  const insets = useSafeAreaInsets();
  const docked = layout.isDuo || !layout.isExpanded;
  const { reduceMotion } = useCKAccessibility();
  const [choicePage, setChoicePage] = useState<FilterChoicePage | null>(null);
  const [bodyOpacity] = useState(() => new Animated.Value(1));
  const bodyHeight = useSharedValue(0);
  const [bodyMeasured, setBodyMeasured] = useState(false);
  const transitionVersion = useRef(0);
  useEffect(
    () => () => {
      transitionVersion.current += 1;
      bodyOpacity.stopAnimation();
    },
    [bodyOpacity],
  );
  const bodyStyle = useAnimatedStyle(() => ({ height: bodyHeight.get() }));
  const maxBodyHeight = Math.max(100, layout.height * 0.9 - 170);
  const measureBody = (_width: number, height: number) => {
    const target = Math.min(height, maxBodyHeight);
    if (!bodyMeasured || reduceMotion) bodyHeight.set(target);
    else
      bodyHeight.set(
        withSpring(target, {
          damping: 30,
          stiffness: 300,
          mass: 1,
          overshootClamping: true,
        }),
      );
    setBodyMeasured(true);
  };
  const changePage = (page: FilterChoicePage | null) => {
    // Keep the outgoing content in place until it fades. Then measure the new
    // page and animate the existing surface on the UI thread, without a new modal.
    const version = ++transitionVersion.current;
    bodyOpacity.stopAnimation();
    if (reduceMotion) {
      setChoicePage(page);
      bodyOpacity.setValue(1);
      return;
    }
    Animated.timing(bodyOpacity, { toValue: 0, duration: 85, useNativeDriver: true }).start(
      ({ finished }) => {
        if (!finished || version !== transitionVersion.current) return;
        setChoicePage(page);
        Animated.timing(bodyOpacity, {
          toValue: 1,
          duration: 190,
          delay: 30,
          useNativeDriver: true,
        }).start();
      },
    );
  };
  const close = onClose;
  return (
    <Modal
      transparent
      visible
      supportedOrientations={modalOrientations}
      animationType={reduceMotion ? 'none' : docked ? 'slide' : 'fade'}
      statusBarTranslucent
      navigationBarTranslucent
      presentationStyle="overFullScreen"
      onRequestClose={() => (choicePage ? changePage(null) : close())}
    >
      <ReservedRegionLayout>
        <View
          style={[
            styles.filterBackdrop,
            {
              paddingTop: insets.top + 12,
              paddingBottom: docked ? 0 : insets.bottom + 12,
              paddingLeft: docked ? insets.left : Math.max(12, insets.left),
              paddingRight: docked ? insets.right : Math.max(12, insets.right),
              // Phones dock at the bottom; Duo keeps that presentation when
              // expanded. Preserve side insets so its toolbar stays clear.
              justifyContent: docked ? 'flex-end' : layout.isExpanded ? 'center' : 'flex-end',
            },
          ]}
        >
          <Pressable
            style={StyleSheet.absoluteFill}
            onPress={close}
            accessibilityRole="button"
            accessibilityLabel={t('upgradeTrackerPlanClose')}
          />
          <GlassSurface
            cornerRadius={28}
            style={[
              styles.filterSheet,
              { backgroundColor: theme.surface },
              docked && styles.dockedSheet,
              docked && { paddingBottom: Math.max(insets.bottom, 12) },
            ]}
            accessibilityViewIsModal
            onAccessibilityEscape={close}
          >
            <View style={styles.filterSheetHeader}>
              {choicePage ? (
                <Pressable
                  accessibilityRole="button"
                  accessibilityLabel={materialBackLabel(locale)}
                  onPress={() => changePage(null)}
                  style={styles.cancelButton}
                >
                  <ChevronLeft size={22} color={theme.onSurface} />
                </Pressable>
              ) : (
                <View style={styles.cancelButton} />
              )}
              <CKText role="sectionTitle" numberOfLines={2} style={styles.filterSheetTitle}>
                {choicePage?.title ?? title}
              </CKText>
              <Pressable
                onPress={close}
                accessibilityRole="button"
                accessibilityLabel={t('upgradeTrackerPlanClose')}
                style={styles.cancelButton}
              >
                <X size={22} color={theme.onSurface} />
              </Pressable>
            </View>
            <Reanimated.View style={bodyMeasured ? bodyStyle : { maxHeight: maxBodyHeight }}>
              <Animated.View style={[bodyMeasured && { flex: 1 }, { opacity: bodyOpacity }]}>
                <ScrollView
                  key={choicePage?.title ?? 'overview'}
                  onContentSizeChange={measureBody}
                  keyboardShouldPersistTaps="handled"
                  contentContainerStyle={styles.filterSheetContent}
                >
                  {choicePage ? (
                    choicePage.options.map((option) => (
                      <Pressable
                        key={option.value}
                        accessibilityRole="radio"
                        accessibilityState={{ checked: option.value === choicePage.value }}
                        onPress={() => {
                          choicePage.onChange(option.value);
                          changePage(null);
                        }}
                        style={[styles.choiceRow, isRtl && styles.rowRtl]}
                      >
                        {option.icon ? (
                          option.icon
                        ) : option.imageUrl ? (
                          <MobileWebImage
                            imageUrl={option.imageUrl}
                            style={styles.filterIconImage}
                            contentFit="contain"
                          />
                        ) : option.value === '' ? (
                          <View
                            style={[
                              styles.unsetFilterIcon,
                              { backgroundColor: theme.surfaceContainerHighest },
                            ]}
                          >
                            <X size={16} strokeWidth={3} color={theme.onSurfaceVariant} />
                          </View>
                        ) : null}
                        <CKText role="rowTitle" style={styles.grow}>
                          {option.label}
                        </CKText>
                        {option.value === choicePage.value ? (
                          <Check size={21} color={theme.primary} />
                        ) : null}
                      </Pressable>
                    ))
                  ) : (
                    <FilterBody render={children} open={changePage} />
                  )}
                </ScrollView>
              </Animated.View>
            </Reanimated.View>
            {
              <View style={[styles.filterSheetFooter, isRtl && styles.rowRtl]}>
                <Pressable
                  accessibilityRole="button"
                  onPress={onReset}
                  style={[
                    styles.filterFooterButton,
                    { backgroundColor: theme.surfaceContainerHighest },
                  ]}
                >
                  <CKText role="rowTitle">{t('generalReset')}</CKText>
                </Pressable>
                <Pressable
                  accessibilityRole="button"
                  onPress={() => {
                    onApply();
                    close();
                  }}
                  style={[styles.filterFooterButton, { backgroundColor: theme.primary }]}
                >
                  <CKText role="rowTitle" style={{ color: theme.onPrimary }}>
                    {applyLabel}
                  </CKText>
                </Pressable>
              </View>
            }
          </GlassSurface>
        </View>
      </ReservedRegionLayout>
    </Modal>
  );
}

const styles = StyleSheet.create({
  filterBackdrop: { flex: 1, backgroundColor: '#00000070', alignItems: 'center' },
  filterSheet: { width: '100%', maxWidth: 560, maxHeight: '90%', overflow: 'hidden' },
  dockedSheet: {
    maxWidth: '100%',
    borderBottomLeftRadius: 0,
    borderBottomRightRadius: 0,
  },
  filterSheetHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 10,
    paddingTop: 10,
    paddingBottom: 4,
    gap: 8,
  },
  filterSheetTitle: { flex: 1, minWidth: 0, textAlign: 'center' },
  filterSheetContent: { paddingHorizontal: 22, paddingVertical: 12 },
  filterSheetFooter: { flexDirection: 'row', gap: 12, padding: 18 },
  filterFooterButton: {
    flex: 1,
    minHeight: 48,
    borderRadius: 24,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 12,
  },
  unsetFilterIcon: {
    width: 24,
    height: 24,
    borderRadius: 7,
    alignItems: 'center',
    justifyContent: 'center',
  },
  choiceRow: {
    minHeight: 52,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingVertical: 12,
  },
  cancelButton: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  filterIconImage: { width: 30, height: 30 },
  grow: { flex: 1 },
  rowRtl: { flexDirection: 'row-reverse' },
});

function FilterBody({
  render,
  open,
}: {
  render: (open: (page: FilterChoicePage) => void) => ReactNode;
  open: (page: FilterChoicePage) => void;
}) {
  return <>{render(open)}</>;
}
