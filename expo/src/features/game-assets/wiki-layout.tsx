import { WikiZoomableImage } from './wiki-image-viewer';
import { useEffect, useId, useMemo, useState, type ReactNode } from 'react';
import { Alert, Pressable, StyleSheet, View, type StyleProp, type ViewStyle } from 'react-native';
import * as Font from 'expo-font';
import Svg, { Defs, LinearGradient, RadialGradient, Rect, Stop } from 'react-native-svg';
import { ArrowLeft, ArrowRight, Share2 } from '@/ui/icons';
import {
  CKText,
  HeaderIconButton,
  MobileWebImage,
  ProfileHeaderAction,
  colorWithAlpha,
  useCKTheme,
} from '../../ui';
import { useCKThemeMode, CKThemeOverrideProvider } from '../../ui/theme';
import { materialBackLabel, useI18n } from '../../i18n';
import { sharePageLink } from '../../core/deep-links/share-page-link';
import { useLinkParameters } from '../../core/deep-links/link-parameters';
import type { AppLinkParams } from '../../core/deep-links/app-link';

/** Preserve paper and sage in light mode. Dark mode uses black canvas,
 * elevated blue surfaces and gray ink, rather than inverting the artwork. */
export function WikiTheme({ children }: { children: ReactNode }) {
  const base = useCKTheme();
  const dark = useCKThemeMode() === 'dark';
  const colors = useMemo(
    () => ({
      ...base,
      background: '#F1E9D9',
      surface: '#FFF9EC',
      card: '#FFF9EC',
      sheet: '#FFF9EC',
      onSurface: '#3D372B',
      onSurfaceVariant: '#796E58',
      surfaceContainerHighest: '#E3D7BD',
      outlineVariant: '#C3B593',
      primary: '#BF272D',
      onPrimary: '#FFFFFF',
      ...(dark
        ? {
            background: '#000000',
            surface: '#172D40',
            card: '#172D40',
            sheet: '#213D54',
            onSurface: '#DEE3E9',
            onSurfaceVariant: '#ADB9C8',
            surfaceContainerHighest: '#365D79',
            outlineVariant: '#5B7E99',
            primary: '#AED5F4',
            onPrimary: '#142235',
            secondary: '#A6C5E5',
          }
        : {}),
    }),
    [base, dark],
  );
  return <CKThemeOverrideProvider colors={colors}>{children}</CKThemeOverrideProvider>;
}
let displayFont: Promise<void> | undefined;
export function WikiTitle({
  children,
  style,
  size = 23,
  centered = false,
  color,
}: {
  children: ReactNode;
  style?: StyleProp<ViewStyle>;
  size?: number;
  centered?: boolean;
  color?: string;
}) {
  const [ready, setReady] = useState(Font.isLoaded('Supercell-Magic'));
  useEffect(() => {
    let active = true;
    displayFont ??= Font.loadAsync({
      'Supercell-Magic': require('../../../assets/clashking/legend-poster/clash.ttf'),
    }).catch(() => {
      displayFont = undefined;
    });
    void displayFont.then(() => {
      if (active) setReady(Font.isLoaded('Supercell-Magic'));
    });
    return () => {
      active = false;
    };
  }, []);
  return (
    <View style={style}>
      <CKText
        role="screenTitle"
        style={{
          ...(color ? { color } : {}),
          fontFamily: ready ? 'Supercell-Magic' : 'ClashKing',
          fontSize: size,
          lineHeight: Math.round(size * 1.35),
          fontWeight: '400',
          textAlign: centered ? 'center' : 'auto',
        }}
      >
        {children}
      </CKText>
    </View>
  );
}

/** Contained Wiki artwork intentionally uses a the approved sage or blue backdrop, not the
 * photo scrim used on account headers. Match the approved illustrated guide. */
function WikiBackdrop({ unit = false }: { unit?: boolean }) {
  const id = useId().replace(/[^a-zA-Z0-9]/g, '');
  const dark = useCKThemeMode() === 'dark';
  const [bounds, setBounds] = useState({ width: 0, height: 0 });
  return (
    <View
      pointerEvents="none"
      // The wrapper owns full native bounds, including padding. Percentage SVG
      // dimensions on the padded header itself leave exposed right/bottom strips.
      style={[
        StyleSheet.absoluteFill,
        { backgroundColor: unit ? '#0D3869' : dark ? '#163852' : '#D8E5CE' },
      ]}
      onLayout={({ nativeEvent: { layout } }) =>
        setBounds((old) =>
          old.width === layout.width && old.height === layout.height ? old : layout,
        )
      }
    >
      <Svg
        pointerEvents="none"
        accessible={false}
        width={bounds.width}
        height={bounds.height}
        viewBox="0 0 100 100"
        preserveAspectRatio="none"
      >
        <Defs>
          <LinearGradient id={`${id}base`} x1="0" y1="0" x2="1" y2="1">
            <Stop offset="0" stopColor={unit ? '#0D3869' : dark ? '#163852' : '#D8E5CE'} />
            <Stop offset="1" stopColor={unit ? '#1A76AC' : dark ? '#3979A0' : '#91AC82'} />
          </LinearGradient>
          <RadialGradient id={`${id}light`} cx="65%" cy="40%" rx="65%" ry="75%">
            <Stop offset="0" stopColor={unit ? '#68B5CF' : '#E9F2D6'} stopOpacity={0.25} />
            <Stop offset="1" stopColor={unit ? '#68B5CF' : '#E9F2D6'} stopOpacity={0} />
          </RadialGradient>
        </Defs>
        <Rect width="100" height="100" fill={`url(#${id}base)`} />
        <Rect width="100" height="100" fill={`url(#${id}light)`} />
      </Svg>
    </View>
  );
}
export function WikiBack({ onBack, light = false }: { onBack: () => void; light?: boolean }) {
  const theme = useCKTheme(),
    { locale, isRtl } = useI18n();
  return (
    <HeaderIconButton
      label={materialBackLabel(locale)}
      onPress={onBack}
      icon={
        isRtl ? (
          <ArrowRight color={light ? '#FFFFFF' : theme.onSurface} />
        ) : (
          <ArrowLeft color={light ? '#FFFFFF' : theme.onSurface} />
        )
      }
    />
  );
}
/** Follow the current Wiki route; explicit params also cover tracker entry points.
 * ProfileHeaderAction moves the action into the native rail on dual-screen layouts. */
export function WikiShare({
  title,
  params,
  light = false,
}: {
  title: string;
  params?: AppLinkParams;
  light?: boolean;
}) {
  const current = useLinkParameters();
  const theme = useCKTheme();
  const { t } = useI18n();
  return (
    <ProfileHeaderAction
      appLinkShare
      label={t('gameAssetsShare')}
      icon={<Share2 size={21} color={light ? '#FFFFFF' : theme.onSurface} />}
      onPress={() => {
        void sharePageLink(
          { kind: 'page', page: 'gameAssets', params: params ?? current },
          title,
        ).catch(() => Alert.alert(t('generalError'), t('errorCannotOpenLink')));
      }}
    />
  );
}
export function WikiHomeHeader({ onBack }: { onBack: () => void }) {
  const theme = useCKTheme(),
    { t } = useI18n();
  return (
    <View
      style={[styles.homeHeader, { borderBottomColor: colorWithAlpha(theme.outlineVariant, 0.25) }]}
    >
      <View style={styles.homeAction}>
        <WikiBack onBack={onBack} />
      </View>
      <WikiTitle size={18} centered style={styles.homeTitle}>
        {t('sideGameAssetsTitle')}
      </WikiTitle>
      <View style={styles.homeAction}>
        <WikiShare title={t('sideGameAssetsTitle')} params={{}} />
      </View>
    </View>
  );
}
export function WikiHomeIntro({ image }: { image?: string }) {
  const { t } = useI18n();
  const dark = useCKThemeMode() === 'dark';
  return (
    <View style={styles.intro}>
      <WikiBackdrop />
      <View style={styles.introCopy}>
        <WikiTitle size={26} centered>
          {t('wikiIntroTitle')}
        </WikiTitle>
        <CKText
          muted
          role="bodySmall"
          style={{
            fontSize: 13,
            lineHeight: 19,
            marginTop: 10,
            textAlign: 'center',
            color: dark ? '#DEE3E9' : '#33472D',
          }}
        >
          {t('wikiIntroBody')}
        </CKText>
      </View>
      {image ? (
        <MobileWebImage imageUrl={image} contentFit="contain" style={styles.introArt} />
      ) : null}
    </View>
  );
}

/** Center identity independently of navigation. A stacked icon/title avoids
 * long translations shifting the image or colliding with Back/Share controls.
 * Height follows the content; large item portraits keep their existing scale. */
export function WikiHeader({
  title,
  image,
  onBack,
  large = false,
  subtitle,
  shareParams,
  compact = false,
  fallbackImages,
}: {
  title: string;
  image?: string;
  onBack: () => void;
  large?: boolean;
  subtitle?: string;
  shareParams?: AppLinkParams;
  compact?: boolean;
  fallbackImages?: readonly string[];
}) {
  return (
    <View style={[styles.hero, large && styles.largeHero, compact && styles.compactHero]}>
      <WikiBackdrop unit={large} />
      <View style={styles.back}>
        <WikiBack onBack={onBack} light={large} />
      </View>
      <View style={styles.share}>
        <WikiShare title={title} params={shareParams} light={large} />
      </View>
      {large ? (
        <>
          {subtitle ? (
            <CKText role="bodySmall" style={[styles.kicker, { color: '#CFDFEB' }]}>
              {subtitle}
            </CKText>
          ) : null}
          <WikiTitle size={28} centered color="#FFFFFF" style={styles.title}>
            {title}
          </WikiTitle>
          {image ? (
            <View style={styles.portrait}>
              <View style={{ height: 218 }}>
                <WikiZoomableImage image={image} title={title}>
                  <MobileWebImage
                    imageUrl={image}
                    fallbackImageUrls={fallbackImages}
                    contentFit="contain"
                    cachePolicy="memory-disk"
                    transition={0}
                    style={styles.largeArt}
                  />
                </WikiZoomableImage>
              </View>
            </View>
          ) : null}
        </>
      ) : (
        <View style={styles.identity}>
          {image ? (
            <MobileWebImage
              imageUrl={image}
              contentFit="contain"
              style={[styles.smallArt, compact && styles.compactArt]}
            />
          ) : null}
          <View style={styles.identityCopy}>
            <WikiTitle size={compact ? 22 : 24} centered>
              {title}
            </WikiTitle>
            {subtitle ? (
              <CKText muted role="bodySmall" style={styles.subtitle}>
                {subtitle}
              </CKText>
            ) : null}
          </View>
        </View>
      )}
    </View>
  );
}
export function WikiChoice({
  label,
  selected,
  onPress,
  image,
}: {
  label: string;
  selected: boolean;
  onPress: () => void;
  image?: string;
}) {
  const theme = useCKTheme();
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityState={{ selected }}
      onPress={onPress}
      style={[
        styles.choice,
        {
          backgroundColor: selected ? theme.primary : theme.card,
          borderColor: selected ? theme.primary : colorWithAlpha(theme.outlineVariant, 0.3),
        },
      ]}
    >
      {image ? (
        <MobileWebImage imageUrl={image} style={{ width: 20, height: 23 }} contentFit="contain" />
      ) : null}
      <CKText
        role="bodySmall"
        style={{
          fontSize: 12,
          lineHeight: 17,
          color: selected ? theme.onPrimary : theme.onSurface,
        }}
      >
        {label}
      </CKText>
    </Pressable>
  );
}
export function WikiSectionLinks({ onSelect }: { onSelect: (section: string) => void }) {
  const { t } = useI18n(),
    theme = useCKTheme();
  const [selected, setSelected] = useState('overview');
  return (
    <View style={[styles.links, { borderBottomColor: colorWithAlpha(theme.outlineVariant, 0.3) }]}>
      {[
        ['overview', t('gameItemOverview')],
        ['levels', t('gameItemLevels')],
      ].map(([key, label]) => (
        <Pressable
          key={key}
          accessibilityRole="button"
          accessibilityState={{ selected: key === selected }}
          onPress={() => {
            setSelected(key!);
            onSelect(key!);
          }}
          style={{
            minHeight: 44,
            justifyContent: 'center',
            borderBottomWidth: 2,
            borderBottomColor: key === selected ? theme.primary : 'transparent',
          }}
        >
          <CKText
            role="bodySmall"
            style={{
              fontSize: 12,
              color: key === selected ? theme.primary : theme.onSurfaceVariant,
            }}
          >
            {label}
          </CKText>
        </Pressable>
      ))}
    </View>
  );
}
const styles = StyleSheet.create({
  homeHeader: {
    minHeight: 60,
    paddingVertical: 8,
    paddingHorizontal: 12,
    flexDirection: 'row',
    alignItems: 'center',
    borderBottomWidth: StyleSheet.hairlineWidth,
  },
  // Equal action slots keep the title on the page center even when Share is
  // moved to the Duo rail and its inline control renders nothing.
  homeAction: { width: 48, alignItems: 'center', justifyContent: 'center' },
  homeTitle: { flex: 1, minWidth: 0, paddingHorizontal: 8 },
  intro: {
    paddingTop: 24,
    paddingHorizontal: 24,
    paddingBottom: 12,
    position: 'relative',
    overflow: 'hidden',
    alignItems: 'center',
    gap: 12,
  },
  introCopy: { width: '100%', maxWidth: 520, zIndex: 1 },
  introArt: { width: 168, height: 160 },
  hero: {
    position: 'relative',
    overflow: 'hidden',
    paddingTop: 60,
    paddingHorizontal: 18,
    paddingBottom: 24,
  },
  largeHero: { paddingTop: 62, paddingBottom: 24 },
  compactHero: { paddingTop: 60, paddingBottom: 20 },
  back: { position: 'absolute', start: 10, top: 8, zIndex: 2 },
  share: { position: 'absolute', end: 10, top: 8, zIndex: 2 },
  identity: { alignItems: 'center', alignSelf: 'center', width: '100%', maxWidth: 620, gap: 12 },
  identityCopy: { width: '100%', gap: 6 },
  title: { width: '100%', maxWidth: 620, alignSelf: 'center', paddingHorizontal: 6 },
  subtitle: { fontSize: 12, lineHeight: 18, textAlign: 'center' },
  smallArt: { width: 75, height: 80 },
  compactArt: { width: 64, height: 68 },
  portrait: { width: '100%', maxWidth: 640, alignSelf: 'center', marginTop: 12 },
  largeArt: { height: 218, width: '100%' },
  kicker: {
    fontSize: 11,
    lineHeight: 16,
    textAlign: 'center',
    marginBottom: 8,
    alignSelf: 'center',
    maxWidth: 620,
  },
  choice: {
    minHeight: 44,
    paddingHorizontal: 13,
    paddingVertical: 8,
    borderWidth: 1,
    borderRadius: 9,
    flexDirection: 'row',
    gap: 7,
    alignItems: 'center',
    justifyContent: 'center',
  },
  links: {
    flexDirection: 'row',
    gap: 22,
    borderBottomWidth: StyleSheet.hairlineWidth,
    paddingHorizontal: 18,
  },
});
