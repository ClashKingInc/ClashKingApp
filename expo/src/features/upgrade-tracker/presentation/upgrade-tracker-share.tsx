import { forwardRef, useRef, useState } from 'react';
import {
  Image,
  Modal,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  View,
  type View as ViewType,
} from 'react-native';
import { captureRef } from 'react-native-view-shot';
import { Images, Share2, X } from 'lucide-react-native';

import { ImageAssets } from '../../../core/assets/image-assets';
import { toIntlLocale, useI18n } from '../../../i18n';
import { CKText, PressableSurface, Surface, ckRadius, useCKTheme } from '../../../ui';
import {
  UpgradeCategory,
  UpgradeCollectionType,
  UpgradePlanStrategy,
  UpgradeQueue,
  UpgradeVillage,
  type UpgradeTrackerSnapshot,
  type UpgradeVillageValue,
} from '../models';

export type TrackerShareKind = 'home' | 'builder' | 'collection';
export type TrackerSharePreview = TrackerShareKind;

const ALL_PREVIEWS: readonly TrackerSharePreview[] = ['home', 'builder', 'collection'];

export function trackerShareFilename(
  snapshot: Pick<UpgradeTrackerSnapshot, 'tag'>,
  preview: TrackerSharePreview,
  single: boolean,
) {
  const tag = snapshot.tag.replaceAll('#', '').toLowerCase();
  if (single && preview === 'collection') return `clashking-collection-${tag}.png`;
  if (single) return `clashking-progress-${tag}.png`;
  const suffix =
    preview === 'home'
      ? 'home-progress'
      : preview === 'builder'
        ? 'builder-progress'
        : 'collection';
  return `clashking-${suffix}-${tag}.png`;
}

export async function shareTrackerCaptures(options: {
  snapshot: Pick<UpgradeTrackerSnapshot, 'name' | 'tag'>;
  selected: TrackerSharePreview;
  all: boolean;
  capture: (preview: TrackerSharePreview, filename: string) => Promise<string>;
  nativeShare: (urls: readonly string[], message: string) => Promise<void>;
  webDownload: (url: string, filename: string) => void;
}) {
  const previews = options.all ? ALL_PREVIEWS : [options.selected];
  const captures: { url: string; filename: string }[] = [];
  for (const preview of previews) {
    const filename = trackerShareFilename(options.snapshot, preview, !options.all);
    captures.push({ url: await options.capture(preview, filename), filename });
  }
  const message = options.all
    ? `${options.snapshot.name} progress and collection on ClashKing`
    : options.selected === 'collection'
      ? `${options.snapshot.name} collection on ClashKing`
      : `${options.snapshot.name} on ClashKing`;
  if (Platform.OS === 'web') {
    for (const capture of captures) options.webDownload(capture.url, capture.filename);
  } else {
    await options.nativeShare(
      captures.map((capture) => capture.url),
      message,
    );
  }
  return { captures, message };
}

export function UpgradeTrackerShareModal({
  visible,
  initial,
  snapshot,
  onClose,
}: {
  visible: boolean;
  initial: TrackerShareKind;
  snapshot: UpgradeTrackerSnapshot;
  onClose: () => void;
}) {
  const [preview, setPreview] = useState<TrackerSharePreview>(initial);
  const [sharing, setSharing] = useState(false);
  const boundary = useRef<ViewType>(null);
  const theme = useCKTheme();
  const title = preview === 'collection' ? 'Share collection' : 'Share progress';

  async function share(all: boolean) {
    if (!boundary.current || sharing) return;
    const original = preview;
    setSharing(true);
    try {
      await Promise.allSettled(trackerArtworkUrls(snapshot).map((url) => Image.prefetch(url)));
      await shareTrackerCaptures({
        snapshot,
        selected: preview,
        all,
        capture: async (next, filename) => {
          setPreview(next);
          await afterPaint();
          return captureRef(boundary, {
            format: 'png',
            quality: 1,
            result: Platform.OS === 'web' ? 'data-uri' : 'tmpfile',
            fileName: filename.replace(/\.png$/, ''),
          });
        },
        nativeShare: async (urls, message) => {
          const { default: Share } = await import('react-native-share');
          await Share.open({ urls: [...urls], message, type: 'image/png', failOnCancel: false });
        },
        webDownload: (url, filename) => {
          if (typeof document === 'undefined') return;
          const anchor = document.createElement('a');
          anchor.href = url;
          anchor.download = filename;
          anchor.click();
        },
      });
    } finally {
      setPreview(original);
      setSharing(false);
    }
  }

  return (
    <Modal visible={visible} transparent animationType="slide" onRequestClose={onClose}>
      <View style={shareStyles.overlay}>
        <Surface radius={ckRadius.card} style={shareStyles.sheet}>
          <View style={shareStyles.header}>
            <CKText role="titleLarge" style={shareStyles.grow}>
              {title}
            </CKText>
            <Pressable accessibilityRole="button" accessibilityLabel="Close" onPress={onClose}>
              <X color={theme.onSurface} />
            </Pressable>
          </View>
          <ScrollView contentContainerStyle={shareStyles.content}>
            <View ref={boundary} collapsable={false} style={shareStyles.graphicBoundary}>
              {preview === 'collection' ? (
                <CollectionGraphic snapshot={snapshot} />
              ) : (
                <ProgressGraphic
                  snapshot={snapshot}
                  village={preview === 'home' ? UpgradeVillage.home : UpgradeVillage.builderBase}
                />
              )}
            </View>
            <PressableSurface
              accessibilityRole="button"
              disabled={sharing}
              onPress={() => void share(false)}
              style={shareStyles.action}
            >
              <Share2 color={theme.onSurface} />
              <CKText>{sharing ? 'Preparing images…' : title}</CKText>
            </PressableSurface>
            <PressableSurface
              accessibilityRole="button"
              disabled={sharing}
              onPress={() => void share(true)}
              style={shareStyles.action}
            >
              <Images color={theme.onSurface} />
              <CKText>Share all 3</CKText>
            </PressableSurface>
          </ScrollView>
        </Surface>
      </View>
    </Modal>
  );
}

const ProgressGraphic = forwardRef<
  ViewType,
  {
    snapshot: UpgradeTrackerSnapshot;
    village: UpgradeVillageValue;
  }
>(function ProgressGraphic({ snapshot, village }, _ref) {
  const { locale } = useI18n();
  const intlLocale = toIntlLocale(locale);
  const [startsAt] = useState(() => new Date());
  const overall = snapshot.overallSummary(village);
  const lanes = [
    ...snapshot.buildPlan({
      queue: UpgradeQueue.builders,
      strategy: UpgradePlanStrategy.balanced,
      village,
      startsAt,
    }),
    ...snapshot.buildPlan({
      queue: UpgradeQueue.laboratory,
      strategy: UpgradePlanStrategy.balanced,
      village,
      startsAt,
    }),
    ...(village === UpgradeVillage.home
      ? snapshot.buildPlan({
          queue: UpgradeQueue.pets,
          strategy: UpgradePlanStrategy.balanced,
          village,
          startsAt,
        })
      : []),
  ];
  const finish = lanes.reduce<Date | null>(
    (latest, lane) =>
      lane.finishesAt && (!latest || lane.finishesAt > latest) ? lane.finishesAt : latest,
    null,
  );
  const days = finish
    ? Math.max(0, Math.ceil((finish.getTime() - startsAt.getTime()) / 86_400_000))
    : 0;
  const preferred =
    village === UpgradeVillage.home
      ? [
          UpgradeCategory.defenses,
          UpgradeCategory.army,
          UpgradeCategory.troops,
          UpgradeCategory.heroes,
          UpgradeCategory.equipment,
          UpgradeCategory.pets,
          UpgradeCategory.walls,
        ]
      : [
          UpgradeCategory.defenses,
          UpgradeCategory.traps,
          UpgradeCategory.army,
          UpgradeCategory.resources,
          UpgradeCategory.troops,
          UpgradeCategory.heroes,
          UpgradeCategory.walls,
        ];
  const resources = Object.entries(overall.costs).sort(
    ([left], [right]) => resourceWeight(left) - resourceWeight(right),
  );
  const ores = resources.filter(([resource]) => resource.toLowerCase().includes('ore'));
  const primaryResources = resources
    .filter(([resource]) => !resource.toLowerCase().includes('ore'))
    .slice(0, 2);
  const categories = preferred
    .map((category) => [category, snapshot.summaryFor(category, village)] as const)
    .filter(([, summary]) => summary.target > 0)
    .slice(0, ores.length ? 4 : 5);
  const hall = village === UpgradeVillage.home ? snapshot.townHallLevel : snapshot.builderHallLevel;
  return (
    <View style={shareStyles.graphic}>
      <Image
        source={{
          uri:
            village === UpgradeVillage.home
              ? ImageAssets.homeBaseBackground
              : ImageAssets.builderBaseBackground,
        }}
        style={StyleSheet.absoluteFill}
      />
      <View style={[StyleSheet.absoluteFill, shareStyles.graphicShade]} />
      <View style={shareStyles.graphicContent}>
        <View style={shareStyles.header}>
          <Image
            source={{
              uri:
                village === UpgradeVillage.home
                  ? ImageAssets.townHall(hall)
                  : ImageAssets.builderHall(hall),
            }}
            style={shareStyles.hall}
          />
          <View style={shareStyles.grow}>
            <CKText style={shareStyles.whiteTitle} numberOfLines={1}>
              {snapshot.name}
            </CKText>
            <CKText style={shareStyles.silver}>{snapshot.tag}</CKText>
          </View>
        </View>
        <CKText style={shareStyles.percent}>{(overall.completion * 100).toFixed(1)}%</CKText>
        <CKText style={shareStyles.silverStrong}>Village complete</CKText>
        <View style={shareStyles.resourceRow}>
          <CKText style={shareStyles.days}>{days} days left</CKText>
          {primaryResources.map(([resource, amount]) => (
            <View key={resource} style={shareStyles.resourcePair}>
              <Image source={{ uri: resourceImage(resource) }} style={shareStyles.resourceIcon} />
              <CKText style={shareStyles.silver}>{compact(amount, intlLocale)}</CKText>
            </View>
          ))}
        </View>
        {ores.length ? (
          <View style={shareStyles.resourceRow}>
            <CKText style={shareStyles.days}>Ore needed</CKText>
            {ores.slice(0, 3).map(([resource, amount]) => (
              <View key={resource} style={shareStyles.resourcePair}>
                <Image source={{ uri: resourceImage(resource) }} style={shareStyles.resourceIcon} />
                <CKText style={shareStyles.silver}>{compact(amount, intlLocale)}</CKText>
              </View>
            ))}
          </View>
        ) : null}
        <View style={shareStyles.categoryList}>
          {categories.map(([category, summary]) => (
            <View key={category} style={shareStyles.categoryRow}>
              <Image
                source={{
                  uri:
                    snapshot.itemsFor({ village, category })[0]?.imageUrl ??
                    ImageAssets.defaultImage,
                }}
                style={shareStyles.categoryIcon}
              />
              <CKText style={shareStyles.categoryLabel}>{categoryLabel(category)}</CKText>
              <View style={shareStyles.bar}>
                <View style={[shareStyles.barFill, { width: `${summary.completion * 100}%` }]} />
              </View>
              <CKText style={shareStyles.categoryPercent}>
                {Math.round(summary.completion * 100)}%
              </CKText>
            </View>
          ))}
        </View>
        <View style={[shareStyles.header, shareStyles.graphicFooter]}>
          <Image source={{ uri: ImageAssets.darkModeLogo }} style={shareStyles.brandIcon} />
          <CKText style={shareStyles.brand}>ClashKing</CKText>
          <CKText style={shareStyles.silver}>{overall.levelsRemaining} levels left</CKText>
        </View>
      </View>
    </View>
  );
});

function CollectionGraphic({ snapshot }: { snapshot: UpgradeTrackerSnapshot }) {
  const types = Object.values(UpgradeCollectionType).filter((type) =>
    snapshot.collections.some((item) => item.type === type),
  );
  return (
    <View style={[shareStyles.graphic, shareStyles.collectionGraphic]}>
      <View style={shareStyles.graphicContent}>
        <View style={shareStyles.header}>
          <Image
            source={{ uri: ImageAssets.townHall(snapshot.townHallLevel) }}
            style={shareStyles.hall}
          />
          <View style={shareStyles.grow}>
            <CKText style={shareStyles.whiteTitle}>{snapshot.name}</CKText>
            <CKText style={shareStyles.silverStrong}>Collection</CKText>
          </View>
        </View>
        <View style={shareStyles.collectionGrid}>
          {types.map((type) => {
            const items = snapshot.collections.filter((item) => item.type === type);
            const image = items.find((item) => item.owned) ?? items[0]!;
            const value =
              type === UpgradeCollectionType.obstacles
                ? items.reduce((sum, item) => sum + item.count, 0)
                : items.filter((item) => item.owned).length;
            return (
              <View key={type} style={shareStyles.collectionCell}>
                <Image source={{ uri: image.imageUrl }} style={shareStyles.collectionImage} />
                <CKText style={shareStyles.collectionValue}>
                  {type === UpgradeCollectionType.obstacles
                    ? `${value} owned`
                    : `${value}/${items.length}`}
                </CKText>
                <CKText style={shareStyles.silver}>{collectionLabel(type)}</CKText>
              </View>
            );
          })}
        </View>
        <View style={[shareStyles.header, shareStyles.graphicFooter]}>
          <Image source={{ uri: ImageAssets.darkModeLogo }} style={shareStyles.brandIcon} />
          <CKText style={shareStyles.brand}>ClashKing</CKText>
        </View>
      </View>
    </View>
  );
}

function afterPaint() {
  return new Promise<void>((resolve) =>
    requestAnimationFrame(() => requestAnimationFrame(() => resolve())),
  );
}

function categoryLabel(value: string) {
  const labels: Record<string, string> = {
    defenses: 'Defenses',
    traps: 'Traps',
    army: 'Army',
    resources: 'Resources',
    troops: 'Troops',
    heroes: 'Heroes',
    equipment: 'Equipment',
    pets: 'Pets',
    walls: 'Walls',
  };
  return labels[value] ?? value;
}

function collectionLabel(value: string) {
  const labels: Record<string, string> = {
    skins: 'Skins',
    sceneries: 'Sceneries',
    decorations: 'Decorations',
    obstacles: 'Obstacles',
    capitalHouseParts: 'House parts',
  };
  return labels[value] ?? value;
}

export function trackerArtworkUrls(snapshot: UpgradeTrackerSnapshot) {
  return [
    ImageAssets.townHall(snapshot.townHallLevel),
    ImageAssets.builderHall(snapshot.builderHallLevel),
    ImageAssets.homeBaseBackground,
    ImageAssets.builderBaseBackground,
    ImageAssets.darkModeLogo,
    ...snapshot.items.filter((item) => !item.isComplete).map((item) => item.imageUrl),
    ...snapshot.collections.map((item) => item.imageUrl),
    ...snapshot.items.flatMap((item) => Object.keys(item.totalCosts).map(resourceImage)),
  ].filter((url, index, values) => url.startsWith('http') && values.indexOf(url) === index);
}

function resourceImage(resource: string) {
  const normalized = resource
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '');
  return `${ImageAssets.baseUrl}/resources/${normalized}.webp`;
}

function resourceWeight(resource: string) {
  const normalized = resource.toLowerCase();
  if (normalized.includes('gold') && !normalized.includes('builder')) return 0;
  if (normalized.includes('elixir') && !normalized.includes('dark')) return 1;
  if (normalized.includes('dark')) return 2;
  if (normalized.includes('shiny')) return 5;
  if (normalized.includes('glowy')) return 6;
  if (normalized.includes('starry')) return 7;
  return 99;
}

function compact(value: number, intlLocale: string) {
  if (value >= 1_000_000_000) return `${(value / 1_000_000_000).toFixed(1)}B`;
  if (value >= 1_000_000) return `${(value / 1_000_000).toFixed(1)}M`;
  if (value >= 1_000) return `${(value / 1_000).toFixed(1)}K`;
  return new Intl.NumberFormat(intlLocale).format(Math.round(value));
}

const shareStyles = StyleSheet.create({
  overlay: { flex: 1, justifyContent: 'flex-end', backgroundColor: '#00000070' },
  sheet: { maxHeight: '92%', width: '100%', maxWidth: 620, alignSelf: 'center', padding: 14 },
  content: { gap: 10, paddingBottom: 24 },
  header: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  grow: { flex: 1 },
  graphicBoundary: { width: '100%', aspectRatio: 1 },
  graphic: { flex: 1, borderRadius: 22, overflow: 'hidden', backgroundColor: '#0d0d0f' },
  graphicShade: { backgroundColor: '#050506dc' },
  graphicContent: { flex: 1, padding: 20 },
  hall: { width: 58, height: 58, resizeMode: 'contain' },
  whiteTitle: { color: '#fff', fontSize: 20, fontWeight: '900' },
  silver: { color: '#bfc2c8', fontSize: 11, fontWeight: '700' },
  silverStrong: { color: '#d4d7dd', fontSize: 11, fontWeight: '900' },
  percent: { color: '#fff', fontSize: 42, lineHeight: 46, fontWeight: '900', marginTop: 8 },
  days: { color: '#fff', fontSize: 10, fontWeight: '900', marginTop: 8 },
  resourceRow: { minHeight: 20, flexDirection: 'row', alignItems: 'center', gap: 8 },
  resourcePair: { flexDirection: 'row', alignItems: 'center', gap: 3 },
  resourceIcon: { width: 16, height: 16, resizeMode: 'contain' },
  categoryList: { gap: 7, marginTop: 10 },
  categoryRow: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  categoryIcon: { width: 20, height: 20, resizeMode: 'contain' },
  categoryLabel: { color: '#fff', width: 76, fontSize: 11, fontWeight: '800' },
  categoryPercent: {
    color: '#fff',
    width: 38,
    textAlign: 'right',
    fontSize: 10,
    fontWeight: '900',
  },
  bar: { flex: 1, height: 6, borderRadius: 99, backgroundColor: '#303238', overflow: 'hidden' },
  barFill: { height: '100%', borderRadius: 99, backgroundColor: '#f1b84b' },
  graphicFooter: { marginTop: 'auto' },
  brand: { color: '#fff', fontSize: 13, fontWeight: '900' },
  brandIcon: { width: 24, height: 24, resizeMode: 'contain' },
  collectionGraphic: { backgroundColor: '#0d0d0f' },
  collectionGrid: { flex: 1, flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginTop: 18 },
  collectionCell: {
    width: '31%',
    minHeight: 86,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: '#313137',
    backgroundColor: '#1a1a1e',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 6,
  },
  collectionImage: { width: 30, height: 30, resizeMode: 'contain' },
  collectionValue: { color: '#fff', fontSize: 15, fontWeight: '900' },
  action: {
    minHeight: 48,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    padding: 12,
  },
});
