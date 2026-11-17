import { useState } from 'react';
import { Modal, Pressable, StyleSheet, View, useWindowDimensions } from 'react-native';
import { Gesture, GestureDetector, GestureHandlerRootView } from 'react-native-gesture-handler';
import Reanimated, { useSharedValue, useAnimatedStyle, withSpring } from 'react-native-reanimated';
import { X, ZoomIn, ZoomOut } from 'lucide-react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { CKText, MobileWebImage, HeaderIconButton, useCKTheme } from '../../ui';
import { useI18n } from '../../i18n';
import { modalOrientations } from '../../ui/modal-orientations';

/** Pinch/pan never changes layout. Closing releases the native image host. */
export function WikiImageViewer({
  image,
  title,
  onClose,
}: {
  image: string;
  title: string;
  onClose: () => void;
}) {
  const theme = useCKTheme(),
    { t } = useI18n(),
    { width, height } = useWindowDimensions();
  const scale = useSharedValue(1),
    saved = useSharedValue(1),
    x = useSharedValue(0),
    y = useSharedValue(0),
    sx = useSharedValue(0),
    sy = useSharedValue(0);
  const pinch = Gesture.Pinch()
    .onUpdate((e) => {
      scale.set(Math.max(1, Math.min(4, saved.get() * e.scale)));
    })
    .onEnd(() => {
      saved.set(scale.get());
      const bx = (width * (scale.get() - 1)) / 2,
        by = (height * (scale.get() - 1)) / 2;
      x.set(Math.max(-bx, Math.min(bx, x.get())));
      y.set(Math.max(-by, Math.min(by, y.get())));
      sx.set(x.get());
      sy.set(y.get());
    });
  const pan = Gesture.Pan()
    .onUpdate((e) => {
      const boundX = (width * (scale.get() - 1)) / 2,
        boundY = (height * (scale.get() - 1)) / 2;
      x.set(Math.max(-boundX, Math.min(boundX, sx.get() + e.translationX)));
      y.set(Math.max(-boundY, Math.min(boundY, sy.get() + e.translationY)));
    })
    .onEnd(() => {
      sx.set(x.get());
      sy.set(y.get());
    });
  const style = useAnimatedStyle(() => ({
    transform: [{ translateX: x.get() }, { translateY: y.get() }, { scale: scale.get() }],
  }));
  const zoom = (value: number) => {
    scale.set(withSpring(value, { damping: 24, stiffness: 250 }));
    saved.set(value);
    x.set(0);
    y.set(0);
    sx.set(0);
    sy.set(0);
  };
  return (
    <Modal
      visible
      supportedOrientations={modalOrientations}
      animationType="fade"
      onRequestClose={onClose}
    >
      <GestureHandlerRootView style={{ flex: 1 }}>
        <SafeAreaView style={{ flex: 1, backgroundColor: theme.background }}>
          <View style={{ flexDirection: 'row', alignItems: 'center', paddingHorizontal: 12 }}>
            <CKText style={{ flex: 1 }} numberOfLines={2}>
              {title}
            </CKText>
            <HeaderIconButton
              label={t('upgradeTrackerPlanClose')}
              onPress={onClose}
              icon={<X color={theme.onSurface} />}
            />
          </View>
          <GestureDetector gesture={Gesture.Simultaneous(pinch, pan)}>
            <Reanimated.View style={[{ flex: 1, overflow: 'hidden' }]}>
              <Reanimated.View style={[StyleSheet.absoluteFill, style]}>
                <MobileWebImage
                  imageUrl={image}
                  contentFit="contain"
                  style={StyleSheet.absoluteFill}
                />
              </Reanimated.View>
            </Reanimated.View>
          </GestureDetector>
          <View style={{ flexDirection: 'row', justifyContent: 'center', gap: 24, padding: 12 }}>
            <HeaderIconButton
              label={t('sideDecrease')}
              icon={<ZoomOut color={theme.onSurface} />}
              onPress={() => zoom(1)}
            />
            <HeaderIconButton
              label={t('sideIncrease')}
              icon={<ZoomIn color={theme.onSurface} />}
              onPress={() => zoom(2.5)}
            />
          </View>
        </SafeAreaView>
      </GestureHandlerRootView>
    </Modal>
  );
}
export function WikiZoomableImage({
  image,
  title,
  children,
}: {
  image: string;
  title: string;
  children: React.ReactNode;
}) {
  const [open, setOpen] = useState(false),
    { t } = useI18n();
  return (
    <>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={`${title} · ${t('sideMockupPreview')}`}
        onPress={() => setOpen(true)}
      >
        {children}
      </Pressable>
      {open ? <WikiImageViewer image={image} title={title} onClose={() => setOpen(false)} /> : null}
    </>
  );
}
