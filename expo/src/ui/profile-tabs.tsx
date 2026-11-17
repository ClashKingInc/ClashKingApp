import { useCallback, useLayoutEffect, useRef, useState, type ReactNode } from 'react';
import { Animated, Easing, Platform, Pressable, ScrollView, StyleSheet, View } from 'react-native';
import type { ScrollViewInstance } from 'react-native';

import { DestinationPicker } from './destination-picker';
import { GlassSurface } from './glass';
import { tintIcon } from './icon-slot';
import { CKText } from './text';
import { ckControlHeight, ckRadius, ckSpacing, colorWithAlpha } from './tokens';
import { useCKTheme } from './theme';
import { useI18n } from '../i18n';
import { useCKAccessibility } from './accessibility';

export type ProfileTab = {
  key: string;
  label: string;
  icon?: ReactNode;
};

export type ProfileTabsProps = {
  tabs: readonly ProfileTab[];
  selectedKey: string;
  onSelect: (key: string) => void;
  overflowLabel?: string;
  onOverflowPress?: () => void;
  // Compact is legacy dense data chrome, not a section-navigation style.
  // For two-choice content switches use SlidingSegmentControl; profile
  // sections use underline. Do not revive compact tabs on new screens.
  variant?: 'glass' | 'underline' | 'compact';
  /** Fit keeps every section visible; useful for four short, text-only tabs. */
  overflow?: 'menu' | 'scroll' | 'fit';
  /** Optional continuous position from a pager; other profile tabs keep their existing behavior. */
  animatedPosition?: Animated.Value;
  indicatorRtl?: boolean;
  busy?: boolean;
};

export function ProfileTabs({
  tabs,
  selectedKey,
  onSelect,
  overflowLabel,
  onOverflowPress,
  variant = 'glass',
  overflow = 'menu',
  animatedPosition,
  indicatorRtl = false,
  busy = false,
}: ProfileTabsProps) {
  const theme = useCKTheme();
  const { isRtl } = useI18n();
  const { reduceMotion } = useCKAccessibility();
  const [underlineWidth, setUnderlineWidth] = useState(0);
  const followsPager = !!animatedPosition && overflow !== 'scroll' && tabs.length > 1;
  const selected = tabs.find((tab) => tab.key === selectedKey) ?? tabs[0];
  const tabScroll = useRef<ScrollViewInstance>(null);
  const tabFrames = useRef(new Map<string, { x: number; width: number }>());
  const scrollSize = useRef({ viewport: 0, content: 0, offset: 0 });
  const requestedKey = useRef<string | null>(null);
  const indicatorMeasured = useRef(false);
  const [indicatorVisible, setIndicatorVisible] = useState(false);
  const [indicatorCenter] = useState(() => new Animated.Value(0));
  const [indicatorScale] = useState(() => new Animated.Value(1));
  const indicatorAnimation = useRef<Animated.CompositeAnimation | null>(null);

  const positionIndicator = useCallback(
    (key: string, animate: boolean) => {
      if (followsPager) return;
      const frame = tabFrames.current.get(key);
      if (!frame || frame.width <= 0) return;
      const center = frame.x + frame.width / 2;
      indicatorAnimation.current?.stop();
      if (!indicatorMeasured.current || !animate || reduceMotion) {
        indicatorCenter.setValue(center);
        indicatorScale.setValue(frame.width);
      } else {
        const config = {
          duration: 200,
          easing: Easing.bezier(0.23, 1, 0.32, 1),
          isInteraction: false,
          useNativeDriver: Platform.OS !== 'web',
        };
        indicatorAnimation.current = Animated.parallel([
          Animated.timing(indicatorCenter, { ...config, toValue: center }),
          Animated.timing(indicatorScale, { ...config, toValue: frame.width }),
        ]);
        indicatorAnimation.current.start();
      }
      if (!indicatorMeasured.current) {
        indicatorMeasured.current = true;
        setIndicatorVisible(true);
      }
    },
    [followsPager, indicatorCenter, indicatorScale, reduceMotion],
  );

  const revealTab = useCallback(
    (key: string, animate: boolean) => {
      if (overflow !== 'scroll') return;
      const frame = tabFrames.current.get(key);
      const { viewport, content, offset } = scrollSize.current;
      if (!frame || viewport <= 0 || content <= viewport) return;
      const inset = 12;
      // A selected tab that is already visible must stay where the user put it.
      // Recentring every selection creates a second, unrelated navigation jump.
      let target = offset;
      if (frame.x < offset + inset) target = frame.x - inset;
      else if (frame.x + frame.width > offset + viewport - inset) {
        target = frame.x + frame.width - viewport + inset;
      }
      target = Math.max(0, Math.min(content - viewport, target));
      if (Math.abs(target - offset) < 1) return;
      tabScroll.current?.scrollTo({ x: target, animated: animate && !reduceMotion });
      if (!animate || reduceMotion) scrollSize.current.offset = target;
    },
    [overflow, reduceMotion],
  );

  useLayoutEffect(() => {
    // The press starts native motion before a potentially expensive parent
    // render. Do not restart that motion when the controlled value commits.
    if (requestedKey.current === selectedKey) {
      requestedKey.current = null;
      return;
    }
    requestedKey.current = null;
    positionIndicator(selectedKey, false);
    revealTab(selectedKey, false);
  }, [selectedKey, isRtl, positionIndicator, revealTab]);
  useLayoutEffect(() => () => indicatorAnimation.current?.stop(), []);

  const selectTab = (key: string) => {
    if (key === selectedKey) return;
    requestedKey.current = key;
    positionIndicator(key, true);
    revealTab(key, true);
    onSelect(key);
  };
  const underline =
    !followsPager && indicatorVisible ? (
      <Animated.View
        pointerEvents="none"
        style={[styles.indicatorAnchor, { transform: [{ translateX: indicatorCenter }] }]}
      >
        <Animated.View
          style={[
            styles.indicatorBar,
            { backgroundColor: theme.primary, transform: [{ scaleX: indicatorScale }] },
          ]}
        />
      </Animated.View>
    ) : null;

  if (tabs.length > 3 && overflow === 'menu') {
    return (
      <DestinationPicker
        accessibilityLabel={overflowLabel ?? selected?.label}
        externallyManaged={onOverflowPress !== undefined}
        onOpen={onOverflowPress}
        onSelect={onSelect}
        options={tabs}
        selectedKey={selectedKey}
        showPositionHint
      />
    );
  }

  if (variant === 'underline') {
    const underlineTabs = tabs.map((tab) => {
      const isSelected = tab.key === selectedKey;
      return (
        <Pressable
          key={tab.key}
          testID={`profile-tabs-underline-tab-${tab.key}`}
          accessibilityRole="tab"
          accessibilityState={{ selected: isSelected, busy: isSelected && busy }}
          accessibilityLabel={tab.label}
          onPress={() => selectTab(tab.key)}
          onLayout={({ nativeEvent: { layout } }) => {
            // display:none retained hosts may report zero geometry. Keep the
            // last real frame until the tab is visible and measured again.
            if (layout.width <= 0) return;
            const previous = tabFrames.current.get(tab.key);
            const changed = previous?.x !== layout.x || previous?.width !== layout.width;
            tabFrames.current.set(tab.key, { x: layout.x, width: layout.width });
            if (changed && isSelected) {
              positionIndicator(tab.key, false);
              revealTab(tab.key, false);
            }
          }}
          style={({ pressed }) => [
            styles.underlineTab,
            overflow === 'scroll' ? styles.underlineScrollTab : { flex: 1 },
            pressed && { opacity: 0.8 },
          ]}
        >
          {tintIcon(tab.icon, colorWithAlpha(theme.onSurface, isSelected ? 1 : 0.64))}
          <CKText
            skeleton={false}
            role="labelLarge"
            style={{ color: colorWithAlpha(theme.onSurface, isSelected ? 1 : 0.64) }}
          >
            {tab.label}
          </CKText>
        </Pressable>
      );
    });
    const underlineStyle = [
      styles.underlineBar,
      { borderBottomColor: colorWithAlpha(theme.outlineVariant, 0.35) },
    ];
    return overflow === 'scroll' ? (
      <ScrollView
        ref={tabScroll}
        testID="profile-tabs-underline-scroll"
        horizontal
        nestedScrollEnabled
        showsHorizontalScrollIndicator={false}
        // Keep scroll coordinates physical on every platform, then reverse
        // the row for RTL. A deep-linked selection stays visible after resize.
        style={[underlineStyle, { direction: 'ltr' }]}
        contentContainerStyle={styles.underlineScrollContainer}
        scrollEventThrottle={16}
        onScroll={({ nativeEvent }) => {
          scrollSize.current.offset = nativeEvent.contentOffset.x;
        }}
        onLayout={({ nativeEvent: { layout } }) => {
          const changed = scrollSize.current.viewport !== layout.width;
          scrollSize.current.viewport = layout.width;
          if (changed) revealTab(selectedKey, false);
        }}
        onContentSizeChange={(width) => {
          const changed = scrollSize.current.content !== width;
          scrollSize.current.content = width;
          if (changed) revealTab(selectedKey, false);
        }}
      >
        <View
          style={[styles.underlineScrollContent, { flexDirection: isRtl ? 'row-reverse' : 'row' }]}
        >
          {underlineTabs}
          {underline}
        </View>
      </ScrollView>
    ) : (
      <View
        testID="profile-tabs-underline"
        style={[
          underlineStyle,
          { flexDirection: (followsPager ? indicatorRtl : isRtl) ? 'row-reverse' : 'row' },
        ]}
        onLayout={(event) => setUnderlineWidth(event.nativeEvent.layout.width)}
      >
        {underlineTabs}
        {underline}
        {followsPager && underlineWidth > 0 ? (
          <Animated.View
            pointerEvents="none"
            style={{
              position: 'absolute',
              left: 0,
              bottom: 0,
              height: 2.5,
              width: underlineWidth / tabs.length,
              backgroundColor: theme.primary,
              transform: [
                {
                  translateX: animatedPosition!.interpolate({
                    inputRange: [0, tabs.length - 1],
                    outputRange: indicatorRtl
                      ? [underlineWidth - underlineWidth / tabs.length, 0]
                      : [0, underlineWidth - underlineWidth / tabs.length],
                    extrapolate: 'clamp',
                  }),
                },
              ],
            }}
          />
        ) : null}
      </View>
    );
  }

  if (variant === 'compact') {
    return (
      <View
        testID="profile-tabs-compact"
        style={[
          styles.compactBar,
          {
            backgroundColor: colorWithAlpha(theme.onSurface, 0.06),
            borderColor: colorWithAlpha(theme.outlineVariant, 0.32),
          },
        ]}
      >
        {tabs.map((tab) => {
          const isSelected = tab.key === selectedKey;
          return (
            <Pressable
              key={tab.key}
              testID={`profile-tabs-compact-tab-${tab.key}`}
              accessibilityRole="tab"
              accessibilityState={{ selected: isSelected }}
              accessibilityLabel={tab.label}
              onPress={() => onSelect(tab.key)}
              style={[
                styles.compactTab,
                isSelected && { backgroundColor: colorWithAlpha(theme.onSurface, 0.12) },
              ]}
            >
              <CKText skeleton={false} role="labelSmall">
                {tab.label}
              </CKText>
            </Pressable>
          );
        })}
      </View>
    );
  }

  return (
    <GlassSurface cornerRadius={ckRadius.card} style={styles.tabBar}>
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.tabContent}
      >
        {tabs.map((tab) => {
          const isSelected = tab.key === selectedKey;
          return (
            <Pressable
              key={tab.key}
              accessibilityRole="tab"
              accessibilityState={{ selected: isSelected }}
              accessibilityLabel={tab.label}
              onPress={() => onSelect(tab.key)}
              style={[
                styles.tab,
                isSelected && { backgroundColor: colorWithAlpha(theme.primary, 0.14) },
              ]}
            >
              {tintIcon(tab.icon, isSelected ? theme.primary : theme.onSurfaceVariant)}
              <CKText
                skeleton={false}
                role="labelLarge"
                style={isSelected ? { color: theme.primary } : undefined}
              >
                {tab.label}
              </CKText>
            </Pressable>
          );
        })}
      </ScrollView>
    </GlassSurface>
  );
}

const styles = StyleSheet.create({
  underlineBar: {
    height: 50,
    flexDirection: 'row',
    borderBottomWidth: StyleSheet.hairlineWidth,
  },
  underlineTab: {
    height: 50,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: ckSpacing.sm,
  },
  underlineScrollContainer: { flexGrow: 1 },
  underlineScrollContent: { flexDirection: 'row', alignItems: 'stretch', flexGrow: 1 },
  // Keep intrinsic label widths in horizontal web scroll views. `flex: 0`
  // becomes a zero flex-basis there and makes the labels overlap.
  underlineScrollTab: { flexGrow: 0, flexShrink: 0, paddingHorizontal: ckSpacing.lg },
  // A fixed one-point bar scales around its center. Separate translation and
  // scale wrappers keep both properties native-driven without scaling position.
  indicatorAnchor: { position: 'absolute', left: 0, bottom: 0, width: 0, height: 2.5 },
  indicatorBar: { position: 'absolute', left: -0.5, top: 0, width: 1, height: 2.5 },
  compactBar: {
    height: 32,
    flexDirection: 'row',
    padding: 2,
    borderWidth: StyleSheet.hairlineWidth,
    borderRadius: 8,
  },
  compactTab: {
    flex: 1,
    minWidth: 72,
    height: 28,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 6,
  },
  tabBar: { minHeight: 50 },
  tabContent: { flexGrow: 1, padding: 3, gap: ckSpacing.xs },
  tab: {
    minWidth: 104,
    minHeight: ckControlHeight.compact,
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: ckSpacing.sm,
    paddingHorizontal: ckSpacing.md,
    borderRadius: ckRadius.tile,
  },
});
