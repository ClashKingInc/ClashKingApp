import { useEffect, useId, type PropsWithChildren } from 'react';
import { StyleSheet, View, type StyleProp, type ViewStyle } from 'react-native';
import { Image } from 'expo-image';
import { DraggableArtworkBubble } from '../../ui/draggable-artwork-bubble';
import Animated, {
  cancelAnimation,
  Easing,
  interpolate,
  useAnimatedStyle,
  useSharedValue,
  withDelay,
  withSpring,
  withTiming,
} from 'react-native-reanimated';
import Svg, { Circle, Defs, LinearGradient, Path, RadialGradient, Stop } from 'react-native-svg';
import { useI18n } from '../../i18n';
import { CKText, colorWithAlpha, useCKTheme, useCKThemeMode } from '../../ui';
import { GlassSurface } from '../../ui/glass';

const art = {
  king: require('../../../assets/clashking/onboarding/king.webp'),
  queen: require('../../../assets/clashking/onboarding/queen.webp'),
  champion: require('../../../assets/clashking/onboarding/champion.webp'),
  townHall: require('../../../assets/clashking/onboarding/town-hall.webp'),
  trophy: require('../../../assets/clashking/onboarding/trophy.png'),
  star: require('../../../assets/clashking/onboarding/star.png'),
  clanOne: require('../../../assets/clashking/onboarding/clan-one.png'),
  clanTwo: require('../../../assets/clashking/onboarding/clan-two.png'),
  swords: require('../../../assets/clashking/onboarding/swords.png'),
  league: require('../../../assets/clashking/onboarding/legend-league.png'),
  builder: require('../../../assets/clashking/calculators/builder-build.webp'),
} as const;
export const onboardingAccents = ['#72CEB5', '#BA9BF5', '#7BB7F9', '#FFC269'] as const;

// A bounded entrance tells a story once. Nothing loops while the user reads,
// and inactive/background pages cancel their work rather than keeping timers alive.
function Arrival({
  children,
  active,
  reduceMotion,
  delay = 0,
  turn = 0,
  style,
}: PropsWithChildren<{
  active: boolean;
  reduceMotion: boolean;
  delay?: number;
  turn?: number;
  style?: StyleProp<ViewStyle>;
}>) {
  const progress = useSharedValue(0);
  useEffect(() => {
    cancelAnimation(progress);
    if (!active || reduceMotion) {
      progress.value = active ? 1 : 0;
      return;
    }
    progress.value = 0;
    progress.value = withDelay(delay, withSpring(1, { damping: 19, stiffness: 145, mass: 0.8 }));
    return () => cancelAnimation(progress);
  }, [active, reduceMotion, delay, progress]);
  const animated = useAnimatedStyle(() => ({
    opacity: interpolate(progress.value, [0, 0.35, 1], [0, 1, 1]),
    transform: [
      { translateY: (1 - progress.value) * 28 },
      { scale: 0.9 + progress.value * 0.1 },
      { rotate: `${turn * progress.value}deg` },
    ],
  }));
  return <Animated.View style={[style, animated]}>{children}</Animated.View>;
}

function HeroToken({
  source,
  active,
  reduceMotion,
  style,
  size = 90,
  delay,
  turn = 0,
}: {
  source: number;
  active: boolean;
  reduceMotion: boolean;
  style: StyleProp<ViewStyle>;
  size?: number;
  delay: number;
  turn?: number;
}) {
  return (
    <Arrival active={active} reduceMotion={reduceMotion} delay={delay} turn={turn} style={style}>
      <DraggableArtworkBubble
        source={source}
        active={active}
        reduceMotion={reduceMotion}
        size={size}
      />
    </Arrival>
  );
}

function Glow({ accent }: { accent: string }) {
  const id = `introGlow${useId().replace(/:/g, '')}`;
  return (
    <Svg width={360} height={360} style={StyleSheet.absoluteFill}>
      <Defs>
        <RadialGradient id={id}>
          <Stop offset="0" stopColor={accent} stopOpacity={0.28} />
          <Stop offset="1" stopColor={accent} stopOpacity={0} />
        </RadialGradient>
      </Defs>
      <Circle cx={180} cy={182} r={180} fill={`url(#${id})`} />
    </Svg>
  );
}

function DemoText({
  children,
  style,
}: PropsWithChildren<{ style?: StyleProp<import('react-native').TextStyle> }>) {
  const fontSize = StyleSheet.flatten(style)?.fontSize;
  return (
    <CKText
      skeleton={false}
      maxFontSizeMultiplier={1.2}
      style={[fontSize ? { lineHeight: Math.ceil(fontSize * 1.2) } : undefined, style]}
    >
      {children}
    </CKText>
  );
}

type SceneProps = { active: boolean; reduceMotion: boolean };
export function OnboardingScene({
  index,
  width,
  active,
  reduceMotion,
}: SceneProps & { index: number; width: number }) {
  const scale = Math.min(1.15, Math.max(0.6, (width - 28) / 360));
  return (
    <View
      style={{ width: '100%', height: 360 * scale, alignItems: 'center', justifyContent: 'center' }}
      accessible={false}
      accessibilityElementsHidden
      importantForAccessibility="no-hide-descendants"
    >
      <View style={{ width: 360, height: 360, transform: [{ scale }] }}>
        {index > 0 ? <Glow accent={onboardingAccents[index]!} /> : null}
        {index === 0 ? (
          <VillageScene active={active} reduceMotion={reduceMotion} />
        ) : index === 1 ? (
          <StatsScene active={active} reduceMotion={reduceMotion} />
        ) : index === 2 ? (
          <WidgetScene active={active} reduceMotion={reduceMotion} />
        ) : (
          <ReminderScene active={active} reduceMotion={reduceMotion} />
        )}
      </View>
    </View>
  );
}

function VillageScene(props: SceneProps) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const progress = useSharedValue(0.56);
  useEffect(() => {
    cancelAnimation(progress);
    progress.value = props.reduceMotion ? 1 : 0.56;
    if (props.active && !props.reduceMotion) {
      // Show one readable tracked upgrade. The app tracks work in Clash;
      // it does not upgrade the village itself or instantly level every hero.
      progress.value = withDelay(
        1200,
        withTiming(1, {
          duration: 1800,
          easing: Easing.inOut(Easing.cubic),
        }),
      );
    }
    return () => cancelAnimation(progress);
  }, [props.active, props.reduceMotion, progress]);
  const fill = useAnimatedStyle(() => ({ transform: [{ scaleX: progress.value }] }));
  const ongoing = useAnimatedStyle(() => ({
    opacity: interpolate(progress.value, [0.94, 1], [1, 0], 'clamp'),
  }));
  const completed = useAnimatedStyle(() => ({
    opacity: interpolate(progress.value, [0.94, 1], [0, 1], 'clamp'),
  }));
  return (
    <>
      <Arrival {...props} delay={60} style={{ position: 'absolute', left: 90, top: 20 }}>
        <Image source={art.townHall} style={{ width: 185, height: 200 }} contentFit="contain" />
      </Arrival>
      <HeroToken
        {...props}
        source={art.king}
        delay={150}
        turn={-12}
        size={77}
        style={{ position: 'absolute', left: 19, top: 81 }}
      />
      <HeroToken
        {...props}
        source={art.champion}
        delay={220}
        turn={9}
        size={72}
        style={{ position: 'absolute', right: 14, top: 55 }}
      />
      <Arrival
        {...props}
        delay={300}
        turn={-3}
        style={{ position: 'absolute', left: 18, top: 215 }}
      >
        <GlassSurface
          cornerRadius={27}
          style={{ width: 324, padding: 17, flexDirection: 'row', alignItems: 'center', gap: 15 }}
        >
          <Image source={art.queen} style={{ width: 68, height: 78 }} contentFit="contain" />
          <View style={{ flex: 1, gap: 8 }}>
            <View style={{ height: 18 }}>
              <Animated.View style={[StyleSheet.absoluteFill, ongoing]}>
                <DemoText style={{ color: theme.onSurfaceVariant, fontSize: 12 }}>
                  {t('upgradeTrackerUpgradingNow')}
                </DemoText>
              </Animated.View>
              <Animated.View style={[StyleSheet.absoluteFill, completed]}>
                <DemoText style={{ color: '#76C9A8', fontSize: 12 }}>
                  {t('homeRecentlyCompleted')}
                </DemoText>
              </Animated.View>
            </View>
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 11 }}>
              <DemoText style={{ fontSize: 28, color: theme.onSurfaceVariant }}>89</DemoText>
              <DemoText style={{ fontSize: 19, color: theme.onSurfaceVariant }}>→</DemoText>
              <DemoText style={{ fontSize: 28, fontWeight: '700' }}>90</DemoText>
            </View>
            <View
              style={{
                height: 5,
                borderRadius: 3,
                overflow: 'hidden',
                backgroundColor: '#7892A638',
              }}
            >
              <Animated.View
                style={[{ height: 5, backgroundColor: '#76C9A8', transformOrigin: 'left' }, fill]}
              />
            </View>
          </View>
        </GlassSurface>
      </Arrival>
    </>
  );
}

function StatsScene(props: SceneProps) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const dark = useCKThemeMode() === 'dark';
  const progress = useSharedValue(props.reduceMotion ? 1 : 0);
  useEffect(() => {
    cancelAnimation(progress);
    progress.value = 0;
    if (props.active)
      progress.value = withDelay(
        props.reduceMotion ? 0 : 350,
        withTiming(1, { duration: props.reduceMotion ? 0 : 850, easing: Easing.out(Easing.cubic) }),
      );
    return () => cancelAnimation(progress);
  }, [props.active, props.reduceMotion, progress]);
  const reveal = useAnimatedStyle(() => ({ width: 264 * progress.value }));
  const id = `chartFill${useId().replace(/:/g, '')}`;
  return (
    <>
      <Arrival {...props} delay={80} turn={-5} style={{ position: 'absolute', left: 27, top: 75 }}>
        <View
          style={[
            styles.chartCard,
            {
              backgroundColor: dark ? '#201A32' : '#F1EAFD',
              borderColor: colorWithAlpha('#BA9BF5', 0.22),
            },
          ]}
        >
          <View style={styles.line}>
            <Image source={art.star} style={styles.smallArt} />
            <DemoText style={{ color: theme.onSurfaceVariant }}>{t('legendsHitrate')}</DemoText>
          </View>
          <DemoText style={[styles.demoMetric, { color: theme.onSurface }]}>
            72.4<DemoText style={{ fontSize: 25, color: '#AC87F4' }}>%</DemoText>
          </DemoText>
          <View style={{ height: 100, width: 264 }}>
            <Svg width={264} height={100} style={StyleSheet.absoluteFill}>
              {[25, 60, 95].map((y) => (
                <Path
                  key={y}
                  d={`M0 ${y}H264`}
                  stroke={theme.onSurface}
                  strokeOpacity={0.08}
                  strokeDasharray="3 5"
                />
              ))}
            </Svg>
            <Animated.View style={[{ height: 100, overflow: 'hidden' }, reveal]}>
              <Svg width={264} height={100}>
                <Defs>
                  <LinearGradient id={id} x1="0" y1="0" x2="0" y2="1">
                    <Stop offset="0" stopColor="#BA9BF5" stopOpacity={0.32} />
                    <Stop offset="1" stopColor="#BA9BF5" stopOpacity={0} />
                  </LinearGradient>
                </Defs>
                <Path
                  d="M0 87 C22 85 24 57 46 64 S74 78 94 51 S119 65 142 36 S169 57 191 27 S221 40 239 16 L264 10 V100 H0Z"
                  fill={`url(#${id})`}
                />
                <Path
                  d="M0 87 C22 85 24 57 46 64 S74 78 94 51 S119 65 142 36 S169 57 191 27 S221 40 239 16 L264 10"
                  stroke="#BA9BF5"
                  strokeWidth={3}
                  fill="none"
                  strokeLinecap="round"
                />
              </Svg>
            </Animated.View>
          </View>
        </View>
      </Arrival>
      <Arrival {...props} delay={230} turn={11} style={{ position: 'absolute', right: 9, top: 20 }}>
        <Image source={art.league} style={{ width: 88, height: 100 }} contentFit="contain" />
      </Arrival>
      <Arrival
        {...props}
        delay={420}
        turn={9}
        style={{ position: 'absolute', right: 13, bottom: 17 }}
      >
        <Image source={art.trophy} style={{ width: 74, height: 94 }} contentFit="contain" />
      </Arrival>
    </>
  );
}

function WidgetScene(props: SceneProps) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const dark = useCKThemeMode() === 'dark';
  return (
    <>
      <Arrival {...props} delay={60} turn={-7} style={{ position: 'absolute', left: 23, top: 46 }}>
        <View
          style={[
            styles.warWidget,
            {
              backgroundColor: dark ? '#162434' : '#E5EFF9',
              borderColor: colorWithAlpha('#7BB7F9', 0.25),
            },
          ]}
        >
          <View style={styles.line}>
            <Image source={art.swords} style={styles.smallArt} />
            <DemoText style={styles.identityText}>{t('warTitle')}</DemoText>
            <View style={{ flex: 1 }} />
            <DemoText style={{ fontSize: 11, color: '#7BB7F9' }}>{t('warInWar')}</DemoText>
          </View>
          <View style={[styles.line, { marginTop: 14, justifyContent: 'space-between', gap: 8 }]}>
            <Image source={art.clanOne} style={{ width: 45, height: 55 }} contentFit="contain" />
            <View style={{ alignItems: 'center', gap: 3 }}>
              <DemoText style={{ fontSize: 32, fontWeight: '700' }}>
                105 <DemoText style={{ color: theme.onSurfaceVariant, fontSize: 22 }}>–</DemoText>{' '}
                102
              </DemoText>
              <Image source={art.star} style={{ width: 17, height: 17 }} contentFit="contain" />
            </View>
            <Image source={art.clanTwo} style={{ width: 45, height: 55 }} contentFit="contain" />
          </View>
        </View>
      </Arrival>
      <Arrival
        {...props}
        delay={240}
        turn={7}
        style={{ position: 'absolute', right: 10, top: 213 }}
      >
        <GlassSurface
          cornerRadius={27}
          style={{
            width: 234,
            height: 106,
            flexDirection: 'row',
            alignItems: 'center',
            paddingHorizontal: 16,
            gap: 12,
          }}
        >
          <Image source={art.builder} contentFit="contain" style={{ width: 57, height: 72 }} />
          <View style={{ flex: 1, gap: 8 }}>
            <DemoText style={{ fontSize: 13 }}>{t('notifGroupProgress')}</DemoText>
            <DemoText style={{ fontSize: 23, fontWeight: '700', color: '#7BB7F9' }}>
              2h 18m
            </DemoText>
            <View
              style={{
                height: 5,
                borderRadius: 4,
                backgroundColor: colorWithAlpha('#7BB7F9', 0.16),
              }}
            >
              <View
                style={{ width: '76%', height: 5, borderRadius: 4, backgroundColor: '#7BB7F9' }}
              />
            </View>
          </View>
        </GlassSurface>
      </Arrival>
    </>
  );
}

function ReminderScene(props: SceneProps) {
  const { t } = useI18n();
  const theme = useCKTheme();
  return (
    <>
      <Arrival {...props} delay={40} turn={-12} style={{ position: 'absolute', left: 85, top: 20 }}>
        <Image source={art.swords} style={{ width: 190, height: 190 }} contentFit="contain" />
      </Arrival>
      <Arrival {...props} delay={280} style={{ position: 'absolute', left: 15, top: 207 }}>
        <GlassSurface cornerRadius={25} style={styles.alert}>
          <Image
            source={require('../../../assets/clashking/icons/app_icon_ios_default.png')}
            style={{ width: 38, height: 38, borderRadius: 10 }}
          />
          <View style={{ flex: 1, gap: 3 }}>
            <DemoText style={{ fontSize: 11, color: theme.onSurfaceVariant }}>ClashKing</DemoText>
            <DemoText style={{ fontSize: 15, fontWeight: '700' }}>
              {t('onboardingAlertTitle')}
            </DemoText>
            <DemoText style={{ fontSize: 13, lineHeight: 18, color: theme.onSurfaceVariant }}>
              {t('onboardingAlertBody')}
            </DemoText>
          </View>
        </GlassSurface>
      </Arrival>
    </>
  );
}

const styles = StyleSheet.create({
  line: { flexDirection: 'row', alignItems: 'center', gap: 9 },
  smallArt: { width: 27, height: 29, objectFit: 'contain' },
  identityText: { fontSize: 15, fontWeight: '600' },
  chartCard: {
    width: 300,
    height: 242,
    borderRadius: 30,
    borderWidth: 1,
    padding: 18,
    shadowColor: '#000',
    shadowOpacity: 0.2,
    shadowOffset: { width: 0, height: 12 },
    shadowRadius: 24,
  },
  demoMetric: { fontSize: 49, fontWeight: '700', lineHeight: 64, marginBottom: 5 },
  warWidget: {
    width: 296,
    height: 167,
    borderWidth: 1,
    borderRadius: 30,
    padding: 20,
    shadowColor: '#000',
    shadowOpacity: 0.16,
    shadowOffset: { width: 0, height: 12 },
    shadowRadius: 24,
  },
  alert: {
    width: 330,
    minHeight: 90,
    padding: 14,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
});
