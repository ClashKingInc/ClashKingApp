import { useState } from 'react';
import { Image, StyleSheet, View, useWindowDimensions } from 'react-native';
import Svg, { Defs, LinearGradient, Rect, Stop } from 'react-native-svg';
import { useCKTheme } from '../../../ui';

// These local derivatives retain the original game artwork. Never hold navigation on a CDN image.
const maps = [
  require('../../../../assets/clashking/cwl/bronze.webp'),
  require('../../../../assets/clashking/cwl/silver.webp'),
  require('../../../../assets/clashking/cwl/gold.webp'),
  require('../../../../assets/clashking/cwl/crystal.webp'),
  require('../../../../assets/clashking/cwl/master.webp'),
  require('../../../../assets/clashking/cwl/champion.webp'),
  require('../../../../assets/clashking/cwl/titan.webp'),
  require('../../../../assets/clashking/cwl/legend.webp'),
];
const families = ['bronze', 'silver', 'gold', 'crystal', 'master', 'champion', 'titan', 'legend'];
// In every 1100px derivative, the wall's league emblem sits around x=532,
// not the canvas midpoint (550). Center the emblem, not the surrounding map.
const wallEmblemX = 532 / 1100;

export function CwlLeagueBackdrop({ league }: { league?: string | null }) {
  const { width: windowWidth } = useWindowDimensions();
  const theme = useCKTheme();
  const [bounds, setBounds] = useState({ width: 0, height: 0 });
  const width = bounds.width || windowWidth;
  const height = bounds.height || 170;
  // Use only the scale needed to cover the header. The extra horizontal
  // allowance centers the actual emblem without exposing either image edge.
  const imageWidth = Math.max(
    width / (2 * Math.min(wallEmblemX, 1 - wallEmblemX)),
    (height * 1700) / 690,
  );
  const imageHeight = (imageWidth * 690) / 1700;
  const index = families.findIndex((name) => league?.toLowerCase().includes(name));
  // Unknown leagues stay neutral rather than falsely displaying a Legend map.
  return (
    <View
      pointerEvents="none"
      onLayout={(event) => {
        const { width, height } = event.nativeEvent.layout;
        setBounds((old) =>
          old.width === width && old.height === height ? old : { width, height },
        );
      }}
      style={[StyleSheet.absoluteFill, { backgroundColor: theme.background, overflow: 'hidden' }]}
    >
      {index >= 0 ? (
        <Image
          source={maps[index]}
          resizeMode="contain"
          fadeDuration={0}
          style={{
            position: 'absolute',
            width: imageWidth,
            height: imageHeight,
            left: '50%',
            transform: [{ translateX: -imageWidth * wallEmblemX }],
            top: (height - imageHeight) / 2,
          }}
        />
      ) : null}
      <Svg pointerEvents="none" width={width} height={height} style={StyleSheet.absoluteFill}>
        <Defs>
          <LinearGradient id="cwl-header-shade" x1="0" y1="0" x2="0" y2="1">
            <Stop offset="0" stopColor="#000000" stopOpacity={0.55} />
            <Stop offset="0.46" stopColor="#000000" stopOpacity={0.48} />
            <Stop offset="0.75" stopColor="#000000" stopOpacity={0.42} />
            <Stop offset="0.91" stopColor={theme.background} stopOpacity={0.55} />
            <Stop offset="1" stopColor={theme.background} stopOpacity={1} />
          </LinearGradient>
        </Defs>
        <Rect width={width} height={height} fill="url(#cwl-header-shade)" />
      </Svg>
    </View>
  );
}
