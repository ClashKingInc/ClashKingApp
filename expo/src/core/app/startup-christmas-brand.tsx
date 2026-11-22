import { useEffect, useState } from 'react';
import {
  AccessibilityInfo,
  Animated,
  AppState,
  Easing,
  StyleSheet,
  useWindowDimensions,
  View,
} from 'react-native';
import Svg, { Circle, G, Path } from 'react-native-svg';

import { startupBrandPaths } from '../assets/startup-brand-paths';
import { StartupWordmark } from './startup-brand';

const TREE_ENTRY = 0.25;
const TREE_STRIKE = 0.46;
const TREE_LANDING = 0.62;
const MARK_COORDINATE_WIDTH = 84.5112;
const MARK_COORDINATE_HEIGHT = 101.14;
const MARK_VIEW_BOX = `0 0 ${MARK_COORDINATE_WIDTH} ${MARK_COORDINATE_HEIGHT}`;
const MARK_WIDTH = 118;
const MARK_HEIGHT = 134;
const MARK_AREA_WIDTH = 180;
const MARK_SCALE = MARK_HEIGHT / MARK_COORDINATE_HEIGHT;
const SHAFT_OUTLINE = '#5C362A';
const SHAFT_HIGHLIGHT = '#FFF3DF';
const SHAFT_OUTLINE_WIDTH = 5.5;
const SHAFT_HIGHLIGHT_WIDTH = 3.2;
const SHAFT_SLOPE = 41 / 77;
const SHAFT_FRONT_TOP = 17;
const SHAFT_FRONT_BOTTOM = 62;

const snowflakes = [
  { left: 7, top: 2, size: 3, start: 0.01, end: 0.77, drift: 10, opacity: 0.48 },
  { left: 18, top: 20, size: 2, start: 0.18, end: 0.91, drift: -6, opacity: 0.38 },
  { left: 25, top: 4, size: 4, start: 0.06, end: 0.84, drift: -9, opacity: 0.44 },
  { left: 36, top: 14, size: 2, start: 0.26, end: 0.95, drift: 11, opacity: 0.36 },
  { left: 46, top: -4, size: 3, start: 0.13, end: 0.81, drift: 7, opacity: 0.43 },
  { left: 53, top: 21, size: 2, start: 0.04, end: 0.69, drift: -10, opacity: 0.38 },
  { left: 62, top: 6, size: 3, start: 0.25, end: 1, drift: 8, opacity: 0.45 },
  { left: 74, top: 0, size: 2, start: 0.15, end: 0.87, drift: 6, opacity: 0.37 },
  { left: 85, top: 12, size: 4, start: 0.03, end: 0.8, drift: -12, opacity: 0.49 },
  { left: 94, top: 3, size: 3, start: 0.21, end: 0.98, drift: -8, opacity: 0.42 },
  { left: 4, top: 37, size: 2, start: 0.09, end: 0.85, drift: 9, opacity: 0.4 },
  { left: 13, top: 67, size: 3, start: 0.22, end: 0.92, drift: -6, opacity: 0.34 },
  { left: 22, top: 82, size: 2, start: 0.05, end: 0.76, drift: 8, opacity: 0.4 },
  { left: 29, top: 48, size: 3, start: 0.17, end: 0.84, drift: 7, opacity: 0.36 },
  { left: 35, top: 73, size: 2, start: 0.26, end: 0.97, drift: -8, opacity: 0.34 },
  { left: 42, top: 32, size: 2, start: 0.02, end: 0.77, drift: -5, opacity: 0.42 },
  { left: 59, top: 59, size: 3, start: 0.13, end: 0.89, drift: 8, opacity: 0.38 },
  { left: 68, top: 83, size: 2, start: 0.1, end: 0.78, drift: -6, opacity: 0.36 },
  { left: 76, top: 40, size: 3, start: 0.2, end: 0.97, drift: 10, opacity: 0.45 },
  { left: 83, top: 69, size: 3, start: 0.03, end: 0.82, drift: 6, opacity: 0.36 },
  { left: 91, top: 49, size: 2, start: 0.18, end: 0.91, drift: -9, opacity: 0.4 },
  { left: 97, top: 77, size: 2, start: 0.08, end: 0.77, drift: -5, opacity: 0.35 },
];

export function StartupChristmasBrand({
  staticOnly,
  foreground,
  snowColor,
  label,
  width,
}: {
  staticOnly: boolean;
  foreground: string;
  snowColor: string;
  label: string;
  width: number;
}) {
  const [entrance] = useState(() => new Animated.Value(staticOnly ? 1 : 0));

  return (
    <View pointerEvents="none" style={[StyleSheet.absoluteFill, styles.screen]}>
      <StartupChristmasSnow color={snowColor} entrance={entrance} staticOnly={staticOnly} />
      <View accessible accessibilityLabel={label} testID="startup-brand" style={styles.brand}>
        <View style={styles.markArea} testID="startup-mark">
          <Animated.View
            style={[
              StyleSheet.absoluteFill,
              {
                transform: [
                  {
                    translateY: entrance.interpolate({
                      inputRange: [0, TREE_STRIKE, 0.55, 0.67, 1],
                      outputRange: [0, 0, 4, -1, 0],
                    }),
                  },
                  {
                    rotate: entrance.interpolate({
                      inputRange: [0, TREE_STRIKE, 0.55, 0.67, 1],
                      outputRange: ['0deg', '0deg', '-3deg', '1deg', '0deg'],
                    }),
                  },
                ],
              },
            ]}
          >
            <ChristmasTreeFlight progress={entrance} />
            <ChristmasTreeImpact progress={entrance} snowColor={snowColor} />
          </Animated.View>
        </View>
        <View testID="startup-wordmark" style={[styles.wordmark, { width }]}>
          <StartupWordmark foreground={foreground} />
        </View>
      </View>
    </View>
  );
}

function StartupChristmasSnow({
  color,
  entrance,
  staticOnly,
}: {
  color: string;
  entrance: Animated.Value;
  staticOnly: boolean;
}) {
  const [progress] = useState(() => new Animated.Value(0));
  const { height } = useWindowDimensions();

  useEffect(() => {
    if (staticOnly) {
      entrance.setValue(1);
      return;
    }

    const landing = Animated.timing(entrance, {
      toValue: 1,
      duration: 720,
      easing: Easing.linear,
      useNativeDriver: true,
      isInteraction: false,
    });
    const snow = Animated.loop(
      Animated.timing(progress, {
        toValue: 1,
        duration: 5200,
        easing: Easing.linear,
        useNativeDriver: true,
        isInteraction: false,
      }),
    );
    let running = false;
    let playedEntrance = false;
    let disposed = false;
    let appState = AppState.currentState;
    let reduceMotion: boolean | undefined;

    const syncMotion = () => {
      if (reduceMotion && !playedEntrance) {
        playedEntrance = true;
        entrance.setValue(1);
      }
      const canAnimate = appState === 'active' && reduceMotion === false;
      if (running === canAnimate) return;
      running = canAnimate;
      if (canAnimate) {
        if (!playedEntrance) {
          playedEntrance = true;
          landing.start();
        }
        snow.start();
      } else {
        landing.stop();
        entrance.setValue(1);
        snow.stop();
        snow.reset();
      }
    };

    const appStateListener = AppState.addEventListener('change', (state) => {
      appState = state;
      syncMotion();
    });
    const motionListener = AccessibilityInfo.addEventListener('reduceMotionChanged', (enabled) => {
      reduceMotion = enabled;
      syncMotion();
    });
    // Stay static until the OS preference is known. A new event wins over the initial read.
    void AccessibilityInfo.isReduceMotionEnabled()
      .then((enabled) => {
        if (disposed || reduceMotion !== undefined) return;
        reduceMotion = enabled;
        syncMotion();
      })
      .catch(() => {
        if (disposed || reduceMotion !== undefined) return;
        reduceMotion = true;
        syncMotion();
      });

    return () => {
      disposed = true;
      appStateListener.remove();
      motionListener.remove();
      landing.stop();
      entrance.setValue(0);
      snow.stop();
      snow.reset();
    };
  }, [entrance, progress, staticOnly]);

  if (staticOnly) return null;

  return (
    <View
      pointerEvents="none"
      accessibilityElementsHidden
      importantForAccessibility="no-hide-descendants"
      style={[StyleSheet.absoluteFill, styles.snowLayer]}
    >
      {snowflakes.map((flake) => {
        const travel = {
          inputRange: [flake.start, flake.end],
          extrapolate: 'clamp' as const,
        };
        return (
          <Animated.View
            key={flake.left}
            style={[
              styles.flake,
              {
                left: `${flake.left}%`,
                top: `${flake.top}%`,
                width: flake.size,
                height: flake.size,
                borderRadius: flake.size / 2,
                backgroundColor: color,
                opacity: progress.interpolate({
                  inputRange: [flake.start, flake.start + 0.1, flake.end - 0.16, flake.end],
                  outputRange: [0, flake.opacity, flake.opacity, 0],
                  extrapolate: 'clamp',
                }),
                transform: [
                  {
                    translateX: progress.interpolate({ ...travel, outputRange: [0, flake.drift] }),
                  },
                  {
                    translateY: progress.interpolate({
                      ...travel,
                      outputRange: [0, height * (flake.size === 4 ? 0.23 : 0.17)],
                    }),
                  },
                ],
              },
            ]}
          />
        );
      })}
    </View>
  );
}

function ChristmasCrown() {
  return (
    <Svg width={MARK_WIDTH} height={MARK_HEIGHT} viewBox={MARK_VIEW_BOX} style={styles.crown}>
      <Path d={startupBrandPaths.crown[0]} fill="#BF0000" />
      <Path d={startupBrandPaths.crown[1]} fill="#D90709" />
      <Path d="m3 33 7 1 5 15-9 9Zm25 14 13-20-3 31-16 15-16-7Z" fill="#EF362C" />
      <Path d="m42 28 13 1 10 22-17 9-9 13 3-45Zm33 6 7-1-4 24-8 6Z" fill="#E82222" />
      <Path d="m48 60 17-9 5 12-4 12-26-3Zm-42 6 16 7-7 1-9 1Z" fill="#A40B16" />
      <Path
        d="m3 32 8 1 5 16 10-2m40 2 6 1 3-17 7-1"
        fill="none"
        stroke="#FF8978"
        strokeWidth={1}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <G fill="#F5FAFF">
        <Circle cx={8} cy={47} r={2} />
        <Circle cx={13} cy={65} r={1.5} />
        <Circle cx={23} cy={56} r={1.2} />
        <Circle cx={32} cy={69} r={2.2} />
        <Circle cx={48} cy={62} r={1.6} />
        <Circle cx={60} cy={72} r={1.2} />
        <Circle cx={73} cy={57} r={2} />
        <Circle cx={77} cy={43} r={1.5} />
      </G>
      <Path
        d="M18 19C22 10 29 10 37 6 49 0 56 10 59 22L29 29c1-5 2-8 1-12-4 1-7 3-11 6Z"
        fill="#D90709"
        stroke="#9E1120"
        strokeWidth={1.2}
      />
      <Path d="M30 17c1 3 2 6 0 9l28-5-2-4c-7 4-15 7-23 6Z" fill="#B40716" />
      <Path
        d="M28 25c4-2 6-1 10-3 4-2 7-1 10-3 4-2 9-4 12 0 2 3 1 5-2 6-4 1-7 3-11 3-5 1-7 3-12 3-3 2-8 2-9-1-1-2 0-4 2-5Z"
        fill="#F5FAFF"
        stroke="#CADDE8"
        strokeWidth={1.2}
      />
      <Circle cx={18} cy={22} r={4.3} fill="#F5FAFF" stroke="#CADDE8" strokeWidth={1.2} />
    </Svg>
  );
}

function ChristmasTreeFlight({ progress }: { progress: Animated.Value }) {
  const flight = { inputRange: [0, 0.2, TREE_LANDING], extrapolate: 'clamp' as const };
  const flightStyle = {
    opacity: progress.interpolate({
      inputRange: [0, 0.14, 1],
      outputRange: [0, 1, 1],
      extrapolate: 'clamp',
    }),
    transform: [
      {
        translateX: progress.interpolate({
          ...flight,
          outputRange: [168 * SHAFT_SLOPE, 125 * SHAFT_SLOPE, 0],
        }),
      },
      { translateY: progress.interpolate({ ...flight, outputRange: [-168, -125, 0] }) },
      {
        rotate: progress.interpolate({
          inputRange: [0, 0.2, TREE_ENTRY],
          outputRange: ['-8deg', '-4deg', '0deg'],
          extrapolate: 'clamp',
        }),
      },
    ],
  };

  return (
    <>
      <Animated.View style={[styles.tree, flightStyle]}>
        <Svg width={MARK_WIDTH} height={MARK_HEIGHT} viewBox={MARK_VIEW_BOX}>
          <Path
            d="M64 10 23 87"
            stroke={SHAFT_OUTLINE}
            strokeWidth={SHAFT_OUTLINE_WIDTH}
            strokeLinecap="round"
          />
          <Path
            d="M64 10 23 87"
            stroke={SHAFT_HIGHLIGHT}
            strokeWidth={SHAFT_HIGHLIGHT_WIDTH}
            strokeLinecap="round"
          />
          <G transform="translate(16 100) rotate(28)">
            <Path
              d="M0 0 6-9H3l6-7H5l6-7h-22l6 7h-4l6 7h-3Z"
              fill="#16734D"
              stroke="#E4F4EA"
              strokeWidth={1.1}
              strokeLinejoin="round"
            />
            <Path d="M0-2v-20h-9l6 7h-4l6 7h-3Z" fill="#235940" />
            <Path
              d="m-3-9 3 1 3-1m-6-7 6 1 3-1"
              stroke="#E4F4EA"
              strokeWidth={1.3}
              strokeLinecap="round"
              fill="none"
            />
            <Circle cx={-3} cy={-19} r={1.1} fill="#F7C75D" />
            <Circle cx={4} cy={-19} r={1.1} fill="#E94A47" />
          </G>
        </Svg>
      </Animated.View>
      <ChristmasCrown />
      <Animated.View style={[styles.tree, flightStyle]}>
        <Svg width={MARK_WIDTH} height={MARK_HEIGHT} viewBox={MARK_VIEW_BOX}>
          <Path
            d="M64 10 60.27 17"
            stroke={SHAFT_OUTLINE}
            strokeWidth={SHAFT_OUTLINE_WIDTH}
            strokeLinecap="round"
          />
          <Path
            d="M64 10 60.27 17"
            stroke={SHAFT_HIGHLIGHT}
            strokeWidth={SHAFT_HIGHLIGHT_WIDTH}
            strokeLinecap="round"
          />
          <Path
            d={startupBrandPaths.crown[3]}
            fill="#153C32"
            fillRule="evenodd"
            stroke="#DFEEE4"
            strokeWidth={0.65}
            strokeLinejoin="round"
          />
        </Svg>
      </Animated.View>
    </>
  );
}

function ChristmasTreeImpact({
  progress,
  snowColor,
}: {
  progress: Animated.Value;
  snowColor: string;
}) {
  // The shaft stops at the cut in the face. The travelling tip stays behind
  // the crown until it clears the lower edge.
  const reveal = progress.interpolate({
    inputRange: [TREE_ENTRY, TREE_STRIKE],
    outputRange: [0, 1],
    extrapolate: 'clamp',
  });

  return (
    <>
      <View style={styles.shaftAxis}>
        <Animated.View style={[styles.shaftOutline, { transform: [{ scaleY: reveal }] }]}>
          <View style={styles.shaftHighlight} />
        </Animated.View>
      </View>
      <Animated.View
        style={[
          styles.tree,
          {
            opacity: progress.interpolate({
              inputRange: [0, TREE_STRIKE - 0.015, TREE_STRIKE, 1],
              outputRange: [0, 0, 1, 1],
            }),
          },
        ]}
      >
        <Svg width={MARK_WIDTH} height={MARK_HEIGHT} viewBox={MARK_VIEW_BOX}>
          <Path
            d="M36.3 59.2 39.2 60.7 36.7 64.4 38.8 66.3 35.7 65.4 34.8 68 34.4 65.8 32.3 66.8 32.8 65 30.9 64.2 33 63.5 32 62.3 34.4 62.7Z"
            fill={SHAFT_HIGHLIGHT}
            stroke={SHAFT_OUTLINE}
            strokeWidth={0.65}
            strokeLinejoin="round"
          />
          <Path d="m37 59.3 1.9 1-2.3 3.4-2-1Z" fill={SHAFT_HIGHLIGHT} />
        </Svg>
      </Animated.View>
      <Animated.View
        style={[
          styles.snowPuff,
          {
            opacity: progress.interpolate({
              inputRange: [0, TREE_STRIKE, 0.53, 0.85],
              outputRange: [0, 0, 0.56, 0],
              extrapolate: 'clamp',
            }),
            transform: [
              {
                scale: progress.interpolate({
                  inputRange: [TREE_STRIKE, 0.85],
                  outputRange: [0.3, 1],
                  extrapolate: 'clamp',
                }),
              },
            ],
          },
        ]}
      >
        <Svg width={54} height={38} viewBox="0 0 54 38" fill={snowColor}>
          <Circle cx={10} cy={14} r={2.4} />
          <Circle cx={19} cy={8} r={3.2} />
          <Circle cx={27} cy={17} r={2.8} />
          <Circle cx={37} cy={10} r={2.2} />
          <Circle cx={44} cy={22} r={3.1} />
          <Circle cx={14} cy={29} r={2} />
          <Circle cx={31} cy={31} r={2.6} />
        </Svg>
      </Animated.View>
    </>
  );
}

const styles = StyleSheet.create({
  screen: { alignItems: 'center', justifyContent: 'center' },
  brand: { alignItems: 'center' },
  markArea: { width: MARK_AREA_WIDTH, height: MARK_HEIGHT },
  crown: { alignSelf: 'center' },
  wordmark: { aspectRatio: 163 / 23, marginTop: 24 },
  snowLayer: { overflow: 'hidden' },
  flake: { position: 'absolute' },
  tree: { position: 'absolute', top: 0, left: (MARK_AREA_WIDTH - MARK_WIDTH) / 2 },
  shaftAxis: {
    position: 'absolute',
    top: SHAFT_FRONT_TOP * MARK_SCALE,
    left:
      (MARK_AREA_WIDTH - MARK_COORDINATE_WIDTH * MARK_SCALE) / 2 +
      (64 - (SHAFT_FRONT_TOP - 10) * SHAFT_SLOPE - SHAFT_OUTLINE_WIDTH / 2) * MARK_SCALE,
    width: SHAFT_OUTLINE_WIDTH * MARK_SCALE,
    height: (SHAFT_FRONT_BOTTOM - SHAFT_FRONT_TOP) * Math.hypot(1, SHAFT_SLOPE) * MARK_SCALE,
    transformOrigin: 'center top',
    transform: [{ rotate: `${(Math.atan(SHAFT_SLOPE) * 180) / Math.PI}deg` }],
  },
  shaftOutline: {
    flex: 1,
    alignItems: 'center',
    transformOrigin: 'center top',
    backgroundColor: SHAFT_OUTLINE,
  },
  shaftHighlight: {
    flex: 1,
    width: SHAFT_HIGHLIGHT_WIDTH * MARK_SCALE,
    backgroundColor: SHAFT_HIGHLIGHT,
  },
  snowPuff: { position: 'absolute', left: 56, top: 65 },
});
