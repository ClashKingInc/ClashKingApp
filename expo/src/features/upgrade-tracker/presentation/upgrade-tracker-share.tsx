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
import { toIntlLocale, useI18n, type I18nValue } from '../../../i18n';
import { CKText, PressableSurface, Surface, ckRadius, useCKTheme } from '../../../ui';
import {
  UpgradeCategory,
  UpgradeCollectionType,
  UpgradePlanStrategy,
  UpgradeQueue,
  UpgradeVillage,
  type UpgradeCategorySummary,
  type UpgradeTrackerItem,
  type UpgradeTrackerSnapshot,
  type UpgradeVillageValue,
} from '../models';
import { formatTrackerDuration } from './upgrade-tracker-logic';

export type TrackerShareKind = 'home' | 'builder' | 'collection';
export type TrackerSharePreview = TrackerShareKind;

const ALL_PREVIEWS: readonly TrackerSharePreview[] = ['home', 'builder', 'collection'];
const CAPTURE_TIMEOUT_MS = 12_000;
const ARTWORK_TIMEOUT_MS = 2_500;

export type TrackerProgressSectionKey =
  | 'walls'
  | 'buildings'
  | 'supercharges'
  | 'heroes'
  | 'laboratory'
  | 'pets'
  | 'equipment'
  | 'craftedDefenses';

export interface TrackerProgressSection {
  readonly key: TrackerProgressSectionKey;
  readonly imageUrl: string;
  readonly summary: UpgradeCategorySummary;
}

export function trackerProgressGraphicAspectRatio(sectionCount: number) {
  const visibleSections = Math.max(1, Math.min(8, Math.round(sectionCount)));
  return Math.min(1, 0.64 + (7 - visibleSections) * 0.07);
}

export function trackerProgressSections(
  snapshot: UpgradeTrackerSnapshot,
  village: UpgradeVillageValue,
): readonly TrackerProgressSection[] {
  const items = snapshot.itemsFor({ village });
  const definitions: readonly [
    TrackerProgressSectionKey,
    readonly UpgradeTrackerItem[],
    keyof typeof UpgradeCategory,
  ][] = [
    ['walls', items.filter((item) => item.category === UpgradeCategory.walls), 'walls'],
    [
      'buildings',
      items.filter(
        (item) =>
          item.queue === UpgradeQueue.builders &&
          item.category !== UpgradeCategory.walls &&
          item.category !== UpgradeCategory.heroes &&
          item.category !== UpgradeCategory.builders &&
          item.category !== UpgradeCategory.craftedDefenses &&
          item.category !== UpgradeCategory.supercharge,
      ),
      'defenses',
    ],
    [
      'supercharges',
      items.filter((item) => item.category === UpgradeCategory.supercharge),
      'supercharge',
    ],
    ['heroes', items.filter((item) => item.category === UpgradeCategory.heroes), 'heroes'],
    ['laboratory', items.filter((item) => item.queue === UpgradeQueue.laboratory), 'troops'],
    ['pets', items.filter((item) => item.category === UpgradeCategory.pets), 'pets'],
    ['equipment', items.filter((item) => item.category === UpgradeCategory.equipment), 'equipment'],
    [
      'craftedDefenses',
      items.filter((item) => item.category === UpgradeCategory.craftedDefenses),
      'craftedDefenses',
    ],
  ];
  return definitions
    .filter(([, matching]) => matching.length > 0)
    .map(([key, matching, category]) => ({
      key,
      imageUrl: progressSectionImage(snapshot, village, key, matching),
      summary: snapshot.summaryForItems(matching, UpgradeCategory[category]),
    }));
}

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

export function trackerNativeShareOptions(urls: readonly string[]) {
  return { urls: [...urls], type: 'image/png' as const, failOnCancel: false };
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
  const [shareError, setShareError] = useState(false);
  const boundary = useRef<ViewType>(null);
  const theme = useCKTheme();
  const { t } = useI18n();
  const title = t('upgradeTrackerShare');
  const progressVillage = preview === 'builder' ? UpgradeVillage.builderBase : UpgradeVillage.home;
  const progressSectionCount =
    preview === 'collection' ? 0 : trackerProgressSections(snapshot, progressVillage).length;

  async function share(all: boolean) {
    if (!boundary.current || sharing) return;
    const original = preview;
    setSharing(true);
    setShareError(false);
    try {
      await shareTrackerCaptures({
        snapshot,
        selected: preview,
        all,
        capture: async (next, filename) => {
          setPreview(next);
          await afterPaint();
          await withTimeout(
            Promise.allSettled(
              trackerArtworkUrls(snapshot, next).map((url) => Image.prefetch(url)),
            ).then(() => undefined),
            ARTWORK_TIMEOUT_MS,
          ).catch(() => undefined);
          await afterPaint();
          if (!boundary.current) throw new Error('Share preview is unavailable.');
          return withTimeout(
            captureRef(boundary.current, {
              format: 'png',
              quality: 1,
              result: Platform.OS === 'web' ? 'data-uri' : 'tmpfile',
              fileName: filename.replace(/\.png$/, ''),
            }),
            CAPTURE_TIMEOUT_MS,
          );
        },
        nativeShare: async (urls) => {
          const { default: Share } = await import('react-native-share');
          await Share.open(trackerNativeShareOptions(urls));
        },
        webDownload: (url, filename) => {
          if (typeof document === 'undefined') return;
          const anchor = document.createElement('a');
          anchor.href = url;
          anchor.download = filename;
          anchor.click();
        },
      });
    } catch {
      setShareError(true);
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
            <View
              ref={boundary}
              collapsable={false}
              style={[
                shareStyles.graphicBoundary,
                preview === 'collection'
                  ? shareStyles.collectionGraphicBoundary
                  : {
                      aspectRatio: trackerProgressGraphicAspectRatio(progressSectionCount),
                    },
              ]}
            >
              {preview === 'collection' ? (
                <CollectionGraphic snapshot={snapshot} />
              ) : (
                <ProgressGraphic
                  snapshot={snapshot}
                  village={preview === 'home' ? UpgradeVillage.home : UpgradeVillage.builderBase}
                />
              )}
            </View>
            {shareError ? (
              <CKText muted role="bodySmall" style={shareStyles.error}>
                {t('apiErrorOperationFailed', { operation: t('upgradeTrackerShare') })}
              </CKText>
            ) : null}
            <PressableSurface
              accessibilityRole="button"
              disabled={sharing}
              onPress={() => void share(false)}
              style={shareStyles.action}
            >
              <Share2 color={theme.onSurface} />
              <CKText>{sharing ? t('generalLoading') : title}</CKText>
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
  const { locale, t } = useI18n();
  const intlLocale = toIntlLocale(locale);
  const [startsAt] = useState(() => new Date());
  const overall = snapshot.overallSummary(village);
  const sections = trackerProgressSections(snapshot, village);
  const builderTime = queueDurationSeconds(snapshot, village, UpgradeQueue.builders, startsAt);
  const laboratoryTime = queueDurationSeconds(snapshot, village, UpgradeQueue.laboratory, startsAt);
  const builderCount = snapshot.buildersFor(village);
  const remainingBuilderItems = snapshot.itemsFor({
    village,
    queue: UpgradeQueue.builders,
    remainingOnly: true,
  });
  const temporaryBuilderItems = remainingBuilderItems.filter(
    (item) =>
      item.category === UpgradeCategory.supercharge ||
      item.category === UpgradeCategory.craftedDefenses,
  );
  const builderTemporaryContent = [
    ...new Set(temporaryBuilderItems.map((item) => item.category)),
  ].map((category) =>
    progressSectionLabel(
      category === UpgradeCategory.supercharge ? 'supercharges' : 'craftedDefenses',
      t,
    ),
  );
  const baseBuilderTime = queueDurationSeconds(
    snapshot,
    village,
    UpgradeQueue.builders,
    startsAt,
    new Set(
      remainingBuilderItems
        .filter((item) => !temporaryBuilderItems.includes(item))
        .map((item) => item.planKey),
    ),
  );
  const builderTemporaryTime = Math.max(0, builderTime - baseBuilderTime);
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
          <View style={shareStyles.overallProgress}>
            <CKText style={shareStyles.percent}>{(overall.completion * 100).toFixed(1)}%</CKText>
            <CKText style={shareStyles.silverStrong}>{t('generalCompleted')}</CKText>
          </View>
        </View>
        <View style={shareStyles.completionDates}>
          <CompletionDate
            imageUrl={ImageAssets.getHomeVillageBuildingImage("Builder's Hut", 1)}
            label={t('upgradeTrackerBuildersCount', { count: builderCount })}
            includedContent={builderTemporaryContent}
            includedSeconds={builderTemporaryTime}
            seconds={builderTime}
            date={completionDate(startsAt, builderTime)}
            locale={intlLocale}
          />
        </View>
        <View style={shareStyles.categoryList}>
          {sections.map((section) => (
            <View key={section.key} style={shareStyles.categoryRow}>
              <Image source={{ uri: section.imageUrl }} style={shareStyles.categoryIcon} />
              <View style={shareStyles.categoryBody}>
                <View style={shareStyles.categoryHeading}>
                  <CKText style={shareStyles.categoryLabel}>
                    {progressSectionLabel(section.key, t)}
                  </CKText>
                  {section.summary.seconds > 0 ? (
                    <CKText style={shareStyles.categoryTime}>
                      {formatTrackerDuration(
                        section.key === 'laboratory' ? laboratoryTime : section.summary.seconds,
                      )}
                    </CKText>
                  ) : null}
                  <CKText style={shareStyles.categoryPercent}>
                    {Math.round(section.summary.completion * 100)}%
                  </CKText>
                </View>
                <View style={shareStyles.categoryDetail}>
                  <View style={shareStyles.bar}>
                    <View
                      style={[
                        shareStyles.barFill,
                        { width: `${section.summary.completion * 100}%` },
                      ]}
                    />
                  </View>
                  <View style={shareStyles.resourceRow}>
                    {Object.entries(section.summary.costs)
                      .sort(([left], [right]) => resourceWeight(left) - resourceWeight(right))
                      .map(([resource, amount]) => (
                        <View key={resource} style={shareStyles.resourcePair}>
                          <Image
                            source={{ uri: resourceImage(resource) }}
                            style={shareStyles.resourceIcon}
                          />
                          <CKText style={shareStyles.silver}>{compact(amount, intlLocale)}</CKText>
                        </View>
                      ))}
                  </View>
                </View>
              </View>
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

function CompletionDate({
  imageUrl,
  label,
  includedContent = [],
  includedSeconds = 0,
  seconds,
  date,
  locale,
}: {
  imageUrl: string;
  label: string;
  includedContent?: readonly string[];
  includedSeconds?: number;
  seconds: number;
  date: Date | null;
  locale: string;
}) {
  return (
    <View style={shareStyles.completionDate}>
      <Image source={{ uri: imageUrl }} style={shareStyles.completionDateIcon} />
      <View style={shareStyles.grow}>
        <CKText style={shareStyles.completionDateLabel}>{label}</CKText>
        {includedContent.length > 0 && includedSeconds > 0 ? (
          <CKText style={shareStyles.completionDateIncluded} numberOfLines={1} adjustsFontSizeToFit>
            + {formatTrackerDuration(includedSeconds)} · {includedContent.join(' · ')}
          </CKText>
        ) : null}
      </View>
      <View style={shareStyles.completionDateTiming}>
        <CKText style={shareStyles.completionDateDuration} numberOfLines={1}>
          {seconds > 0 ? formatTrackerDuration(seconds) : '—'}
        </CKText>
        <CKText style={shareStyles.completionDateValue} numberOfLines={1}>
          {date ? formatTrackerCompletionDate(date, locale) : '—'}
        </CKText>
      </View>
    </View>
  );
}

function completionDate(startsAt: Date, seconds: number) {
  return seconds > 0 ? new Date(startsAt.getTime() + seconds * 1000) : null;
}

export function formatTrackerCompletionDate(date: Date, locale: string) {
  const intlLocale = toIntlLocale(locale);
  if (!intlLocale.toLowerCase().startsWith('en')) {
    return new Intl.DateTimeFormat(intlLocale, {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    }).format(date);
  }
  const parts = new Intl.DateTimeFormat(intlLocale, {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  }).formatToParts(date);
  const month = parts.find((part) => part.type === 'month')?.value ?? '';
  const day = Number(parts.find((part) => part.type === 'day')?.value ?? 0);
  const year = parts.find((part) => part.type === 'year')?.value ?? '';
  const modulo100 = day % 100;
  const suffix =
    modulo100 >= 11 && modulo100 <= 13
      ? 'th'
      : day % 10 === 1
        ? 'st'
        : day % 10 === 2
          ? 'nd'
          : day % 10 === 3
            ? 'rd'
            : 'th';
  return `${month} ${day}${suffix} ${year}`;
}

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

function progressSectionLabel(key: TrackerProgressSectionKey, t: I18nValue['t']) {
  const labels: Record<TrackerProgressSectionKey, string> = {
    walls: t('upgradeTrackerWalls'),
    buildings: t('gameAssetsCategoryBuildings'),
    supercharges: t('upgradeTrackerPlanCategorySupercharge'),
    heroes: t('gameHeroes'),
    laboratory: t('upgradeTrackerLaboratory'),
    pets: t('upgradeTrackerPets'),
    equipment: t('upgradeTrackerEquipment'),
    craftedDefenses: t('upgradeTrackerPlanCategoryCraftedDefenses'),
  };
  return labels[key];
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

export function trackerArtworkUrls(
  snapshot: UpgradeTrackerSnapshot,
  preview: TrackerSharePreview = 'home',
) {
  const village = preview === 'builder' ? UpgradeVillage.builderBase : UpgradeVillage.home;
  const sections = preview === 'collection' ? [] : trackerProgressSections(snapshot, village);
  return [
    ImageAssets.townHall(snapshot.townHallLevel),
    ImageAssets.builderHall(snapshot.builderHallLevel),
    ImageAssets.homeBaseBackground,
    ImageAssets.builderBaseBackground,
    ImageAssets.darkModeLogo,
    ...(preview === 'collection' ? snapshot.collections.map((item) => item.imageUrl) : []),
    ...sections.map((section) => section.imageUrl),
    ...sections.flatMap((section) => Object.keys(section.summary.costs).map(resourceImage)),
  ].filter((url, index, values) => url.startsWith('http') && values.indexOf(url) === index);
}

function progressSectionImage(
  snapshot: UpgradeTrackerSnapshot,
  village: UpgradeVillageValue,
  key: TrackerProgressSectionKey,
  items: readonly UpgradeTrackerItem[],
) {
  if (key === 'buildings')
    return village === UpgradeVillage.home
      ? ImageAssets.getHomeVillageBuildingImage("Builder's Hut", 1)
      : ImageAssets.getBuilderBaseBuildingImage("Builder's Hut", 1);
  if (key === 'laboratory')
    return village === UpgradeVillage.home
      ? ImageAssets.getHomeVillageBuildingImage('Laboratory', 1)
      : ImageAssets.getBuilderBaseBuildingImage('Star Laboratory', 1);
  return items[0]?.imageUrl ?? ImageAssets.defaultImage;
}

function queueDurationSeconds(
  snapshot: UpgradeTrackerSnapshot,
  village: UpgradeVillageValue,
  queue: (typeof UpgradeQueue)[keyof typeof UpgradeQueue],
  startsAt: Date,
  includedItemKeys?: ReadonlySet<string>,
) {
  const finish = snapshot
    .buildPlan({
      queue,
      strategy: UpgradePlanStrategy.balanced,
      village,
      startsAt,
      includedItemKeys,
    })
    .reduce<Date | null>(
      (latest, lane) =>
        lane.finishesAt && (!latest || lane.finishesAt > latest) ? lane.finishesAt : latest,
      null,
    );
  return finish ? Math.max(0, (finish.getTime() - startsAt.getTime()) / 1000) : 0;
}

function withTimeout<T>(promise: Promise<T>, timeoutMs: number): Promise<T> {
  return new Promise<T>((resolve, reject) => {
    const timeout = setTimeout(() => reject(new Error('Operation timed out.')), timeoutMs);
    promise.then(
      (value) => {
        clearTimeout(timeout);
        resolve(value);
      },
      (error) => {
        clearTimeout(timeout);
        reject(error);
      },
    );
  });
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
  graphicBoundary: { width: '100%' },
  collectionGraphicBoundary: { aspectRatio: 1 },
  graphic: { flex: 1, borderRadius: 22, overflow: 'hidden', backgroundColor: '#0d0d0f' },
  graphicShade: { backgroundColor: '#050506dc' },
  graphicContent: { flex: 1, padding: 18 },
  hall: { width: 58, height: 58, resizeMode: 'contain' },
  whiteTitle: { color: '#fff', fontSize: 20, fontWeight: '900' },
  silver: { color: '#bfc2c8', fontSize: 11, fontWeight: '700' },
  silverStrong: { color: '#d4d7dd', fontSize: 11, fontWeight: '900' },
  overallProgress: { alignItems: 'flex-end' },
  percent: { color: '#fff', fontSize: 28, lineHeight: 31, fontWeight: '900' },
  completionDates: { flexDirection: 'row', gap: 6, marginTop: 8 },
  completionDate: {
    flex: 1,
    minHeight: 42,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    borderRadius: 10,
    backgroundColor: '#1a1a1ecc',
    paddingHorizontal: 7,
    paddingVertical: 5,
  },
  completionDateIcon: { width: 21, height: 21, resizeMode: 'contain' },
  completionDateLabel: { color: '#bfc2c8', fontSize: 8, fontWeight: '700' },
  completionDateIncluded: { color: '#f1b84b', fontSize: 7, fontWeight: '900' },
  completionDateTiming: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  completionDateDuration: { color: '#fff', fontSize: 9, fontWeight: '900' },
  completionDateValue: { color: '#fff', fontSize: 9, fontWeight: '900' },
  resourceRow: { minHeight: 16, flexDirection: 'row', alignItems: 'center', gap: 6 },
  resourcePair: { flexDirection: 'row', alignItems: 'center', gap: 3 },
  resourceIcon: { width: 14, height: 14, resizeMode: 'contain' },
  categoryList: { gap: 5, marginTop: 8 },
  categoryRow: {
    minHeight: 35,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    borderRadius: 11,
    backgroundColor: '#151519c9',
    paddingHorizontal: 7,
    paddingVertical: 4,
  },
  categoryIcon: { width: 26, height: 26, resizeMode: 'contain' },
  categoryBody: { flex: 1, gap: 3 },
  categoryHeading: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  categoryDetail: { flexDirection: 'row', alignItems: 'center', gap: 7 },
  categoryLabel: { flex: 1, color: '#fff', fontSize: 10, fontWeight: '800' },
  categoryTime: { color: '#bfc2c8', fontSize: 9, fontWeight: '700' },
  categoryPercent: {
    color: '#fff',
    width: 32,
    textAlign: 'right',
    fontSize: 9,
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
  error: { color: '#ff8d88', textAlign: 'center', paddingVertical: 4 },
});
