import { memo } from 'react';
import { StyleSheet, View, useWindowDimensions } from 'react-native';
import { HeaderArtwork } from './header-artwork';
import { prepareHeaderArtwork } from '../core/assets/header-artwork-cache';
import { useCKTheme } from './theme';
import { HeroHeaderScrim } from './hero-header-scrim';

export type RankedCheckerColor = 'blue' | 'purple' | 'green' | 'red';
const artwork = {
  blue: require('../../assets/clashking/backgrounds/blue.webp'),
  purple: require('../../assets/clashking/backgrounds/purple.webp'),
  green: require('../../assets/clashking/backgrounds/green.webp'),
  red: require('../../assets/clashking/backgrounds/red.webp'),
};
const fallback = { blue: '#302A68', purple: '#4A203D', green: '#174A20', red: '#652626' };
let warmup: Promise<unknown> | undefined;

/** Opportunistic warmup only: routing and the launch screen never await artwork. */
export function warmRankedCheckerBackgrounds() {
  warmup ??= Promise.allSettled(
    Object.values(artwork).map((source) => prepareHeaderArtwork(source)),
  );
  return warmup;
}

/** Cache the checker artwork, then share the same measured scrim as other headers. */
export const RankedCheckerBackground = memo(function RankedCheckerBackground({
  color,
}: {
  color: RankedCheckerColor;
}) {
  const theme = useCKTheme();
  const { width: screenWidth } = useWindowDimensions();
  const width = Math.max(700, screenWidth);
  return (
    <View
      pointerEvents="none"
      style={[StyleSheet.absoluteFill, styles.clip, { backgroundColor: fallback[color] }]}
    >
      <HeaderArtwork
        source={artwork[color]}
        contentFit="cover"
        style={{
          position: 'absolute',
          width,
          height: width * 0.75,
          left: '50%',
          top: 0,
          transform: [{ translateX: -width / 2 }],
        }}
      />
      {/* Custom ProfilePageHeader backdrops own their scrim. Use the same
          measured fade as illustrated headers, never a stretched fade bitmap. */}
      <HeroHeaderScrim edgeColor={theme.background} />
    </View>
  );
});
const styles = StyleSheet.create({ clip: { overflow: 'hidden' } });
