import { useRef, useState, type ReactNode } from 'react';
import {
  Modal,
  Image,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  View,
  type LayoutChangeEvent,
  type View as ViewType,
} from 'react-native';
import { Share2, X } from 'lucide-react-native';
import { captureRef } from 'react-native-view-shot';

import { materialCloseLabel, useI18n } from '../i18n';
import { CKText } from './text';
import { PressableSurface, Surface } from './surfaces';
import { ckRadius } from './tokens';
import { useCKTheme } from './theme';

const CAPTURE_TIMEOUT_MS = 12_000;
const CAPTURE_WIDTH = 1200;
const CAPTURE_HEIGHT = 675;

export interface HorizontalImageCanvasSize {
  readonly width: number;
  readonly height: number;
}

const defaultCanvasSize: HorizontalImageCanvasSize = { width: 600, height: 337.5 };

export function horizontalImagePreviewScale(availableWidth: number, canvasWidth: number): number {
  if (!Number.isFinite(availableWidth) || !Number.isFinite(canvasWidth) || canvasWidth <= 0) {
    return 0;
  }
  return Math.min(1, Math.max(0, availableWidth) / canvasWidth);
}

export function horizontalImageFilename(
  kind: 'battlelog' | 'legends',
  playerName: string,
  qualifier = '',
  now = new Date(),
): string {
  const safeName = playerName
    .replace(/[^\w\s-]/gu, '')
    .trim()
    .replace(/\s+/gu, '_');
  const safeQualifier = qualifier.replace(/[^\w-]/gu, '').toLowerCase();
  const pad = (value: number) => String(value).padStart(2, '0');
  const timestamp = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}_${pad(now.getHours())}-${pad(now.getMinutes())}-${pad(now.getSeconds())}`;
  return [kind, safeQualifier, safeName, timestamp].filter(Boolean).join('_') + '.png';
}

export async function shareHorizontalCapture(options: {
  readonly fileName: string;
  readonly message: string;
  readonly platform: 'web' | 'native';
  readonly capture: () => Promise<string>;
  readonly nativeShare: (url: string, message: string) => Promise<void>;
  readonly webDownload: (url: string, fileName: string) => void;
}) {
  const url = await options.capture();
  if (options.platform === 'web') options.webDownload(url, options.fileName);
  else await options.nativeShare(url, options.message);
  return { url, fileName: options.fileName };
}

export function HorizontalImageShareModal({
  children,
  artworkUrls = [],
  fileName,
  message,
  title,
  visible,
  onClose,
  canvasSize = defaultCanvasSize,
}: {
  readonly children: ReactNode;
  readonly artworkUrls?: readonly string[];
  readonly canvasSize?: HorizontalImageCanvasSize;
  readonly fileName: string;
  readonly message: string;
  readonly title: string;
  readonly visible: boolean;
  readonly onClose: () => void;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const boundary = useRef<ViewType>(null);
  const [previewWidth, setPreviewWidth] = useState(0);
  const [sharing, setSharing] = useState(false);
  const [failed, setFailed] = useState(false);

  async function share() {
    if (!boundary.current || sharing) return;
    setSharing(true);
    setFailed(false);
    try {
      await shareHorizontalCapture({
        fileName,
        message,
        platform: Platform.OS === 'web' ? 'web' : 'native',
        capture: async () => {
          await afterPaint();
          await Promise.allSettled(artworkUrls.map((url) => Image.prefetch(url)));
          await afterPaint();
          return withTimeout(
            captureRef(boundary.current!, {
              format: 'png',
              quality: 1,
              result: Platform.OS === 'web' ? 'data-uri' : 'tmpfile',
              fileName: fileName.replace(/\.png$/u, ''),
              width: CAPTURE_WIDTH,
              height: CAPTURE_HEIGHT,
            }),
            CAPTURE_TIMEOUT_MS,
          );
        },
        nativeShare: async (url, shareMessage) => {
          const { default: Share } = await import('react-native-share');
          await Share.open({ url, message: shareMessage, type: 'image/png', failOnCancel: false });
        },
        webDownload: (url, downloadName) => {
          if (typeof document === 'undefined') return;
          const anchor = document.createElement('a');
          anchor.href = url;
          anchor.download = downloadName;
          anchor.click();
        },
      });
    } catch {
      setFailed(true);
    } finally {
      setSharing(false);
    }
  }

  return (
    <Modal visible={visible} transparent animationType="slide" onRequestClose={onClose}>
      <View style={styles.overlay}>
        <Surface radius={ckRadius.card} style={styles.sheet}>
          <View style={styles.header}>
            <CKText role="titleLarge" style={styles.grow}>
              {title}
            </CKText>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={materialCloseLabel(locale)}
              onPress={onClose}
            >
              <X color={theme.onSurface} />
            </Pressable>
          </View>
          <ScrollView contentContainerStyle={styles.content}>
            <View
              onLayout={(event: LayoutChangeEvent) =>
                setPreviewWidth(event.nativeEvent.layout.width)
              }
              style={styles.previewFrame}
            >
              <View
                pointerEvents="none"
                style={[
                  styles.canvasScaler,
                  {
                    width: canvasSize.width,
                    height: canvasSize.height,
                    opacity: previewWidth > 0 ? 1 : 0,
                    transform: [
                      { scale: horizontalImagePreviewScale(previewWidth, canvasSize.width) },
                    ],
                  },
                ]}
              >
                <View
                  ref={boundary}
                  collapsable={false}
                  style={[
                    styles.graphicBoundary,
                    { width: canvasSize.width, height: canvasSize.height },
                  ]}
                >
                  {children}
                </View>
              </View>
            </View>
            {failed ? <CKText muted>{t('generalError')}</CKText> : null}
            <PressableSurface
              accessibilityRole="button"
              disabled={sharing}
              onPress={() => void share()}
              style={styles.action}
            >
              <Share2 color={theme.onSurface} />
              <CKText>{sharing ? t('generalLoading') : t('generalExport')}</CKText>
            </PressableSurface>
          </ScrollView>
        </Surface>
      </View>
    </Modal>
  );
}

function afterPaint(): Promise<void> {
  return new Promise((resolve) => {
    if (typeof requestAnimationFrame !== 'function') {
      setTimeout(resolve, 0);
      return;
    }
    requestAnimationFrame(() => requestAnimationFrame(() => resolve()));
  });
}

async function withTimeout<T>(promise: Promise<T>, timeoutMs: number): Promise<T> {
  let timeout: ReturnType<typeof setTimeout> | undefined;
  try {
    return await Promise.race([
      promise,
      new Promise<never>((_, reject) => {
        timeout = setTimeout(() => reject(new Error('Image export timed out.')), timeoutMs);
      }),
    ]);
  } finally {
    if (timeout !== undefined) clearTimeout(timeout);
  }
}

const styles = StyleSheet.create({
  overlay: { flex: 1, justifyContent: 'flex-end', backgroundColor: '#00000099' },
  sheet: { maxHeight: '92%', borderBottomLeftRadius: 0, borderBottomRightRadius: 0 },
  header: { flexDirection: 'row', alignItems: 'center', padding: 16, gap: 12 },
  grow: { flex: 1 },
  content: { padding: 16, paddingTop: 0, gap: 14 },
  previewFrame: {
    width: '100%',
    aspectRatio: 16 / 9,
    alignSelf: 'center',
    overflow: 'hidden',
    backgroundColor: '#111827',
  },
  canvasScaler: {
    position: 'absolute',
    left: 0,
    top: 0,
    transformOrigin: 'top left',
  },
  graphicBoundary: { backgroundColor: '#111827', overflow: 'hidden' },
  action: {
    minHeight: 50,
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    gap: 8,
    padding: 12,
  },
});
