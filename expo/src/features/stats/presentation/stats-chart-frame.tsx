import { createContext, useContext, useEffect, useRef, useState, type ReactNode } from 'react';
import { Image, Pressable, StyleSheet, View } from 'react-native';
import { Check, Copy } from 'lucide-react-native';
import * as Clipboard from 'expo-clipboard';
import { captureRef } from 'react-native-view-shot';
import { ImageAssets } from '../../../core/assets/image-assets';
import { useI18n } from '../../../i18n';
import { CKText, MobileWebImage, useCKTheme } from '../../../ui';

const ExportContext = createContext(false);
/** One export boundary for every analytics visualization, including its branding. */
export function StatsChartFrame({
  title,
  children,
  showTitle = true,
  testID,
  exportContent,
  copyEnabled = true,
  copyPlacement = 'overlay',
}: {
  readonly title: string;
  readonly children: ReactNode;
  readonly showTitle?: boolean;
  readonly testID?: string;
  readonly exportContent?: ReactNode;
  readonly copyEnabled?: boolean;
  readonly copyPlacement?: 'overlay' | 'footer';
}) {
  const exporting = useContext(ExportContext);
  const theme = useCKTheme();
  const { t } = useI18n();
  const capture = useRef<View>(null);
  const captureStarted = useRef(false);
  const [width, setWidth] = useState(360);
  const [status, setStatus] = useState<'idle' | 'copying' | 'copied' | 'failed'>('idle');
  useEffect(() => {
    if (status !== 'copied') return;
    const timer = setTimeout(() => setStatus('idle'), 1600);
    return () => clearTimeout(timer);
  }, [status]);
  async function captureExport() {
    if (!capture.current || captureStarted.current) return;
    captureStarted.current = true;
    try {
      await Promise.resolve(Image.prefetch(ImageAssets.fallbackLogo)).catch(() => false);
      const data = await captureRef(capture.current, {
        format: 'png',
        result: 'base64',
        quality: 1,
      });
      await Clipboard.setImageAsync(data);
      setStatus('copied');
    } catch {
      setStatus('failed');
    }
  }
  if (exporting || !copyEnabled)
    return (
      <View style={styles.capture}>
        {showTitle ? <CKText role="titleSmall">{title}</CKText> : null}
        {children}
      </View>
    );
  const copyButton = (
    <Pressable
      testID={testID ? `${testID}-copy` : undefined}
      accessibilityRole="button"
      accessibilityLabel={status === 'copied' ? t('generalCopiedToClipboard') : t('statsCopyChart')}
      accessibilityState={{ disabled: status === 'copying' }}
      disabled={status === 'copying'}
      onPress={() => {
        captureStarted.current = false;
        setStatus('copying');
      }}
      style={({ pressed }) => [
        styles.copy,
        copyPlacement === 'footer' ? styles.copyFooter : styles.copyOverlay,
        { opacity: pressed || status === 'copying' ? 0.5 : 1 },
      ]}
    >
      {status === 'copied' ? (
        <Check size={18} color={theme.primary} />
      ) : (
        <Copy size={18} color={theme.onSurfaceVariant} />
      )}
    </Pressable>
  );
  return (
    <View
      testID={testID}
      style={styles.root}
      onLayout={(event) => setWidth(event.nativeEvent.layout.width || 360)}
    >
      {copyPlacement === 'overlay' ? copyButton : null}
      <View style={styles.capture}>
        {showTitle ? (
          <CKText
            role="titleSmall"
            style={copyPlacement === 'overlay' ? styles.titleWithCopy : styles.title}
          >
            {title}
          </CKText>
        ) : null}
        {children}
      </View>
      {copyPlacement === 'footer' ? copyButton : null}
      {status === 'copying' ? (
        <View
          pointerEvents="none"
          accessibilityElementsHidden
          importantForAccessibility="no-hide-descendants"
          style={styles.exportHost}
        >
          <View
            testID="stats-chart-export"
            ref={capture}
            collapsable={false}
            onLayout={() => {
              void captureExport();
            }}
            style={[styles.exportCanvas, { width: width + 40, backgroundColor: theme.surface }]}
          >
            <ExportContext.Provider value={true}>
              <CKText role="titleSmall">{title}</CKText>
              {exportContent ?? children}
              <View style={styles.credit}>
                <MobileWebImage
                  imageUrl={ImageAssets.fallbackLogo}
                  contentFit="contain"
                  style={styles.logo}
                  accessible={false}
                />
                <CKText role="bodySmall" muted>
                  ClashKing
                </CKText>
              </View>
            </ExportContext.Provider>
          </View>
        </View>
      ) : null}
      {status === 'failed' ? (
        <CKText role="bodySmall" accessibilityLiveRegion="polite" muted>
          {t('statsCopyChartFailed')}
        </CKText>
      ) : null}
    </View>
  );
}
const styles = StyleSheet.create({
  root: { position: 'relative' },
  capture: { gap: 8 },
  exportHost: { position: 'absolute', left: -10000, top: 0 },
  // Match the live plot width so export layout cannot alter its scrub coordinates.
  exportCanvas: { gap: 16, padding: 20, borderRadius: 24, overflow: 'hidden' },
  title: { minHeight: 28, textAlignVertical: 'center' },
  titleWithCopy: { paddingRight: 44, minHeight: 28, textAlignVertical: 'center' },
  copy: {
    width: 44,
    height: 44,
    alignItems: 'center',
    justifyContent: 'center',
  },
  copyOverlay: {
    position: 'absolute',
    right: 0,
    top: 0,
    zIndex: 1,
  },
  copyFooter: { alignSelf: 'flex-end' },
  credit: { flexDirection: 'row', alignItems: 'center', justifyContent: 'flex-end', gap: 5 },
  logo: { width: 20, height: 20 },
});
