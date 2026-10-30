import { type ReactNode } from 'react';
import { Pressable, StyleSheet, View, useWindowDimensions } from 'react-native';
import { ArrowLeft } from 'lucide-react-native';
import { illustratedHeaderLayout } from './illustrated-header-layout';
import { HeroHeaderScrim } from './hero-header-scrim';
import { useNativeRailBack } from './native-back-context';
import { useAdaptiveLayout } from './adaptive-layout';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { HeaderArtwork } from './header-artwork';

import { ImageAssets } from '../core/assets/image-assets';
import { CKText } from './text';
import { MobileWebImage, headerArtworkSize } from './mobile-web-image';

export interface ProfilePageHeaderProps {
  title: string;
  titleImageUrl?: string;
  subtitle?: string;
  imageUrl: string;
  imageElement?: ReactNode;
  imageSize?: number;
  backgroundUrl?: string;
  backgroundSource?: number;
  backgroundElement?: ReactNode;
  compactIdentity?: boolean;
  /** Compact library headers keep the artwork behind a single identity row. */
  identityLayout?: 'stacked' | 'inline';
  identityOffsetY?: number;
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
  titleImageUrl,
  subtitle,
  imageUrl,
  imageElement,
  imageSize = 64,
  backgroundUrl = ImageAssets.homeBaseBackground,
  backgroundSource,
  backgroundElement,
  compactIdentity = false,
  identityLayout = 'stacked',
  identityOffsetY = 0,
  onBack,
  backLabel,
  safeTop = 0,
  bottomPadding = 16,
  controlsTopPadding = 12,
  actions,
  children,
  testID = 'profile-page-header',
}: ProfilePageHeaderProps) {
  const nativeBack = useNativeRailBack(onBack);
  const layout = useAdaptiveLayout();
  const insets = useSafeAreaInsets();
  const { width } = useWindowDimensions();
  if (layout.isExpanded) {
    const geometry = illustratedHeaderLayout(layout);
    const railLeft = layout.isDuo ? insets.left : 0;
    const railRight = layout.isDuo ? insets.right : 0;
    return (
      <View
        testID={testID}
        style={[
          styles.header,
          {
            paddingTop: safeTop,
            minHeight: geometry.minHeight + safeTop,
            marginLeft: -railLeft,
            marginRight: -railRight,
          },
        ]}
      >
        <View testID="profile-page-header-backdrop" pointerEvents="none" style={styles.backdrop}>
          {backgroundElement ?? (
            <>
              {backgroundSource ? (
                <HeaderArtwork
                  source={backgroundSource}
                  style={StyleSheet.absoluteFill}
                  contentFit="cover"
                />
              ) : (
                <MobileWebImage
                  imageUrl={backgroundUrl}
                  displaySize={headerArtworkSize(width)}
                  cachePolicy="memory-disk"
                  priority="high"
                  transition={0}
                  style={StyleSheet.absoluteFill}
                  contentFit="cover"
                />
              )}
              <HeroHeaderScrim clipRailInset />
            </>
          )}
        </View>
        <View
          style={{
            width: '100%',
            maxWidth: layout.contentMaxWidth + railLeft + railRight,
            alignSelf: 'center',
            paddingLeft: railLeft,
            paddingRight: railRight,
          }}
        >
          <View style={[styles.actionRow, { paddingHorizontal: 20 }]}>
            {nativeBack ? (
              <View style={styles.backButton} />
            ) : (
              <Pressable
                accessibilityRole="button"
                accessibilityLabel={backLabel}
                hitSlop={8}
                onPress={onBack}
                style={styles.backButton}
              >
                <ArrowLeft color="#fff" />
              </Pressable>
            )}
            <View style={styles.actionSpacer} />
            {actions ? <View style={styles.actions}>{actions}</View> : null}
          </View>
          <View
            style={{
              minHeight: geometry.bodyMinHeight,
              justifyContent: 'center',
              gap: 16,
              paddingHorizontal: geometry.horizontal,
              paddingTop: 8,
              paddingBottom: Math.max(geometry.bottom, bottomPadding),
            }}
          >
            <View
              style={{
                width: '100%',
                flexDirection: 'row',
                alignItems: 'center',
                gap: geometry.gap,
              }}
            >
              {imageElement ?? (
                <MobileWebImage
                  imageUrl={imageUrl}
                  cachePolicy="memory-disk"
                  priority="high"
                  transition={0}
                  style={{
                    width: Math.max(imageSize, geometry.image),
                    height: Math.max(imageSize, geometry.image),
                  }}
                  contentFit="contain"
                  testID="profile-page-header-image"
                />
              )}
              <View style={{ flex: 1, minWidth: 0, gap: 6 }}>
                <View style={[styles.titleRow, { justifyContent: 'flex-start' }]}>
                  {titleImageUrl ? (
                    <MobileWebImage
                      imageUrl={titleImageUrl}
                      style={styles.titleImage}
                      contentFit="contain"
                    />
                  ) : null}
                  <CKText
                    role="titleLarge"
                    style={[
                      styles.title,
                      {
                        textAlign: 'left',
                        fontSize: geometry.title,
                        lineHeight: geometry.titleLine,
                      },
                    ]}
                  >
                    {title}
                  </CKText>
                </View>
                {subtitle ? (
                  <CKText
                    role="bodySmall"
                    style={[styles.subtitle, { textAlign: 'left', paddingHorizontal: 0 }]}
                  >
                    {subtitle}
                  </CKText>
                ) : null}
              </View>
            </View>
            {children ? (
              <View style={{ width: '100%', minWidth: 0, gap: 8, alignItems: 'flex-start' }}>
                {children}
              </View>
            ) : null}
          </View>
        </View>
      </View>
    );
  }
  return (
    <View testID={testID} style={[styles.header, { paddingTop: safeTop }]}>
      <View testID="profile-page-header-backdrop" pointerEvents="none" style={styles.backdrop}>
        {backgroundElement ?? (
          <>
            {backgroundSource ? (
              <HeaderArtwork
                source={backgroundSource}
                style={StyleSheet.absoluteFill}
                contentFit="cover"
              />
            ) : (
              <MobileWebImage
                imageUrl={backgroundUrl}
                displaySize={headerArtworkSize(width)}
                cachePolicy="memory-disk"
                priority="high"
                transition={0}
                style={StyleSheet.absoluteFill}
                contentFit="cover"
              />
            )}
            <HeroHeaderScrim />
          </>
        )}
      </View>
      <View
        style={[
          styles.content,
          { paddingBottom: bottomPadding },
          layout.isDuo && { maxWidth: layout.contentMaxWidth },
        ]}
      >
        <View style={styles.actionRow}>
          {nativeBack ? (
            <View style={styles.backButton} />
          ) : (
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={backLabel}
              hitSlop={8}
              onPress={onBack}
              style={styles.backButton}
            >
              <ArrowLeft color="#fff" />
            </Pressable>
          )}
          <View style={styles.actionSpacer} />
          {actions ? <View style={styles.actions}>{actions}</View> : null}
        </View>
        <View
          style={[
            styles.identity,
            compactIdentity && { marginTop: -24 },
            identityLayout === 'inline' && styles.inlineIdentity,
            identityOffsetY !== 0 && { transform: [{ translateY: identityOffsetY }] },
          ]}
        >
          {imageElement ?? (
            <MobileWebImage
              imageUrl={imageUrl}
              cachePolicy="memory-disk"
              priority="high"
              transition={0}
              style={[styles.identityImage, { width: imageSize, height: imageSize }]}
              contentFit="contain"
              testID="profile-page-header-image"
            />
          )}
          <View style={styles.titleRow}>
            {titleImageUrl ? (
              <MobileWebImage
                imageUrl={titleImageUrl}
                style={styles.titleImage}
                contentFit="contain"
              />
            ) : null}
            <CKText role="titleLarge" style={styles.title}>
              {title}
            </CKText>
          </View>
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
  inlineIdentity: { flexDirection: 'row', gap: 12, paddingTop: 4, paddingBottom: 8 },
  titleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    maxWidth: '100%',
  },
  titleImage: { width: 28, height: 32 },
  title: { color: '#fff', textAlign: 'center', flexShrink: 1 },
  subtitle: { color: '#ffffffcc', textAlign: 'center', paddingHorizontal: 12 },
  controls: { paddingHorizontal: 16, paddingTop: 12, gap: 8, alignItems: 'stretch' },
});
