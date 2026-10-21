import { useEffect, useRef, useState } from 'react';
import { Modal, PixelRatio, Platform, Pressable, StyleSheet, View } from 'react-native';
import { Check, Copy, Download } from 'lucide-react-native';
import * as Clipboard from 'expo-clipboard';
import { captureRef, releaseCapture } from 'react-native-view-shot';
import { File } from 'expo-file-system';
import { ImageAssets } from '../../core/assets/image-assets';
import { useI18n } from '../../i18n';
import { CKText, LoadingIndicator, MobileWebImage, useCKTheme } from '../../ui';
import { reportException } from '../../core/observability/observability';
import { prefetchMobileImage } from '../../ui/mobile-web-image';

export interface EquipmentComparisonExportData {
  heroName: string;
  heroImage: string;
  heroLevel: number;
  mode: string;
  attribute?: string;
  columns: readonly string[];
  rows: readonly {
    id: string;
    equipment: readonly { name: string; image: string; level: number }[];
    values: readonly string[];
  }[];
}

/** Snapshot the complete comparison, never the horizontally scrolled viewport. */
export function EquipmentComparisonCopy({ data }: { data: EquipmentComparisonExportData }) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const boundary = useRef<View>(null);
  const started = useRef(false);
  const modalReady = useRef(false);
  const runId = useRef(0);
  const [nativeHeight, setNativeHeight] = useState(0);
  const [snapshot, setSnapshot] = useState<EquipmentComparisonExportData>();
  const [status, setStatus] = useState<'idle' | 'copying' | 'copied' | 'downloaded' | 'failed'>(
    'idle',
  );
  useEffect(() => {
    if (status !== 'copied' && status !== 'downloaded') return;
    const timer = setTimeout(() => setStatus('idle'), 2400);
    return () => clearTimeout(timer);
  }, [status]);
  useEffect(
    () => () => {
      runId.current += 1;
    },
    [],
  );
  useEffect(() => {
    if (!snapshot) return;
    const timer = setTimeout(() => {
      if (started.current) return;
      reportException(
        new Error('Comparison export view did not finish layout'),
        'equipment_comparison_export.layout',
      );
      runId.current += 1;
      setSnapshot(undefined);
      setStatus('failed');
    }, 10_000);
    return () => clearTimeout(timer);
  }, [snapshot]);
  async function exportImage(height: number) {
    if (!boundary.current || !snapshot || started.current) return;
    started.current = true;
    const currentRun = runId.current;
    let stage = 'artwork';
    let temporaryFile: string | undefined;
    try {
      const images = [
        ...new Set([
          ImageAssets.darkModeTextLogo,
          snapshot.heroImage,
          ...snapshot.rows.flatMap((row) => row.equipment.map((gear) => gear.image)),
        ]),
      ];
      const warmup = withTimeout(
        Promise.allSettled(images.map((image) => prefetchMobileImage(image, 128, 128))),
        15_000,
      );
      if (Platform.OS === 'web') await warmup;
      else
        await warmup.catch((error) =>
          reportException(error, 'equipment_comparison_export.artwork'),
        );
      await new Promise<void>((resolve) =>
        requestAnimationFrame(() => requestAnimationFrame(() => resolve())),
      );
      if (currentRun !== runId.current) return;
      const width = canvasWidth(snapshot);
      stage = 'capture';
      // Native capture dimensions are the scaled boundary itself. iOS treats
      // width/height options as points, then multiplies by device scale; passing
      // the old 1.5x export size could allocate a bitmap nine times larger.
      const captured = await withTimeout(
        captureRef(boundary.current, {
          format: 'png',
          quality: 1,
          result: Platform.OS === 'web' ? 'base64' : 'tmpfile',
          ...(Platform.OS === 'web'
            ? { width: Math.round(width * 1.5), height: Math.round(height * 1.5) }
            : { useRenderInContext: Platform.OS === 'ios' }),
        }),
        Platform.OS === 'web' ? 12_000 : 20_000,
      );
      if (Platform.OS !== 'web') temporaryFile = captured;
      if (currentRun !== runId.current) return;
      if (Platform.OS === 'web') {
        const uri = `data:image/png;base64,${captured}`;
        stage = 'web_clipboard';
        try {
          const blob = await (await fetch(uri)).blob();
          await navigator.clipboard.write([new ClipboardItem({ 'image/png': blob })]);
          setStatus('copied');
        } catch {
          const anchor = document.createElement('a');
          anchor.href = uri;
          anchor.download = `clashking-${snapshot.heroName.replace(/[^\p{L}\p{N}]+/gu, '-').toLowerCase()}-${Date.now()}.png`;
          anchor.click();
          setStatus('downloaded');
        }
      } else {
        try {
          stage = 'native_clipboard';
          const png = await new File(captured).base64();
          if (currentRun !== runId.current) return;
          await Clipboard.setImageAsync(png);
          setStatus('copied');
        } catch (error) {
          if (currentRun !== runId.current) return;
          reportException(error, 'equipment_comparison_export.native_clipboard');
          stage = 'native_share';
          // Present the native share sheet after dismissing our capture modal.
          setSnapshot(undefined);
          await new Promise<void>((resolve) =>
            requestAnimationFrame(() => requestAnimationFrame(() => resolve())),
          );
          if (currentRun !== runId.current) return;
          const { default: Share } = await import('react-native-share');
          await Share.open({
            url: captured,
            type: 'image/png',
            filename: 'clashking-comparison',
            failOnCancel: false,
          });
          setStatus('idle');
        }
      }
    } catch (error) {
      reportException(
        new Error(
          `Comparison export ${stage} failed (${Platform.OS}; rows=${snapshot.rows.length}; columns=${snapshot.columns.length}; canvas=${canvasWidth(snapshot)}x${Math.round(height)})`,
          { cause: error },
        ),
        `equipment_comparison_export.${stage}`,
      );
      if (currentRun === runId.current) setStatus('failed');
    } finally {
      if (temporaryFile) {
        try {
          releaseCapture(temporaryFile);
        } catch (error) {
          reportException(error, 'equipment_comparison_export.cleanup');
        }
      }
      if (currentRun === runId.current) setSnapshot(undefined);
    }
  }
  return (
    <View style={styles.controlRow}>
      {status === 'failed' || status === 'downloaded' ? (
        <CKText muted role="metadata" accessibilityLiveRegion="polite" style={styles.feedback}>
          {t(status === 'failed' ? 'calcComparisonExportFailed' : 'calcComparisonDownloaded')}
        </CKText>
      ) : null}
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={t(
          status === 'copied' ? 'generalCopiedToClipboard' : 'calcCopyComparison',
        )}
        accessibilityState={{ disabled: status === 'copying' }}
        disabled={status === 'copying'}
        testID="equipment-comparison-copy"
        style={({ pressed }) => [
          styles.button,
          { opacity: pressed || status === 'copying' ? 0.5 : 1 },
        ]}
        onPress={() => {
          runId.current += 1;
          started.current = false;
          modalReady.current = false;
          setNativeHeight(0);
          setStatus('copying');
          setSnapshot(data);
        }}
      >
        {status === 'copied' ? (
          <Check size={19} color={theme.secondary} />
        ) : status === 'downloaded' ? (
          <Download size={19} color={theme.secondary} />
        ) : (
          <Copy size={19} color={theme.onSurfaceVariant} />
        )}
      </Pressable>
      {snapshot && Platform.OS === 'web' ? (
        <View
          pointerEvents="none"
          accessibilityElementsHidden
          importantForAccessibility="no-hide-descendants"
          style={styles.host}
        >
          <View
            ref={boundary}
            collapsable={false}
            testID="equipment-comparison-export"
            style={[styles.canvas, { width: canvasWidth(snapshot) }]}
            onLayout={(event) => {
              void exportImage(event.nativeEvent.layout.height);
            }}
          >
            <ComparisonComposition data={snapshot} />
          </View>
        </View>
      ) : null}
      {snapshot && Platform.OS !== 'web' ? (
        <Modal
          transparent
          animationType="none"
          visible
          onShow={() => {
            modalReady.current = true;
            if (nativeHeight > 0) void exportImage(nativeHeight);
          }}
          onRequestClose={() => {
            runId.current += 1;
            setSnapshot(undefined);
            setStatus('idle');
          }}
        >
          <View style={styles.nativeStage}>
            <View
              ref={boundary}
              collapsable={false}
              pointerEvents="none"
              accessibilityElementsHidden
              importantForAccessibility="no-hide-descendants"
              style={[styles.nativeBoundary, nativeCanvasSize(canvasWidth(snapshot), nativeHeight)]}
              onLayout={() => {
                if (modalReady.current && nativeHeight > 0) void exportImage(nativeHeight);
              }}
            >
              <View
                style={[
                  styles.canvas,
                  {
                    width: canvasWidth(snapshot),
                    transform: [{ scale: nativeCanvasScale(canvasWidth(snapshot), nativeHeight) }],
                    transformOrigin: 'top left',
                  },
                ]}
                onLayout={(event) => setNativeHeight(event.nativeEvent.layout.height)}
              >
                <ComparisonComposition data={snapshot} />
              </View>
            </View>
            <View
              style={[
                StyleSheet.absoluteFill,
                styles.nativeCover,
                { backgroundColor: theme.background },
              ]}
            >
              <LoadingIndicator />
              <CKText accessibilityLiveRegion="polite">{t('generalLoading')}</CKText>
            </View>
          </View>
        </Modal>
      ) : null}
    </View>
  );
}

function canvasWidth(data: EquipmentComparisonExportData) {
  return Math.max(1040, 344 + data.columns.length * 152 + 64);
}

function nativeCanvasScale(width: number, height: number): number {
  const safeHeight = Math.max(1, height);
  // Bound the actual bitmap to six megapixels and 8192 pixels per edge while
  // keeping the full grid. The native capture root lives outside both scrolls.
  const pixelScale = Math.min(
    1.5,
    8192 / Math.max(width, safeHeight),
    Math.sqrt(6_000_000 / (width * safeHeight)),
  );
  return pixelScale / PixelRatio.get();
}

function nativeCanvasSize(width: number, height: number) {
  const scale = nativeCanvasScale(width, height);
  return { width: width * scale, height: Math.max(1, height * scale) };
}

function ComparisonComposition({ data }: { data: EquipmentComparisonExportData }) {
  const { t } = useI18n();
  return (
    <>
      <View style={styles.brandRow}>
        <MobileWebImage
          imageUrl={ImageAssets.darkModeTextLogo}
          contentFit="contain"
          style={styles.brand}
        />
        <CKText style={styles.eyebrow}>{t('calcEquipmentTitle')}</CKText>
      </View>
      <View style={styles.heroRow}>
        <MobileWebImage imageUrl={data.heroImage} contentFit="contain" style={styles.hero} />
        <View style={styles.heroCopy}>
          <CKText style={styles.heroName}>{data.heroName}</CKText>
          <CKText style={styles.subtitle}>
            {t('sideLevel', { level: data.heroLevel })} · {data.mode}
            {data.attribute ? ` · ${data.attribute}` : ''}
          </CKText>
        </View>
        <View style={styles.redAccent} />
      </View>
      <View style={styles.grid}>
        <View style={[styles.row, styles.columnHead]}>
          <View style={styles.identity}>
            <CKText style={styles.columnLabel}>{t('calcCompareLoadouts')}</CKText>
          </View>
          {data.columns.map((column, index) => (
            <View key={index} style={styles.value}>
              <CKText style={styles.columnLabel}>{column}</CKText>
            </View>
          ))}
        </View>
        {data.rows.map((row, index) => (
          <View
            key={row.id}
            style={[styles.row, { backgroundColor: index % 2 ? '#1B2232' : '#171E2D' }]}
          >
            <View style={styles.identity}>
              <View style={styles.gears}>
                {row.equipment.length ? (
                  row.equipment.map((gear) => (
                    <View key={gear.name} style={styles.gear}>
                      <MobileWebImage
                        imageUrl={gear.image}
                        contentFit="contain"
                        style={styles.gearImage}
                      />
                      <View style={styles.gearCopy}>
                        <CKText style={styles.gearName}>{gear.name}</CKText>
                        <CKText style={styles.level}>
                          {t('sideLevel', { level: gear.level })}
                        </CKText>
                      </View>
                    </View>
                  ))
                ) : (
                  <CKText style={styles.gearName}>{t('calcNoEquipment')}</CKText>
                )}
              </View>
            </View>
            {row.values.map((value, column) => (
              <View key={column} style={styles.value}>
                <CKText style={styles.cellText}>{value}</CKText>
              </View>
            ))}
          </View>
        ))}
      </View>
    </>
  );
}

async function withTimeout<T>(promise: Promise<T>, milliseconds: number): Promise<T> {
  let timer: ReturnType<typeof setTimeout> | undefined;
  try {
    return await Promise.race([
      promise,
      new Promise<never>((_, reject) => {
        timer = setTimeout(() => reject(new Error('Image capture timed out')), milliseconds);
      }),
    ]);
  } finally {
    if (timer) clearTimeout(timer);
  }
}

const styles = StyleSheet.create({
  controlRow: {
    minHeight: 40,
    flexDirection: 'row',
    justifyContent: 'flex-end',
    alignItems: 'center',
    position: 'relative',
  },
  feedback: { flex: 1, textAlign: 'right' },
  button: { width: 44, height: 40, justifyContent: 'center', alignItems: 'center' },
  host: { position: 'absolute', left: -10000, top: 0 },
  nativeStage: { flex: 1 },
  nativeBoundary: { position: 'absolute', left: 0, top: 0, overflow: 'hidden' },
  nativeCover: { alignItems: 'center', justifyContent: 'center', gap: 16 },
  canvas: { backgroundColor: '#101521', padding: 32, gap: 24 },
  brandRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 20,
  },
  // Match the source PNG's 3806×558 bounds, including snapshot renderers that
  // rasterize the image box rather than preserving contentFit letterboxing.
  brand: { width: 260, height: (260 * 558) / 3806 },
  eyebrow: { color: '#CBD4E5', fontSize: 19 },
  heroRow: { flexDirection: 'row', alignItems: 'center', gap: 24, paddingBottom: 4 },
  hero: { width: 124, height: 124 },
  heroCopy: { flex: 1, gap: 10 },
  heroName: { color: '#FFFFFF', fontSize: 36, lineHeight: 44, fontWeight: '700' },
  subtitle: { color: '#ACBBD4', fontSize: 18, lineHeight: 26 },
  redAccent: { width: 6, height: 84, borderRadius: 3, backgroundColor: '#D90709' },
  grid: { gap: 6 },
  row: {
    flexDirection: 'row',
    alignItems: 'stretch',
    borderRadius: 14,
    overflow: 'hidden',
    minHeight: 98,
  },
  columnHead: { backgroundColor: '#263047', minHeight: 100 },
  identity: { width: 344, padding: 16, justifyContent: 'center', gap: 8 },
  columnLabel: { color: '#CDD8EA', fontSize: 15, lineHeight: 21 },
  value: { flex: 1, minWidth: 152, padding: 16, justifyContent: 'center', alignItems: 'center' },
  cellText: { color: '#F4F7FE', fontSize: 18, lineHeight: 24, textAlign: 'center' },
  gears: { flexDirection: 'row', gap: 16, flexWrap: 'wrap' },
  gear: { flexDirection: 'row', alignItems: 'center', width: 146, gap: 8 },
  gearCopy: { flex: 1, gap: 4 },
  gearImage: { width: 40, height: 40 },
  gearName: { color: '#E2EAF8', fontSize: 13, lineHeight: 18 },
  level: { color: '#8FA0BC', fontSize: 12, lineHeight: 17 },
});
