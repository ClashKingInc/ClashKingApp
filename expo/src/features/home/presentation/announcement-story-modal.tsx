import { useEffect, useRef, useState } from 'react';
import {
  Animated,
  Easing,
  Modal,
  Pressable,
  StyleSheet,
  View,
  useWindowDimensions,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { Skeleton, ckMotion, ckRadius, colorWithAlpha, useCKAccessibility } from '../../../ui';
import type { AppAnnouncement } from '../data';
import { AnnouncementWebView } from './announcement-webview';
import { parseAnnouncementStoryMessage } from './announcement-webview-contract';

export type AnnouncementStoryResult = 'closed' | 'completed';

export function AnnouncementStoryModal({
  announcement,
  preparedUri,
  onFinish,
}: {
  announcement: AppAnnouncement;
  preparedUri: string;
  onFinish: (result: AnnouncementStoryResult) => void;
}) {
  const { width, height } = useWindowDimensions();
  const insets = useSafeAreaInsets();
  const { reduceMotion } = useCKAccessibility();
  const [entrance] = useState(() => new Animated.Value(reduceMotion ? 1 : 0));
  const [reveal] = useState(() => new Animated.Value(0));
  const revealTimer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  const [ready, setReady] = useState(false);
  const dimension = Math.max(
    0,
    Math.min(560, width - 24, height - insets.top - insets.bottom - 24),
  );

  useEffect(() => {
    if (reduceMotion) return undefined;
    Animated.timing(entrance, {
      toValue: 1,
      duration: 240,
      easing: Easing.bezier(...ckMotion.standardCurve),
      useNativeDriver: true,
    }).start();
    return undefined;
  }, [entrance, reduceMotion]);

  useEffect(
    () => () => {
      if (revealTimer.current) clearTimeout(revealTimer.current);
    },
    [],
  );

  const scheduleReveal = (delay: number) => {
    if (ready) return;
    if (revealTimer.current) clearTimeout(revealTimer.current);
    revealTimer.current = setTimeout(() => {
      setReady(true);
      Animated.timing(reveal, {
        toValue: 1,
        duration: reduceMotion ? 0 : 180,
        easing: Easing.out(Easing.ease),
        useNativeDriver: true,
      }).start();
    }, delay);
  };

  const handleMessage = (rawMessage: string) => {
    const type = parseAnnouncementStoryMessage(rawMessage);
    if (type === 'ready') scheduleReveal(120);
    else if (type === 'close') onFinish('closed');
    else if (type === 'complete') onFinish('completed');
  };

  return (
    <Modal
      animationType="none"
      onRequestClose={() => onFinish('closed')}
      presentationStyle="overFullScreen"
      transparent
      visible
    >
      <View
        accessibilityLabel={`Close ${announcement.title}`}
        accessibilityViewIsModal
        style={styles.overlay}
      >
        <Pressable
          accessibilityLabel={`Close ${announcement.title}`}
          accessibilityRole="button"
          onPress={() => onFinish('closed')}
          style={StyleSheet.absoluteFill}
        />
        <Animated.View
          style={[
            styles.stage,
            {
              height: dimension,
              width: dimension,
              opacity: entrance,
              transform: [
                { scale: entrance.interpolate({ inputRange: [0, 1], outputRange: [0.94, 1] }) },
              ],
            },
          ]}
        >
          <Animated.View
            pointerEvents={ready ? 'auto' : 'none'}
            style={[styles.story, { opacity: reveal }]}
          >
            <AnnouncementWebView
              fileUri={preparedUri}
              onPageFinished={() => scheduleReveal(350)}
              onStoryMessage={handleMessage}
              pageFinishedJavaScript="document.querySelector('.close-button')?.remove(); true;"
              showLoadingProgress={false}
              trustedStory
            />
          </Animated.View>
          {!ready ? (
            <View pointerEvents="none" style={styles.loading}>
              <Skeleton height={8} radius={ckRadius.pill} width={26} />
            </View>
          ) : null}
        </Animated.View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 12,
    backgroundColor: colorWithAlpha('#000000', 0.86),
  },
  stage: { alignItems: 'center', justifyContent: 'center' },
  story: {
    width: '100%',
    height: '100%',
    overflow: 'hidden',
    borderRadius: 24,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: colorWithAlpha('#FFFFFF', 0.16),
    backgroundColor: '#111529',
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 20 },
    shadowOpacity: 0.4,
    shadowRadius: 40,
    elevation: 24,
  },
  loading: {
    position: 'absolute',
    left: 0,
    right: 0,
    top: 0,
    bottom: 0,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
