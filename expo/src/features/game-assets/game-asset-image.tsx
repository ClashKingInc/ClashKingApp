import { useState } from 'react';
import {
  StyleSheet,
  View,
  type ImageStyle,
  type LayoutChangeEvent,
  type StyleProp,
} from 'react-native';
import { ImageOff } from 'lucide-react-native';

import { MobileWebImage, Skeleton, useCKTheme } from '../../ui';
import type { GameAsset } from './models';

export function GameAssetImage({
  asset,
  contentFit = 'contain',
  style,
}: {
  asset: GameAsset;
  contentFit?: 'contain' | 'cover';
  style?: StyleProp<ImageStyle>;
}) {
  const theme = useCKTheme();
  const [loaded, setLoaded] = useState(false);
  const [skeletonSide, setSkeletonSide] = useState(64);
  const measure = (event: LayoutChangeEvent) => {
    const { width, height } = event.nativeEvent.layout;
    const boundedSide = Math.min(width || 72, height || 72);
    setSkeletonSide(Math.max(36, Math.min(96, boundedSide * 0.56)));
  };
  return (
    <View style={[styles.frame, style]} onLayout={measure}>
      {!loaded ? (
        <Skeleton width={skeletonSide} height={skeletonSide} radius={skeletonSide * 0.24} />
      ) : null}
      <MobileWebImage
        imageUrl={asset.url}
        contentFit={contentFit}
        onLoad={() => setLoaded(true)}
        errorFallback={
          <View style={[StyleSheet.absoluteFill, styles.error]}>
            <ImageOff size={24} color={theme.onSurfaceVariant} />
          </View>
        }
        style={[StyleSheet.absoluteFill, !loaded && styles.hidden]}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  frame: { alignItems: 'center', justifyContent: 'center', overflow: 'hidden' },
  error: { alignItems: 'center', justifyContent: 'center' },
  hidden: { opacity: 0 },
});
