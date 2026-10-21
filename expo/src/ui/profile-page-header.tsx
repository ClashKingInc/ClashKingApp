import { useState, type ReactNode } from 'react';
import { Pressable, StyleSheet, View, useWindowDimensions } from 'react-native';
import { ArrowLeft } from 'lucide-react-native';
import Svg, { Defs, LinearGradient, Rect, Stop } from 'react-native-svg';

import { ImageAssets } from '../core/assets/image-assets';
import { CKText } from './text';
import { MobileWebImage, headerArtworkSize } from './mobile-web-image';
import { useCKThemeMode } from './theme';

export interface ProfilePageHeaderProps {
  title: string;
  subtitle?: string;
  imageUrl: string;
  backgroundUrl?: string;
  backgroundElement?: ReactNode;
  compactIdentity?: boolean;
  onBack: () => void;
  backLabel: string;
  safeTop?: number;
  bottomPadding?: number;
  controlsTopPadding?: number;
  actions?: ReactNode;
  children?: ReactNode;
  testID?: string;
}

export function ProfilePageHeader({
  title,
  subtitle,
  imageUrl,
  backgroundUrl = ImageAssets.homeBaseBackground,
  backgroundElement,
  compactIdentity = false,
  onBack,
  backLabel,
  safeTop = 0,
  bottomPadding = 16,
  controlsTopPadding = 12,
  actions,
  children,
  testID = 'profile-page-header',
}: ProfilePageHeaderProps) {
  const themeMode = useCKThemeMode();
  const { width } = useWindowDimensions();
  const [headerSize, setHeaderSize] = useState({ width: 0, height: 0 });
  return (
    <View
      testID={testID}
      style={[styles.header, { paddingTop: safeTop }]}
      onLayout={(event) => {
        const { width, height } = event.nativeEvent.layout;
        setHeaderSize((current) =>
          current.width === width && current.height === height ? current : { width, height },
        );
      }}
    >
      <View testID="profile-page-header-backdrop" pointerEvents="none" style={styles.backdrop}>
        {backgroundElement ?? <>
        <MobileWebImage
          imageUrl={backgroundUrl}
          displaySize={headerArtworkSize(width)}
          cachePolicy="memory-disk"
          priority="high"
          transition={0}
          style={StyleSheet.absoluteFill}
          contentFit="cover"
        />
        <View style={[StyleSheet.absoluteFill, styles.scrim]} />
        {/* Explicit bounds avoid native percentage clipping inside padded headers. */}
        {headerSize.width > 0 ? (
          <Svg
            style={StyleSheet.absoluteFill}
            width={headerSize.width}
            height={headerSize.height}
            viewBox={`0 0 ${headerSize.width} ${headerSize.height}`}
            pointerEvents="none"
          >
            <Defs>
              <LinearGradient id="profile-page-header-gradient" x1="0%" y1="0%" x2="0%" y2="100%">
                <Stop offset="0" stopColor="#000" stopOpacity={themeMode === 'dark' ? 0.36 : 0.2} />
                <Stop
                  offset="0.5"
                  stopColor="#000"
                  stopOpacity={themeMode === 'dark' ? 0.64 : 0.4}
                />
                <Stop
                  offset="1"
                  stopColor="#000"
                  stopOpacity={themeMode === 'dark' ? 0.92 : 0.65}
                />
              </LinearGradient>
            </Defs>
            <Rect
              width={headerSize.width}
              height={headerSize.height}
              fill="url(#profile-page-header-gradient)"
            />
          </Svg>
        ) : null}
        </>}
      </View>
      <View style={[styles.content, { paddingBottom: bottomPadding }]}>
        <View style={styles.actionRow}>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={backLabel}
            hitSlop={8}
            onPress={onBack}
            style={styles.backButton}
          >
            <ArrowLeft color="#fff" />
          </Pressable>
          <View style={styles.actionSpacer} />
          {actions ? <View style={styles.actions}>{actions}</View> : null}
        </View>
        <View style={[styles.identity, compactIdentity && { marginTop: -24 }]}>
          <MobileWebImage
            imageUrl={imageUrl}
            cachePolicy="memory-disk"
            priority="high"
            transition={0}
            style={styles.identityImage}
            contentFit="contain"
            testID="profile-page-header-image"
          />
          <CKText role="titleLarge" style={styles.title}>
            {title}
          </CKText>
          {subtitle ? (
            <CKText role="bodySmall" style={styles.subtitle}>
              {subtitle}
            </CKText>
          ) : null}
        </View>
        {children ? (
          <View style={[styles.controls, { paddingTop: controlsTopPadding }]}>{children}</View>
        ) : null}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  header: { overflow: 'hidden' },
  backdrop: { position: 'absolute', top: 0, right: 0, bottom: 0, left: 0, overflow: 'hidden' },
  scrim: { backgroundColor: '#00000080' },
  content: { maxWidth: 1120, width: '100%', alignSelf: 'center' },
  actionRow: {
    minHeight: 48,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    gap: 8,
  },
  backButton: { width: 48, height: 48, alignItems: 'center', justifyContent: 'center' },
  actionSpacer: { flex: 1 },
  actions: {
    minHeight: 48,
    flexDirection: 'row',
    alignItems: 'center',
    flexWrap: 'wrap',
    justifyContent: 'flex-end',
    gap: 8,
  },
  identity: { alignItems: 'center', justifyContent: 'center', paddingHorizontal: 16, gap: 4 },
  identityImage: { width: 64, height: 64 },
  title: { color: '#fff', textAlign: 'center' },
  subtitle: { color: '#ffffffcc', textAlign: 'center', paddingHorizontal: 12 },
  controls: { paddingHorizontal: 16, paddingTop: 12, gap: 8, alignItems: 'stretch' },
});
