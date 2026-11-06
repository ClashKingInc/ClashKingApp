import { useAvatarNames } from './avatar-names';
import { memo, useEffect, useMemo, useRef, useState, type ElementRef } from 'react';
import { AppState, StyleSheet, View, type GestureResponderEvent } from 'react-native';
import Svg, { Path } from 'react-native-svg';
import Animated, {
  cancelAnimation,
  Easing,
  useAnimatedReaction,
  useAnimatedStyle,
  useSharedValue,
  useDerivedValue,
  withDelay,
  withRepeat,
  withSequence,
  withSpring,
  withTiming,
  type SharedValue,
} from 'react-native-reanimated';
import { useCKAccessibility } from '../../ui/accessibility';
import catalog from './catalog.json';
import { useAvatarPreference } from './avatar-preference';

// Keep the face SVG static. Android's SVG renderer invalidates its entire bitmap
// when an eye prop changes; ordinary view transforms can animate the eyes without
// re-rasterizing the hair, crown and face (or parsing a new happy path each frame).
const AvatarArtwork = memo(function AvatarArtwork({
  avatar,
  size,
}: {
  avatar: (typeof catalog)[number];
  size: number;
}) {
  return (
    <Svg width={size} height={size} viewBox="-10 -10 120 120">
      {avatar.shapes.map((shape) => (
        <Path key={shape.name} d={shape.path} fill={shape.fill} />
      ))}
    </Svg>
  );
});

function AvatarEye({
  left,
  center,
  scale,
  fill,
  x,
  y,
  blink,
  happy,
  valkyrie,
  reduced,
  size,
}: {
  left: number;
  center: number;
  scale: number;
  fill: string;
  x: SharedValue<number>;
  y: SharedValue<number>;
  blink: SharedValue<number>;
  happy: SharedValue<number>;
  valkyrie: boolean;
  reduced: boolean;
  size: number;
}) {
  const unit = size / 120;
  const motion = useAnimatedStyle(() => ({
    transform: [
      { translateX: x.value * (valkyrie ? 1.6 : 3.2) * (reduced ? 0.7 : 1) * unit },
      { translateY: y.value * (valkyrie && y.value < 0 ? 0.66 : 2.2) * (reduced ? 0.7 : 1) * unit },
    ],
  }));
  const open = useAnimatedStyle(() => ({
    opacity: 1 - happy.value,
    transform: [{ scaleY: blink.value }],
  }));
  const smile = useAnimatedStyle(() => ({ opacity: happy.value }));
  return (
    <Animated.View
      pointerEvents="none"
      style={[
        {
          position: 'absolute',
          left: (left + 10) * unit,
          top: (center + 10 - 5 * scale) * unit,
          width: 4.4 * scale * unit,
          height: 10 * scale * unit,
        },
        motion,
      ]}
    >
      <Animated.View
        style={[
          StyleSheet.absoluteFill,
          {
            backgroundColor: fill,
            borderRadius: 2.2 * scale * unit,
          },
          open,
        ]}
      />
      <Animated.View
        style={[
          {
            position: 'absolute',
            left: -scale * unit,
            top: 0,
            width: 6.4 * scale * unit,
            height: 10 * scale * unit,
          },
          smile,
        ]}
      >
        <Svg width="100%" height="100%" viewBox="-1 -5 6.4 10">
          <Path
            d="M 0 1.2 Q 2.2 -4 4.4 1.2"
            fill="none"
            stroke={fill}
            strokeWidth={1.8}
            strokeLinecap="round"
          />
        </Svg>
      </Animated.View>
    </Animated.View>
  );
}
export function ProfileAvatar({
  size = 40,
  interactive = false,
}: {
  size?: number;
  interactive?: boolean;
}) {
  const { id } = useAvatarPreference();
  return <ClashAvatar id={id} size={size} interactive={interactive} />;
}
export const ClashAvatar = memo(function ClashAvatar({
  id,
  size = 80,
  interactive = false,
  lookX,
  allowTouch = true,
  observeTouch = false,
  carouselProgress,
  carouselIndex = 0,
  carouselScrolling,
  selectionPulse = 0,
}: {
  id: string;
  lookX?: SharedValue<number>;
  carouselProgress?: SharedValue<number>;
  carouselIndex?: number;
  carouselScrolling?: SharedValue<boolean>;
  selectionPulse?: number;
  allowTouch?: boolean;
  observeTouch?: boolean;
  size?: number;
  interactive?: boolean;
}) {
  const names = useAvatarNames();
  const avatar = catalog.find((a) => a.id === id) ?? catalog[0]!;
  const { reduceMotion } = useCKAccessibility();
  const [active, setActive] = useState(AppState.currentState === 'active');
  const lastSelectionPulse = useRef(0);
  const origin = useRef({ x: 0, y: 0 });
  const touchStart = useRef({ x: 0, y: 0 });
  const dragging = useRef(false),
    measured = useRef(false);
  const host = useRef<ElementRef<typeof View>>(null);
  const x = useSharedValue(0),
    y = useSharedValue(0),
    breath = useSharedValue(0),
    blink = useSharedValue(1),
    happy = useSharedValue(0),
    gazeX = useSharedValue(0),
    gazeY = useSharedValue(0),
    arrival = useSharedValue(1),
    celebrationLift = useSharedValue(0),
    celebrationSway = useSharedValue(0);
  useEffect(() => {
    const sub = AppState.addEventListener('change', (state) => setActive(state === 'active'));
    return () => sub.remove();
  }, []);
  useEffect(() => {
    x.set(0);
    y.set(0);
    happy.set(0);
    celebrationLift.set(0);
    celebrationSway.set(0);
    gazeX.set(0);
    gazeY.set(0);
    dragging.current = false;
    measured.current = false;
    if (interactive && active && !reduceMotion) {
      arrival.set(1);
      breath.set(withRepeat(withTiming(1, { duration: 2400 }), -1, true));
      blink.set(
        withRepeat(
          withSequence(
            withDelay(3100, withTiming(0.12, { duration: 70 })),
            withTiming(1, { duration: 120 }),
          ),
          -1,
        ),
      );
    } else {
      arrival.set(1);
      breath.set(0);
      blink.set(1);
    }
    return () => {
      cancelAnimation(x);
      cancelAnimation(y);
      cancelAnimation(breath);
      cancelAnimation(blink);
      cancelAnimation(happy);
      cancelAnimation(gazeX);
      cancelAnimation(gazeY);
      cancelAnimation(arrival);
      cancelAnimation(celebrationLift);
      cancelAnimation(celebrationSway);
    };
  }, [
    interactive,
    active,
    reduceMotion,
    id,
    x,
    y,
    breath,
    blink,
    happy,
    gazeX,
    gazeY,
    arrival,
    celebrationLift,
    celebrationSway,
  ]);
  useEffect(() => {
    if (!selectionPulse || selectionPulse === lastSelectionPulse.current) return;
    lastSelectionPulse.current = selectionPulse;
    if (!interactive || !active) return;
    // One short UI-thread sequence for the settled face. The monotonic pulse
    // prevents replay on app resume, rerender or a reduced-motion setting change.
    happy.set(
      withSequence(
        withTiming(1, { duration: reduceMotion ? 0 : 90 }),
        withDelay(650, withTiming(0, { duration: reduceMotion ? 0 : 150 })),
      ),
    );
    if (reduceMotion) return;
    const easing = Easing.out(Easing.quad);
    celebrationLift.set(
      withSequence(
        withTiming(1, { duration: 140, easing }),
        withTiming(0, { duration: 180, easing }),
        withTiming(0.35, { duration: 90, easing }),
        withTiming(0, { duration: 130, easing }),
      ),
    );
    celebrationSway.set(
      withSequence(
        withTiming(-1, { duration: 120, easing }),
        withTiming(1, { duration: 180, easing }),
        withTiming(-0.25, { duration: 120, easing }),
        withTiming(0, { duration: 120, easing }),
      ),
    );
  }, [selectionPulse, interactive, active, reduceMotion, happy, celebrationLift, celebrationSway]);
  useAnimatedReaction(
    () => carouselScrolling?.value ?? false,
    (moving, previous) => {
      if (!moving || previous) return;
      // A new swipe immediately owns motion; do not let a previous celebration
      // animate the outgoing face or wait for a React render to stop it.
      celebrationLift.set(0);
      celebrationSway.set(0);
      happy.set(0);
    },
  );
  const follow = (pageX: number, pageY: number) => {
    const clamp = (v: number) => Math.max(-1, Math.min(1, v));
    const nextX = clamp((pageX - origin.current.x - size / 2) / (size * 0.4)),
      nextY = clamp((pageY - origin.current.y - size / 2) / (size * 0.4));
    gazeX.set(reduceMotion ? nextX : withTiming(nextX, { duration: 80 }));
    gazeY.set(reduceMotion ? nextY : withTiming(nextY, { duration: 80 }));
    x.set(
      withSpring(nextX, {
        damping: 22,
        stiffness: 170,
        overshootClamping: true,
      }),
    );
    y.set(
      withSpring(nextY, {
        damping: 22,
        stiffness: 170,
        overshootClamping: true,
      }),
    );
  };
  const reset = () => {
    dragging.current = false;
    measured.current = false;
    gazeX.set(reduceMotion ? 0 : withTiming(0, { duration: 180 }));
    gazeY.set(reduceMotion ? 0 : withTiming(0, { duration: 180 }));
    arrival.set(reduceMotion ? 1 : withSpring(1, { damping: 11, stiffness: 200 }));
    x.set(withSpring(0, { damping: 22 }));
    y.set(withSpring(0, { damping: 22 }));
  };
  const finishTouch = (event: GestureResponderEvent) => {
    const tapped =
      dragging.current &&
      Math.hypot(
        event.nativeEvent.pageX - touchStart.current.x,
        event.nativeEvent.pageY - touchStart.current.y,
      ) < 12;
    reset();
    if (tapped)
      happy.set(
        withSequence(
          withTiming(1, { duration: reduceMotion ? 0 : 100 }),
          withDelay(850, withTiming(0, { duration: reduceMotion ? 0 : 180 })),
        ),
      );
  };
  const beginTouch = (event: GestureResponderEvent) => {
    if (event.nativeEvent.touches.length !== 1) {
      reset();
      return;
    }
    // Direct touch takes over from the decorative hop without moving its hitbox.
    celebrationLift.set(0);
    celebrationSway.set(0);
    touchStart.current = { x: event.nativeEvent.pageX, y: event.nativeEvent.pageY };

    dragging.current = true;
    if (!reduceMotion) arrival.set(withTiming(0.96, { duration: 100 }));
    measured.current = false;
    const { pageX, pageY } = event.nativeEvent;
    host.current?.measureInWindow((left, top) => {
      if (!dragging.current) return;
      origin.current = { x: left, y: top };
      measured.current = true;
      follow(pageX, pageY);
    });
  };
  // Observe light touches without claiming the carousel's horizontal gesture.
  // Once movement is a swipe, release the face animation and let the list own it.
  const passiveTouch =
    observeTouch && interactive && active
      ? {
          onTouchStart: beginTouch,
          onTouchMove: (event: GestureResponderEvent) => {
            if (!dragging.current) return;
            const dx = Math.abs(event.nativeEvent.pageX - touchStart.current.x);
            const dy = Math.abs(event.nativeEvent.pageY - touchStart.current.y);
            if (dx > 12 && dx > dy) {
              reset();
              return;
            }
            if (measured.current) follow(event.nativeEvent.pageX, event.nativeEvent.pageY);
          },
          onTouchEnd: finishTouch,
          onTouchCancel: () => {
            if (dragging.current) reset();
          },
        }
      : {};
  const responder = {
    onStartShouldSetResponder: () => interactive && active && allowTouch,
    onMoveShouldSetResponder: () => interactive && active && allowTouch,
    onResponderGrant: beginTouch,
    onResponderMove: (event: GestureResponderEvent) => {
      if (dragging.current && measured.current)
        follow(event.nativeEvent.pageX, event.nativeEvent.pageY);
    },
    // A drag begun on the face belongs to it; the surrounding page still scrolls elsewhere.
    onResponderTerminationRequest: () => false,
    onResponderRelease: finishTouch,
    onResponderTerminate: reset,
  };
  const visible = useDerivedValue(
    () => !carouselProgress || Math.abs(carouselProgress.value - carouselIndex) < 1.6,
  );
  const lookingX = useDerivedValue(() =>
    !visible.value
      ? 0
      : Math.max(
          -1,
          Math.min(
            1,
            gazeX.value +
              (lookX?.value ?? 0) * 0.85 +
              (interactive && active && !reduceMotion
                ? Math.sin(breath.value * Math.PI * 2) * 0.35
                : 0),
          ),
        ),
  );
  const lookingY = useDerivedValue(() =>
    Math.max(
      -1,
      Math.min(
        1,
        gazeY.value +
          (interactive && active && !reduceMotion ? Math.sin(breath.value * Math.PI) * 0.1 : 0),
      ),
    ),
  );
  const head = useAnimatedStyle(() => ({
    transform: [
      { translateX: reduceMotion ? 0 : (x.value * 0.085 + celebrationSway.value * 0.014) * size },
      {
        translateY: reduceMotion
          ? 0
          : (y.value * 0.058 - breath.value * 0.004 - celebrationLift.value * 0.035) * size,
      },
      {
        rotate: `${reduceMotion ? 0 : x.value * 5 + celebrationSway.value * 4}deg`,
      },
      {
        scale: (reduceMotion ? 1 : arrival.value) * (1 + (reduceMotion ? 0 : breath.value * 0.014)),
      },
    ],
  }));
  const eyePositions = useMemo(
    () =>
      [-1, 1].map(
        (side) => avatar.eyes.x + (side * avatar.eyes.spacing) / 2 - 2.2 * avatar.eyes.scale,
      ),
    [avatar],
  );
  return (
    <View
      ref={host}
      collapsable={false}
      style={{ width: size, height: size }}
      {...responder}
      {...passiveTouch}
      accessible
      accessibilityLabel={names[avatar.id]}
    >
      <Animated.View style={[{ width: size, height: size }, head]}>
        <AvatarArtwork avatar={avatar} size={size} />
        {eyePositions.map((left, i) => (
          <AvatarEye
            key={i}
            size={size}
            left={left}
            center={avatar.eyes.y}
            scale={avatar.eyes.scale}
            fill={avatar.eyes.fill}
            x={lookingX}
            y={lookingY}
            blink={blink}
            happy={happy}
            valkyrie={id === 'valkyrie'}
            reduced={reduceMotion}
          />
        ))}
      </Animated.View>
    </View>
  );
});
