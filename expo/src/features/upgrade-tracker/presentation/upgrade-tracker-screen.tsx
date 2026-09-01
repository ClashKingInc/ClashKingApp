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
  Modal,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  View,
  useWindowDimensions,
  type LayoutChangeEvent,
  type NativeScrollEvent,
  type NativeSyntheticEvent,
} from 'react-native';
import {
  ArrowLeft,
  Check,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  Filter,
  Hammer,
  Headphones,
  Home,
  ImageIcon,
  Pause,
  Play,
  Search,
  Share2,
  SlidersHorizontal,
  Upload,
  Users,
  X,
} from 'lucide-react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';
import * as Clipboard from 'expo-clipboard';
import Svg, { Defs, LinearGradient, Rect, Stop } from 'react-native-svg';

import { ImageAssets } from '../../../core/assets/image-assets';
import {
  materialBackLabel,
  toIntlLocale,
  useI18n,
  type I18nValue,
  type MessageKey,
} from '../../../i18n';
import {
  CKText,
  EmptyState,
  GlassSurface,
  MobileWebImage,
  PillSurface,
  PressableSurface,
  ProfileTabs,
  ResponsiveGrid,
  SearchField,
  Skeleton,
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
  UpgradeVillage,
  type UpgradeCollectionItem,
  type UpgradeCollectionTypeValue,
  type UpgradeCategorySummary,
  type UpgradePlanPreferences as UpgradePlanPreferencesType,
  type PlannedUpgrade,
  type UpgradeTrackerItem,
  type UpgradeTrackerSnapshot,
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
import {
  UpgradeCategorySummaryModal,
  UpgradeCollectionSummaryModal,
  UpgradeItemDetailModal,
} from './upgrade-tracker-breakdowns';
import { UpgradeTrackerPlanEditor } from './upgrade-tracker-plan-editor';
import { UpgradeTrackerShareModal } from './upgrade-tracker-share';

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
  const viewportWidth = useWindowDimensions().width;
  const desktop = Platform.OS === 'web' && viewportWidth >= 900;
  const [tab, setTab] = useState<TrackerTab>('home');
  const [accountOpen, setAccountOpen] = useState(false);
  const [importOpen, setImportOpen] = useState(false);
  const [shareOpen, setShareOpen] = useState(false);
  const [shareKind, setShareKind] = useState<'home' | 'builder' | 'collection' | null>(null);
  const [settingsOpen, setSettingsOpen] = useState(false);
  const [goldPassOpen, setGoldPassOpen] = useState(false);
  const pager = useRef<PagerViewHandle>(null);
  const [trackerScrollY] = useState(() => new Animated.Value(0));
  const [trackerOffsets, setTrackerOffsets] = useState<Partial<Record<TrackerTab, number>>>({});
  const snapshot = props.snapshot;
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
      icon: <MobileWebImage imageUrl={ImageAssets.clanGamesMedals} style={styles.tabImage} />,
    },
  ];
  const selectTab = (next: TrackerTab) => {
    setTab(next);
    trackerScrollY.setValue(trackerOffsets[next] ?? 0);
    pager.current?.setPage(trackerTabs.indexOf(next));
  };
  const trackerHeaderHeight = (desktop ? 214 : 276) + insets.top;
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
        <View
          testID="upgrade-tracker-empty-header"
          style={[styles.header, { paddingTop: insets.top + 12 }]}
        >
          <IconButton label={materialBackLabel(locale)} onPress={props.onBack}>
            <ArrowLeft color={theme.onSurface} />
          </IconButton>
          <View style={styles.grow}>
            <CKText role="screenTitle">{t('upgradeTrackerTitle')}</CKText>
            <CKText muted role="labelSmall" numberOfLines={1}>
              {t('upgradeTrackerChooseAccount')}
            </CKText>
          </View>
          <IconButton label={t('upgradeTrackerChooseAccount')} onPress={() => setAccountOpen(true)}>
            <Users color={theme.onSurface} />
          </IconButton>
          <IconButton label={t('upgradeTrackerPasteJson')} onPress={() => setImportOpen(true)}>
            <Upload color={theme.onSurface} />
          </IconButton>
        </View>
      ) : null}
      {props.loading ? (
        <TrackerSkeleton />
      ) : props.error ? (
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
            actionLabel={props.selectedTag ? t('upgradeTrackerPasteClipboard') : undefined}
            onAction={
              props.selectedTag
                ? () =>
                    void Clipboard.getStringAsync()
                      .then((value) => importSnapshot(value.trim()))
                      .catch(() => undefined)
                : undefined
            }
          />
          {props.selectedTag ? (
            <PressableSurface
              accessibilityRole="button"
              onPress={props.onOpenGameSettings}
              style={styles.secondaryButton}
            >
              <CKText>{t('upgradeTrackerOpenMoreSettings')}</CKText>
            </PressableSurface>
          ) : null}
        </View>
      ) : (
        <View style={styles.trackerBody}>
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
            onSelect={(next) => {
              setTab(next);
              trackerScrollY.setValue(trackerOffsets[next] ?? 0);
            }}
          />
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
              tab={tab}
              plan={plan!}
              goldPassPercent={props.goldPassPercent}
              locale={locale}
              onBack={props.onBack}
              onAccount={() => setAccountOpen(true)}
              onGoldPass={() => setGoldPassOpen(true)}
              onPriorities={() => setSettingsOpen(true)}
              onShare={() => setShareOpen(true)}
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
        onImport={async (json) => {
          setImportOpen(false);
          await importSnapshot(json).catch(() => undefined);
        }}
      />
      <ChoiceModal
        visible={shareOpen}
        title={t('upgradeTrackerShare')}
        onClose={() => setShareOpen(false)}
      >
        <ChoiceRow
          label={t('upgradeTrackerShareProgress', {
            village: t('upgradeTrackerHomeVillage'),
          })}
          icon={<Home color={theme.onSurfaceVariant} />}
          onPress={() => {
            setShareOpen(false);
            setShareKind('home');
          }}
        />
        <ChoiceRow
          label={t('upgradeTrackerShareProgress', {
            village: t('upgradeTrackerBuilderBase'),
          })}
          icon={<Hammer color={theme.onSurfaceVariant} />}
          onPress={() => {
            setShareOpen(false);
            setShareKind('builder');
          }}
        />
        <ChoiceRow
          label={t('upgradeTrackerCollection')}
          icon={<ImageIcon color={theme.onSurfaceVariant} />}
          onPress={() => {
            setShareOpen(false);
            setShareKind('collection');
          }}
        />
      </ChoiceModal>
      {snapshot && shareKind ? (
        <UpgradeTrackerShareModal
          visible
          initial={shareKind}
          snapshot={snapshot}
          onClose={() => setShareKind(null)}
        />
      ) : null}
      {snapshot && settingsOpen ? (
        <UpgradeTrackerPlanEditor
          visible
          snapshot={snapshot}
          preferences={props.preferences}
          onClose={() => setSettingsOpen(false)}
          onSave={(value) => {
            props.onPreferencesChange(value);
            setSettingsOpen(false);
          }}
        />
      ) : null}
      <ChoiceModal
        visible={goldPassOpen}
        title={goldPassLabel(props.goldPassPercent, t)}
        onClose={() => setGoldPassOpen(false)}
      >
        {[0, 10, 15, 20].map((value) => (
          <ChoiceRow
            key={value}
            label={goldPassLabel(value, t)}
            selected={value === props.goldPassPercent}
            icon={<MobileWebImage imageUrl={ImageAssets.goldPass} style={styles.choiceIcon} />}
            onPress={() => {
              props.onGoldPassChange(value);
              setGoldPassOpen(false);
            }}
          />
        ))}
      </ChoiceModal>
    </SafeAreaView>
  );
}

function TrackerHeader({
  snapshot,
  tab,
  plan,
  goldPassPercent,
  locale,
  onBack,
  onAccount,
  onGoldPass,
  onPriorities,
  onShare,
  onImport,
}: {
  snapshot: UpgradeTrackerSnapshot;
  tab: TrackerTab;
  plan: ReturnType<typeof buildTrackerPlanData>;
  goldPassPercent: number;
  locale: Parameters<typeof materialBackLabel>[0];
  onBack: () => void;
  onAccount: () => void;
  onGoldPass: () => void;
  onPriorities: () => void;
  onShare: () => void;
  onImport: () => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const themeMode = useCKThemeMode();
  const insets = useSafeAreaInsets();
  const viewportWidth = useWindowDimensions().width;
  const desktop = Platform.OS === 'web' && viewportWidth >= 900;
  const village = tab === 'builder' ? UpgradeVillage.builderBase : UpgradeVillage.home;
  const collection = tab === 'collection';
  const summary = snapshot.overallSummary(village);
  const owned = snapshot.collections.filter((item) => item.owned).length;
  const builders = snapshot.buildersFor(village);
  const busy = snapshot
    .itemsFor({ village, queue: UpgradeQueue.builders })
    .filter((item) => snapshot.remainingActiveSeconds(item) > 0).length;
  const villageFinish = plan.allLanes
    .flatMap((lane) => lane.upgrades)
    .filter((upgrade) => upgrade.item.village === village)
    .reduce<Date | null>(
      (latest, upgrade) => (!latest || upgrade.endsAt > latest ? upgrade.endsAt : latest),
      null,
    );
  const hall = collection
    ? ImageAssets.townHall(snapshot.townHallLevel)
    : village === UpgradeVillage.home
      ? ImageAssets.townHall(snapshot.townHallLevel)
      : ImageAssets.builderHall(snapshot.builderHallLevel);
  const background =
    village === UpgradeVillage.home
      ? ImageAssets.homeBaseBackground
      : ImageAssets.builderBaseBackground;
  const values = collection
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
          image: ImageAssets.clanGamesMedals,
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
          value: `${(summary.completion * 100).toFixed(1)}%`,
          image: ImageAssets.iconTick,
        },
        {
          label: t('upgradeTrackerHeaderLevelsLeft'),
          value: String(summary.levelsRemaining),
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
    <View style={[styles.heroHeader, { height: (desktop ? 214 : 276) + insets.top }]}>
      <MobileWebImage imageUrl={background} contentFit="cover" style={styles.heroBackdrop} />
      <Svg pointerEvents="none" style={StyleSheet.absoluteFill}>
        <Defs>
          <LinearGradient id="tracker-header-scrim" x1="0" y1="0" x2="0" y2="1">
            <Stop offset="0" stopColor="#000" stopOpacity={themeMode === 'dark' ? 0.5 : 0.34} />
            <Stop offset="0.5" stopColor="#000" stopOpacity={themeMode === 'dark' ? 0.72 : 0.52} />
            <Stop offset="1" stopColor="#000" stopOpacity={themeMode === 'dark' ? 0.94 : 0.72} />
          </LinearGradient>
        </Defs>
        <Rect width="100%" height="100%" fill="url(#tracker-header-scrim)" />
      </Svg>
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
        <HeroIconButton label={goldPassLabel(goldPassPercent, t)} onPress={onGoldPass}>
          <MobileWebImage imageUrl={ImageAssets.goldPass} style={styles.heroActionImage} />
        </HeroIconButton>
        <HeroIconButton label={t('upgradeTrackerPlanPrioritiesTitle')} onPress={onPriorities}>
          <SlidersHorizontal color="white" />
        </HeroIconButton>
        <HeroIconButton label={t('upgradeTrackerShare')} onPress={onShare}>
          <Share2 color="white" />
        </HeroIconButton>
        <HeroIconButton label={t('upgradeTrackerPasteJson')} onPress={onImport}>
          <Upload color="white" />
        </HeroIconButton>
      </View>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={t('upgradeTrackerChooseAccount')}
        onPress={onAccount}
        style={styles.heroProfile}
      >
        <MobileWebImage
          imageUrl={hall}
          style={[styles.heroHall, desktop && styles.heroHallDesktop]}
        />
        <View style={styles.heroNameRow}>
          <CKText
            role="titleLarge"
            style={[styles.heroText, { fontSize: desktop ? 24 : 26, fontWeight: '700' }]}
            numberOfLines={1}
          >
            {snapshot.name}
          </CKText>
          <ChevronDown color="white" size={20} />
        </View>
        <CKText role="labelSmall" style={styles.heroSecondary}>
          {snapshot.tag}
        </CKText>
        <CKText role="labelSmall" style={styles.heroSecondary}>
          {snapshotAgeLabel(snapshot.capturedAt, locale, t)}
        </CKText>
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
            <MobileWebImage imageUrl={value.image} style={styles.quickStatImage} />
            <CKText role="labelLarge">{value.value}</CKText>
          </View>
        ))}
      </View>
    </View>
  );
}

function TrackerSkeleton() {
  return (
    <View accessibilityRole="progressbar" style={styles.skeletonPage}>
      {Array.from({ length: 5 }, (_, index) => (
        <Surface key={index} radius={ckRadius.card} style={styles.skeletonCard}>
          <Skeleton width={48} height={48} radius={ckRadius.tile} />
          <View style={styles.grow}>
            <Skeleton width="64%" height={16} />
            <Skeleton width="42%" height={12} />
          </View>
        </Surface>
      ))}
    </View>
  );
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

function snapshotAgeLabel(
  capturedAt: Date,
  locale: Parameters<typeof materialBackLabel>[0],
  t: ReturnType<typeof useI18n>['t'],
) {
  const minutes = Math.floor(Math.max(0, Date.now() - capturedAt.getTime()) / 60_000);
  if (minutes < 1) return t('upgradeTrackerUpdatedJustNow');
  if (minutes < 60) return t('upgradeTrackerUpdatedMinutesAgo', { count: minutes });
  if (minutes < 24 * 60)
    return t('upgradeTrackerUpdatedHoursAgo', { count: Math.floor(minutes / 60) });
  return t('upgradeTrackerUpdatedOn', {
    date: new Intl.DateTimeFormat(toIntlLocale(locale), {
      dateStyle: 'medium',
      timeStyle: 'short',
    }).format(capturedAt),
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
  const theme = useCKTheme();
  const viewportWidth = useWindowDimensions().width;
  const desktop = Platform.OS === 'web' && viewportWidth >= 900;
  const cachePrefix = village === UpgradeVillage.home ? 'home' : 'builder';
  const [query, setQuery] = useCachedPageState(stateStore, `${cachePrefix}.query`, '');
  const [selected, setSelected] = useState<UpgradeTrackerItem | null>(null);
  const [summary, setSummary] = useState<{
    title: string;
    value: UpgradeCategorySummary;
  } | null>(null);
  const [expanded, setExpanded] = useCachedPageState<ReadonlySet<UpgradeGroup>>(
    stateStore,
    `${cachePrefix}.expanded`,
    () => new Set(),
  );
  const initialContentOffset = useInitialScrollOffset(initialOffset);
  const active = uniqueUpgradeItems(
    activeTrackerItems(snapshot).filter((item) => item.village === village),
  );
  const groups = groupedUpgradeItems(
    filteredUpgradeItems(snapshot, village, query, false),
    village,
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
      {active.length ? (
        <Section title={t('upgradeTrackerHeaderActive')}>
          {active.map((item) => (
            <UpgradeRow
              key={`active-${upgradeItemRenderIdentity(item)}`}
              item={item}
              snapshot={snapshot}
              onPress={() => setSelected(item)}
            />
          ))}
        </Section>
      ) : null}
      <View style={desktop ? styles.desktopSectionGrid : undefined}>
        {groups.map(([group, items]) => {
          const open = expanded.has(group);
          const summary = snapshot.summaryForItems(items);
          return (
            <Surface
              key={group}
              radius={ckRadius.card}
              style={[
                styles.upgradeGroupSection,
                open && styles.upgradeGroupSectionOpen,
                desktop && styles.desktopSection,
              ]}
            >
              <Pressable
                accessibilityRole="button"
                accessibilityLabel={upgradeGroupLabel(group, village, t)}
                onPress={() =>
                  setExpanded((current) => {
                    const next = new Set(current);
                    if (next.has(group)) next.delete(group);
                    else next.add(group);
                    return next;
                  })
                }
                style={styles.collapsibleHeader}
              >
                <ChevronRight
                  size={22}
                  color={colorWithAlpha(theme.onSurface, 0.72)}
                  style={{ transform: [{ rotate: open ? '90deg' : '0deg' }] }}
                />
                <MobileWebImage
                  imageUrl={items[0]?.imageUrl ?? ImageAssets.defaultImage}
                  style={styles.groupImage}
                />
                <View style={styles.grow}>
                  <CKText role="sectionTitle">{upgradeGroupLabel(group, village, t)}</CKText>
                  <CKText muted role="labelSmall">
                    {t('upgradeTrackerLevelsLeft', { count: summary.levelsRemaining })} ·{' '}
                    {t('upgradeTrackerItemCount', { count: items.length })}
                  </CKText>
                </View>
                <SectionProgressBadge
                  progress={summary.completion}
                  accessibilityLabel={t('upgradeTrackerGroupSummary', {
                    group: upgradeGroupLabel(group, village, t),
                  })}
                  onPress={() =>
                    setSummary({ title: upgradeGroupLabel(group, village, t), value: summary })
                  }
                />
              </Pressable>
              {open ? (
                <UpgradeGroupTiles
                  group={group}
                  items={items}
                  snapshot={snapshot}
                  onSelect={setSelected}
                />
              ) : null}
            </Surface>
          );
        })}
      </View>
      {!groups.length ? <EmptyState title={t('upgradeTrackerNoMatchingItems')} /> : null}
      <UpgradeItemDetailModal
        item={selected}
        snapshot={snapshot}
        onClose={() => setSelected(null)}
      />
      <UpgradeCategorySummaryModal
        visible={summary !== null}
        title={summary?.title ?? ''}
        summary={summary?.value ?? null}
        onClose={() => setSummary(null)}
      />
    </Animated.ScrollView>
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
            <ResponsiveGrid minItemWidth={54} maxColumns={12} gap={8}>
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

function SectionProgressBadge({
  progress,
  accessibilityLabel,
  onPress,
}: {
  progress: number;
  accessibilityLabel: string;
  onPress: () => void;
}) {
  const theme = useCKTheme();
  const [size, setSize] = useState({ width: 0, height: 0 });
  const normalized = Math.max(0, Math.min(1, progress));
  const progressColor = normalized >= 1 ? '#FFD75E' : '#E0302B';
  const perimeter = Math.max(1, 2 * (size.width + size.height - 4));
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={accessibilityLabel}
      onLayout={(event: LayoutChangeEvent) => setSize(event.nativeEvent.layout)}
      onPress={(event) => {
        event.stopPropagation();
        onPress();
      }}
      style={[
        styles.sectionProgressBadge,
        {
          backgroundColor:
            normalized >= 1
              ? colorWithAlpha(progressColor, 0.14)
              : colorWithAlpha(theme.surfaceContainerHighest, 0.55),
        },
      ]}
    >
      {size.width > 0 && size.height > 0 ? (
        <Svg
          pointerEvents="none"
          width={size.width}
          height={size.height}
          style={StyleSheet.absoluteFill}
        >
          <Rect
            x={1}
            y={1}
            width={Math.max(0, size.width - 2)}
            height={Math.max(0, size.height - 2)}
            rx={Math.max(0, size.height / 2 - 1)}
            fill="none"
            stroke={colorWithAlpha(theme.outlineVariant, 0.58)}
            strokeWidth={2}
          />
          <Rect
            x={1}
            y={1}
            width={Math.max(0, size.width - 2)}
            height={Math.max(0, size.height - 2)}
            rx={Math.max(0, size.height / 2 - 1)}
            fill="none"
            stroke={progressColor}
            strokeDasharray={`${perimeter * normalized} ${perimeter}`}
            strokeLinecap="round"
            strokeWidth={2}
          />
        </Svg>
      ) : null}
      <CKText role="labelMedium" style={styles.sectionProgressLabel}>
        {formatSectionProgress(normalized)}%
      </CKText>
    </Pressable>
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

function UpgradeRow({
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
  return (
    <PressableSurface
      accessibilityRole="button"
      accessibilityLabel={item.name}
      onPress={onPress}
      style={styles.row}
    >
      <MobileWebImage imageUrl={item.imageUrl} style={styles.itemImage} />
      <View style={styles.grow}>
        <CKText role="rowTitle" numberOfLines={1}>
          {item.name}
        </CKText>
        <CKText muted role="labelSmall">
          {t('gameLevel', { level: item.currentLevel, maxLevel: item.targetLevel })} ·{' '}
          {t('upgradeTrackerLevelsLeft', { count: item.levelsRemaining })}
        </CKText>
        {remaining > 0 ? (
          <CKText role="labelSmall">
            {t('upgradeTrackerTimelineRemainingDuration', {
              duration: formatTrackerDuration(remaining),
            })}
          </CKText>
        ) : null}
      </View>
      <Progress value={item.progressCompletion} />
      <ChevronRight color={theme.onSurfaceVariant} />
    </PressableSurface>
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
      accessibilityLabel={t('upgradeTrackerItemSemanticLabel', {
        item: item.name,
        currentLevel: item.currentLevel,
        targetLevel: item.targetLevel,
        count: item.count,
      })}
      onPress={onPress}
    >
      <View
        style={[
          styles.upgradeTile,
          {
            backgroundColor: frameBackground,
            borderColor: frameBorder,
            shadowColor: item.isComplete ? frameBorder : 'transparent',
          },
        ]}
      >
        <View style={[styles.upgradeTileArt, containedArt && styles.upgradeTileContainedArt]}>
          <MobileWebImage
            imageUrl={item.imageUrl}
            contentFit={containedArt ? 'contain' : 'cover'}
            style={styles.upgradeTileImage}
          />
        </View>
        <View style={[styles.levelBadge, item.isComplete && styles.levelBadgeComplete]}>
          <CKText
            role="labelSmall"
            style={item.isComplete ? styles.levelBadgeTextComplete : styles.levelBadgeText}
          >
            {item.currentLevel}
          </CKText>
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
  const [period, setPeriod] = useCachedPageState(stateStore, 'calendar.period', 0);
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
  const [horizontalTranslate] = useState(() => new Animated.Value(horizontalOffset));
  const handleHorizontalScroll = useMemo(
    () =>
      Animated.event([{ nativeEvent: { contentOffset: { x: horizontalTranslate } } }], {
        useNativeDriver: Platform.OS !== 'web' && process.env.NODE_ENV !== 'test',
      }),
    [horizontalTranslate],
  );
  const commitHorizontalScroll = (event: NativeSyntheticEvent<NativeScrollEvent>) => {
    const offset = Math.max(0, event.nativeEvent.contentOffset.x);
    setHorizontalOffset(offset);
  };
  const [selected, setSelected] = useState<PlannedUpgrade | null>(null);
  const groups = [
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
  ] as const;
  const allCalendarUpgrades = groups.flatMap(([, , , , lanes]) =>
    lanes.flatMap((lane) => lane.upgrades),
  );
  const start = new Date(plan.startsAt);
  start.setHours(0, 0, 0, 0);
  const latest = allCalendarUpgrades.reduce<Date | null>(
    (value, upgrade) => (!value || upgrade.endsAt > value ? upgrade.endsAt : value),
    null,
  );
  const maxPeriod = latest
    ? Math.max(0, Math.floor((latest.getTime() - start.getTime()) / (30 * 86_400_000)))
    : 0;
  const firstDay = new Date(start.getTime() + period * 30 * 86_400_000);
  const lastDay = new Date(firstDay.getTime() + 29 * 86_400_000);
  const horizonEnd = new Date(firstDay.getTime() + 30 * 86_400_000);
  const dayWidth = 64;
  const labelWidth = 56;
  const timelineWidth = dayWidth * 30;
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
      contentContainerStyle={[styles.calendarRoot, { paddingTop: contentInset + 12 }]}
      contentOffset={initialContentOffset}
      onScroll={onScroll}
      onMomentumScrollEnd={onScrollSettled}
      onScrollEndDrag={onScrollSettled}
      scrollEventThrottle={16}
    >
      <View style={styles.periodBar}>
        <IconButton
          label={t('upgradeTrackerPreviousPeriod')}
          onPress={() => setPeriod(Math.max(0, period - 1))}
        >
          <ChevronLeft color={theme.onSurface} />
        </IconButton>
        <View style={styles.grow}>
          <CKText role="labelLarge" style={styles.centerText}>
            {firstDay.toLocaleDateString(toIntlLocale(locale), {
              month: 'short',
              day: 'numeric',
            })}{' '}
            –{' '}
            {lastDay.toLocaleDateString(toIntlLocale(locale), {
              month: 'short',
              day: 'numeric',
            })}
          </CKText>
          <CKText muted role="labelSmall" style={styles.centerText}>
            {maxPeriod > 0
              ? t('upgradeTrackerPeriodCount', { current: period + 1, total: maxPeriod + 1 })
              : ''}
          </CKText>
        </View>
        <IconButton
          label={t('upgradeTrackerNextPeriod')}
          onPress={() => setPeriod(Math.min(maxPeriod, period + 1))}
        >
          <ChevronRight color={theme.onSurface} />
        </IconButton>
      </View>
      <Animated.ScrollView
        testID="upgrade-tracker-calendar-timeline"
        contentOffset={initialHorizontalContentOffset}
        directionalLockEnabled
        horizontal
        nestedScrollEnabled
        onScroll={handleHorizontalScroll}
        onMomentumScrollEnd={commitHorizontalScroll}
        onScrollEndDrag={commitHorizontalScroll}
        scrollEventThrottle={16}
        showsHorizontalScrollIndicator
      >
        <View style={styles.calendarContent}>
          <View style={{ width: labelWidth + timelineWidth }}>
            <View style={styles.calendarDayHeader}>
              <View style={{ width: labelWidth }} />
              {Array.from({ length: 30 }, (_, index) => {
                const day = new Date(firstDay.getTime() + index * 86_400_000);
                const today = sameDay(day, now);
                return (
                  <CKText
                    key={day.toISOString()}
                    role="labelSmall"
                    style={[
                      styles.calendarDay,
                      { width: dayWidth },
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
            {groups
              .filter(([, , , , lanes]) => lanes.some((lane) => lane.upgrades.length))
              .map(([key, title, queue, capacity, lanes, accent]) => {
                const upgrades = lanes.flatMap((lane) => lane.upgrades);
                const nextFinish = upgrades
                  .filter((upgrade) => upgrade.endsAt > now)
                  .sort((a, b) => a.endsAt.getTime() - b.endsAt.getTime())[0];
                return (
                  <Surface key={key} radius={ckRadius.card} style={styles.calendarSection}>
                    <Pressable
                      accessibilityRole="button"
                      accessibilityState={{ expanded: expanded.has(key) }}
                      onPress={() => toggle(key)}
                      style={styles.calendarSectionHeader}
                    >
                      <ChevronRight
                        size={20}
                        color={theme.onSurfaceVariant}
                        style={{ transform: [{ rotate: expanded.has(key) ? '90deg' : '0deg' }] }}
                      />
                      <MobileWebImage
                        imageUrl={calendarGroupImage(snapshot, key)}
                        contentFit="contain"
                        style={styles.calendarGroupImage}
                      />
                      <CKText role="sectionTitle" style={styles.grow}>
                        {title}
                      </CKText>
                      <PillSurface style={styles.calendarPill}>
                        <CKText role="labelSmall">
                          {t('upgradeTrackerItemCount', { count: upgrades.length })}
                        </CKText>
                      </PillSurface>
                      {nextFinish ? (
                        <PillSurface style={styles.calendarPill}>
                          <CKText role="labelSmall">
                            ⚑{' '}
                            {formatTrackerDuration(
                              (nextFinish.endsAt.getTime() - now.getTime()) / 1000,
                            )}
                          </CKText>
                        </PillSurface>
                      ) : null}
                    </Pressable>
                    {expanded.has(key)
                      ? lanes
                          .filter((lane) => lane.upgrades.length)
                          .map((lane) => (
                            <View
                              key={`${key}-${lane.index}`}
                              style={[styles.calendarLane, { width: labelWidth + timelineWidth }]}
                            >
                              <View
                                style={[
                                  styles.calendarGrid,
                                  { left: labelWidth, width: timelineWidth },
                                ]}
                              >
                                {Array.from({ length: 30 }, (_, index) => (
                                  <View
                                    key={index}
                                    style={[
                                      styles.calendarGridDay,
                                      { left: index * dayWidth, width: dayWidth },
                                    ]}
                                  />
                                ))}
                                {lane.upgrades
                                  .filter(
                                    (upgrade) =>
                                      upgrade.endsAt > firstDay && upgrade.startsAt < horizonEnd,
                                  )
                                  .map((upgrade, index) => {
                                    const visibleStart =
                                      upgrade.startsAt < firstDay ? firstDay : upgrade.startsAt;
                                    const visibleEnd =
                                      upgrade.endsAt > horizonEnd ? horizonEnd : upgrade.endsAt;
                                    const left =
                                      ((visibleStart.getTime() - firstDay.getTime()) / 86_400_000) *
                                      dayWidth;
                                    const width = Math.max(
                                      1,
                                      ((visibleEnd.getTime() - visibleStart.getTime()) /
                                        86_400_000) *
                                        dayWidth,
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
                                  })}
                                {now >= firstDay && now < horizonEnd ? (
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
                              <Animated.View
                                style={[
                                  styles.calendarLaneLabel,
                                  {
                                    width: labelWidth,
                                    transform: [{ translateX: horizontalTranslate }],
                                  },
                                ]}
                              >
                                <CKText muted role="labelSmall">
                                  {planLaneLabel(queue, lane.index, capacity)}
                                </CKText>
                              </Animated.View>
                            </View>
                          ))
                      : null}
                  </Surface>
                );
              })}
          </View>
        </View>
      </Animated.ScrollView>
      {selected ? (
        <PlannedUpgradeModal upgrade={selected} onClose={() => setSelected(null)} />
      ) : null}
    </Animated.ScrollView>
  );
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
                <CKText role="labelSmall" numberOfLines={1}>
                  {upgrade.isOngoing ? `Ongoing: ${upgrade.item.name}` : upgrade.item.name}
                </CKText>
                {metadata ? (
                  <CKText muted role="labelSmall" numberOfLines={1}>
                    Level {upgrade.step.targetLevel} ·{' '}
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
  return (
    <Modal visible transparent animationType="slide" onRequestClose={onClose}>
      <View style={styles.overlay}>
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
              <CKText role="titleLarge">{upgrade.item.name}</CKText>
              <CKText muted role="bodySmall">
                {t('upgradeTrackerLevelTransition', {
                  from: upgrade.item.currentLevel,
                  to: upgrade.step.targetLevel,
                })}{' '}
                ·{' '}
                {upgrade.item.village === UpgradeVillage.home
                  ? t('upgradeTrackerHomeVillage')
                  : t('upgradeTrackerBuilderBase')}{' '}
                · {upgrade.item.category}
              </CKText>
            </View>
            <IconButton label={t('upgradeTrackerPlanClose')} onPress={onClose}>
              <X color={theme.onSurface} />
            </IconButton>
          </View>
          <View style={styles.timelineDetailGrid}>
            <TimelineDetailMetric
              label={t('warAttacksDetailsDuration')}
              value={formatTrackerDuration(
                (upgrade.endsAt.getTime() - upgrade.startsAt.getTime()) / 1000,
              )}
            />
            <TimelineDetailMetric
              label={t('upgradeTrackerStarts')}
              value={upgrade.startsAt.toLocaleString(intlLocale)}
            />
            <TimelineDetailMetric
              label={t('upgradeTrackerHeaderFinishes')}
              value={upgrade.endsAt.toLocaleString(intlLocale)}
            />
            <TimelineDetailMetric
              label={t('upgradeTrackerLane')}
              value={
                upgrade.isOngoing
                  ? t('upgradeTrackerInProgress')
                  : t('upgradeTrackerScheduledLane', { lane: upgrade.instance })
              }
            />
          </View>
          {upgrade.costs.length ? (
            <>
              <CKText role="sectionTitle">{t('gameItemUpgradeCost')}</CKText>
              <View style={styles.wrap}>
                {upgrade.costs.map((cost) => (
                  <PillSurface key={`${cost.resource}-${cost.amount}`} style={styles.pill}>
                    <CKText role="labelSmall">
                      {compactNumber(cost.amount, intlLocale)} {planResourceLabel(cost.resource, t)}
                    </CKText>
                  </PillSurface>
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
    <Surface radius={ckRadius.tile} style={styles.timelineDetailMetric}>
      <CKText muted role="labelSmall">
        {label}
      </CKText>
      <CKText role="rowTitle">{value}</CKText>
    </Surface>
  );
}

function PlanTab({
  plan,
  stateStore,
  contentInset,
  initialOffset,
  onScroll,
  onScrollSettled,
}: {
  plan: ReturnType<typeof buildTrackerPlanData>;
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
  const [picker, setPicker] = useState<'village' | 'sort' | null>(null);
  const initialContentOffset = useInitialScrollOffset(initialOffset);
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
      <LootOutlook plan={plan} />
      <View style={styles.filterWrap}>
        {(['all', 'builders', 'laboratory', 'pets', 'walls'] as const).map((value) => (
          <FilterPill key={value} selected={queue === value} onPress={() => setQueue(value)}>
            {queueLabels[value]}
          </FilterPill>
        ))}
      </View>
      <View style={styles.planDropdownRow}>
        <PressableSurface
          accessibilityRole="button"
          accessibilityState={{ expanded: picker === 'village' }}
          onPress={() => setPicker('village')}
          style={styles.planDropdown}
        >
          <CKText style={styles.grow}>{villageLabels[village]}</CKText>
          <ChevronDown size={18} color={theme.onSurfaceVariant} />
        </PressableSurface>
        <PressableSurface
          accessibilityRole="button"
          accessibilityState={{ expanded: picker === 'sort' }}
          onPress={() => setPicker('sort')}
          style={styles.planDropdown}
        >
          <CKText style={styles.grow}>{sortLabels[sort]}</CKText>
          <ChevronDown size={18} color={theme.onSurfaceVariant} />
        </PressableSurface>
      </View>
      {!groups.length ? (
        <EmptyState
          title={t('upgradeTrackerNoMatchingUpgrades')}
          body={t('upgradeTrackerNoMatchingUpgradesBody')}
        />
      ) : (
        <View style={[styles.planRows, desktop && styles.desktopSectionGrid]}>
          {groups.map((group) => {
            const upgrade = group.upgrades[0]!;
            return (
              <Surface
                key={`${upgradeItemRenderIdentity(upgrade.item)}-${upgrade.instance}-${upgrade.step.targetLevel}-${upgrade.startsAt.getTime()}-${group.upgrades.length}`}
                radius={ckRadius.tile}
                style={[styles.row, desktop && styles.desktopSection]}
              >
                <MobileWebImage imageUrl={upgrade.item.imageUrl} style={styles.itemImage} />
                <View style={styles.grow}>
                  <CKText role="rowTitle">
                    {upgrade.item.name}
                    {group.upgrades.length > 1 ? ` ×${group.upgrades.length}` : ''}
                  </CKText>
                  <CKText muted role="labelSmall">
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
                    <CKText muted role="labelSmall">
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
              </Surface>
            );
          })}
        </View>
      )}
      <ChoiceModal
        visible={picker !== null}
        title={picker === 'village' ? t('dashboardUpgradeTrackerVillage') : t('statsSortBy')}
        onClose={() => setPicker(null)}
      >
        {picker === 'village'
          ? (Object.keys(villageLabels) as (keyof typeof villageLabels)[]).map((value) => (
              <ChoiceRow
                key={value}
                label={villageLabels[value]}
                selected={village === value}
                onPress={() => {
                  setVillage(value);
                  setPicker(null);
                }}
              />
            ))
          : (Object.keys(sortLabels) as (keyof typeof sortLabels)[]).map((value) => (
              <ChoiceRow
                key={value}
                label={sortLabels[value]}
                selected={sort === value}
                onPress={() => {
                  setSort(value);
                  setPicker(null);
                }}
              />
            ))}
      </ChoiceModal>
    </Animated.ScrollView>
  );
}

function LootOutlook({ plan }: { plan: ReturnType<typeof buildTrackerPlanData> }) {
  const { t } = useI18n();
  const theme = useCKTheme();
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
        <CKText role="sectionTitle">{t('upgradeTrackerLootOutlook')}</CKText>
      </View>
      <PlanPeriodSummary
        label={t('upgradeTrackerLootNow')}
        upgrades={lootNow}
        countLabel={
          lootNow.length
            ? t('upgradeTrackerIdleBuilders', { count: lootNow.length })
            : t('upgradeTrackerAllBuildersOccupied')
        }
        emptyLabel={t('upgradeTrackerNothingNeededNow')}
        showCount={false}
      />
      <View
        accessibilityElementsHidden
        importantForAccessibility="no-hide-descendants"
        style={[
          styles.lootOutlookDivider,
          { backgroundColor: colorWithAlpha(theme.onSurface, 0.1) },
        ]}
      />
      <View style={styles.periodRow}>
        <PlanPeriodSummary label={t('upgradeTrackerNextDays', { count: 7 })} upgrades={within(7)} />
        <PlanPeriodSummary
          label={t('upgradeTrackerNextDays', { count: 30 })}
          upgrades={within(30)}
        />
      </View>
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
  label: string;
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
  const resources = [...costs.entries()]
    .sort(([left], [right]) => planResourceWeight(left) - planResourceWeight(right))
    .slice(0, 4);
  return (
    <View style={styles.periodSummary}>
      <CKText role="labelLarge">{label}</CKText>
      <View style={styles.periodCountRow}>
        {showCount ? <CKText role="titleLarge">{upgrades.length}</CKText> : null}
        <CKText muted={!showCount} role={showCount ? 'labelSmall' : 'rowTitle'} style={styles.grow}>
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
                <CKText muted numberOfLines={1} role="labelSmall" style={styles.grow}>
                  {resourceLabel}
                </CKText>
                <CKText role="labelSmall">{formattedAmount}</CKText>
              </View>
            );
          })}
        </View>
      ) : (
        <CKText muted role="labelSmall">
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

function FilterPill({
  selected,
  onPress,
  children,
}: {
  selected: boolean;
  onPress: () => void;
  children: ReactNode;
}) {
  const theme = useCKTheme();
  return (
    <PressableSurface
      accessibilityRole="button"
      accessibilityState={{ selected }}
      onPress={onPress}
      style={[
        styles.pill,
        selected && { borderColor: theme.primary, backgroundColor: theme.surfaceContainerHighest },
      ]}
    >
      <CKText role="labelSmall">{children}</CKText>
    </PressableSurface>
  );
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
  const viewportWidth = useWindowDimensions().width;
  const desktop = Platform.OS === 'web' && viewportWidth >= 900;
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
  const [showFilters, setShowFilters] = useCachedPageState(
    stateStore,
    'collection.showFilters',
    false,
  );
  const [picker, setPicker] = useState<'village' | 'sort' | null>(null);
  const [expanded, setExpanded] = useCachedPageState<ReadonlySet<UpgradeCollectionTypeValue>>(
    stateStore,
    'collection.expanded',
    () => new Set(),
  );
  const [selected, setSelected] = useState<UpgradeCollectionItem | null>(null);
  const [summaryType, setSummaryType] = useState<UpgradeCollectionTypeValue | null>(null);
  const initialContentOffset = useInitialScrollOffset(initialOffset);
  const collectionItems = useMemo(
    () => uniqueCollectionItems(snapshot.collections),
    [snapshot.collections],
  );
  const supportsVillage =
    collectionItems.some((item) => item.village === UpgradeVillage.home) &&
    collectionItems.some((item) => item.village === UpgradeVillage.builderBase);
  const items = collectionItems
    .filter(
      (item) =>
        (!query.trim() ||
          item.name.toLocaleLowerCase().includes(query.trim().toLocaleLowerCase())) &&
        (filter === 'all' || item.owned === (filter === 'owned')) &&
        (village === 'all' ||
          item.type === UpgradeCollectionType.capitalHouseParts ||
          item.village === (village === 'home' ? UpgradeVillage.home : UpgradeVillage.builderBase)),
    )
    .sort((left, right) => {
      if (sort === 'nameAscending') return left.name.localeCompare(right.name);
      if (sort === 'nameDescending') return right.name.localeCompare(left.name);
      return sort === 'newest' ? right.id - left.id : left.id - right.id;
    });
  const groups = Object.values(UpgradeCollectionType)
    .map((type) => [type, items.filter((item) => item.type === type)] as const)
    .filter(([type]) =>
      collectionItems.some(
        (item) =>
          item.type === type &&
          (village === 'all' ||
            type === UpgradeCollectionType.capitalHouseParts ||
            item.village ===
              (village === 'home' ? UpgradeVillage.home : UpgradeVillage.builderBase)),
      ),
    );
  const villageLabels = {
    all: t('upgradeTrackerAllVillages'),
    home: t('upgradeTrackerHomeVillage'),
    builderBase: t('upgradeTrackerBuilderBase'),
  } as const;
  const sortLabels = {
    nameAscending: 'A → Z',
    nameDescending: 'Z → A',
    newest: t('warEventsNewest'),
    oldest: t('warEventsOldest'),
  } as const;
  return (
    <Animated.ScrollView
      testID="upgrade-tracker-collection-scroll"
      contentContainerStyle={[styles.content, { paddingTop: contentInset + 12 }]}
      contentOffset={initialContentOffset}
      onScroll={onScroll}
      onMomentumScrollEnd={onScrollSettled}
      onScrollEndDrag={onScrollSettled}
      scrollEventThrottle={16}
    >
      <SearchBar
        value={query}
        onChange={setQuery}
        placeholder={t('upgradeTrackerSearchCollection')}
        filtered={filter !== 'all' || village !== 'all' || sort !== 'nameAscending'}
        filterTestID="upgrade-tracker-collection-filter"
        onFilter={() => setShowFilters((value) => !value)}
      />
      {showFilters ? (
        <View style={styles.filterPanel}>
          <View style={styles.filterWrap}>
            {(['all', 'owned', 'missing'] as const).map((value) => (
              <FilterPill key={value} selected={filter === value} onPress={() => setFilter(value)}>
                {value === 'all'
                  ? t('upgradeTrackerFilterAll')
                  : value === 'owned'
                    ? t('upgradeTrackerFilterOwned')
                    : t('upgradeTrackerFilterMissing')}
              </FilterPill>
            ))}
          </View>
          <View style={styles.filterDropdownRow}>
            {supportsVillage ? (
              <PressableSurface
                testID="upgrade-tracker-collection-village-filter"
                accessibilityRole="button"
                accessibilityState={{ expanded: picker === 'village' }}
                onPress={() => setPicker('village')}
                style={styles.compactDropdown}
              >
                <CKText numberOfLines={1} style={styles.grow}>
                  {villageLabels[village]}
                </CKText>
                <ChevronDown size={18} color={theme.onSurfaceVariant} />
              </PressableSurface>
            ) : null}
            <PressableSurface
              testID="upgrade-tracker-collection-sort-filter"
              accessibilityRole="button"
              accessibilityState={{ expanded: picker === 'sort' }}
              onPress={() => setPicker('sort')}
              style={styles.compactDropdown}
            >
              <CKText numberOfLines={1} style={styles.grow}>
                {sortLabels[sort]}
              </CKText>
              <ChevronDown size={18} color={theme.onSurfaceVariant} />
            </PressableSurface>
          </View>
        </View>
      ) : null}
      <View style={desktop ? styles.desktopSectionGrid : undefined}>
        {groups.map(([type, values]) => {
          const scoped = collectionItems.filter(
            (item) =>
              item.type === type &&
              (village === 'all' ||
                type === UpgradeCollectionType.capitalHouseParts ||
                item.village ===
                  (village === 'home' ? UpgradeVillage.home : UpgradeVillage.builderBase)),
          );
          const scopedOwned = scoped.filter((item) => item.owned).length;
          return (
            <Surface
              key={type}
              radius={ckRadius.card}
              style={[
                styles.upgradeGroupSection,
                expanded.has(type) && styles.upgradeGroupSectionOpen,
                desktop && styles.desktopSection,
              ]}
            >
              <Pressable
                accessibilityRole="button"
                accessibilityLabel={collectionTypeLabel(type, t)}
                onPress={() =>
                  setExpanded((current) => {
                    const next = new Set(current);
                    if (next.has(type)) next.delete(type);
                    else next.add(type);
                    return next;
                  })
                }
                style={styles.collapsibleHeader}
              >
                <ChevronRight
                  size={22}
                  color={colorWithAlpha(theme.onSurface, 0.72)}
                  style={{ transform: [{ rotate: expanded.has(type) ? '90deg' : '0deg' }] }}
                />
                <MobileWebImage
                  imageUrl={scoped[0]?.imageUrl ?? ImageAssets.defaultImage}
                  style={styles.groupImage}
                />
                <View style={styles.grow}>
                  <CKText role="sectionTitle">{collectionTypeLabel(type, t)}</CKText>
                  <CKText muted role="labelSmall">
                    {t('upgradeTrackerOwnedCount', {
                      owned: scopedOwned,
                      total: scoped.length,
                    })}
                  </CKText>
                </View>
                <SectionProgressBadge
                  progress={scopedOwned / scoped.length}
                  accessibilityLabel={t('upgradeTrackerGroupSummary', {
                    group: collectionTypeLabel(type, t),
                  })}
                  onPress={() => setSummaryType(type)}
                />
              </Pressable>
              {expanded.has(type) ? (
                values.length ? (
                  <ResponsiveGrid minItemWidth={104} maxColumns={7}>
                    {values.map((item) => (
                      <Pressable
                        key={collectionItemRenderIdentity(item)}
                        accessibilityRole="button"
                        accessibilityLabel={collectionDisplayName(item)}
                        onPress={() => setSelected(item)}
                      >
                        <Surface
                          radius={ckRadius.tile}
                          style={[styles.collectionTile, !item.owned && styles.muted]}
                        >
                          <MobileWebImage imageUrl={item.imageUrl} style={styles.collectionImage} />
                          <CKText role="labelSmall" numberOfLines={2}>
                            {collectionDisplayName(item)}
                          </CKText>
                          {item.owned ? <Check size={16} color={theme.primary} /> : null}
                        </Surface>
                      </Pressable>
                    ))}
                  </ResponsiveGrid>
                ) : (
                  <EmptyState title={t('upgradeTrackerNoMatchingItems')} />
                )
              ) : null}
            </Surface>
          );
        })}
      </View>
      <ChoiceModal
        visible={picker !== null}
        title={picker === 'village' ? t('dashboardUpgradeTrackerVillage') : t('statsSortBy')}
        onClose={() => setPicker(null)}
      >
        {picker === 'village'
          ? (Object.keys(villageLabels) as (keyof typeof villageLabels)[]).map((value) => (
              <ChoiceRow
                key={value}
                label={villageLabels[value]}
                selected={village === value}
                onPress={() => {
                  setVillage(value);
                  setPicker(null);
                }}
              />
            ))
          : (Object.keys(sortLabels) as (keyof typeof sortLabels)[]).map((value) => (
              <ChoiceRow
                key={value}
                label={sortLabels[value]}
                selected={sort === value}
                onPress={() => {
                  setSort(value);
                  setPicker(null);
                }}
              />
            ))}
      </ChoiceModal>
      <CollectionDetailModal item={selected} onClose={() => setSelected(null)} />
      <UpgradeCollectionSummaryModal
        visible={summaryType !== null}
        title={summaryType ? collectionTypeLabel(summaryType, t) : ''}
        items={
          summaryType
            ? collectionItems.filter(
                (item) =>
                  item.type === summaryType &&
                  (village === 'all' ||
                    summaryType === UpgradeCollectionType.capitalHouseParts ||
                    item.village ===
                      (village === 'home' ? UpgradeVillage.home : UpgradeVillage.builderBase)),
              )
            : []
        }
        onClose={() => setSummaryType(null)}
      />
    </Animated.ScrollView>
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

function ImportModal({
  visible,
  onClose,
  onImport,
}: {
  visible: boolean;
  onClose: () => void;
  onImport: (json: string) => Promise<void>;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [busy, setBusy] = useState(false);
  return (
    <ChoiceModal visible={visible} title={t('upgradeTrackerImportTitle')} onClose={onClose}>
      <CKText muted>{t('upgradeTrackerImportDescription')}</CKText>
      <PressableSurface
        accessibilityRole="button"
        accessibilityLabel={t('upgradeTrackerPasteClipboard')}
        disabled={busy}
        onPress={() => {
          setBusy(true);
          void Clipboard.getStringAsync()
            .then((value) => onImport(value.trim()))
            .finally(() => setBusy(false));
        }}
        style={styles.primaryButton}
      >
        <Upload color={theme.onSurface} />
        <CKText>{busy ? t('generalLoading') : t('upgradeTrackerPasteClipboard')}</CKText>
      </PressableSurface>
    </ChoiceModal>
  );
}

function AccountModal({
  visible,
  accounts,
  selectedTag,
  onClose,
  onSelect,
  onImport,
}: {
  visible: boolean;
  accounts: readonly UpgradeTrackerAccountOption[];
  selectedTag: string | null;
  onClose: () => void;
  onSelect: (tag: string) => void;
  onImport: () => void;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const [query, setQuery] = useState('');
  const values = accounts.filter((a) =>
    `${a.name} ${a.tag}`.toLocaleLowerCase().includes(query.toLocaleLowerCase()),
  );
  return (
    <ChoiceModal visible={visible} title={t('accountsManageTitle')} onClose={onClose}>
      <SearchBar value={query} onChange={setQuery} placeholder={t('upgradeTrackerChooseAccount')} />
      {values.map((account) => (
        <ChoiceRow
          key={account.tag}
          label={account.name}
          detail={[
            `${account.tag} · ${[
              account.townHallLevel > 0 ? `TH${account.townHallLevel}` : '',
              account.builderHallLevel > 0 ? `BH${account.builderHallLevel}` : '',
            ]
              .filter(Boolean)
              .join(' · ')}`,
            account.capturedAt ? snapshotAgeLabel(account.capturedAt, locale, t) : '',
          ]
            .filter(Boolean)
            .join('\n')}
          selected={account.tag === selectedTag}
          icon={
            <MobileWebImage
              imageUrl={
                account.townHallLevel
                  ? ImageAssets.townHall(account.townHallLevel)
                  : ImageAssets.builderHall(account.builderHallLevel)
              }
              style={styles.accountHall}
            />
          }
          onPress={() => onSelect(account.tag)}
        />
      ))}
      <PressableSurface accessibilityRole="button" onPress={onImport} style={styles.primaryButton}>
        <Upload color={theme.onSurface} />
        <CKText>{t('upgradeTrackerImportAction')}</CKText>
      </PressableSurface>
    </ChoiceModal>
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
    <Modal visible={visible} transparent animationType="slide" onRequestClose={onClose}>
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
function ChoiceRow({
  label,
  detail,
  icon,
  selected,
  onPress,
}: {
  label: string;
  detail?: string;
  icon?: ReactNode;
  selected?: boolean;
  onPress: () => void;
}) {
  const theme = useCKTheme();
  return (
    <PressableSurface
      accessibilityRole="button"
      accessibilityLabel={label}
      onPress={onPress}
      style={styles.row}
    >
      {icon}
      <View style={styles.grow}>
        <CKText role="rowTitle">{label}</CKText>
        {detail ? (
          <CKText muted role="labelSmall">
            {detail}
          </CKText>
        ) : null}
      </View>
      {selected ? <Check color={theme.primary} /> : <ChevronRight color={theme.onSurfaceVariant} />}
    </PressableSurface>
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
function Section({
  title,
  subtitle,
  children,
}: {
  title: string;
  subtitle?: string;
  children: ReactNode;
}) {
  return (
    <Surface radius={ckRadius.card} style={styles.section}>
      <View style={styles.toolbar}>
        <CKText role="sectionTitle" style={styles.grow}>
          {title}
        </CKText>
        {subtitle ? (
          <CKText muted role="labelSmall">
            {subtitle}
          </CKText>
        ) : null}
      </View>
      {children}
    </Surface>
  );
}
function Progress({ value }: { value: number }) {
  const theme = useCKTheme();
  return (
    <View style={styles.progress}>
      <View
        style={[
          styles.progressFill,
          { width: `${Math.max(0, Math.min(100, value * 100))}%`, backgroundColor: theme.primary },
        ]}
      />
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
  heroHeaderDesktop: { height: 214 },
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
  heroHall: { width: 70, height: 70 },
  heroHallDesktop: { width: 58, height: 58 },
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
    minWidth: 62,
    paddingHorizontal: 10,
    paddingVertical: 6,
    flexDirection: 'row',
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
  upgradeGroupSection: { padding: 12 },
  upgradeGroupSectionOpen: { gap: 12 },
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
  groupImage: { width: 34, height: 30 },
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
  calendarContent: { paddingHorizontal: 16, paddingTop: 8, paddingBottom: 28 },
  periodBar: {
    flexDirection: 'row',
    alignItems: 'center',
    minHeight: 52,
    marginHorizontal: 12,
    marginBottom: 8,
    paddingHorizontal: 12,
  },
  centerText: { textAlign: 'center' },
  calendarDayHeader: { height: 44, flexDirection: 'row', alignItems: 'center' },
  calendarDay: { textAlign: 'center' },
  calendarTodayText: { color: '#4F91FF' },
  calendarSection: {
    marginBottom: 12,
    paddingTop: 10,
    paddingBottom: 10,
    overflow: 'hidden',
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: '#80808055',
  },
  calendarSectionHeader: {
    minHeight: 36,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 12,
  },
  calendarGroupImage: { width: 28, height: 25 },
  calendarPill: { paddingHorizontal: 8, paddingVertical: 5 },
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
  calendarLaneLabel: {
    position: 'absolute',
    left: 0,
    top: 0,
    bottom: 0,
    zIndex: 5,
    justifyContent: 'center',
    paddingLeft: 5,
    borderRightWidth: StyleSheet.hairlineWidth,
    borderColor: '#80808055',
    backgroundColor: '#19191D',
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
  calendarBlockLevelText: { fontSize: 8 },
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
  planDropdown: {
    minHeight: 44,
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 12,
  },
  planRows: { gap: 1 },
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
  overlay: { flex: 1, justifyContent: 'flex-end', backgroundColor: '#00000070' },
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
