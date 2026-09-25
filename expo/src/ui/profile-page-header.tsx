import type { ReactNode } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { ArrowLeft } from 'lucide-react-native';
import Svg, { Defs, LinearGradient, Rect, Stop } from 'react-native-svg';

import { ImageAssets } from '../core/assets/image-assets';
import { CKText } from './text';
import { MobileWebImage } from './mobile-web-image';
import { useCKThemeMode } from './theme';

export interface ProfilePageHeaderProps {
  title: string;
  imageUrl: string;
  backgroundUrl?: string;
  onBack: () => void;
  backLabel: string;
  safeTop?: number;
  bottomPadding?: number;
  actions?: ReactNode;
  children?: ReactNode;
  testID?: string;
}

export function ProfilePageHeader({
  title,
  imageUrl,
  backgroundUrl = ImageAssets.homeBaseBackground,
  onBack,
  backLabel,
  safeTop = 0,
  bottomPadding = 16,
  actions,
  children,
  testID = 'profile-page-header',
}: ProfilePageHeaderProps) {
  const themeMode = useCKThemeMode();
  return (
    <View testID={testID} style={[styles.header, { paddingTop: safeTop }]}>
      <View testID="profile-page-header-backdrop" pointerEvents="none" style={styles.backdrop}>
        <MobileWebImage
          imageUrl={backgroundUrl}
          style={StyleSheet.absoluteFill}
          contentFit="cover"
        />
        <View style={[StyleSheet.absoluteFill, styles.scrim]} />
        <Svg style={StyleSheet.absoluteFill} width="100%" height="100%" pointerEvents="none">
          <Defs>
            <LinearGradient id="profile-page-header-gradient" x1="0%" y1="0%" x2="0%" y2="100%">
              <Stop offset="0" stopColor="#000" stopOpacity={themeMode === 'dark' ? 0.36 : 0.2} />
              <Stop offset="0.5" stopColor="#000" stopOpacity={themeMode === 'dark' ? 0.64 : 0.4} />
              <Stop offset="1" stopColor="#000" stopOpacity={themeMode === 'dark' ? 0.92 : 0.65} />
            </LinearGradient>
          </Defs>
          <Rect width="100%" height="100%" fill="url(#profile-page-header-gradient)" />
        </Svg>
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
        <View style={styles.identity}>
          <MobileWebImage
            imageUrl={imageUrl}
            style={styles.identityImage}
            contentFit="contain"
            testID="profile-page-header-image"
          />
          <CKText role="titleLarge" style={styles.title}>
            {title}
          </CKText>
        </View>
        {children ? <View style={styles.controls}>{children}</View> : null}
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
  controls: { paddingHorizontal: 16, paddingTop: 12, gap: 8, alignItems: 'stretch' },
});
