import { modalOrientations } from '../../../ui/modal-orientations';
import { useLinkParameters, linkChoice } from '../../../core/deep-links/link-parameters';
import { Asset } from 'expo-asset';
import {
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
  type Dispatch,
  type ReactNode,
  type SetStateAction,
} from 'react';
import {
  Animated,
  ActivityIndicator,
  Modal,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  View,
  useWindowDimensions,
  type NativeScrollEvent,
  type NativeSyntheticEvent,
} from 'react-native';
import {
  ArrowLeft,
  ChevronDown,
  ChevronRight,
  Filter,
  Headphones,
  Lock,
  Pause,
  Play,
  Search,
  Share2,
  Upload,
  X,
} from 'lucide-react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';
import * as Clipboard from 'expo-clipboard';
import { HeroHeaderScrim } from '../../../ui/hero-header-scrim';

import { ImageAssets } from '../../../core/assets/image-assets';
import { translationForTid } from '../../../core/game-data/game-data-localization';
import {
  materialBackLabel,
  toIntlLocale,
  useI18n,
  type I18nValue,
  type MessageKey,
} from '../../../i18n';
import {
  CKText,
  SelectionPickerModal,
  EmptyState,
  GlassSurface,
  MobileWebImage,
  PressableSurface,
  ProfileTabs,
  ResponsiveGrid,
  SearchField,
  SelectionPicker,
  Skeleton,
  SkeletonContent,
  useSkeletonContent,
  Surface,
  ckRadius,
  colorWithAlpha,
  useCKTheme,
  useCKThemeMode,
} from '../../../ui';
import {
  PagerView,
  type PagerViewHandle,
  type PagerViewOnPageSelectedEvent,
} from '../../../ui/pager';
import { SceneryAudioService, type SceneryAudioState } from '../audio/scenery-audio-service';
import {
  UpgradeCategory,
  UpgradeCollectionType,
  UpgradeQueue,
  UpgradeBoosts,
  UpgradeStep,
  UpgradeTrackerItem,
  UpgradeTrackerSnapshot,
  UpgradeCollectionItem,
  UpgradeVillage,
  type UpgradeCollectionTypeValue,
  type UpgradePlanPreferences as UpgradePlanPreferencesType,
  type PlannedUpgrade,
  type UpgradeVillageValue,
} from '../models';
import {
  activeTrackerItems,
  buildTrackerPlanData,
  filteredUpgradeItems,
  formatTrackerDuration,
  groupPlannedUpgrades,
  planLaneLabel,
  sceneryMusicUrl,
  trackerTabs,
  type TrackerTab,
} from './upgrade-tracker-logic';
import { UpgradeItemDetailModal } from './upgrade-tracker-breakdowns';
import { UpgradeTrackerPlanEditor } from './upgrade-tracker-plan-editor';
import { UpgradeTrackerShareModal } from './upgrade-tracker-share';
import { trackerCategoryImage, trackerCategoryImageScale } from './tracker-category-art';
import { ongoingUpgradeQueues } from '../models/ongoing-upgrade-queues';
import { TrackerSummaryCard } from './tracker-summary-card';
import { upgradeSnapshotNeedsRefresh } from '../models/snapshot-freshness';

export interface UpgradeTrackerAccountOption {
  readonly tag: string;
  readonly name: string;
  readonly townHallLevel: number;
  readonly builderHallLevel: number;
  readonly capturedAt?: Date;
}

export interface UpgradeTrackerScreenProps {
  readonly snapshot: UpgradeTrackerSnapshot | null;
  readonly accounts: readonly UpgradeTrackerAccountOption[];
  readonly selectedTag: string | null;
  readonly loading: boolean;
  readonly accountLoading?: boolean;
  readonly error: string | null;
  readonly goldPassPercent: number;
  readonly preferences: UpgradePlanPreferencesType;
  readonly onBack: () => void;
  readonly onSelectAccount: (tag: string) => void;
  readonly onImport: (json: string) => Promise<void>;
  readonly onRefresh: () => Promise<void>;
  readonly onGoldPassChange: (value: number) => void;
  readonly onPreferencesChange: (value: UpgradePlanPreferencesType) => void;
  readonly onOpenGameSettings: () => void;
}

export function UpgradeTrackerScreen(props: UpgradeTrackerScreenProps) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  const link = useLinkParameters();
  const [tab, setTab] = useState<TrackerTab>(linkChoice(link.tab, trackerTabs, 'home'));
  const [accountOpen, setAccountOpen] = useState(false);
  // A Home shortcut opens the same importer once. Closing it must not reopen
  // it on loading updates, so this is initial state rather than a link effect.
  const [importOpen, setImportOpen] = useState(() => link.import === '1');
  const [shareKind, setShareKind] = useState<'home' | 'builder' | 'collection' | null>(null);
  const [settingsOpen, setSettingsOpen] = useState(false);
  const [goldPassOpen, setGoldPassOpen] = useState(false);
  const pager = useRef<PagerViewHandle>(null);
  const [trackerScrollY] = useState(() => new Animated.Value(0));
  const [trackerOffsets, setTrackerOffsets] = useState<Partial<Record<TrackerTab, number>>>({});
  const pending = props.loading && !props.snapshot;
  const placeholder = useMemo(
    () =>
      trackerLoadingSnapshot(props.accounts.find((account) => account.tag === props.selectedTag)),
    [props.accounts, props.selectedTag],
  );
  const snapshot = props.snapshot ?? (pending ? placeholder : null);
  const viewportWidth = useWindowDimensions().width;
  const desktop = Platform.OS === 'web' && viewportWidth >= 900;
  const selectedAccount = props.accounts.find((account) => account.tag === props.selectedTag);
  const clock = useTrackerClock(snapshot);
  const plan = useMemo(
    () =>
      snapshot ? buildTrackerPlanData(snapshot, props.goldPassPercent, props.preferences) : null,
    [props.goldPassPercent, props.preferences, snapshot],
  );
  const tabs = [
    {
      key: 'home',
      label: t('upgradeTrackerHomeVillage'),
      icon: (
        <MobileWebImage
          imageUrl={ImageAssets.townHall(snapshot?.townHallLevel ?? 1)}
          style={styles.tabImage}
        />
      ),
    },
    {
      key: 'builder',
      label: t('upgradeTrackerBuilderBase'),
      icon: (
        <MobileWebImage
          imageUrl={ImageAssets.builderHall(snapshot?.builderHallLevel ?? 1)}
          style={styles.tabImage}
        />
      ),
    },
    {
      key: 'calendar',
      label: t('upgradeTrackerCalendar'),
      icon: <MobileWebImage imageUrl={ImageAssets.iconClock} style={styles.tabImage} />,
    },
    {
      key: 'plan',
      label: t('upgradeTrackerPlan'),
      icon: <MobileWebImage imageUrl={ImageAssets.hammerOfBuilding} style={styles.tabImage} />,
    },
    {
      key: 'collection',
      label: t('upgradeTrackerCollection'),
      icon: (
        <MobileWebImage
          imageUrl={snapshot?.collections[0]?.imageUrl ?? ImageAssets.iconTick}
          style={styles.tabImage}
        />
      ),
    },
  ];
  const selectTab = (next: TrackerTab) => {
    setTab(next);
    trackerScrollY.setValue(trackerOffsets[next] ?? 0);
    pager.current?.setPageWithoutAnimation(trackerTabs.indexOf(next));
  };
  const trackerHeaderHeight = (desktop ? 280 : 300) + insets.top;
  const trackerTabHeight = 54;
  const trackerChromeInset = trackerHeaderHeight + trackerTabHeight;
  const trackerCollapseDistance = trackerHeaderHeight - insets.top;
  const trackerChromeTranslate = trackerScrollY.interpolate({
    inputRange: [0, trackerCollapseDistance],
    outputRange: [0, -trackerCollapseDistance],
    extrapolate: 'clamp',
  });
  const handleTrackerScroll = (_page: TrackerTab) =>
    Animated.event([{ nativeEvent: { contentOffset: { y: trackerScrollY } } }], {
      useNativeDriver: Platform.OS !== 'web' && process.env.NODE_ENV !== 'test',
    });
  const commitTrackerScroll =
    (page: TrackerTab) => (event: NativeSyntheticEvent<NativeScrollEvent>) => {
      const offset = Math.max(0, event.nativeEvent.contentOffset.y);
      setTrackerOffsets((current) => ({ ...current, [page]: offset }));
      if (page === tab) trackerScrollY.setValue(offset);
    };
  const importSnapshot = async (json: string) => {
    await props.onImport(json);
    selectTab('home');
  };
  return (
    <SafeAreaView edges={['left', 'right']} style={styles.safe}>
      {!snapshot ? (
        <TrackerHeader
          snapshot={null}
          account={selectedAccount}
          tab={tab}
          plan={null}
          locale={locale}
          onBack={props.onBack}
          onAccount={() => setAccountOpen(true)}
          onShare={() => {}}
          onImport={() => setImportOpen(true)}
        />
      ) : null}
      {props.error && !snapshot ? (
        <EmptyState
          title={t('upgradeTrackerSnapshotUnreadable')}
          body={props.error}
          actionLabel={t('upgradeTrackerTryAgain')}
          onAction={() => void props.onRefresh()}
        />
      ) : !snapshot ? (
        <View style={styles.emptyBody}>
          <EmptyState
            title={t('upgradeTrackerNoDataTitle')}
            body={
              props.selectedTag
                ? `${t('upgradeTrackerNoDataBody')}\n${t('upgradeTrackerNoDataLocation')}`
                : t('upgradeTrackerNoLinkedAccount')
            }
          />
          {props.selectedTag ? (
            <PressableSurface
              accessibilityRole="button"
              onPress={() => setImportOpen(true)}
              style={[
                styles.primaryButton,
                {
                  backgroundColor: theme.primary,
                  borderRadius: ckRadius.control,
                  alignSelf: 'stretch',
                },
              ]}
            >
              <Upload size={20} color={theme.onPrimary} />
              <CKText role="bodyMedium" style={{ color: theme.onPrimary }}>
                {t('upgradeTrackerImportTitle')}
              </CKText>
            </PressableSurface>
          ) : null}
          {props.selectedTag ? (
            <PressableSurface
              accessibilityRole="button"
              onPress={props.onOpenGameSettings}
              style={[
                styles.secondaryButton,
                {
                  backgroundColor: theme.surfaceContainerHighest,
                  paddingHorizontal: 20,
                  borderRadius: 16,
                  alignSelf: 'stretch',
                },
              ]}
            >
              <CKText style={{ color: theme.onSurface }}>
                {t('upgradeTrackerOpenMoreSettings')}
              </CKText>
            </PressableSurface>
          ) : null}
        </View>
      ) : (
        <View style={styles.trackerBody}>
          <SkeletonContent loading={pending} style={{ flex: 1 }}>
            <TrackerPager
              pager={pager}
              tab={tab}
              snapshot={snapshot}
              plan={plan!}
              now={clock}
              contentInset={trackerChromeInset}
              initialOffsets={trackerOffsets}
              onScroll={handleTrackerScroll}
              onScrollSettled={commitTrackerScroll}
              onPriorities={() => setSettingsOpen(true)}
              onGoldPass={() => setGoldPassOpen(true)}
              goldPassPercent={props.goldPassPercent}
              onSelect={(next) => {
                setTab(next);
                trackerScrollY.setValue(trackerOffsets[next] ?? 0);
              }}
            />
          </SkeletonContent>
          <Animated.View
            testID="upgrade-tracker-collapsible-header"
            pointerEvents="box-none"
            style={[
              styles.trackerHeaderOverlay,
              { height: trackerHeaderHeight, transform: [{ translateY: trackerChromeTranslate }] },
            ]}
          >
            <TrackerHeader
              snapshot={snapshot}
              loading={pending}
              tab={tab}
              plan={plan!}
              locale={locale}
              onBack={props.onBack}
              onAccount={() => setAccountOpen(true)}
              onShare={() =>
                !pending &&
                setShareKind(
                  tab === 'builder' ? 'builder' : tab === 'collection' ? 'collection' : 'home',
                )
              }
              onImport={() => setImportOpen(true)}
            />
          </Animated.View>
          <Animated.View
            testID="upgrade-tracker-pinned-tabs"
            style={[
              styles.tabWrap,
              styles.trackerTabsOverlay,
              {
                top: trackerHeaderHeight,
                backgroundColor: theme.background,
                transform: [{ translateY: trackerChromeTranslate }],
              },
            ]}
          >
            <View style={styles.tabControl}>
              <ProfileTabs
                tabs={tabs}
                selectedKey={tab}
                onSelect={(key) => selectTab(key as TrackerTab)}
              />
            </View>
          </Animated.View>
        </View>
      )}
      <AccountModal
        visible={accountOpen}
        accounts={props.accounts}
        selectedTag={props.selectedTag}
        loading={props.accountLoading ?? false}
        onClose={() => setAccountOpen(false)}
        onSelect={(tag) => {
          props.onSelectAccount(tag);
          setAccountOpen(false);
        }}
        onImport={() => {
          setAccountOpen(false);
          setImportOpen(true);
        }}
      />
      <ImportModal
        visible={importOpen}
        onClose={() => setImportOpen(false)}
        onOpenGameSettings={props.onOpenGameSettings}
        onImport={async (json) => {
          await importSnapshot(json);
          setImportOpen(false);
        }}
      />
      {props.snapshot && shareKind ? (
        <UpgradeTrackerShareModal
          visible
          initial={shareKind}
          snapshot={props.snapshot}
          onClose={() => setShareKind(null)}
        />
      ) : null}
      {props.snapshot && settingsOpen ? (
        <UpgradeTrackerPlanEditor
          visible
          snapshot={props.snapshot}
          preferences={props.preferences}
          onClose={() => setSettingsOpen(false)}
          onSave={(value) => {
            props.onPreferencesChange(value);
            setSettingsOpen(false);
          }}
        />
      ) : null}
      <SelectionPickerModal
        visible={goldPassOpen}
        title={goldPassLabel(props.goldPassPercent, t)}
        onClose={() => setGoldPassOpen(false)}
        selectedKey={String(props.goldPassPercent)}
        options={[0, 10, 15, 20].map((value) => ({
          key: String(value),
          label: goldPassLabel(value, t),
          icon: (
            <MobileWebImage imageUrl={ImageAssets.goldPass} style={{ width: 30, height: 30 }} />
          ),
        }))}
        onSelect={(value) => {
          props.onGoldPassChange(Number(value));
          setGoldPassOpen(false);
        }}
      />
    </SafeAreaView>
  );
}

function TrackerHeader({
  snapshot,
  account,
  tab,
  plan,
  locale,
  onBack,
  onAccount,
  onShare,
  onImport,
  loading = false,
}: {
  snapshot: UpgradeTrackerSnapshot | null;
  account?: UpgradeTrackerAccountOption;
  tab: TrackerTab;
  plan: ReturnType<typeof buildTrackerPlanData> | null;
  locale: Parameters<typeof materialBackLabel>[0];
  onBack: () => void;
  onAccount: () => void;
  onShare: () => void;
  onImport: () => void;
  loading?: boolean;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  const viewportWidth = useWindowDimensions().width;
  const desktop = Platform.OS === 'web' && viewportWidth >= 900;
  const village = tab === 'builder' ? UpgradeVillage.builderBase : UpgradeVillage.home;
  const collection = tab === 'collection';
  const summary = snapshot?.overallSummary(village);
  const owned = snapshot?.collections.filter((item) => item.owned).length ?? 0;
  const builders = snapshot?.buildersFor(village) ?? 0;
  const busy = snapshot
    ? snapshot
        .itemsFor({ village, queue: UpgradeQueue.builders })
        .filter((item) => snapshot.remainingActiveSeconds(item) > 0).length
    : 0;
  const villageFinish = plan?.allLanes
    .flatMap((lane) => lane.upgrades)
    .filter((upgrade) => upgrade.item.village === village)
    .reduce<Date | null>(
      (latest, upgrade) => (!latest || upgrade.endsAt > latest ? upgrade.endsAt : latest),
      null,
    );
  const hall = collection
    ? ImageAssets.townHall(snapshot?.townHallLevel ?? account?.townHallLevel ?? 1)
    : village === UpgradeVillage.home
      ? ImageAssets.townHall(snapshot?.townHallLevel ?? account?.townHallLevel ?? 1)
      : ImageAssets.builderHall(snapshot?.builderHallLevel ?? account?.builderHallLevel ?? 1);
  const background = Asset.fromModule(
    require('../../../../assets/clashking/tracker/builder-village-flat-roof.jpg'),
  ).uri;
  const values = !snapshot
    ? []
    : collection
      ? [
          {
            label: t('upgradeTrackerCollected'),
            value: snapshot.collections.length
              ? `${((owned * 100) / snapshot.collections.length).toFixed(1)}%`
              : '0%',
            image: ImageAssets.iconTick,
          },
          {
            label: t('upgradeTrackerHeaderOwned'),
            value: `${owned} / ${snapshot.collections.length}`,
            image: snapshot.collections[0]?.imageUrl ?? ImageAssets.iconTick,
          },
          {
            label: t('upgradeTrackerHeaderUpdated'),
            value: shortAge(snapshot.capturedAt),
            image: ImageAssets.iconClock,
          },
        ]
      : [
          {
            label: t('upgradeTrackerHeaderComplete'),
            value: `${((summary?.completion ?? 0) * 100).toFixed(1)}%`,
            image: ImageAssets.iconTick,
          },
          {
            label: t('upgradeTrackerHeaderLevelsLeft'),
            value: String(summary?.levelsRemaining ?? 0),
            image: ImageAssets.hammerOfBuilding,
          },
          {
            label: t('upgradeTrackerHeaderActive'),
            value: `${busy}/${builders}`,
            image: ImageAssets.getHomeVillageBuildingImage("Builder's Hut", 1),
          },
          {
            label: t('upgradeTrackerHeaderFinishes'),
            value: villageFinish
              ? new Intl.DateTimeFormat(toIntlLocale(locale), {
                  month: 'short',
                  day: 'numeric',
                }).format(villageFinish)
              : '—',
            image: ImageAssets.iconClock,
          },
        ];
  return (
    <View style={[styles.heroHeader, { height: (desktop ? 280 : 300) + insets.top }]}>
      <MobileWebImage imageUrl={background} contentFit="cover" style={styles.heroBackdrop} />
      <HeroHeaderScrim />
      <View
        style={[
          styles.heroActions,
          { paddingTop: insets.top, paddingHorizontal: desktop ? 24 : 12 },
        ]}
      >
        <HeroIconButton label={materialBackLabel(locale)} onPress={onBack}>
          <ArrowLeft color="white" />
        </HeroIconButton>
        <View style={styles.grow} />
        {snapshot ? (
          <HeroIconButton label={t('upgradeTrackerShare')} onPress={onShare}>
            <Share2 color="white" />
          </HeroIconButton>
        ) : null}
        <HeroIconButton label={t('upgradeTrackerPasteJson')} onPress={onImport}>
          <Upload color="white" />
        </HeroIconButton>
      </View>
      <SkeletonContent loading={loading} style={{ flex: 1 }}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={t('upgradeTrackerChooseAccount')}
          onPress={onAccount}
          style={styles.heroProfile}
        >
          <View style={styles.heroHallBadge}>
            <MobileWebImage
              imageUrl={hall}
              style={[styles.heroHall, desktop && styles.heroHallDesktop]}
            />
          </View>
          <View style={styles.heroNameRow}>
            <CKText
              role="titleLarge"
              style={[styles.heroText, { fontSize: desktop ? 24 : 26, fontWeight: '700' }]}
              numberOfLines={1}
            >
              {snapshot?.name ?? account?.name ?? t('upgradeTrackerChooseAccount')}
            </CKText>
            <ChevronDown color="white" size={20} />
          </View>
          {snapshot && upgradeSnapshotNeedsRefresh(snapshot) ? (
            <Pressable
              onPress={(event) => {
                event.stopPropagation();
                onImport();
              }}
              accessibilityRole="button"
              style={styles.freshnessAction}
            >
              <Upload size={14} color="#E8A524" />
              <CKText role="metadata" style={{ color: '#E8A524' }}>
                {t('widgetDataStale')}
              </CKText>
            </Pressable>
          ) : snapshot ? (
            <CKText role="metadata" style={styles.heroSecondary}>
              {snapshotAgeLabel(snapshot.capturedAt, t)}
            </CKText>
          ) : null}
        </Pressable>
        <View
          style={[
            styles.quickStats,
            { paddingHorizontal: desktop ? 24 : 16, paddingBottom: desktop ? 12 : 10 },
          ]}
        >
          {values.map((value) => (
            <View
              key={value.label}
              accessibilityLabel={value.label}
              style={[styles.quickStat, { backgroundColor: colorWithAlpha(theme.surface, 0.58) }]}
            >
              <View
                style={{
                  flexDirection: 'row',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: 5,
                }}
              >
                <MobileWebImage imageUrl={value.image} style={styles.quickStatImage} />
                <CKText role="bodyMedium" style={{ color: 'white' }}>
                  {value.value}
                </CKText>
              </View>
              <CKText role="metadata" style={{ color: '#FFFFFFC7', textAlign: 'center' }}>
                {value.label}
              </CKText>
            </View>
          ))}
        </View>
      </SkeletonContent>
    </View>
  );
}

/** Presentation-only records mount the real tab/card layout while its snapshot
 * loads. Never send this snapshot to storage, widgets, sharing or plan edits. */
function trackerLoadingSnapshot(account?: UpgradeTrackerAccountOption) {
  const home = UpgradeVillage.home;
  const builder = UpgradeVillage.builderBase;
  const hall = account?.townHallLevel ?? 1;
  const categories = [
    UpgradeCategory.army,
    UpgradeCategory.defenses,
    UpgradeCategory.traps,
    UpgradeCategory.troops,
    UpgradeCategory.walls,
    ...(hall >= 7 ? [UpgradeCategory.heroes] : []),
    ...(hall >= 8 ? [UpgradeCategory.equipment] : []),
    ...(hall >= 14 ? [UpgradeCategory.pets] : []),
  ];
  const items = [home, builder].flatMap((village) =>
    categories
      .filter(
        (category) =>
          village === home ||
          (category !== UpgradeCategory.pets && category !== UpgradeCategory.equipment),
      )
      .map(
        (category, index) =>
          new UpgradeTrackerItem({
            id: -(index + 1 + (village === builder ? 100 : 0)),
            name: 'Upgrade',
            imageUrl: '',
            village,
            category,
            queue:
              category === UpgradeCategory.troops
                ? UpgradeQueue.laboratory
                : category === UpgradeCategory.pets
                  ? UpgradeQueue.pets
                  : UpgradeQueue.builders,
            currentLevel: 0,
            targetLevel: 1,
            count: 1,
            steps: [new UpgradeStep(1, [], 3600)],
            completedUpgradeSeconds: 0,
            totalUpgradeSeconds: 3600,
            activeSeconds:
              index === 0 ||
              category === UpgradeCategory.troops ||
              category === UpgradeCategory.pets
                ? 3600
                : null,
          }),
      ),
  );
  return new UpgradeTrackerSnapshot({
    tag: account?.tag ?? '#LOADING',
    name: account?.name ?? 'Player',
    townHallLevel: hall,
    builderHallLevel: account?.builderHallLevel ?? 1,
    homeBuilderCount: 5,
    builderBaseBuilderCount: 2,
    items,
    collections: Object.values(UpgradeCollectionType).map(
      (type, index) =>
        new UpgradeCollectionItem({
          id: -(index + 1),
          name: 'Collection',
          imageUrl: '',
          type,
          owned: false,
        }),
    ),
    boosts: new UpgradeBoosts(),
    events: [],
    capturedAt: new Date(),
  });
}

function HeroIconButton({
  label,
  onPress,
  children,
}: {
  label: string;
  onPress: () => void;
  children: ReactNode;
}) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      onPress={onPress}
      style={styles.heroIconButton}
    >
      {children}
    </Pressable>
  );
}

function shortAge(capturedAt: Date) {
  const milliseconds = Math.max(0, Date.now() - capturedAt.getTime());
  const days = Math.floor(milliseconds / 86_400_000);
  if (days > 0) return `${days}d`;
  const hours = Math.floor(milliseconds / 3_600_000);
  if (hours > 0) return `${hours}h`;
  return `${Math.min(59, Math.floor(milliseconds / 60_000))}m`;
}

function goldPassLabel(percent: number, t: I18nValue['t']) {
  return percent === 0
    ? t('upgradeTrackerNoGoldPass')
    : t('upgradeTrackerGoldPassPercent', { percent });
}

function snapshotAgeLabel(capturedAt: Date, t: ReturnType<typeof useI18n>['t']) {
  const minutes = Math.floor(Math.max(0, Date.now() - capturedAt.getTime()) / 60_000);
  if (minutes < 1) return t('upgradeTrackerUpdatedJustNow');
  if (minutes < 60) return t('upgradeTrackerUpdatedMinutesAgo', { count: minutes });
  if (minutes < 24 * 60)
    return t('upgradeTrackerUpdatedHoursAgo', { count: Math.floor(minutes / 60) });
  const days = Math.floor(minutes / (24 * 60));
  // Hermes does not provide RelativeTimeFormat on every supported device.
  // Reuse translated day strings instead of requiring another Intl constructor.
  return t('warWidgetLastUpdated', {
    time: days === 1 ? t('timeDayAgo', { day: days }) : t('timeDaysAgo', { days }),
  });
}

function useTrackerClock(snapshot: UpgradeTrackerSnapshot | null) {
  const [clock, setClock] = useState(() => new Date());
  useEffect(() => {
    if (!snapshot) return;
    let timer: ReturnType<typeof setTimeout> | null = null;
    const schedule = (now: Date) => {
      const target = nextTrackerTick(snapshot, now);
      if (!target) return;
      timer = setTimeout(
        () => {
          const nextNow = new Date();
          setClock(nextNow);
          schedule(nextNow);
        },
        Math.min(86_400_000, Math.max(12, target.getTime() - now.getTime() + 12)),
      );
    };
    schedule(new Date());
    return () => {
      if (timer) clearTimeout(timer);
    };
  }, [snapshot]);
  return clock;
}

function useCachedPageState<T>(
  store: Map<string, unknown>,
  key: string,
  initial: T | (() => T),
): [T, Dispatch<SetStateAction<T>>] {
  const [value, setValue] = useState<T>(() => {
    if (store.has(key)) return store.get(key) as T;
    const resolved = typeof initial === 'function' ? (initial as () => T)() : initial;
    store.set(key, resolved);
    return resolved;
  });
  const setCachedValue = useCallback<Dispatch<SetStateAction<T>>>(
    (next) => {
      setValue((current) => {
        const resolved = typeof next === 'function' ? (next as (value: T) => T)(current) : next;
        store.set(key, resolved);
        return resolved;
      });
    },
    [key, store],
  );
  return [value, setCachedValue];
}

function useInitialScrollOffset(initialOffset: number) {
  const [offset] = useState(() => ({ x: 0, y: initialOffset }));
  return offset;
}

function upgradeItemRenderIdentity(item: UpgradeTrackerItem) {
  return [
    item.planKey,
    item.village,
    item.currentLevel,
    item.targetLevel,
    item.count,
    item.parentName ?? '',
    item.isExtra ? 'extra' : 'standard',
    item.activeSeconds ?? 0,
    item.helperSeconds ?? 0,
  ].join(':');
}

export function uniqueUpgradeItems(items: readonly UpgradeTrackerItem[]) {
  const seen = new Set<string>();
  return items.filter((item) => {
    const identity = upgradeItemRenderIdentity(item);
    if (seen.has(identity)) return false;
    seen.add(identity);
    return true;
  });
}

function collectionItemRenderIdentity(item: UpgradeCollectionItem) {
  return [item.type, item.village ?? '', item.id, item.name].join(':');
}

export function uniqueCollectionItems(items: readonly UpgradeCollectionItem[]) {
  const seen = new Set<string>();
  return items.filter((item) => {
    const identity = collectionItemRenderIdentity(item);
    if (seen.has(identity)) return false;
    seen.add(identity);
    return true;
  });
}

function nextTrackerTick(snapshot: UpgradeTrackerSnapshot, now: Date): Date | null {
  let next: Date | null = null;
  const consider = (candidate: Date) => {
    if (candidate > now && (!next || candidate < next)) next = candidate;
  };
  const considerRemaining = (originalSeconds: number) => {
    const remaining = snapshot.remainingCapturedSeconds(originalSeconds, now);
    if (remaining <= 0) return;
    consider(new Date(snapshot.capturedAt.getTime() + originalSeconds * 1000));
    const displayUnit = remaining >= 86_400 ? 3_600 : 60;
    consider(new Date(now.getTime() + ((remaining % displayUnit) + 1) * 1000));
  };
  const ageMilliseconds = now.getTime() - snapshot.capturedAt.getTime();
  const ageMinutes = Math.floor(ageMilliseconds / 60_000);
  const ageHours = Math.floor(ageMilliseconds / 3_600_000);
  if (ageMilliseconds < 0 || ageMinutes < 1)
    consider(new Date(snapshot.capturedAt.getTime() + 60_000));
  else if (ageHours < 1)
    consider(new Date(snapshot.capturedAt.getTime() + (ageMinutes + 1) * 60_000));
  else if (ageHours < 24)
    consider(new Date(snapshot.capturedAt.getTime() + (ageHours + 1) * 3_600_000));
  for (const item of snapshot.items) {
    considerRemaining(item.activeSeconds ?? 0);
    considerRemaining(item.helperSeconds ?? 0);
    considerRemaining(item.cooldownSeconds ?? 0);
  }
  const boosts = snapshot.boosts;
  for (const effect of boosts.activeEffects ?? []) considerRemaining(effect.seconds);
  for (const seconds of [
    boosts.builderBoostSeconds,
    boosts.labBoostSeconds,
    boosts.clockTowerBoostSeconds,
    boosts.builderConsumableSeconds,
    boosts.labConsumableSeconds,
    boosts.petConsumableSeconds,
    boosts.clockTowerCooldownSeconds,
  ])
    considerRemaining(seconds);
  for (const event of snapshot.events)
    if (now >= event.startsAt && now < event.endsAt) consider(event.endsAt);
  return next;
}

function TrackerPager({
  pager,
  tab,
  snapshot,
  plan,
  now,
  contentInset,
  initialOffsets,
  onScroll,
  onScrollSettled,
  onSelect,
  onPriorities,
  onGoldPass,
  goldPassPercent,
}: {
  pager: React.RefObject<PagerViewHandle | null>;
  tab: TrackerTab;
  snapshot: UpgradeTrackerSnapshot;
  plan: ReturnType<typeof buildTrackerPlanData>;
  now: Date;
  contentInset: number;
  initialOffsets: Partial<Record<TrackerTab, number>>;
  onScroll: (page: TrackerTab) => (event: NativeSyntheticEvent<NativeScrollEvent>) => void;
  onScrollSettled: (page: TrackerTab) => (event: NativeSyntheticEvent<NativeScrollEvent>) => void;
  onSelect: (tab: TrackerTab) => void;
  onPriorities: () => void;
  onGoldPass: () => void;
  goldPassPercent: number;
}) {
  const previousTab = useRef(tab);
  const [pageStateStore] = useState(() => new Map<string, unknown>());
  const [mountedPages, setMountedPages] = useState<ReadonlySet<TrackerTab>>(
    () =>
      new Set([tab, trackerTabs[Math.min(trackerTabs.length - 1, trackerTabs.indexOf(tab) + 1)]!]),
  );
  useEffect(() => {
    setMountedPages((current) => boundedTrackerPageCache(current, previousTab.current, tab));
    previousTab.current = tab;
  }, [tab]);
  const handlePageSelected = (event: PagerViewOnPageSelectedEvent) => {
    const next = trackerTabs[event.nativeEvent.position];
    if (next && next !== tab) onSelect(next);
  };
  const pages: Readonly<Record<TrackerTab, ReactNode>> = {
    home: (
      <UpgradesTab
        snapshot={snapshot}
        village={UpgradeVillage.home}
        stateStore={pageStateStore}
        contentInset={contentInset}
        initialOffset={initialOffsets.home ?? 0}
        onScroll={onScroll('home')}
        onScrollSettled={onScrollSettled('home')}
      />
    ),
    builder: (
      <UpgradesTab
        snapshot={snapshot}
        village={UpgradeVillage.builderBase}
        stateStore={pageStateStore}
        contentInset={contentInset}
        initialOffset={initialOffsets.builder ?? 0}
        onScroll={onScroll('builder')}
        onScrollSettled={onScrollSettled('builder')}
      />
    ),
    calendar: (
      <CalendarTab
        snapshot={snapshot}
        plan={plan}
        now={now}
        stateStore={pageStateStore}
        contentInset={contentInset}
        initialOffset={initialOffsets.calendar ?? 0}
        onScroll={onScroll('calendar')}
        onScrollSettled={onScrollSettled('calendar')}
      />
    ),
    plan: (
      <PlanTab
        plan={plan}
        onPriorities={onPriorities}
        onGoldPass={onGoldPass}
        goldPassPercent={goldPassPercent}
        stateStore={pageStateStore}
        contentInset={contentInset}
        initialOffset={initialOffsets.plan ?? 0}
        onScroll={onScroll('plan')}
        onScrollSettled={onScrollSettled('plan')}
      />
    ),
    collection: (
      <CollectionTab
        snapshot={snapshot}
        stateStore={pageStateStore}
        contentInset={contentInset}
        initialOffset={initialOffsets.collection ?? 0}
        onScroll={onScroll('collection')}
        onScrollSettled={onScrollSettled('collection')}
      />
    ),
  };
  return (
    <PagerView
      ref={pager}
      initialPage={trackerTabs.indexOf(tab)}
      keyboardDismissMode="on-drag"
      onPageSelected={handlePageSelected}
      orientation="horizontal"
      overdrag={false}
      overScrollMode="never"
      scrollEnabled={false}
      style={styles.trackerPager}
      testID="upgrade-tracker-pager"
    >
      {trackerTabs.map((page) => (
        <View
          key={page}
          accessibilityElementsHidden={page !== tab}
          importantForAccessibility={page === tab ? 'auto' : 'no-hide-descendants'}
          style={styles.trackerPage}
        >
          {mountedPages.has(page) ? pages[page] : null}
        </View>
      ))}
    </PagerView>
  );
}

export function boundedTrackerPageCache(
  current: ReadonlySet<TrackerTab>,
  previous: TrackerTab,
  next: TrackerTab,
) {
  const nextIndex = trackerTabs.indexOf(next);
  const candidates = [
    next,
    previous,
    trackerTabs[nextIndex - 1],
    trackerTabs[nextIndex + 1],
    ...Array.from(current).reverse(),
  ];
  return new Set(
    Array.from(new Set(candidates.filter((page): page is TrackerTab => page !== undefined))).slice(
      0,
      3,
    ),
  );
}

function UpgradesTab({
  snapshot,
  village,
  stateStore,
  contentInset,
  initialOffset,
  onScroll,
  onScrollSettled,
}: {
  snapshot: UpgradeTrackerSnapshot;
  village: UpgradeVillageValue;
  stateStore: Map<string, unknown>;
  contentInset: number;
  initialOffset: number;
  onScroll: (event: NativeSyntheticEvent<NativeScrollEvent>) => void;
  onScrollSettled: (event: NativeSyntheticEvent<NativeScrollEvent>) => void;
}) {
  const { t } = useI18n();
  const viewportWidth = useWindowDimensions().width;
  const desktop = Platform.OS === 'web' && viewportWidth >= 900;
  const cachePrefix = village === UpgradeVillage.home ? 'home' : 'builder';
  const [query, setQuery] = useCachedPageState(stateStore, `${cachePrefix}.query`, '');
  const [activeOpen, setActiveOpen] = useCachedPageState(
    stateStore,
    `${cachePrefix}.activeExpanded`,
    false,
  );
  const [selected, setSelected] = useState<UpgradeTrackerItem | null>(null);
  const [expanded, setExpanded] = useCachedPageState<ReadonlySet<UpgradeGroup>>(
    stateStore,
    `${cachePrefix}.expanded`,
    () => new Set(),
  );
  const initialContentOffset = useInitialScrollOffset(initialOffset);
  const active = useMemo(
    () =>
      uniqueUpgradeItems(activeTrackerItems(snapshot).filter((item) => item.village === village)),
    [snapshot, village],
  );
  const groups = useMemo(
    () => groupedUpgradeItems(filteredUpgradeItems(snapshot, village, query, false), village),
    [snapshot, village, query],
  );
  return (
    <Animated.ScrollView
      testID={
        village === UpgradeVillage.home
          ? 'upgrade-tracker-home-scroll'
          : 'upgrade-tracker-builder-scroll'
      }
      contentContainerStyle={[styles.content, { paddingTop: contentInset + 12 }]}
      contentOffset={initialContentOffset}
      keyboardShouldPersistTaps="handled"
      onScroll={onScroll}
      onMomentumScrollEnd={onScrollSettled}
      onScrollEndDrag={onScrollSettled}
      scrollEventThrottle={16}
    >
      <SearchBar
        value={query}
        onChange={setQuery}
        placeholder={t('upgradeTrackerSearchUpgrades')}
      />
      <TrackerSummaryCard
        title={t('upgradeTrackerOngoingUpgrades')}
        imageUrl={ImageAssets.iconClock}
        percent={0}
        showProgress={false}
        compactHeader
        open={activeOpen}
        onToggle={() => setActiveOpen((open) => !open)}
        headerAccessory={
          <View style={{ flex: 1, minWidth: 0 }}>
            <ActiveUpgradeEffects snapshot={snapshot} village={village} />
          </View>
        }
        footer={
          !activeOpen ? <ActiveQueueSummary snapshot={snapshot} village={village} /> : undefined
        }
      >
        {active.length === 0 ? (
          <CKText muted role="metadata">
            {t('widgetNoActiveUpgrades')}
          </CKText>
        ) : null}
        <View style={{ gap: 16 }}>
          {[
            {
              queue: UpgradeQueue.builders,
              label: t('dashboardUpgradeTrackerBuilders'),
              image: trackerCategoryImage('builders', village),
            },
            {
              queue: UpgradeQueue.laboratory,
              label: t('upgradeTrackerLaboratory'),
              image: trackerCategoryImage('laboratory', village),
            },
            {
              queue: UpgradeQueue.pets,
              label: t('upgradeTrackerPetHouse'),
              image: ImageAssets.getHomeVillageBuildingImage('Pet House', 1),
            },
            { queue: UpgradeQueue.none, label: t('generalOthers'), image: ImageAssets.iconClock },
          ].map(({ queue, label, image }) => {
            // Group by the scheduler queue, not item category: heroes and
            // supercharges still use builders, while pets use their own slot.
            const items = active.filter((item) => item.queue === queue);
            if (!items.length) return null;
            return (
              <View key={queue}>
                <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
                  <MobileWebImage imageUrl={image} style={{ width: 20, height: 20 }} />
                  <CKText accessibilityRole="header" role="metadata" muted>
                    {label}
                  </CKText>
                </View>
                {items.map((item) => (
                  <CurrentUpgradeRow
                    key={`active-${upgradeItemRenderIdentity(item)}`}
                    item={item}
                    snapshot={snapshot}
                    onPress={() => setSelected(item)}
                  />
                ))}
              </View>
            );
          })}
        </View>
      </TrackerSummaryCard>
      <View style={desktop ? styles.desktopSectionGrid : styles.upgradeGroupList}>
        {groups.map(([group, items]) => {
          const open = expanded.has(group);
          const summary = snapshot.summaryForItems(items);
          return (
            <View key={group} style={desktop ? styles.desktopSection : undefined}>
              <TrackerSummaryCard
                title={upgradeGroupLabel(group, village, t)}
                imageUrl={trackerCategoryImage(group, village)}
                imageScale={trackerCategoryImageScale(group)}
                percent={summary.completion * 100}
                open={open}
                onToggle={() =>
                  setExpanded((current) => {
                    const next = new Set(current);
                    if (next.has(group)) next.delete(group);
                    else next.add(group);
                    return next;
                  })
                }
                footer={
                  <UpgradeSummaryMetrics
                    levels={summary.levelsRemaining}
                    seconds={summary.seconds}
                    costs={summary.costs}
                  />
                }
              >
                <UpgradeGroupTiles
                  group={group}
                  items={items}
                  snapshot={snapshot}
                  onSelect={setSelected}
                />
              </TrackerSummaryCard>
            </View>
          );
        })}
      </View>
      {!groups.length ? <EmptyState title={t('upgradeTrackerNoMatchingItems')} /> : null}
      <UpgradeItemDetailModal
        item={selected}
        snapshot={snapshot}
        onClose={() => setSelected(null)}
      />
    </Animated.ScrollView>
  );
}

function UpgradeSummaryMetrics({
  levels,
  seconds,
  costs,
}: {
  levels: number;
  seconds: number;
  costs: Readonly<Record<string, number>>;
}) {
  const { t, locale } = useI18n();
  const resources = Object.entries(costs).filter(([, amount]) => amount > 0);
  const fontSize = 12;
  const label =
    levels === 0 ? t('homeRecentlyCompleted') : t('gameItemLevelCount', { count: levels });
  return (
    <View
      style={{
        width: '100%',
        flexDirection: 'row',
        alignItems: 'center',
        gap: 6,
        flexWrap: 'nowrap',
      }}
    >
      <CKText role="bodyMedium" muted numberOfLines={1} style={{ fontSize, flexShrink: 1 }}>
        {label}
      </CKText>
      {levels > 0 && seconds > 0 ? (
        <CKText
          role="bodyMedium"
          muted
          numberOfLines={1}
          style={{ fontSize, flexShrink: 1 }}
          accessibilityLabel={`${t('gameItemUpgradeTime')}: ${formatTrackerDuration(seconds)}`}
        >
          · {formatTrackerDuration(seconds)}
        </CKText>
      ) : null}
      {resources.map(([resource, amount]) => (
        <View
          key={resource}
          style={{ flexDirection: 'row', alignItems: 'center', gap: 3, flexShrink: 1 }}
          accessible
          accessibilityLabel={`${planResourceLabel(resource, t)} ${amount}`}
        >
          <MobileWebImage
            imageUrl={planResourceImage(resource)}
            style={{ width: 15, height: 15 }}
          />
          <CKText role="bodyMedium" numberOfLines={1} style={{ fontSize, flexShrink: 1 }}>
            {compactNumber(amount, toIntlLocale(locale)).replace(/\.0(?=[KMB]$)/, '')}
          </CKText>
        </View>
      ))}
    </View>
  );
}

function UpgradeGroupTiles({
  group,
  items,
  snapshot,
  onSelect,
}: {
  group: UpgradeGroup;
  items: readonly UpgradeTrackerItem[];
  snapshot: UpgradeTrackerSnapshot;
  onSelect: (item: UpgradeTrackerItem) => void;
}) {
  const { t } = useI18n();
  const { width } = useWindowDimensions();
  if (group === 'craftedDefenses') {
    return <CraftedDefenseGroups items={items} snapshot={snapshot} onSelect={onSelect} />;
  }
  const sections: readonly (readonly [string, readonly UpgradeTrackerItem[]])[] =
    group === 'laboratory'
      ? [
          [
            t('gameTroops'),
            items.filter(
              (item) =>
                item.category === UpgradeCategory.troops ||
                item.category === UpgradeCategory.darkTroops,
            ),
          ],
          [t('gameSpells'), items.filter((item) => item.category === UpgradeCategory.spells)],
          [
            t('gameSiegeMachines'),
            items.filter((item) => item.category === UpgradeCategory.sieges),
          ],
        ]
      : group === 'equipment'
        ? equipmentHeroGroups(items, t)
        : [['', items]];
  return (
    <View style={styles.groupedTileSections}>
      {sections.map(([label, values]) =>
        values.length ? (
          <View key={label || group} style={styles.groupedTileSection}>
            {label ? (
              <View style={styles.groupedTileHeading}>
                {group === 'equipment' && label !== t('generalOthers') ? (
                  <MobileWebImage
                    imageUrl={ImageAssets.getHeroImage(label)}
                    style={styles.groupedTileHeadingImage}
                  />
                ) : null}
                <CKText role="labelLarge">{label}</CKText>
              </View>
            ) : null}
            <ResponsiveGrid
              minItemWidth={60}
              maxColumns={8}
              gap={8}
              waitForLayout
              initialWidth={Math.max(0, Math.min(width, 1180) - 56)}
            >
              {values.map((item) => (
                <UpgradeTile
                  key={`${item.planKey}-${item.id}`}
                  item={item}
                  active={snapshot.remainingActiveSeconds(item) > 0}
                  onPress={() => onSelect(item)}
                />
              ))}
            </ResponsiveGrid>
          </View>
        ) : null,
      )}
    </View>
  );
}

function CraftedDefenseGroups({
  items,
  snapshot,
  onSelect,
}: {
  items: readonly UpgradeTrackerItem[];
  snapshot: UpgradeTrackerSnapshot;
  onSelect: (item: UpgradeTrackerItem) => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [expanded, setExpanded] = useState<string | null>(null);
  const families = new Map<string, UpgradeTrackerItem[]>();
  for (const item of items) {
    const family = item.parentName ?? item.name;
    families.set(family, [...(families.get(family) ?? []), item]);
  }
  // Components remain independent scheduler jobs; only the browsing hierarchy
  // combines them. Summed levels describe progress, not an invented upgrade chain.
  return (
    <View style={{ gap: 12 }}>
      {[...families].map(([name, components]) => {
        const current = components.reduce((sum, item) => sum + item.currentLevel, 0);
        const target = components.reduce((sum, item) => sum + item.targetLevel, 0);
        const open = expanded === name;
        return (
          <View key={name}>
            <Pressable
              accessibilityRole="button"
              accessibilityState={{ expanded: open }}
              onPress={() => setExpanded(open ? null : name)}
              style={styles.craftedFamily}
            >
              <MobileWebImage
                imageUrl={components[0]?.imageUrl ?? ImageAssets.defaultImage}
                style={styles.itemImage}
              />
              <View style={styles.grow}>
                <CKText role="rowTitle">{name}</CKText>
                <CKText role="metadata" muted>
                  {t('gameLevel', { level: current, maxLevel: target })}
                </CKText>
              </View>
              <ChevronDown
                size={20}
                color={theme.onSurfaceVariant}
                style={{ transform: [{ rotate: open ? '180deg' : '0deg' }] }}
              />
            </Pressable>
            {open
              ? components.map((item) => (
                  <Pressable
                    key={item.planKey}
                    accessibilityRole="button"
                    onPress={() => onSelect(item)}
                    style={{
                      padding: 10,
                      marginTop: 8,
                      borderRadius: 12,
                      gap: 7,
                      backgroundColor: colorWithAlpha(theme.surfaceContainerHighest, 0.25),
                    }}
                  >
                    <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
                      <CKText role="bodyMedium" style={styles.grow}>
                        {item.name.startsWith(`${name} `)
                          ? item.name.slice(name.length + 1)
                          : item.name}
                      </CKText>
                      <CKText role="metadata" muted>
                        {item.currentLevel}/{item.targetLevel}
                      </CKText>
                      <ChevronRight size={16} color={theme.onSurfaceVariant} />
                    </View>
                    <UpgradeSummaryMetrics
                      levels={item.levelsRemaining}
                      seconds={item.totalSeconds}
                      costs={item.totalCosts}
                    />
                  </Pressable>
                ))
              : null}
          </View>
        );
      })}
    </View>
  );
}

export function formatSectionProgress(progress: number): string {
  const percentage = Math.max(0, Math.min(1, progress)) * 100;
  return Number.isInteger(percentage) ? `${percentage}` : percentage.toFixed(1);
}

function equipmentHeroGroups(items: readonly UpgradeTrackerItem[], t: I18nValue['t']) {
  const preferred = [
    'Barbarian King',
    'Archer Queen',
    'Grand Warden',
    'Royal Champion',
    'Minion Prince',
  ];
  const groups = new Map<string, UpgradeTrackerItem[]>();
  for (const item of items) {
    const raw = item.meta?.hero;
    const hero = typeof raw === 'string' && raw.trim() ? raw.trim() : t('generalOthers');
    groups.set(hero, [...(groups.get(hero) ?? []), item]);
  }
  return [...groups].sort(([left], [right]) => {
    const leftIndex = preferred.indexOf(left);
    const rightIndex = preferred.indexOf(right);
    if (leftIndex >= 0 && rightIndex >= 0) return leftIndex - rightIndex;
    if (leftIndex >= 0) return -1;
    if (rightIndex >= 0) return 1;
    return left.localeCompare(right);
  });
}

function ActiveQueueSummary({
  snapshot,
  village,
}: {
  snapshot: UpgradeTrackerSnapshot;
  village: UpgradeVillageValue;
}) {
  const { t } = useI18n();
  const queues = ongoingUpgradeQueues(snapshot, village);
  return (
    <ResponsiveGrid minItemWidth={90} maxColumns={3} gap={12} fillLastRow>
      {queues.map(({ queue, capacity, used, free, times, extra }) => {
        const label =
          queue === UpgradeQueue.builders
            ? t('dashboardUpgradeTrackerBuilders')
            : queue === UpgradeQueue.laboratory
              ? t('upgradeTrackerLaboratory')
              : t('upgradeTrackerPetHouse');
        const image =
          queue === UpgradeQueue.builders
            ? trackerCategoryImage('builders', village)
            : queue === UpgradeQueue.laboratory
              ? trackerCategoryImage('laboratory', village)
              : ImageAssets.getHomeVillageBuildingImage('Pet House', 1);
        const status =
          capacity === 0
            ? t('upgradeTrackerNotBuilt')
            : free > 0
              ? t('upgradeTrackerFreeSlots', { count: free })
              : t('upgradeTrackerFreeIn', { duration: formatTrackerDuration(Math.min(...times)) });
        return (
          <View key={queue} style={{ gap: 3 }}>
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 5 }}>
              <MobileWebImage imageUrl={image} style={{ width: 20, height: 20 }} />
              <CKText role="metadata" style={{ flexShrink: 1 }}>
                {label}
              </CKText>
            </View>
            <CKText role="rowTitle">
              {used}/{capacity}
            </CKText>
            {extra > 0 ? (
              <CKText muted role="metadata">
                · {t('upgradeTrackerExtraSlots', { count: extra })}
              </CKText>
            ) : null}
            <CKText muted role="metadata">
              {status}
            </CKText>
          </View>
        );
      })}
    </ResponsiveGrid>
  );
}

function ActiveUpgradeEffects({
  snapshot,
  village,
}: {
  snapshot: UpgradeTrackerSnapshot;
  village: UpgradeVillageValue;
}) {
  const theme = useCKTheme();
  // Fast Refresh can retain snapshots built before this field existed.
  // Treat those as having no parsed effect metadata until the next load.
  const effects = (snapshot.boosts.activeEffects ?? []).flatMap((effect) => {
    const remaining = snapshot.remainingCapturedSeconds(effect.seconds);
    return effect.village === village && remaining > 0 ? [{ ...effect, remaining }] : [];
  });
  if (!effects.length) return null;
  return (
    <View style={{ flexDirection: 'row', flexWrap: 'wrap', justifyContent: 'flex-end', gap: 4 }}>
      {effects.map((effect) => (
        <View
          key={effect.key}
          accessible
          accessibilityLabel={`${translationForTid(effect.nameTid) ?? effect.name}, ${formatTrackerDuration(effect.remaining)}`}
          style={{
            flexDirection: 'row',
            alignItems: 'center',
            gap: 3,
            paddingHorizontal: 5,
            paddingVertical: 4,
            borderRadius: ckRadius.pill,
            backgroundColor: theme.surface,
          }}
        >
          <MobileWebImage imageUrl={effect.imageUrl} style={{ width: 20, height: 20 }} />
          <CKText role="metadata">{formatTrackerDuration(effect.remaining)}</CKText>
        </View>
      ))}
    </View>
  );
}

function CurrentUpgradeRow({
  item,
  snapshot,
  onPress,
}: {
  item: UpgradeTrackerItem;
  snapshot: UpgradeTrackerSnapshot;
  onPress: () => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const remaining = snapshot.remainingActiveSeconds(item);
  const helperRemaining = snapshot.remainingHelperSeconds(item);
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={item.name}
      onPress={onPress}
      style={styles.currentUpgradeRow}
    >
      <MobileWebImage imageUrl={item.imageUrl} style={{ width: 38, height: 38 }} />
      <View style={styles.grow}>
        <View style={{ flexDirection: 'row', alignItems: 'center', gap: 5 }}>
          <CKText role="rowTitle" numberOfLines={1} style={{ flexShrink: 1 }}>
            {item.parentName ?? item.name}
          </CKText>
          {item.isSupercharge ? (
            <MobileWebImage
              imageUrl={trackerCategoryImage('supercharge', item.village)}
              accessibilityLabel={t('upgradeTrackerPlanCategorySupercharge')}
              style={{ width: 20, height: 20 }}
            />
          ) : null}
        </View>
        <CKText muted role="metadata" numberOfLines={1}>
          {item.parentName && !item.isSupercharge
            ? `${item.name.replace(`${item.parentName} `, '')} · `
            : ''}
          {t('upgradeTrackerToLevel', {
            level: item.steps[0]?.targetLevel ?? item.currentLevel + 1,
          })}
        </CKText>
        {helperRemaining > 0 ? (
          <View
            accessible
            accessibilityLabel={`${snapshot.helperNameFor(item)}, ${formatTrackerDuration(helperRemaining)}`}
            style={{ flexDirection: 'row', alignItems: 'center', gap: 4, marginTop: 3 }}
          >
            <MobileWebImage
              imageUrl={ImageAssets.getHelperImage(
                item.queue === UpgradeQueue.laboratory ? 'Lab Assistant' : "Builder's Apprentice",
              )}
              style={{ width: 20, height: 20 }}
            />
            <CKText muted role="metadata">
              {formatTrackerDuration(helperRemaining)}
            </CKText>
          </View>
        ) : null}
      </View>
      <CKText role="bodyMedium">{formatTrackerDuration(remaining)}</CKText>
      <ChevronRight size={18} color={theme.onSurfaceVariant} />
    </Pressable>
  );
}

type UpgradeGroup =
  | 'buildings'
  | 'defenses'
  | 'craftedDefenses'
  | 'traps'
  | 'supercharges'
  | 'heroes'
  | 'guardians'
  | 'laboratory'
  | 'equipment'
  | 'pets'
  | 'walls'
  | 'helpers';

function upgradeGroupFor(category: string): UpgradeGroup {
  if (category === UpgradeCategory.army || category === UpgradeCategory.resources)
    return 'buildings';
  if (category === UpgradeCategory.defenses) return 'defenses';
  if (category === UpgradeCategory.craftedDefenses) return 'craftedDefenses';
  if (category === UpgradeCategory.traps) return 'traps';
  if (category === UpgradeCategory.supercharge) return 'supercharges';
  if (category === UpgradeCategory.heroes) return 'heroes';
  if (category === UpgradeCategory.guardians) return 'guardians';
  if (
    category === UpgradeCategory.troops ||
    category === UpgradeCategory.darkTroops ||
    category === UpgradeCategory.spells ||
    category === UpgradeCategory.sieges
  )
    return 'laboratory';
  if (category === UpgradeCategory.equipment) return 'equipment';
  if (category === UpgradeCategory.pets) return 'pets';
  if (category === UpgradeCategory.walls) return 'walls';
  return 'helpers';
}

const upgradeGroupOrder: readonly UpgradeGroup[] = [
  'buildings',
  'defenses',
  'craftedDefenses',
  'traps',
  'supercharges',
  'heroes',
  'guardians',
  'laboratory',
  'equipment',
  'pets',
  'walls',
  'helpers',
];

function groupedUpgradeItems(
  items: readonly UpgradeTrackerItem[],
  village: UpgradeVillageValue,
): readonly [UpgradeGroup, UpgradeTrackerItem[]][] {
  const values = new Map<UpgradeGroup, UpgradeTrackerItem[]>();
  for (const item of items) {
    // Crafting Station has no upgrade progression. It is an export container,
    // not a defense that the player can schedule or improve.
    if (item.id === 1000097 && item.steps.length === 0) continue;
    // Builder Base camps are capacity unlocks, not upgradeable buildings. Keep
    // their imported data intact, but do not present them as upgrade targets.
    if (
      village === UpgradeVillage.builderBase &&
      item.name.toLowerCase().replace(/[^a-z]/g, '') === 'armycamp' &&
      item.steps.length === 0
    )
      continue;
    const group = upgradeGroupFor(item.category);
    if (
      group === 'helpers' &&
      (village === UpgradeVillage.home
        ? item.queue !== UpgradeQueue.none
        : item.queue !== UpgradeQueue.builders)
    )
      continue;
    values.set(group, [...(values.get(group) ?? []), item]);
  }
  return upgradeGroupOrder.flatMap((group) => {
    const groupItems = values.get(group);
    return groupItems?.length ? [[group, groupItems] as [UpgradeGroup, UpgradeTrackerItem[]]] : [];
  });
}

function upgradeGroupLabel(group: UpgradeGroup, village: UpgradeVillageValue, t: I18nValue['t']) {
  const labels: Record<UpgradeGroup, string> = {
    buildings: t('gameAssetsCategoryBuildings'),
    defenses: t('warDefensesTitle'),
    craftedDefenses: t('upgradeTrackerPlanCategoryCraftedDefenses'),
    traps: t('upgradeTrackerPlanCategoryTraps'),
    supercharges: t('upgradeTrackerPlanCategorySupercharge'),
    heroes: t('gameHeroes'),
    guardians: t('gameAssetsCategoryGuardians'),
    laboratory: t('upgradeTrackerLaboratory'),
    equipment: t('upgradeTrackerEquipment'),
    pets: t('upgradeTrackerPets'),
    walls: t('upgradeTrackerWalls'),
    helpers:
      village === UpgradeVillage.home
        ? t('upgradeTrackerHelpers')
        : t('dashboardUpgradeTrackerBuilders'),
  };
  return labels[group];
}

function UpgradeTile({
  item,
  active,
  onPress,
}: {
  item: UpgradeTrackerItem;
  active: boolean;
  onPress: () => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const themeMode = useCKThemeMode();
  const containedArt = usesContainedUpgradeArt(item.category);
  const lockedEquipment = item.category === UpgradeCategory.equipment && item.isUnbuilt;
  const frameBackground =
    item.category === UpgradeCategory.equipment
      ? String(item.meta?.rarity ?? '') === '2'
        ? '#800080'
        : '#1976D2'
      : 'transparent';
  const frameBorder = active
    ? theme.primary
    : item.isComplete
      ? '#FFD75E'
      : themeMode === 'dark'
        ? '#FFFFFFE0'
        : '#000000DE';
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={
        lockedEquipment
          ? `${item.name}, ${t('widgetNotUnlocked')}`
          : t('upgradeTrackerItemSemanticLabel', {
              item: item.name,
              currentLevel: item.currentLevel,
              targetLevel: item.targetLevel,
              count: item.count,
            })
      }
      onPress={onPress}
    >
      <View
        style={[
          styles.upgradeTile,
          {
            backgroundColor: lockedEquipment ? theme.surfaceContainerHighest : frameBackground,
            borderColor: frameBorder,
            shadowColor: item.isComplete ? frameBorder : 'transparent',
          },
        ]}
      >
        <View style={[styles.upgradeTileArt, containedArt && styles.upgradeTileContainedArt]}>
          <MobileWebImage
            imageUrl={item.imageUrl}
            fallbackImageUrls={
              item.name === 'Blacksmith'
                ? [ImageAssets.getHomeVillageBuildingImage('Blacksmith', 1)]
                : undefined
            }
            displaySize={{ width: 64, height: 64 }}
            transition={0}
            contentFit={containedArt ? 'contain' : 'cover'}
            style={[styles.upgradeTileImage, lockedEquipment && { opacity: 0.35 }]}
          />
        </View>
        <View style={[styles.levelBadge, item.isComplete && styles.levelBadgeComplete]}>
          {lockedEquipment ? (
            <Lock size={12} color={theme.onSurfaceVariant} />
          ) : (
            <CKText
              role="labelSmall"
              style={item.isComplete ? styles.levelBadgeTextComplete : styles.levelBadgeText}
            >
              {item.currentLevel}
            </CKText>
          )}
        </View>
        {item.count > 1 ? (
          <View style={styles.countBadge}>
            <CKText role="labelSmall" style={styles.levelBadgeText}>
              ×{item.count}
            </CKText>
          </View>
        ) : null}
      </View>
    </Pressable>
  );
}

export function usesContainedUpgradeArt(category: string): boolean {
  return new Set<string>([
    UpgradeCategory.defenses,
    UpgradeCategory.traps,
    UpgradeCategory.craftedDefenses,
    UpgradeCategory.army,
    UpgradeCategory.resources,
    UpgradeCategory.walls,
    UpgradeCategory.supercharge,
  ]).has(category);
}

function CalendarTab({
  snapshot,
  plan,
  now,
  stateStore,
  contentInset,
  initialOffset,
  onScroll,
  onScrollSettled,
}: {
  snapshot: UpgradeTrackerSnapshot;
  plan: ReturnType<typeof buildTrackerPlanData>;
  now: Date;
  stateStore: Map<string, unknown>;
  contentInset: number;
  initialOffset: number;
  onScroll: (event: NativeSyntheticEvent<NativeScrollEvent>) => void;
  onScrollSettled: (event: NativeSyntheticEvent<NativeScrollEvent>) => void;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const loading = useSkeletonContent();
  const [expanded, setExpanded] = useCachedPageState<ReadonlySet<string>>(
    stateStore,
    'calendar.expanded',
    () =>
      new Set(['home-builders', 'builder-builders', 'laboratory', 'builder-laboratory', 'pets']),
  );
  const [horizontalOffset, setHorizontalOffset] = useCachedPageState(
    stateStore,
    'calendar.horizontalOffset',
    0,
  );
  const initialContentOffset = useInitialScrollOffset(initialOffset);
  const [initialHorizontalContentOffset] = useState(() => ({ x: horizontalOffset, y: 0 }));
  const [visibleHorizontalOffset, setVisibleHorizontalOffset] = useState(horizontalOffset);
  const viewportWidth = useWindowDimensions().width;
  const commitHorizontalScroll = (event: NativeSyntheticEvent<NativeScrollEvent>) => {
    const offset = Math.max(0, event.nativeEvent.contentOffset.x);
    setHorizontalOffset(offset);
  };
  const [selected, setSelected] = useState<PlannedUpgrade | null>(null);
  const [shortUpgrades, setShortUpgrades] = useState<readonly PlannedUpgrade[]>([]);
  const groups = useMemo(
    () =>
      [
        [
          'home-builders',
          t('dashboardUpgradeTrackerBuilders'),
          UpgradeQueue.builders,
          snapshot.homeBuilderCount,
          plan.homeBuilders,
          '#4D9DE0',
        ],
        [
          'builder-builders',
          t('upgradeTrackerBuilderBaseBuilders'),
          UpgradeQueue.builders,
          snapshot.builderBaseBuilderCount,
          plan.builderBuilders,
          '#E7953D',
        ],
        [
          'laboratory',
          t('upgradeTrackerLaboratory'),
          UpgradeQueue.laboratory,
          1,
          plan.laboratory,
          '#9B6DE3',
        ],
        [
          'builder-laboratory',
          t('upgradeTrackerBuilderBaseLaboratory'),
          UpgradeQueue.laboratory,
          1,
          plan.builderLaboratory,
          '#43B3AE',
        ],
        ['pets', t('upgradeTrackerPets'), UpgradeQueue.pets, 1, plan.pets, '#E56B9F'],
      ] as const,
    [plan, snapshot, t],
  );
  const allCalendarUpgrades = useMemo(
    () => groups.flatMap(([, , , , lanes]) => lanes.flatMap((lane) => lane.upgrades)),
    [groups],
  );
  const start = new Date(plan.startsAt);
  start.setHours(0, 0, 0, 0);
  const latest = useMemo(
    () =>
      allCalendarUpgrades.reduce<Date | null>(
        (value, upgrade) => (!value || upgrade.endsAt > value ? upgrade.endsAt : value),
        null,
      ),
    [allCalendarUpgrades],
  );
  // The canvas represents the full finite plan. Only nearby labels and events mount,
  // so long plans do not create thousands of native date views or require pagination.
  const firstDay = start;
  const windowDays = Math.max(
    7,
    latest ? Math.ceil((latest.getTime() - start.getTime()) / 86_400_000) + 1 : 7,
  );
  const horizonEnd = new Date(firstDay.getTime() + windowDays * 86_400_000);
  const dayWidth = 144;
  const labelWidth = 64;
  const timelineWidth = dayWidth * windowDays;
  // Only mount nearby blocks. The date canvas can cover months without mounting the whole plan.
  const visibleStartDay = Math.min(
    windowDays - 1,
    Math.max(0, Math.floor(visibleHorizontalOffset / dayWidth) - 2),
  );
  const visibleEndDay = Math.max(
    visibleStartDay + 1,
    Math.min(windowDays, Math.ceil((visibleHorizontalOffset + viewportWidth) / dayWidth) + 2),
  );
  const renderStart = new Date(firstDay.getTime() + visibleStartDay * 86_400_000);
  const renderEnd = new Date(firstDay.getTime() + visibleEndDay * 86_400_000);
  const visibleGroups = groups.filter(([, , , , lanes]) =>
    lanes.some((lane) => lane.upgrades.length),
  );
  const toggle = (key: string) =>
    setExpanded((value) => {
      const next = new Set(value);
      if (next.has(key)) next.delete(key);
      else next.add(key);
      return next;
    });
  return (
    <Animated.ScrollView
      testID="upgrade-tracker-calendar-scroll"
      contentContainerStyle={[styles.calendarRoot, { paddingTop: contentInset + 4 }]}
      contentOffset={initialContentOffset}
      onScroll={onScroll}
      onMomentumScrollEnd={onScrollSettled}
      onScrollEndDrag={onScrollSettled}
      scrollEventThrottle={16}
    >
      <View style={{ position: 'relative', marginLeft: labelWidth }}>
        <Animated.ScrollView
          testID="upgrade-tracker-calendar-timeline"
          contentOffset={initialHorizontalContentOffset}
          directionalLockEnabled
          horizontal
          nestedScrollEnabled
          onScroll={(event) =>
            setVisibleHorizontalOffset(
              Math.floor(Math.max(0, event.nativeEvent.contentOffset.x) / dayWidth) * dayWidth,
            )
          }
          onMomentumScrollEnd={commitHorizontalScroll}
          onScrollEndDrag={commitHorizontalScroll}
          scrollEventThrottle={64}
          showsHorizontalScrollIndicator
        >
          <View style={styles.calendarContent}>
            <View style={{ width: timelineWidth }}>
              <View style={styles.calendarDayHeader}>
                {Array.from({ length: visibleEndDay - visibleStartDay }, (_, offset) => {
                  const index = visibleStartDay + offset;
                  const day = new Date(firstDay.getTime() + index * 86_400_000);
                  const today = sameDay(day, now);
                  return (
                    <CKText
                      key={day.toISOString()}
                      role="metadata"
                      style={[
                        styles.calendarDay,
                        { position: 'absolute', left: index * dayWidth, width: dayWidth },
                        today && styles.calendarTodayText,
                      ]}
                    >
                      {today
                        ? t('homeToday')
                        : day.toLocaleDateString(toIntlLocale(locale), {
                            month: 'short',
                            day: 'numeric',
                          })}
                    </CKText>
                  );
                })}
              </View>
              {visibleGroups.map(([key, , , , lanes, accent]) => {
                return (
                  <Surface key={key} radius={ckRadius.card} style={styles.calendarSection}>
                    <View style={{ height: 36 }} />
                    {expanded.has(key)
                      ? lanes
                          .filter((lane) => lane.upgrades.length)
                          .map((lane) => (
                            <View
                              key={`${key}-${lane.index}`}
                              style={[styles.calendarLane, { width: timelineWidth }]}
                            >
                              <View
                                style={[styles.calendarGrid, { left: 0, width: timelineWidth }]}
                              >
                                {Array.from(
                                  { length: visibleEndDay - visibleStartDay },
                                  (_, offset) => (
                                    <View
                                      key={visibleStartDay + offset}
                                      style={[
                                        styles.calendarGridDay,
                                        {
                                          left: (visibleStartDay + offset) * dayWidth,
                                          width: dayWidth,
                                        },
                                      ]}
                                    />
                                  ),
                                )}
                                {loading ? (
                                  <Skeleton
                                    width={Math.max(240, viewportWidth - labelWidth - 32)}
                                    height={56}
                                    radius={12}
                                  />
                                ) : (
                                  calendarTimelineEntries(
                                    lane.upgrades.filter(
                                      (upgrade) =>
                                        upgrade.endsAt > renderStart &&
                                        upgrade.startsAt < renderEnd,
                                    ),
                                    firstDay,
                                    dayWidth,
                                  ).map((entry, index) => {
                                    const upgrade = entry[0]!;
                                    const visibleStart =
                                      upgrade.startsAt < firstDay ? firstDay : upgrade.startsAt;
                                    const entryEnd = entry[entry.length - 1]!.endsAt;
                                    const visibleEnd =
                                      entryEnd > horizonEnd ? horizonEnd : entryEnd;
                                    const left =
                                      ((visibleStart.getTime() - firstDay.getTime()) / 86_400_000) *
                                      dayWidth;
                                    const width = Math.max(
                                      1,
                                      ((visibleEnd.getTime() - visibleStart.getTime()) /
                                        86_400_000) *
                                        dayWidth,
                                    );
                                    if (entry.length > 1 || width < 56)
                                      return (
                                        <Pressable
                                          key={`short-${index}`}
                                          accessibilityRole="button"
                                          accessibilityLabel={t('upgradeTrackerItemCount', {
                                            count: entry.length,
                                          })}
                                          onPress={() =>
                                            entry.length > 1
                                              ? setShortUpgrades(entry)
                                              : setSelected(upgrade)
                                          }
                                          hitSlop={{
                                            top: 8,
                                            bottom: 8,
                                            left: Math.max(0, (44 - width) / 2),
                                            right: Math.max(0, (44 - width) / 2),
                                          }}
                                          style={[
                                            styles.calendarShortBlock,
                                            {
                                              left,
                                              width: Math.max(4, width - 2),
                                              backgroundColor: colorWithAlpha(accent, 0.22),
                                              borderColor: accent,
                                            },
                                          ]}
                                        >
                                          {width >= 26 ? (
                                            <MobileWebImage
                                              imageUrl={upgrade.item.imageUrl}
                                              style={{ width: 26, height: 26 }}
                                            />
                                          ) : null}
                                          {width >= 40 ? (
                                            <CKText role="metadata" numberOfLines={1}>
                                              {entry.length > 1
                                                ? `×${entry.length}`
                                                : formatTrackerDuration(
                                                    (upgrade.endsAt.getTime() -
                                                      upgrade.startsAt.getTime()) /
                                                      1000,
                                                  )}
                                            </CKText>
                                          ) : null}
                                        </Pressable>
                                      );
                                    return (
                                      <TimelineBlock
                                        key={`${upgrade.item.planKey}-${upgrade.instance}-${index}`}
                                        upgrade={upgrade}
                                        left={left}
                                        width={width}
                                        accent={accent}
                                        onPress={() => setSelected(upgrade)}
                                      />
                                    );
                                  })
                                )}
                                {!loading && now >= firstDay && now < horizonEnd ? (
                                  <View
                                    pointerEvents="none"
                                    style={[
                                      styles.calendarNowLine,
                                      {
                                        left:
                                          ((now.getTime() - firstDay.getTime()) / 86_400_000) *
                                          dayWidth,
                                      },
                                    ]}
                                  />
                                ) : null}
                              </View>
                            </View>
                          ))
                      : null}
                  </Surface>
                );
              })}
            </View>
          </View>
        </Animated.ScrollView>
        {/* This rail is a sibling of the horizontal scroller, not a translated child.
          Its position cannot drift during native momentum scrolling or rubber-banding. */}
        <View
          pointerEvents="box-none"
          style={{ position: 'absolute', top: 52, left: -labelWidth, right: 0 }}
        >
          {visibleGroups.map(([key, title, queue, capacity, lanes]) => (
            <View key={key} pointerEvents="box-none" style={{ paddingTop: 10, paddingBottom: 22 }}>
              <Pressable
                accessibilityRole="button"
                accessibilityState={{ expanded: expanded.has(key) }}
                onPress={() => toggle(key)}
                style={[styles.calendarSectionHeader, { backgroundColor: theme.card }]}
              >
                <MobileWebImage
                  imageUrl={calendarGroupImage(snapshot, key)}
                  style={styles.calendarGroupImage}
                />
                <CKText role="rowTitle" style={styles.grow}>
                  {title}
                </CKText>
                <ChevronRight
                  size={18}
                  color={theme.onSurfaceVariant}
                  style={{ transform: [{ rotate: expanded.has(key) ? '90deg' : '0deg' }] }}
                />
              </Pressable>
              {expanded.has(key)
                ? lanes
                    .filter((lane) => lane.upgrades.length)
                    .map((lane) => (
                      <View
                        key={lane.index}
                        style={[
                          styles.calendarFixedLaneLabel,
                          { backgroundColor: theme.card, width: labelWidth },
                        ]}
                      >
                        <CKText muted role="metadata" numberOfLines={1}>
                          {planLaneLabel(queue, lane.index, capacity)}
                        </CKText>
                      </View>
                    ))
                : null}
            </View>
          ))}
        </View>
      </View>
      {selected ? (
        <PlannedUpgradeModal upgrade={selected} onClose={() => setSelected(null)} />
      ) : null}
      <ChoiceModal
        visible={shortUpgrades.length > 0}
        title={t('upgradeTrackerItemCount', { count: shortUpgrades.length })}
        onClose={() => setShortUpgrades([])}
      >
        {shortUpgrades.map((upgrade, index) => (
          <PressableSurface
            key={index}
            onPress={() => {
              setShortUpgrades([]);
              setSelected(upgrade);
            }}
            style={styles.row}
          >
            <MobileWebImage imageUrl={upgrade.item.imageUrl} style={styles.itemImage} />
            <View style={styles.grow}>
              <CKText role="rowTitle">{upgrade.item.name}</CKText>
              <CKText role="metadata" muted>
                {t('upgradeTrackerLevelTransition', {
                  from: upgrade.step.targetLevel - 1,
                  to: upgrade.step.targetLevel,
                })}{' '}
                ·{' '}
                {formatTrackerDuration(
                  (upgrade.endsAt.getTime() - upgrade.startsAt.getTime()) / 1000,
                )}
              </CKText>
            </View>
            <ChevronRight size={20} color={theme.onSurfaceVariant} />
          </PressableSurface>
        ))}
      </ChoiceModal>
    </Animated.ScrollView>
  );
}

/** Adjacent small events share a detail target; their visual width remains true to time. */
function calendarTimelineEntries(
  upgrades: readonly PlannedUpgrade[],
  firstDay: Date,
  dayWidth: number,
) {
  const entries: PlannedUpgrade[][] = [];
  let previousShortEnd = -1;
  for (const upgrade of upgrades) {
    const width =
      ((upgrade.endsAt.getTime() - Math.max(firstDay.getTime(), upgrade.startsAt.getTime())) /
        86_400_000) *
      dayWidth;
    const left = Math.max(
      0,
      ((upgrade.startsAt.getTime() - firstDay.getTime()) / 86_400_000) * dayWidth,
    );
    // Never inflate a short event across the next long upgrade. It obscures the start
    // of that upgrade and makes the schedule appear to contain simultaneous work.
    if (width < 56 && left < previousShortEnd) entries[entries.length - 1]!.push(upgrade);
    else {
      entries.push([upgrade]);
      previousShortEnd = width < 56 ? left + 56 : -1;
    }
  }
  return entries;
}

function sameDay(left: Date, right: Date) {
  return (
    left.getFullYear() === right.getFullYear() &&
    left.getMonth() === right.getMonth() &&
    left.getDate() === right.getDate()
  );
}

function calendarGroupImage(snapshot: UpgradeTrackerSnapshot, key: string) {
  if (key === 'builder-builders') return ImageAssets.builderHall(snapshot.builderHallLevel);
  const names: Record<string, string> = {
    'home-builders': "Builder's Hut",
    laboratory: 'Laboratory',
    'builder-laboratory': 'Star Laboratory',
    pets: 'Pet House',
  };
  const name = names[key];
  return snapshot.items.find((item) => item.name === name)?.imageUrl ?? ImageAssets.defaultImage;
}

function TimelineBlock({
  upgrade,
  left,
  width,
  accent,
  onPress,
}: {
  upgrade: PlannedUpgrade;
  left: number;
  width: number;
  accent: string;
  onPress: () => void;
}) {
  const { locale, t } = useI18n();
  const intlLocale = toIntlLocale(locale);
  const iconOnly = width < 78;
  const metadata = width >= 168;
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={t('upgradeTrackerTimelineSemanticLabel', {
        item: upgrade.item.name,
        level: upgrade.step.targetLevel,
        start: upgrade.startsAt.toLocaleString(intlLocale),
        end: upgrade.endsAt.toLocaleString(intlLocale),
      })}
      onPress={onPress}
      style={[
        styles.calendarBlock,
        {
          left: left + 0.75,
          width: Math.max(1, width - 1.5),
          borderColor: upgrade.isOngoing ? '#4F91FF' : accent,
          borderWidth: upgrade.isOngoing ? 2 : 1,
          backgroundColor: `${accent}38`,
        },
      ]}
    >
      {width >= 24 ? (
        <>
          <View style={[styles.calendarBlockAccent, { backgroundColor: accent }]} />
          <View style={[styles.calendarBlockBody, iconOnly && styles.calendarBlockCompact]}>
            <View style={styles.calendarBlockIconWrap}>
              <MobileWebImage
                imageUrl={upgrade.item.imageUrl}
                contentFit="contain"
                style={styles.calendarBlockIcon}
              />
              <View style={styles.calendarBlockLevel}>
                <CKText role="labelSmall" style={styles.calendarBlockLevelText}>
                  {upgrade.step.targetLevel}
                </CKText>
              </View>
            </View>
            {!iconOnly ? (
              <View style={styles.grow}>
                <CKText role="rowTitle" numberOfLines={1}>
                  {upgrade.item.name}
                </CKText>
                {metadata ? (
                  <CKText muted role="metadata" numberOfLines={1}>
                    {t('upgradeTrackerLevelTransition', {
                      from: upgrade.step.targetLevel - 1,
                      to: upgrade.step.targetLevel,
                    })}{' '}
                    ·{' '}
                    {formatTrackerDuration(
                      (upgrade.endsAt.getTime() - upgrade.startsAt.getTime()) / 1000,
                    )}
                  </CKText>
                ) : null}
              </View>
            ) : null}
          </View>
        </>
      ) : null}
    </Pressable>
  );
}

function PlannedUpgradeModal({
  upgrade,
  onClose,
}: {
  upgrade: PlannedUpgrade;
  onClose: () => void;
}) {
  const { locale, t } = useI18n();
  const theme = useCKTheme();
  const intlLocale = toIntlLocale(locale);
  const formatScheduleDate = (date: Date) =>
    new Intl.DateTimeFormat(intlLocale, {
      day: 'numeric',
      month: 'short',
      ...(date.getFullYear() !== new Date().getFullYear() ? { year: 'numeric' as const } : {}),
      hour: 'numeric',
      minute: '2-digit',
    }).format(date);
  return (
    <Modal
      supportedOrientations={modalOrientations}
      visible
      transparent
      animationType="fade"
      onRequestClose={onClose}
    >
      <View style={[styles.overlay, { justifyContent: 'center', padding: 20 }]}>
        <Pressable
          testID="planned-upgrade-modal-backdrop"
          accessible={false}
          onPress={onClose}
          style={StyleSheet.absoluteFill}
        />
        <Surface
          accessibilityViewIsModal
          onAccessibilityEscape={onClose}
          radius={ckRadius.card}
          style={styles.modal}
        >
          <View style={styles.detailHero}>
            <MobileWebImage
              imageUrl={upgrade.item.imageUrl}
              contentFit="contain"
              style={styles.timelineDetailImage}
            />
            <View style={styles.grow}>
              <CKText role="titleMedium">{upgrade.item.parentName ?? upgrade.item.name}</CKText>
              <CKText muted role="bodySmall">
                {t('upgradeTrackerLevelTransition', {
                  from: upgrade.step.targetLevel - 1,
                  to: upgrade.step.targetLevel,
                })}{' '}
                ·{' '}
                {upgrade.item.village === UpgradeVillage.home
                  ? t('upgradeTrackerHomeVillage')
                  : t('upgradeTrackerBuilderBase')}{' '}
              </CKText>
            </View>
            <IconButton label={t('upgradeTrackerPlanClose')} onPress={onClose}>
              <X color={theme.onSurface} />
            </IconButton>
          </View>
          <View style={{ gap: 4, paddingVertical: 6 }}>
            <TimelineDetailMetric
              label={t('warAttacksDetailsDuration')}
              value={formatTrackerDuration(
                (upgrade.endsAt.getTime() - upgrade.startsAt.getTime()) / 1000,
              )}
            />
            <TimelineDetailMetric
              label={t('upgradeTrackerStarts')}
              value={formatScheduleDate(upgrade.startsAt)}
            />
            <TimelineDetailMetric
              label={t('upgradeTrackerHeaderFinishes')}
              value={formatScheduleDate(upgrade.endsAt)}
            />
          </View>
          {upgrade.costs.length ? (
            <>
              <CKText role="bodyMedium" muted>
                {t('gameItemUpgradeCost')}
              </CKText>
              <View style={styles.wrap}>
                {upgrade.costs.map((cost) => (
                  <View
                    key={`${cost.resource}-${cost.amount}`}
                    style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}
                  >
                    <MobileWebImage
                      imageUrl={planResourceImage(cost.resource)}
                      style={{ width: 24, height: 24 }}
                    />
                    <CKText role="bodyMedium">
                      {compactNumber(cost.amount, intlLocale)} {planResourceLabel(cost.resource, t)}
                    </CKText>
                  </View>
                ))}
              </View>
            </>
          ) : null}
        </Surface>
      </View>
    </Modal>
  );
}

function TimelineDetailMetric({ label, value }: { label: string; value: string }) {
  return (
    <View
      style={{
        minHeight: 38,
        flexDirection: 'row',
        gap: 14,
        alignItems: 'center',
        justifyContent: 'space-between',
      }}
    >
      <CKText muted role="bodyMedium">
        {label}
      </CKText>
      <CKText role="bodyMedium" style={{ flex: 1, textAlign: 'right' }}>
        {value}
      </CKText>
    </View>
  );
}

function PlanTab({
  plan,
  onPriorities,
  onGoldPass,
  goldPassPercent = 0,
  stateStore,
  contentInset,
  initialOffset,
  onScroll,
  onScrollSettled,
}: {
  plan: ReturnType<typeof buildTrackerPlanData>;
  onPriorities?: () => void;
  onGoldPass?: () => void;
  goldPassPercent?: number;
  stateStore: Map<string, unknown>;
  contentInset: number;
  initialOffset: number;
  onScroll: (event: NativeSyntheticEvent<NativeScrollEvent>) => void;
  onScrollSettled: (event: NativeSyntheticEvent<NativeScrollEvent>) => void;
}) {
  const { locale, t } = useI18n();
  const theme = useCKTheme();
  const intlLocale = toIntlLocale(locale);
  const viewportWidth = useWindowDimensions().width;
  const desktop = Platform.OS === 'web' && viewportWidth >= 900;
  const [village, setVillage] = useCachedPageState<'all' | 'home' | 'builderBase'>(
    stateStore,
    'plan.village',
    'all',
  );
  const [queue, setQueue] = useCachedPageState<
    'all' | 'builders' | 'laboratory' | 'pets' | 'walls'
  >(stateStore, 'plan.queue', 'all');
  const [sort, setSort] = useCachedPageState<'scheduled' | 'name' | 'long' | 'short'>(
    stateStore,
    'plan.sort',
    'scheduled',
  );
  const initialContentOffset = useInitialScrollOffset(initialOffset);
  const [selectedUpgrade, setSelectedUpgrade] = useState<PlannedUpgrade | null>(null);
  const [visibleCount, setVisibleCount] = useState(40);
  const upgrades = plan.upgrades
    .filter((upgrade) => {
      const villageMatch =
        village === 'all' ||
        upgrade.item.village ===
          (village === 'home' ? UpgradeVillage.home : UpgradeVillage.builderBase);
      const queueMatch =
        queue === 'all' ||
        (queue === 'walls'
          ? upgrade.item.category === UpgradeCategory.walls
          : queue === 'builders'
            ? upgrade.item.queue === UpgradeQueue.builders &&
              upgrade.item.category !== UpgradeCategory.walls
            : upgrade.item.queue === queue);
      return villageMatch && queueMatch;
    })
    .sort((left, right) => {
      const duration = (upgrade: (typeof plan.upgrades)[number]) =>
        upgrade.endsAt.getTime() - upgrade.startsAt.getTime();
      const primary =
        sort === 'scheduled'
          ? left.startsAt.getTime() - right.startsAt.getTime()
          : sort === 'name'
            ? left.item.name.localeCompare(right.item.name)
            : sort === 'long'
              ? duration(right) - duration(left)
              : duration(left) - duration(right);
      return primary || left.endsAt.getTime() - right.endsAt.getTime();
    });
  const groups = groupPlannedUpgrades(upgrades);
  const villageLabels = {
    all: t('generalAll'),
    home: t('upgradeTrackerHomeVillage'),
    builderBase: t('upgradeTrackerBuilderBase'),
  } as const;
  const sortLabels = {
    scheduled: t('upgradeTrackerSortScheduled'),
    name: t('upgradeTrackerSortName'),
    long: t('upgradeTrackerSortLongest'),
    short: t('upgradeTrackerSortShortest'),
  } as const;
  const queueLabels = {
    all: t('generalAll'),
    builders: t('dashboardUpgradeTrackerBuilders'),
    laboratory: t('upgradeTrackerLaboratory'),
    pets: t('upgradeTrackerPets'),
    walls: t('upgradeTrackerWalls'),
  } as const;
  return (
    <Animated.ScrollView
      testID="upgrade-tracker-plan-scroll"
      contentContainerStyle={[styles.content, { paddingTop: contentInset + 12 }]}
      contentOffset={initialContentOffset}
      onScroll={onScroll}
      onMomentumScrollEnd={onScrollSettled}
      onScrollEndDrag={onScrollSettled}
      scrollEventThrottle={16}
    >
      <View style={styles.planSettingsRow}>
        {onPriorities ? (
          <PressableSurface onPress={onPriorities} style={styles.planSetting}>
            <MobileWebImage
              imageUrl={ImageAssets.hammerOfBuilding}
              style={{ width: 28, height: 28 }}
            />
            <CKText role="bodyMedium" style={styles.grow}>
              {t('upgradeTrackerPlanPrioritiesTitle')}
            </CKText>
            <ChevronRight size={18} color={theme.onSurfaceVariant} />
          </PressableSurface>
        ) : null}
        {onGoldPass ? (
          <PressableSurface onPress={onGoldPass} style={styles.planSetting}>
            <MobileWebImage imageUrl={ImageAssets.goldPass} style={{ width: 28, height: 28 }} />
            <CKText role="bodyMedium">{goldPassLabel(goldPassPercent, t)}</CKText>
          </PressableSurface>
        ) : null}
      </View>
      <LootOutlook plan={plan} />
      <SelectionPicker
        title={t('generalFilters')}
        selectedKey={queue}
        onSelect={(value) => {
          setQueue(value);
          setVisibleCount(40);
        }}
        options={(Object.keys(queueLabels) as (keyof typeof queueLabels)[]).map((key) => ({
          key,
          label: queueLabels[key],
        }))}
        fillWidth
      />
      <View style={styles.planDropdownRow}>
        <View style={styles.grow}>
          <SelectionPicker
            title={t('dashboardUpgradeTrackerVillage')}
            selectedKey={village}
            onSelect={(value) => {
              setVillage(value);
              setVisibleCount(40);
            }}
            options={(Object.keys(villageLabels) as (keyof typeof villageLabels)[]).map((key) => ({
              key,
              label: villageLabels[key],
            }))}
            fillWidth
          />
        </View>
        <View style={styles.grow}>
          <SelectionPicker
            title={t('statsSortBy')}
            selectedKey={sort}
            onSelect={(value) => {
              setSort(value);
              setVisibleCount(40);
            }}
            options={(Object.keys(sortLabels) as (keyof typeof sortLabels)[]).map((key) => ({
              key,
              label: sortLabels[key],
            }))}
            fillWidth
          />
        </View>
      </View>
      {!groups.length ? (
        <EmptyState
          title={t('upgradeTrackerNoMatchingUpgrades')}
          body={t('upgradeTrackerNoMatchingUpgradesBody')}
        />
      ) : (
        <View style={[styles.planRows, desktop && styles.desktopSectionGrid]}>
          {groups.slice(0, visibleCount).map((group) => {
            const upgrade = group.upgrades[0]!;
            return (
              <PressableSurface
                key={`${upgradeItemRenderIdentity(upgrade.item)}-${upgrade.instance}-${upgrade.step.targetLevel}-${upgrade.startsAt.getTime()}-${group.upgrades.length}`}
                radius={ckRadius.tile}
                style={[styles.row, desktop && styles.desktopSection]}
                onPress={() => setSelectedUpgrade(upgrade)}
              >
                <MobileWebImage imageUrl={upgrade.item.imageUrl} style={styles.itemImage} />
                <View style={styles.grow}>
                  <CKText role="rowTitle">
                    {upgrade.item.name}
                    {group.upgrades.length > 1 ? ` ×${group.upgrades.length}` : ''}
                  </CKText>
                  <CKText muted role="metadata">
                    {t('upgradeTrackerLevelTransition', {
                      from: upgrade.step.targetLevel - 1,
                      to: upgrade.step.targetLevel,
                    })}{' '}
                    ·{' '}
                    {upgrade.startsAt.toLocaleDateString(intlLocale, {
                      month: 'short',
                      day: 'numeric',
                    })}
                    {group.isOngoing ? ` · ${t('upgradeTrackerUpgradingNow')}` : ''}
                  </CKText>
                  {group.costs.length ? (
                    <CKText muted role="metadata">
                      {group.costs
                        .map(
                          (cost) =>
                            `${compactNumber(cost.amount, intlLocale)} ${planResourceLabel(cost.resource, t)}`,
                        )
                        .join(' · ')}
                    </CKText>
                  ) : null}
                </View>
                <CKText>
                  {formatTrackerDuration(
                    (group.endsAt.getTime() - group.startsAt.getTime()) / 1000,
                  )}
                </CKText>
              </PressableSurface>
            );
          })}
          {groups.length > visibleCount ? (
            <PressableSurface
              onPress={() => setVisibleCount((value) => value + 40)}
              style={styles.planLoadMore}
            >
              <CKText role="bodyMedium">{t('postsLoadMore')}</CKText>
            </PressableSurface>
          ) : null}
        </View>
      )}
      {selectedUpgrade ? (
        <PlannedUpgradeModal upgrade={selectedUpgrade} onClose={() => setSelectedUpgrade(null)} />
      ) : null}
    </Animated.ScrollView>
  );
}

function LootOutlook({ plan }: { plan: ReturnType<typeof buildTrackerPlanData> }) {
  const { t } = useI18n();
  const [period, setPeriod] = useState<'now' | 'week' | 'month'>('now');
  const startsAt = plan.startsAt;
  const upgrades = plan.upgrades
    .filter((upgrade) => !upgrade.isOngoing)
    .sort((left, right) => left.startsAt.getTime() - right.startsAt.getTime());
  const within = (days: number) =>
    upgrades.filter(
      (upgrade) => upgrade.startsAt < new Date(startsAt.getTime() + days * 86_400_000),
    );
  const lootNow = upgrades.filter(
    (upgrade) =>
      upgrade.item.village === UpgradeVillage.home &&
      upgrade.item.queue === UpgradeQueue.builders &&
      upgrade.startsAt <= new Date(startsAt.getTime() + 60_000),
  );
  return (
    <Surface radius={ckRadius.card} style={styles.lootOutlook}>
      <View style={styles.lootOutlookHeader}>
        <MobileWebImage imageUrl={ImageAssets.lootCart} style={styles.lootOutlookImage} />
        <CKText role="titleSmall" style={styles.grow}>
          {t('upgradeTrackerLootOutlook')}
        </CKText>
        <View style={{ maxWidth: 155 }}>
          <SelectionPicker
            title={t('upgradeTrackerLootOutlook')}
            selectedKey={period}
            onSelect={setPeriod}
            options={[
              { key: 'now', label: t('upgradeTrackerLootNow') },
              { key: 'week', label: t('upgradeTrackerNextDays', { count: 7 }) },
              { key: 'month', label: t('upgradeTrackerNextDays', { count: 30 }) },
            ]}
          />
        </View>
      </View>
      <PlanPeriodSummary
        upgrades={period === 'now' ? lootNow : within(period === 'week' ? 7 : 30)}
        countLabel={
          period !== 'now'
            ? undefined
            : lootNow.length
              ? t('upgradeTrackerIdleBuilders', { count: lootNow.length })
              : t('upgradeTrackerAllBuildersOccupied')
        }
        emptyLabel={t('upgradeTrackerNothingNeededNow')}
        showCount={period !== 'now'}
      />
    </Surface>
  );
}

function PlanPeriodSummary({
  label,
  upgrades,
  countLabel,
  emptyLabel,
  showCount = true,
}: {
  label?: string;
  upgrades: readonly ReturnType<typeof buildTrackerPlanData>['upgrades'][number][];
  countLabel?: string;
  emptyLabel?: string;
  showCount?: boolean;
}) {
  const { locale, t } = useI18n();
  const intlLocale = toIntlLocale(locale);
  const costs = new Map<string, number>();
  for (const upgrade of upgrades)
    for (const cost of upgrade.costs)
      costs.set(cost.resource, (costs.get(cost.resource) ?? 0) + cost.amount);
  const resources = [...costs.entries()].sort(
    ([left], [right]) => planResourceWeight(left) - planResourceWeight(right),
  );
  return (
    <View style={styles.periodSummary}>
      {label ? <CKText role="bodyMedium">{label}</CKText> : null}
      <View style={styles.periodCountRow}>
        {showCount ? <CKText role="titleLarge">{upgrades.length}</CKText> : null}
        <CKText muted={!showCount} role={showCount ? 'metadata' : 'rowTitle'} style={styles.grow}>
          {countLabel ?? t('upgradeTrackerUpgradesStarting')}
        </CKText>
      </View>
      {resources.length ? (
        <View style={styles.periodResources}>
          {resources.map(([resource, amount]) => {
            const resourceLabel = planResourceLabel(resource, t);
            const formattedAmount = compactNumber(amount, intlLocale);
            return (
              <View
                key={resource}
                accessible
                accessibilityLabel={t('upgradeTrackerResourceAmount', {
                  resource: resourceLabel,
                  amount: formattedAmount,
                })}
                style={styles.planResourceRow}
              >
                <MobileWebImage
                  testID={`upgrade-tracker-plan-resource-${normalizePlanResource(resource)}`}
                  imageUrl={planResourceImage(resource)}
                  style={styles.planResourceImage}
                />
                <CKText role="bodyMedium">{formattedAmount}</CKText>
              </View>
            );
          })}
        </View>
      ) : (
        <CKText muted role="metadata">
          {emptyLabel ?? '—'}
        </CKText>
      )}
    </View>
  );
}

const planResourceLabelKeys = {
  gold: 'resourceGold',
  elixir: 'resourceElixir',
  dark_elixir: 'resourceDarkElixir',
  builder_gold: 'resourceBuilderGold',
  builder_elixir: 'resourceBuilderElixir',
  shiny_ore: 'resourceShinyOre',
  glowy_ore: 'resourceGlowyOre',
  starry_ore: 'resourceStarryOre',
} as const satisfies Readonly<Record<string, MessageKey>>;

function normalizePlanResource(resource: string) {
  return resource
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '');
}

function planResourceLabel(resource: string, t: I18nValue['t']) {
  const normalized = normalizePlanResource(resource);
  const labelKey = planResourceLabelKeys[normalized as keyof typeof planResourceLabelKeys];
  if (labelKey) return t(labelKey);
  return normalized
    .split('_')
    .filter(Boolean)
    .map((part) => part[0]!.toUpperCase() + part.slice(1))
    .join(' ');
}

function planResourceImage(resource: string) {
  const normalized = normalizePlanResource(resource);
  return normalized
    ? `${ImageAssets.baseUrl}/resources/${normalized}.webp`
    : ImageAssets.defaultImage;
}

function planResourceWeight(resource: string) {
  const normalized = normalizePlanResource(resource);
  if (normalized === 'gold') return 0;
  if (normalized === 'elixir') return 1;
  if (normalized === 'dark_elixir') return 2;
  if (normalized === 'builder_gold') return 3;
  if (normalized === 'builder_elixir') return 4;
  if (normalized === 'shiny_ore') return 5;
  if (normalized === 'glowy_ore') return 6;
  if (normalized === 'starry_ore') return 7;
  return 99;
}

function compactNumber(value: number, intlLocale: string) {
  if (value >= 1_000_000_000) return `${(value / 1_000_000_000).toFixed(1)}B`;
  if (value >= 1_000_000) return `${(value / 1_000_000).toFixed(1)}M`;
  if (value >= 1_000) return `${(value / 1_000).toFixed(1)}K`;
  return new Intl.NumberFormat(intlLocale).format(Math.round(value));
}

function CollectionTab({
  snapshot,
  stateStore,
  contentInset,
  initialOffset,
  onScroll,
  onScrollSettled,
}: {
  snapshot: UpgradeTrackerSnapshot;
  stateStore: Map<string, unknown>;
  contentInset: number;
  initialOffset: number;
  onScroll: (event: NativeSyntheticEvent<NativeScrollEvent>) => void;
  onScrollSettled: (event: NativeSyntheticEvent<NativeScrollEvent>) => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [query, setQuery] = useCachedPageState(stateStore, 'collection.query', '');
  const [filter, setFilter] = useCachedPageState<'all' | 'owned' | 'missing'>(
    stateStore,
    'collection.filter',
    'all',
  );
  const [village, setVillage] = useCachedPageState<'all' | 'home' | 'builderBase'>(
    stateStore,
    'collection.village',
    'all',
  );
  const [sort, setSort] = useCachedPageState<
    'nameAscending' | 'nameDescending' | 'newest' | 'oldest'
  >(stateStore, 'collection.sort', 'nameAscending');
  const [showFilters, setShowFilters] = useState(false);
  const [category, setCategory] = useCachedPageState<UpgradeCollectionTypeValue | null>(
    stateStore,
    'collection.expandedCategory',
    null,
  );
  const [selected, setSelected] = useState<UpgradeCollectionItem | null>(null);
  const initialContentOffset = useInitialScrollOffset(initialOffset);
  const collectionItems = useMemo(
    () => uniqueCollectionItems(snapshot.collections),
    [snapshot.collections],
  );
  const supportsVillage =
    collectionItems.some((item) => item.village === UpgradeVillage.home) &&
    collectionItems.some((item) => item.village === UpgradeVillage.builderBase);
  const summaries = useMemo(
    () =>
      Object.values(UpgradeCollectionType).flatMap((type) => {
        const all = collectionItems.filter((item) => item.type === type);
        if (!all.length) return [];
        return [
          {
            type,
            owned: all.filter((item) => item.owned).length,
            total: all.length,
            art: (all.find((item) => item.owned) ?? all[0])?.imageUrl ?? ImageAssets.defaultImage,
          },
        ];
      }),
    [collectionItems],
  );
  const visibleItems = useMemo(
    () =>
      collectionItems
        .filter(
          (item) =>
            item.type === category &&
            (!query.trim() ||
              collectionDisplayName(item)
                .toLocaleLowerCase()
                .includes(query.trim().toLocaleLowerCase())) &&
            (filter === 'all' || item.owned === (filter === 'owned')) &&
            (village === 'all' ||
              item.type === UpgradeCollectionType.capitalHouseParts ||
              item.village ===
                (village === 'home' ? UpgradeVillage.home : UpgradeVillage.builderBase)),
        )
        .sort((left, right) => {
          if (sort === 'nameAscending') return left.name.localeCompare(right.name);
          if (sort === 'nameDescending') return right.name.localeCompare(left.name);
          return sort === 'newest' ? right.id - left.id : left.id - right.id;
        }),
    [collectionItems, category, query, filter, village, sort],
  );
  type CollectionRow =
    | { kind: 'summary'; key: string; summary: (typeof summaries)[number] }
    | { kind: 'items'; key: string; items: UpgradeCollectionItem[] }
    | { kind: 'empty'; key: string };
  // Flatten the open category into the parent list: no nested scrolling grid,
  // and closed categories never mount hundreds of collection images.
  const rows = useMemo<CollectionRow[]>(
    () =>
      summaries.flatMap((summary) => {
        const result: CollectionRow[] = [{ kind: 'summary', key: summary.type, summary }];
        if (summary.type !== category) return result;
        if (!visibleItems.length) result.push({ kind: 'empty', key: summary.type + '-empty' });
        for (let index = 0; index < visibleItems.length; index += 3) {
          result.push({
            kind: 'items',
            key: summary.type + '-' + index,
            items: visibleItems.slice(index, index + 3),
          });
        }
        return result;
      }),
    [summaries, category, visibleItems],
  );
  const filtered =
    !!query.trim() || filter !== 'all' || village !== 'all' || sort !== 'nameAscending';
  const ownershipLabels = {
    all: t('upgradeTrackerFilterAll'),
    owned: t('upgradeTrackerFilterOwned'),
    missing: t('upgradeTrackerFilterMissing'),
  };
  const villageLabels = {
    all: t('upgradeTrackerAllVillages'),
    home: t('upgradeTrackerHomeVillage'),
    builderBase: t('upgradeTrackerBuilderBase'),
  };
  const sortLabels = {
    nameAscending: 'A → Z',
    nameDescending: 'Z → A',
    newest: t('warEventsNewest'),
    oldest: t('warEventsOldest'),
  };
  return (
    <View style={{ flex: 1 }}>
      <Animated.FlatList
        testID="upgrade-tracker-collection-scroll"
        contentContainerStyle={[styles.content, { paddingTop: contentInset + 12 }]}
        contentOffset={initialContentOffset}
        onScroll={onScroll}
        onMomentumScrollEnd={onScrollSettled}
        onScrollEndDrag={onScrollSettled}
        scrollEventThrottle={16}
        data={rows}
        keyExtractor={(row) => row.key}
        initialNumToRender={8}
        maxToRenderPerBatch={6}
        windowSize={5}
        renderItem={({ item: row }) => {
          if (row.kind === 'empty')
            return <EmptyState title={t('upgradeTrackerNoMatchingItems')} />;
          if (row.kind === 'summary') {
            const { summary } = row;
            const open = category === summary.type;
            return (
              <View style={{ marginBottom: 10 }}>
                <TrackerSummaryCard
                  title={collectionTypeLabel(summary.type, t)}
                  imageUrl={summary.art}
                  percent={summary.total ? (summary.owned / summary.total) * 100 : 0}
                  open={open}
                  onToggle={() => setCategory(open ? null : summary.type)}
                  footer={
                    <View
                      style={{
                        flex: 1,
                        flexDirection: 'row',
                        justifyContent: 'space-between',
                        gap: 12,
                      }}
                    >
                      <CKText role="bodyMedium" muted>
                        {summary.owned} {t('upgradeTrackerFilterOwned')}
                      </CKText>
                      <CKText role="bodyMedium" muted>
                        {summary.total - summary.owned} {t('upgradeTrackerFilterMissing')}
                      </CKText>
                    </View>
                  }
                >
                  <View
                    style={{
                      flexDirection: 'row',
                      alignItems: 'center',
                      justifyContent: 'space-between',
                      gap: 12,
                    }}
                  >
                    <CKText role="bodyMedium" muted>
                      {visibleItems.length} / {summary.total}
                    </CKText>
                    <Pressable
                      accessibilityRole="button"
                      accessibilityLabel={t('generalFilters')}
                      accessibilityState={{ selected: filtered }}
                      onPress={() => setShowFilters(true)}
                      hitSlop={8}
                      style={{
                        minWidth: 44,
                        minHeight: 44,
                        alignItems: 'center',
                        justifyContent: 'center',
                      }}
                    >
                      <Filter size={22} color={filtered ? theme.primary : theme.onSurfaceVariant} />
                    </Pressable>
                  </View>
                </TrackerSummaryCard>
              </View>
            );
          }
          return (
            <View style={{ flexDirection: 'row', gap: 8, marginBottom: 8 }}>
              {row.items.map((item) => (
                <Pressable
                  key={collectionItemRenderIdentity(item)}
                  accessibilityRole="button"
                  accessibilityLabel={collectionDisplayName(item)}
                  onPress={() => setSelected(item)}
                  style={{ flex: 1, maxWidth: '32%' }}
                >
                  <Surface
                    radius={ckRadius.tile}
                    style={[styles.collectionTile, { borderWidth: 0, minHeight: 142 }]}
                  >
                    <MobileWebImage
                      imageUrl={item.imageUrl}
                      style={[styles.collectionImage, !item.owned && { opacity: 0.45 }]}
                    />
                    <CKText role="body" numberOfLines={2} style={{ textAlign: 'center' }}>
                      {collectionDisplayName(item)}
                    </CKText>
                    <CKText role="bodyMedium" muted>
                      {item.owned ? ownershipLabels.owned : ownershipLabels.missing}
                    </CKText>
                  </Surface>
                </Pressable>
              ))}
            </View>
          );
        }}
      />
      <ChoiceModal
        visible={showFilters}
        title={t('upgradeTrackerSearchCollection')}
        onClose={() => setShowFilters(false)}
      >
        <SearchBar
          value={query}
          onChange={setQuery}
          placeholder={t('upgradeTrackerSearchCollection')}
        />
        <View style={{ gap: 12, marginTop: 12 }}>
          <SelectionPicker
            fillWidth
            selectedKey={filter}
            title={t('generalFilters')}
            options={Object.entries(ownershipLabels).map(([key, label]) => ({
              key: key as keyof typeof ownershipLabels,
              label,
            }))}
            onSelect={setFilter}
          />
          {supportsVillage ? (
            <SelectionPicker
              fillWidth
              selectedKey={village}
              title={t('dashboardUpgradeTrackerVillage')}
              options={Object.entries(villageLabels).map(([key, label]) => ({
                key: key as keyof typeof villageLabels,
                label,
              }))}
              onSelect={setVillage}
            />
          ) : null}
          <SelectionPicker
            fillWidth
            selectedKey={sort}
            title={t('statsSortBy')}
            options={Object.entries(sortLabels).map(([key, label]) => ({
              key: key as keyof typeof sortLabels,
              label,
            }))}
            onSelect={setSort}
          />
        </View>
      </ChoiceModal>
      <CollectionDetailModal item={selected} onClose={() => setSelected(null)} />
    </View>
  );
}

function CollectionDetailModal({
  item,
  onClose,
}: {
  item: UpgradeCollectionItem | null;
  onClose: () => void;
}) {
  const { locale, t } = useI18n();
  const intlLocale = toIntlLocale(locale);
  if (!item) return null;
  const music = sceneryMusicUrl(item);
  const info = collectionInfo(item, intlLocale, t);
  return (
    <ChoiceModal visible title={collectionDisplayName(item)} onClose={onClose}>
      <MobileWebImage imageUrl={item.imageUrl} style={styles.collectionDetailImage} />
      <CKText muted style={styles.centerText}>
        {item.type === UpgradeCollectionType.decorations ||
        item.type === UpgradeCollectionType.obstacles
          ? t('upgradeTrackerItemsOwned', { count: item.count })
          : item.owned
            ? t('upgradeTrackerFilterOwned')
            : t('upgradeTrackerFilterMissing')}
      </CKText>
      {music ? <SceneryPlayer source={music} /> : null}
      {info.map((row) => (
        <View key={row.label} style={styles.detailLine}>
          <CKText muted style={styles.grow}>
            {row.label}
          </CKText>
          <CKText>{row.value}</CKText>
        </View>
      ))}
    </ChoiceModal>
  );
}

function collectionInfo(item: UpgradeCollectionItem, locale: string, t: I18nValue['t']) {
  const meta = item.meta;
  if (!meta) return [];
  const rows: { label: string; value: string }[] = [];
  const add = (label: string, value: unknown) => {
    if (value === null || value === undefined || String(value).length === 0) return;
    rows.push({ label, value: String(value) });
  };
  const addResource = (label: string, amount: unknown, resource: unknown) => {
    const numeric = Number(amount);
    if (!Number.isFinite(numeric) || numeric <= 0 || !resource) return;
    rows.push({ label, value: `${compactNumber(numeric, locale)} ${String(resource)}` });
  };
  const villageName = (value: unknown) => {
    if (value === 'builderBase' || value === 'builder') return t('upgradeTrackerBuilderBase');
    if (value === 'war') return t('upgradeTrackerWarBase');
    if (value === 'home') return t('upgradeTrackerHomeVillage');
    return value;
  };
  if (item.type === UpgradeCollectionType.skins) {
    add(t('upgradeTrackerTier'), meta.tier);
    add(t('statsHero'), meta.character);
  } else if (item.type === UpgradeCollectionType.sceneries) {
    add(t('dashboardUpgradeTrackerVillage'), villageName(meta.type));
    if (meta.music !== null && meta.music !== undefined)
      add(t('upgradeTrackerMusic'), t('upgradeTrackerCustomSoundtrack'));
  } else if (item.type === UpgradeCollectionType.decorations) {
    add(t('dashboardUpgradeTrackerVillage'), villageName(meta.village));
    if (meta.width !== null && meta.width !== undefined)
      add(t('upgradeTrackerSize'), `${String(meta.width)} × ${String(meta.width)}`);
    add(t('generalMaximum'), item.maxCount);
    addResource(t('upgradeTrackerBuildCost'), meta.build_cost, meta.build_resource);
    if (meta.pass_reward === true) add(t('rankingsSource'), t('upgradeTrackerPassReward'));
  } else if (item.type === UpgradeCollectionType.obstacles) {
    add(t('dashboardUpgradeTrackerVillage'), villageName(meta.village));
    if (meta.width !== null && meta.width !== undefined)
      add(t('upgradeTrackerSize'), `${String(meta.width)} × ${String(meta.width)}`);
    addResource(t('upgradeTrackerClearCost'), meta.clear_cost, meta.clear_resource);
    addResource(t('capitalRaidLoot'), meta.loot_count, meta.loot_resource);
  } else {
    add(t('upgradeTrackerPart'), meta.slot_type);
  }
  return rows;
}

function SceneryPlayer({ source }: { source: string }) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [trackWidth, setTrackWidth] = useState(0);
  const [state, setState] = useState<SceneryAudioState>({
    checking: true,
    available: false,
    loading: false,
    playing: false,
    positionMilliseconds: 0,
    durationMilliseconds: 0,
  });
  const service = useRef<SceneryAudioService | null>(null);
  useEffect(() => {
    let active = true;
    let unsubscribe: () => void = () => undefined;
    const runtimeImport =
      Platform.OS === 'web'
        ? import('../audio/expo-scenery-audio-runtime').then(
            ({ ExpoSceneryAudioRuntime }) => new ExpoSceneryAudioRuntime(),
          )
        : import('../audio/native-scenery-audio-runtime').then(
            ({ NativeSceneryAudioRuntime }) => new NativeSceneryAudioRuntime(),
          );
    void runtimeImport.then((runtime) => {
      if (!active) return;
      const next = new SceneryAudioService(
        source,
        Platform.OS === 'ios' ? 'ios' : Platform.OS === 'android' ? 'android' : 'web',
        runtime,
      );
      service.current = next;
      unsubscribe = next.subscribe(setState);
      void next.checkAvailability();
    });
    return () => {
      active = false;
      unsubscribe();
      void service.current?.dispose();
      service.current = null;
    };
  }, [source]);
  if (!state.checking && !state.available) return null;
  const duration = Math.max(1, state.durationMilliseconds);
  return (
    <View style={styles.audio}>
      <PressableSurface
        accessibilityRole="button"
        accessibilityLabel={
          state.playing ? t('upgradeTrackerPauseSoundtrack') : t('upgradeTrackerPlaySoundtrack')
        }
        disabled={state.loading}
        onPress={() => void service.current?.toggle()}
        style={styles.audioButton}
      >
        {state.loading ? (
          <Headphones color={theme.onSurface} />
        ) : state.playing ? (
          <Pause color={theme.onSurface} />
        ) : (
          <Play color={theme.onSurface} />
        )}
      </PressableSurface>
      <View style={styles.audioTimeline}>
        <Pressable
          accessibilityRole="adjustable"
          accessibilityLabel={t('upgradeTrackerSoundtrackPosition')}
          disabled={state.durationMilliseconds <= 0}
          onLayout={(event) => setTrackWidth(event.nativeEvent.layout.width)}
          onPress={(event) =>
            void service.current?.seek(
              (Math.max(0, event.nativeEvent.locationX) / Math.max(1, trackWidth)) * duration,
            )
          }
          style={styles.audioTrack}
        >
          <View
            style={[
              styles.audioTrackFill,
              { width: `${Math.min(100, (state.positionMilliseconds * 100) / duration)}%` },
            ]}
          />
        </Pressable>
        <View style={styles.audioTimes}>
          <CKText role="labelSmall">{formatAudio(state.positionMilliseconds)}</CKText>
          <CKText role="labelSmall">
            {state.durationMilliseconds ? formatAudio(state.durationMilliseconds) : '–:––'}
          </CKText>
        </View>
      </View>
    </View>
  );
}

export { ImportModal as UpgradeImportModal };

function ImportModal({
  visible,
  onClose,
  onImport,
  onOpenGameSettings,
}: {
  visible: boolean;
  onClose: () => void;
  onImport: (json: string) => Promise<void>;
  onOpenGameSettings?: () => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [busy, setBusy] = useState(false);
  const [failed, setFailed] = useState<string | null>(null);
  return (
    <ChoiceModal
      visible={visible}
      title={t('upgradeTrackerPasteJson')}
      onClose={() => {
        if (!busy) {
          setFailed(null);
          onClose();
        }
      }}
    >
      <CKText role="body" muted>
        {t('upgradeTrackerNoDataLocation')}
      </CKText>
      {onOpenGameSettings ? (
        <PressableSurface
          accessibilityRole="button"
          onPress={onOpenGameSettings}
          style={[
            styles.secondaryButton,
            {
              marginTop: 6,
              minHeight: 48,
              borderRadius: 12,
              backgroundColor: theme.surfaceContainerHighest,
              flexDirection: 'row',
              gap: 10,
              paddingHorizontal: 14,
            },
          ]}
        >
          <CKText role="bodyMedium" style={styles.grow}>
            {t('upgradeTrackerOpenMoreSettings')}
          </CKText>
          <ChevronRight size={20} color={theme.onSurface} />
        </PressableSurface>
      ) : null}
      <PressableSurface
        accessibilityRole="button"
        accessibilityLabel={t('upgradeTrackerPasteClipboard')}
        disabled={busy}
        style={[
          styles.primaryButton,
          { minHeight: 48, borderRadius: 12, backgroundColor: theme.primary },
        ]}
        onPress={() => {
          setBusy(true);
          setFailed(null);
          void Clipboard.getStringAsync()
            .then((value) => onImport(value.trim()))
            .catch((error: unknown) =>
              setFailed(
                error instanceof Error ? error.message : t('upgradeTrackerSnapshotUnreadable'),
              ),
            )
            .finally(() => setBusy(false));
        }}
      >
        {busy ? (
          <ActivityIndicator color={theme.onPrimary} />
        ) : (
          <Upload size={20} color={theme.onPrimary} />
        )}
        <CKText role="bodyMedium" style={{ color: theme.onPrimary }}>
          {t(busy ? 'generalLoading' : 'upgradeTrackerPasteClipboard')}
        </CKText>
      </PressableSurface>
      {failed ? (
        <CKText role="bodyMedium" accessibilityRole="alert" style={{ color: theme.error }}>
          {failed}
        </CKText>
      ) : null}
    </ChoiceModal>
  );
}

function AccountModal({
  visible,
  accounts,
  selectedTag,
  loading,
  onClose,
  onSelect,
}: {
  visible: boolean;
  accounts: readonly UpgradeTrackerAccountOption[];
  selectedTag: string | null;
  loading: boolean;
  onClose: () => void;
  onSelect: (tag: string) => void;
  onImport?: () => void;
}) {
  const { t } = useI18n();
  return (
    <SelectionPickerModal
      visible={visible}
      title={t('upgradeTrackerChooseAccount')}
      optionHeight={68}
      selectedKey={selectedTag ?? ''}
      onClose={onClose}
      onSelect={(tag) => {
        onSelect(tag);
        onClose();
      }}
      searchPlaceholder={t('upgradeTrackerChooseAccount')}
      options={accounts.map((account) => ({
        key: account.tag,
        label: account.name,
        searchText: account.name + ' ' + account.tag,
        subtitle: account.capturedAt ? snapshotAgeLabel(account.capturedAt, t) : '',
        icon:
          loading && account.tag === selectedTag ? (
            <ActivityIndicator />
          ) : (
            <MobileWebImage
              imageUrl={
                account.townHallLevel
                  ? ImageAssets.townHall(account.townHallLevel)
                  : ImageAssets.builderHall(account.builderHallLevel)
              }
              style={styles.accountHall}
            />
          ),
      }))}
    />
  );
}

function ChoiceModal({
  visible,
  title,
  onClose,
  children,
}: {
  visible: boolean;
  title: string;
  onClose: () => void;
  children: ReactNode;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  return (
    <Modal
      supportedOrientations={modalOrientations}
      visible={visible}
      transparent
      animationType="fade"
      statusBarTranslucent
      onRequestClose={onClose}
    >
      <View style={styles.overlay}>
        <Pressable
          testID="upgrade-tracker-choice-modal-backdrop"
          accessible={false}
          onPress={onClose}
          style={StyleSheet.absoluteFill}
        />
        <Surface
          accessibilityViewIsModal
          onAccessibilityEscape={onClose}
          radius={ckRadius.card}
          style={styles.modal}
        >
          <View style={styles.toolbar}>
            <CKText role="titleLarge" style={styles.grow}>
              {title}
            </CKText>
            <IconButton label={t('generalCancel')} onPress={onClose}>
              <X color={theme.onSurface} />
            </IconButton>
          </View>
          <ScrollView
            contentContainerStyle={styles.modalContent}
            keyboardShouldPersistTaps="handled"
          >
            {children}
          </ScrollView>
        </Surface>
      </View>
    </Modal>
  );
}
function SearchBar({
  value,
  onChange,
  placeholder,
  filtered = false,
  filterTestID,
  onFilter,
}: {
  value: string;
  onChange: (v: string) => void;
  placeholder: string;
  filtered?: boolean;
  filterTestID?: string;
  onFilter?: () => void;
}) {
  const theme = useCKTheme();
  const { t } = useI18n();
  return (
    <View style={styles.toolbar}>
      <SearchField
        value={value}
        onChangeText={onChange}
        placeholder={placeholder}
        searchIcon={<Search size={18} color={theme.onSurfaceVariant} />}
      />
      {onFilter ? (
        <IconButton testID={filterTestID} label={t('generalFilters')} onPress={onFilter}>
          <Filter color={filtered ? theme.primary : theme.onSurface} />
        </IconButton>
      ) : null}
    </View>
  );
}
function IconButton({
  testID,
  label,
  onPress,
  children,
}: {
  testID?: string;
  label: string;
  onPress: () => void;
  children: ReactNode;
}) {
  return (
    <Pressable
      testID={testID}
      accessibilityRole="button"
      accessibilityLabel={label}
      onPress={onPress}
    >
      <GlassSurface cornerRadius={999} interactive style={styles.iconButton}>
        {children}
      </GlassSurface>
    </Pressable>
  );
}
function collectionTypeLabel(type: UpgradeCollectionTypeValue, t: I18nValue['t']) {
  const labels: Record<UpgradeCollectionTypeValue, string> = {
    [UpgradeCollectionType.skins]: t('gameAssetsCategorySkins'),
    [UpgradeCollectionType.sceneries]: t('upgradeTrackerSceneries'),
    [UpgradeCollectionType.decorations]: t('gameAssetsCategoryDecorations'),
    [UpgradeCollectionType.obstacles]: t('upgradeTrackerObstacles'),
    [UpgradeCollectionType.capitalHouseParts]: t('upgradeTrackerHouseParts'),
  };
  return labels[type];
}
function collectionDisplayName(item: UpgradeCollectionItem) {
  const name = item.name.replaceAll('\\q', '"');
  return item.type === UpgradeCollectionType.sceneries ? name.replace(/\s+Scenery$/i, '') : name;
}
function formatAudio(ms: number) {
  const seconds = Math.max(0, Math.floor(ms / 1000));
  return `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, '0')}`;
}

const styles = StyleSheet.create({
  safe: { flex: 1 },
  trackerBody: { flex: 1, overflow: 'hidden' },
  trackerHeaderOverlay: {
    position: 'absolute',
    top: 0,
    right: 0,
    left: 0,
    zIndex: 2,
  },
  trackerTabsOverlay: {
    position: 'absolute',
    right: 0,
    left: 0,
    zIndex: 3,
  },
  grow: { flex: 1 },
  emptyBody: { flex: 1, alignItems: 'center', justifyContent: 'center', gap: 8, padding: 16 },
  secondaryButton: { minHeight: 44, alignItems: 'center', justifyContent: 'center', padding: 10 },
  skeletonPage: { flex: 1, gap: 10, padding: 16 },
  skeletonCard: { minHeight: 72, flexDirection: 'row', alignItems: 'center', gap: 12, padding: 12 },
  heroHeader: { height: 276, overflow: 'hidden' },
  heroHeaderDesktop: { height: 260 },
  heroBackdrop: { position: 'absolute', top: 0, right: 0, bottom: 0, left: 0 },
  heroActions: {
    minHeight: 52,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 2,
  },
  heroIconButton: { width: 48, height: 48, alignItems: 'center', justifyContent: 'center' },
  heroActionImage: { width: 26, height: 26 },
  heroProfile: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  freshnessAction: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
    minHeight: 36,
  },
  heroHallBadge: { width: 112, height: 112, alignItems: 'center', justifyContent: 'center' },
  heroHall: { width: 108, height: 108 },
  heroHallDesktop: { width: 96, height: 96 },
  heroNameRow: { maxWidth: '80%', flexDirection: 'row', alignItems: 'center', gap: 3 },
  heroText: { color: 'white' },
  heroSecondary: { color: '#FFFFFFC7' },
  quickStats: {
    minHeight: 50,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 7,
  },
  quickStat: {
    flex: 1,
    minWidth: 0,
    paddingHorizontal: 4,
    paddingVertical: 6,
    flexDirection: 'column',
    alignItems: 'center',
    gap: 5,
    borderRadius: 999,
  },
  quickStatImage: { width: 19, height: 19, resizeMode: 'contain' },
  header: { flexDirection: 'row', alignItems: 'center', gap: 8, padding: 12 },
  tabWrap: {
    height: 54,
    paddingHorizontal: 12,
    paddingTop: 8,
    paddingBottom: 2,
    justifyContent: 'center',
  },
  tabControl: { width: '100%', maxWidth: 520, alignSelf: 'center' },
  tabImage: { width: 20, height: 20, resizeMode: 'contain' },
  content: {
    padding: 12,
    paddingBottom: 48,
    gap: 12,
    maxWidth: 1180,
    width: '100%',
    alignSelf: 'center',
  },
  trackerPager: { flex: 1 },
  trackerPage: { flex: 1 },
  iconButton: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  toolbar: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  section: { padding: 12, gap: 8 },
  upgradeGroupList: { gap: 12 },
  compactGroupSummary: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    alignItems: 'center',
    columnGap: 7,
    rowGap: 4,
  },
  groupResourcePair: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  currentUpgradeRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    minHeight: 56,
    paddingVertical: 5,
  },
  craftedFamily: { minHeight: 72, flexDirection: 'row', alignItems: 'center', gap: 12 },
  desktopSectionGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 12 },
  desktopSection: { width: '49%' },
  groupedTileSections: { gap: 10 },
  groupedTileSection: { gap: 7 },
  groupedTileHeading: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  groupedTileHeadingImage: { width: 24, height: 24 },
  collapsibleHeader: {
    minHeight: 44,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingVertical: 2,
  },
  sectionProgressBadge: {
    minWidth: 54,
    minHeight: 30,
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 999,
    alignItems: 'center',
    justifyContent: 'center',
  },
  sectionProgressLabel: { fontWeight: '600' },
  upgradeTile: {
    width: '100%',
    aspectRatio: 1,
    overflow: 'hidden',
    borderWidth: 2,
    borderRadius: 8,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.2,
    shadowRadius: 10,
  },
  upgradeTileArt: { flex: 1, overflow: 'hidden', borderRadius: 6 },
  upgradeTileContainedArt: { padding: 4 },
  upgradeTileImage: { width: '100%', height: '100%' },
  levelBadge: {
    position: 'absolute',
    right: 2,
    bottom: 2,
    minWidth: 23,
    height: 18,
    paddingHorizontal: 4,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 5,
    backgroundColor: '#000000DB',
  },
  levelBadgeComplete: { backgroundColor: '#FFD75E' },
  levelBadgeText: { color: 'white' },
  levelBadgeTextComplete: { color: 'black' },
  countBadge: {
    position: 'absolute',
    left: 2,
    top: 2,
    paddingHorizontal: 4,
    paddingVertical: 2,
    borderRadius: 5,
    backgroundColor: '#000000C7',
  },
  row: { minHeight: 64, flexDirection: 'row', alignItems: 'center', gap: 10, padding: 10 },
  itemImage: { width: 48, height: 48, resizeMode: 'contain' },
  metric: { minHeight: 88, alignItems: 'center', justifyContent: 'center', gap: 4, padding: 10 },
  progress: {
    width: 58,
    height: 8,
    borderRadius: 99,
    overflow: 'hidden',
    backgroundColor: '#80808044',
  },
  progressFill: { height: '100%' },
  calendarRoot: { paddingBottom: 48 },
  calendarContent: { paddingTop: 8, paddingBottom: 28 },
  centerText: { textAlign: 'center' },
  calendarDayHeader: { height: 44, flexDirection: 'row', alignItems: 'center' },
  calendarDay: { textAlign: 'center' },
  calendarTodayText: { color: '#4F91FF' },
  calendarSection: {
    marginBottom: 12,
    paddingTop: 10,
    paddingBottom: 10,
    overflow: 'hidden',
    borderWidth: 0,
  },
  calendarSectionHeader: {
    minHeight: 36,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 12,
  },
  calendarGroupImage: { width: 28, height: 25 },
  calendarPill: {
    paddingHorizontal: 8,
    paddingVertical: 5,
    minWidth: 0,
    maxWidth: 160,
    flexShrink: 1,
    overflow: 'hidden',
  },
  calendarLane: { height: 60, position: 'relative' },
  calendarGrid: { position: 'absolute', top: 0, height: 60, overflow: 'hidden' },
  calendarGridDay: {
    position: 'absolute',
    top: 0,
    bottom: 0,
    borderLeftWidth: StyleSheet.hairlineWidth,
    borderColor: '#80808038',
    backgroundColor: '#80808009',
  },
  calendarFixedLaneLabel: {
    height: 60,
    justifyContent: 'center',
    paddingLeft: 5,
  },
  calendarNowLine: {
    position: 'absolute',
    top: 0,
    bottom: 0,
    width: 2,
    backgroundColor: '#4F91FF',
  },
  calendarBlock: {
    position: 'absolute',
    top: 3,
    height: 54,
    borderRadius: 10,
    overflow: 'hidden',
    flexDirection: 'row',
  },
  calendarShortBlock: {
    position: 'absolute',
    top: 3,
    height: 54,
    borderRadius: 12,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
  },
  calendarBlockAccent: { width: 3 },
  calendarBlockBody: { flex: 1, flexDirection: 'row', alignItems: 'center', gap: 5, padding: 5 },
  calendarBlockCompact: { justifyContent: 'center', paddingHorizontal: 3 },
  calendarBlockIconWrap: { width: 30, height: 30 },
  calendarBlockIcon: { width: 30, height: 30 },
  calendarBlockLevel: {
    position: 'absolute',
    right: -1,
    bottom: -1,
    minWidth: 15,
    paddingHorizontal: 3,
    paddingVertical: 1,
    alignItems: 'center',
    borderRadius: 999,
    backgroundColor: '#17171B',
  },
  calendarBlockLevelText: { fontSize: 10 },
  timelineDetailImage: { width: 58, height: 58 },
  timelineDetailGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  timelineDetailMetric: { minWidth: 140, flex: 1, gap: 3, padding: 10 },
  collectionTile: {
    minHeight: 132,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 5,
    padding: 8,
  },
  collectionImage: { width: 76, height: 76, resizeMode: 'contain' },
  collectionControls: { padding: 12, gap: 12, marginBottom: 16, borderWidth: 0 },
  collectionCategories: { flexDirection: 'row', flexWrap: 'wrap', gap: 6 },
  collectionCategory: {
    flexBasis: '30%',
    flexGrow: 1,
    minHeight: 82,
    padding: 8,
    borderRadius: 16,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 5,
    overflow: 'hidden',
  },
  collectionCategoryImage: { width: 30, height: 30 },
  collectionCategoryMarker: { height: 2.5, position: 'absolute', bottom: 0, left: 16, right: 16 },
  collectionOwnershipSummary: {
    minHeight: 36,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  collectionSummaryAction: {
    minHeight: 40,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'flex-end',
    gap: 4,
    padding: 6,
  },
  filterPanel: { gap: 10 },
  filterWrap: { flexDirection: 'row', flexWrap: 'wrap', alignItems: 'center', gap: 8 },
  filterDropdownRow: { flexDirection: 'row', justifyContent: 'flex-end', gap: 8 },
  compactDropdown: {
    minHeight: 40,
    minWidth: 118,
    maxWidth: 180,
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 12,
  },
  planDropdownRow: { flexDirection: 'row', gap: 8 },
  planSettingsRow: { flexDirection: 'row', alignItems: 'stretch', flexShrink: 0, gap: 8 },
  planSetting: {
    flex: 1,
    minWidth: 0,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    minHeight: 56,
    padding: 12,
  },
  planLoadMore: { minHeight: 48, alignItems: 'center', justifyContent: 'center', marginTop: 8 },
  planDropdown: {
    minHeight: 44,
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 12,
  },
  planRows: { gap: 8 },
  lootOutlook: { gap: 10, paddingHorizontal: 14, paddingVertical: 12 },
  lootOutlookHeader: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  lootOutlookImage: { width: 28, height: 28 },
  lootOutlookDivider: { height: StyleSheet.hairlineWidth },
  periodRow: { flexDirection: 'row', alignItems: 'flex-start', gap: 16 },
  periodSummary: { flex: 1, gap: 5 },
  periodCountRow: { minHeight: 28, flexDirection: 'row', alignItems: 'baseline', gap: 6 },
  periodResources: { gap: 3 },
  planResourceRow: { minHeight: 24, flexDirection: 'row', alignItems: 'center', gap: 5 },
  planResourceImage: { width: 16, height: 16 },
  muted: { opacity: 0.42 },
  overlay: { flex: 1, justifyContent: 'center', padding: 16, backgroundColor: '#00000070' },
  modal: {
    maxHeight: '90%',
    width: '100%',
    maxWidth: 760,
    alignSelf: 'center',
    padding: 14,
    gap: 10,
  },
  modalContent: { gap: 10, paddingBottom: 24 },
  detailHero: { flexDirection: 'row', alignItems: 'center', gap: 14 },
  detailImage: { width: 88, height: 88, resizeMode: 'contain' },
  detailLine: { minHeight: 44, flexDirection: 'row', alignItems: 'center', gap: 10, padding: 8 },
  collectionDetailImage: { width: '100%', height: 260, resizeMode: 'contain' },
  audio: { flexDirection: 'row', alignItems: 'center', gap: 12, padding: 12 },
  audioButton: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  audioTimeline: { flex: 1, gap: 4 },
  audioTrack: {
    height: 28,
    justifyContent: 'center',
    borderRadius: 999,
    backgroundColor: '#80808044',
  },
  audioTrackFill: { height: 3, borderRadius: 999, backgroundColor: '#D32F2F' },
  audioTimes: { flexDirection: 'row', justifyContent: 'space-between' },
  primaryButton: {
    minHeight: 48,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    padding: 12,
  },
  wrap: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  pill: {
    minHeight: 36,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 12,
    paddingVertical: 5,
    borderWidth: 1,
    borderColor: 'transparent',
  },
  choiceIcon: { width: 28, height: 28 },
  accountHall: { width: 44, height: 44, resizeMode: 'contain' },
});
