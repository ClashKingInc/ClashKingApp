import { useAdaptiveLayout } from '../../ui/adaptive-layout';
import type { StyleProp, ViewStyle } from 'react-native';
import { modalOrientations } from '../../ui/modal-orientations';
import { cloneElement, useCallback, useEffect, useRef, useState, type ReactElement } from 'react';
import * as Clipboard from 'expo-clipboard';
import { PagerView, type PagerViewHandle } from '../../ui/pager';
import { useCKAccessibility } from '../../ui/accessibility';
import { usePrimarySwipeGuard } from '../../ui/primary-swipe-guard';
import {
  Bookmark,
  Swords,
  CalendarDays,
  Check,
  ChevronDown,
  ChevronUp,
  Download,
  ExternalLink,
  Link2,
  Pencil,
  ThumbsUp,
  ThumbsDown,
  Trash2,
  X,
} from 'lucide-react-native';
import {
  Animated,
  Linking,
  KeyboardAvoidingView,
  Modal,
  Platform,
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  TextInput,
  View,
  useWindowDimensions,
} from 'react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';

import { useAppRuntime } from '../../core/app/runtime-context';
import { ImageAssets } from '../../core/assets/image-assets';
import { LegendArmy, LegendArmyPreview } from '../legends/presentation/legend-army-presentation';
import { materialBackLabel, materialCloseLabel, useI18n } from '../../i18n';
import {
  CKText,
  EmptyState,
  ErrorState,
  HeaderIconButton,
  SkeletonContent,
  ProfilePageHeader,
  ProfileTabs,
  MobileWebImage,
  SelectionPicker,
  Surface,
  colorWithAlpha,
  useCKTheme,
} from '../../ui';
import type {
  PersonalArmiesServiceContract,
  PersonalArmiesState,
  PersonalArmy,
} from './personal-armies-service';
import type {
  PersonalBase,
  PersonalBasesServiceContract,
  PersonalBasesState,
} from './personal-bases-service';
import { townHallLevelFromBaseLink } from './base-link';
import { useLinkParameters, linkChoice } from '../../core/deep-links/link-parameters';

export function BasesArmiesRoot({ onBack }: { readonly onBack: () => void }) {
  const runtime = useAppRuntime();
  return (
    <BasesArmiesScreen
      armyService={runtime.personalArmies}
      baseService={runtime.personalBases}
      onBack={onBack}
    />
  );
}

export function BasesArmiesScreen({
  armyService,
  baseService,
  onBack,
}: {
  readonly armyService: PersonalArmiesServiceContract;
  readonly baseService: PersonalBasesServiceContract;
  readonly onBack: () => void;
}) {
  const { t, locale, isRtl } = useI18n();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  const { width, fontScale } = useWindowDimensions();
  const layout = useAdaptiveLayout();
  const effectiveWidth =
    layout.isDuo && !layout.isExpanded
      ? Math.min(layout.width, layout.contentMaxWidth)
      : layout.isDuo || layout.isTablet
        ? layout.width
        : width;
  const contentWidth = layout.isExpanded
    ? Math.min(layout.usableWidth, layout.contentMaxWidth)
    : Math.min(effectiveWidth, 1200);
  const horizontal = 16;
  const [expandedArmy, setExpandedArmy] = useState<string | null>(null);
  const [state, setState] = useState<PersonalBasesState | null>(null);
  const [armyState, setArmyState] = useState<PersonalArmiesState | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [loadError, setLoadError] = useState(false);
  const [mutationError, setMutationError] = useState(false);
  const [busyKey, setBusyKey] = useState<string | null>(null);
  const [cleanupVisible, setCleanupVisible] = useState(false);
  const [cleanupNow, setCleanupNow] = useState(Date.now);
  const link = useLinkParameters();
  const [section, setSection] = useState(linkChoice(link.section, ['bases', 'armies'], 'bases'));
  // Army compositions need more horizontal room than base thumbnails. Keep
  // the same sizing rule for loaded cards and their loading placeholders.
  const baseColumns = layout.isExpanded
    ? layout.columns(210, layout.isTablet ? 5 : 4)
    : layout.isDuo
      ? fontScale > 1.35
        ? 1
        : 2
      : effectiveWidth < 350 || fontScale > 1.35
        ? 1
        : effectiveWidth >= 900
          ? 4
          : effectiveWidth >= 600
            ? 3
            : 2;
  const armyColumns = layout.isExpanded
    ? layout.columns(380, 2)
    : !layout.isDuo && effectiveWidth >= 600 && fontScale <= 1.35
      ? 2
      : 1;
  const [initialSection] = useState(section);
  const pager = useRef<PagerViewHandle>(null);
  const [tabPosition] = useState(() => new Animated.Value(initialSection === 'bases' ? 0 : 1));
  const { reduceMotion } = useCKAccessibility();
  const blockPrimarySwipe = usePrimarySwipeGuard();
  useEffect(() => () => blockPrimarySwipe(false), [blockPrimarySwipe]);
  const selectSection = (next: 'bases' | 'armies') => {
    setSection(next);
    const index = next === 'bases' ? 0 : 1;
    if (reduceMotion) {
      pager.current?.setPageWithoutAnimation(index);
      tabPosition.setValue(index);
    } else pager.current?.setPage(index);
  };
  const [townHallFilter, setTownHallFilter] = useState('all');
  const [armyTownHallFilter, setArmyTownHallFilter] = useState('all');
  const [editingArmy, setEditingArmy] = useState<PersonalArmy | null>(null);
  const [armyName, setArmyName] = useState('');
  const [armyNotes, setArmyNotes] = useState('');
  const [editError, setEditError] = useState(false);

  const load = useCallback(
    async (refresh = false) => {
      if (refresh) setRefreshing(true);
      else setLoading(true);
      setLoadError(false);
      try {
        const [bases, armies] = await Promise.all([baseService.load(), armyService.load()]);
        setState(bases);
        setArmyState(armies);
      } catch {
        setLoadError(true);
      } finally {
        setLoading(false);
        setRefreshing(false);
      }
    },
    [armyService, baseService],
  );

  useEffect(() => {
    let current = true;
    void Promise.all([baseService.load(), armyService.load()])
      .then(([bases, armies]) => {
        if (current) {
          setState(bases);
          setArmyState(armies);
        }
      })
      .catch(() => {
        if (current) setLoadError(true);
      })
      .finally(() => {
        if (current) setLoading(false);
      });
    return () => {
      current = false;
    };
  }, [armyService, baseService]);

  const mutate = useCallback(
    async (key: string, operation: () => Promise<void>) => {
      if (busyKey !== null) return;
      setBusyKey(key);
      setMutationError(false);
      try {
        await operation();
      } catch {
        setMutationError(true);
      } finally {
        setBusyKey(null);
      }
    },
    [busyKey],
  );
  const items = [...new Map(state?.items.map((base) => [base.id, base])).values()];
  const armies = armyState?.items ?? [];
  const armyTownHallLevels = [
    ...new Set(
      armies.flatMap((army) => (army.minimumTownHall == null ? [] : [army.minimumTownHall])),
    ),
  ].sort((a, b) => b - a);
  const visibleArmies = armies.filter(
    (army) =>
      armyTownHallFilter === 'all' ||
      (armyTownHallFilter === 'unknown'
        ? army.minimumTownHall == null
        : army.minimumTownHall === Number(armyTownHallFilter)),
  );
  const savedItems = items.filter((base) => base.saved);
  const townHallLevels = [
    ...new Set(
      items
        .map((base) => townHallLevelFromBaseLink(base.baseLink))
        .filter((level): level is number => level !== null),
    ),
  ].sort((left, right) => right - left);
  const visibleItems = items.filter(
    (base) =>
      townHallFilter === 'all' ||
      townHallLevelFromBaseLink(base.baseLink) === Number(townHallFilter),
  );
  const cutoff = cleanupNow - 90 * 86_400_000;
  const oldSavedCount = savedItems.filter(
    (base) => base.savedAt !== null && new Date(base.savedAt).getTime() < cutoff,
  ).length;

  return (
    <SafeAreaView
      edges={['left', 'right']}
      style={[styles.fill, { backgroundColor: theme.background }]}
    >
      <ProfilePageHeader
        title={t('sideBasesArmiesTitle')}
        imageUrl={ImageAssets.clanCastle}
        imageSize={40}
        identityLayout="inline"
        identityOffsetY={-8}
        backgroundSource={require('../../../assets/clashking/backgrounds/library-barbarians.webp')}
        safeTop={insets.top}
        onBack={onBack}
        backLabel={materialBackLabel(locale)}
        controlsTopPadding={9}
        bottomPadding={12}
        actions={
          section === 'bases' && oldSavedCount > 0 ? (
            <HeaderIconButton
              icon={<Trash2 color="white" size={20} />}
              label={t('personalBasesDeleteOld')}
              onPress={() => {
                if (busyKey !== null) return;
                setCleanupNow(Date.now());
                setCleanupVisible(true);
              }}
            />
          ) : undefined
        }
      />
      <View style={[styles.libraryTabs, { paddingHorizontal: horizontal }]}>
        <ProfileTabs
          variant="underline"
          selectedKey={section}
          animatedPosition={tabPosition}
          indicatorRtl={isRtl}
          onSelect={(key) => selectSection(key as 'bases' | 'armies')}
          tabs={[
            {
              key: 'bases',
              label: t('personalBasesTab'),
              icon: (
                <MobileWebImage
                  imageUrl={ImageAssets.townHall(10)}
                  style={{ width: 24, height: 24 }}
                  contentFit="contain"
                />
              ),
            },
            { key: 'armies', label: t('statsArmies'), icon: <Swords size={20} /> },
          ]}
        />
      </View>

      {/* Both the section tabs and its filters stay outside the scrolling list. */}
      <View
        testID="personal-library-filters"
        style={[styles.filters, { paddingHorizontal: horizontal }]}
      >
        <SelectionPicker
          fillWidth
          title={t('filtersTownHall')}
          accessibilityLabel={t('filtersTownHall')}
          selectedKey={section === 'bases' ? townHallFilter : armyTownHallFilter}
          onSelect={section === 'bases' ? setTownHallFilter : setArmyTownHallFilter}
          options={[
            { key: 'all', label: t('statsAllTownHalls') },
            ...(section === 'bases' ? townHallLevels : armyTownHallLevels).map((level) => ({
              key: String(level),
              label: t('gameTownHallShortLevel', { level }),
              icon: (
                <MobileWebImage
                  imageUrl={ImageAssets.townHall(level)}
                  style={{ width: 30, height: 30 }}
                  contentFit="contain"
                />
              ),
            })),
            ...(section === 'armies' && armies.some((army) => army.minimumTownHall == null)
              ? [{ key: 'unknown', label: t('personalArmyUnknownTownHall') }]
              : []),
          ]}
        />
      </View>

      <View
        style={styles.list}
        onTouchStart={() => blockPrimarySwipe(true)}
        onTouchEnd={() => blockPrimarySwipe(false)}
        onTouchCancel={() => blockPrimarySwipe(false)}
      >
        <PagerView
          ref={pager}
          style={styles.list}
          testID="personal-library-pager"
          initialPage={initialSection === 'bases' ? 0 : 1}
          layoutDirection={isRtl ? 'rtl' : 'ltr'}
          onPageScroll={(event) =>
            tabPosition.setValue(event.nativeEvent.position + event.nativeEvent.offset)
          }
          onPageSelected={(event) =>
            setSection(event.nativeEvent.position === 0 ? 'bases' : 'armies')
          }
        >
          {(['bases', 'armies'] as const).map((page) => {
            const columns = page === 'bases' ? baseColumns : armyColumns;
            const tileWidth = (contentWidth - horizontal * 2 - (columns - 1) * 12) / columns;
            return (
              <View
                key={page}
                collapsable={false}
                style={styles.list}
                accessibilityElementsHidden={page !== section}
                importantForAccessibility={page !== section ? 'no-hide-descendants' : 'auto'}
              >
                {loading && state === null ? (
                  <View
                    accessibilityRole="progressbar"
                    accessibilityLabel={t('generalLoading')}
                    style={[styles.content, { paddingHorizontal: horizontal }]}
                  >
                    <SkeletonContent loading style={styles.libraryGrid}>
                      {[0, 1, 2, 3].map((index) =>
                        page === 'bases' ? (
                          <BaseCard
                            key={index}
                            style={{ width: tileWidth }}
                            busy
                            onOpen={() => {}}
                            onToggleSaved={() => {}}
                          />
                        ) : (
                          <ArmyCard
                            key={index}
                            style={{ width: tileWidth }}
                            busy
                            onOpen={() => {}}
                            onRemove={() => {}}
                            onEdit={() => {}}
                          />
                        ),
                      )}
                    </SkeletonContent>
                  </View>
                ) : loadError && state === null ? (
                  <View style={[styles.feedbackWrap, { paddingHorizontal: horizontal }]}>
                    <ErrorState
                      title={t('generalError')}
                      actionLabel={t('generalRetry')}
                      onAction={() => void load()}
                    />
                  </View>
                ) : (
                  <ScrollView
                    style={styles.list}
                    contentContainerStyle={[
                      styles.content,
                      { paddingHorizontal: horizontal, paddingBottom: insets.bottom + 28 },
                    ]}
                    refreshControl={
                      <RefreshControl refreshing={refreshing} onRefresh={() => void load(true)} />
                    }
                  >
                    {mutationError ? (
                      <ErrorState
                        title={t('generalError')}
                        actionLabel={t('generalRetry')}
                        onAction={() => void load(true)}
                        style={styles.mutationError}
                      />
                    ) : null}
                    {page === 'bases' ? (
                      <>
                        {visibleItems.length === 0 ? (
                          <EmptyState
                            title={t('personalBasesEmptyTitle')}
                            body={t('personalBasesEmptyBody')}
                          />
                        ) : (
                          <View style={styles.libraryGrid}>
                            {visibleItems.map((base) => (
                              <BaseCard
                                style={{ width: tileWidth }}
                                base={base}
                                busy={busyKey !== null}
                                key={base.id}
                                onOpen={() => void Linking.openURL(base.baseLink)}
                                onToggleSaved={() =>
                                  void mutate(`base:${base.id}`, async () => {
                                    setState(
                                      await (base.saved
                                        ? baseService.unsave(base.id)
                                        : baseService.save(base.id)),
                                    );
                                  })
                                }
                              />
                            ))}
                          </View>
                        )}
                      </>
                    ) : (
                      <>
                        {visibleArmies.length === 0 ? (
                          <EmptyState
                            title={t('personalArmiesEmptyTitle')}
                            body={t('personalArmiesEmptyBody')}
                          />
                        ) : (
                          <View style={styles.libraryGrid}>
                            {visibleArmies.map((army) => (
                              <ArmyCard
                                style={{
                                  width:
                                    expandedArmy === army.shareCode ? contentWidth - 32 : tileWidth,
                                }}
                                expanded={expandedArmy === army.shareCode}
                                onToggleExpanded={() =>
                                  setExpandedArmy((current) =>
                                    current === army.shareCode ? null : army.shareCode,
                                  )
                                }
                                army={army}
                                busy={busyKey !== null}
                                key={army.shareCode}
                                onOpen={() => void Linking.openURL(army.armyLink)}
                                onEdit={() => {
                                  setEditingArmy(army);
                                  setArmyName(army.name ?? '');
                                  setArmyNotes(army.notes ?? '');
                                  setEditError(false);
                                }}
                                onRemove={() =>
                                  void mutate(`army:${army.shareCode}`, async () => {
                                    setArmyState(await armyService.remove(army.shareCode));
                                  })
                                }
                              />
                            ))}
                          </View>
                        )}
                      </>
                    )}
                  </ScrollView>
                )}
              </View>
            );
          })}
        </PagerView>
      </View>
      <Modal
        supportedOrientations={modalOrientations}
        transparent
        visible={cleanupVisible}
        onRequestClose={() => setCleanupVisible(false)}
      >
        <Pressable style={styles.modalBackdrop} onPress={() => setCleanupVisible(false)}>
          <Surface radius={18} style={styles.confirmation}>
            <View style={styles.confirmationHeader}>
              <CKText role="titleLarge" style={styles.grow}>
                {t('generalConfirm')}
              </CKText>
              <Pressable
                accessibilityRole="button"
                accessibilityLabel={t('generalCancel')}
                onPress={() => setCleanupVisible(false)}
                style={styles.closeButton}
              >
                <X color={theme.onSurface} />
              </Pressable>
            </View>
            <CKText>{t('personalBasesDeleteOldConfirm', { count: oldSavedCount })}</CKText>
            <View style={styles.confirmationActions}>
              <ActionButton
                label={t('generalCancel')}
                icon={<X color={theme.primary} />}
                onPress={() => setCleanupVisible(false)}
              />
              <ActionButton
                label={t('generalConfirm')}
                icon={<Trash2 color={theme.primary} />}
                onPress={() => {
                  setCleanupVisible(false);
                  void mutate('cleanup', async () => {
                    await baseService.deleteOld();
                    setState(await baseService.load());
                  });
                }}
              />
            </View>
          </Surface>
        </Pressable>
      </Modal>
      <Modal
        supportedOrientations={modalOrientations}
        transparent
        visible={editingArmy !== null}
        onRequestClose={() => {
          if (busyKey === null) setEditingArmy(null);
        }}
      >
        <KeyboardAvoidingView
          style={styles.modalBackdrop}
          behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        >
          <Surface radius={18} style={styles.confirmation}>
            <CKText role="titleLarge">{t('personalArmyEdit')}</CKText>
            <CKText>{t('personalArmyName')}</CKText>
            <TextInput
              value={armyName}
              onChangeText={setArmyName}
              maxLength={100}
              editable={busyKey === null}
              accessibilityLabel={t('personalArmyName')}
              placeholder={t('personalArmyUnnamed')}
              placeholderTextColor={theme.onSurfaceVariant}
              style={[
                styles.editInput,
                { color: theme.onSurface, backgroundColor: theme.surfaceContainerHighest },
              ]}
            />
            <CKText>{t('personalArmyNotes')}</CKText>
            <TextInput
              value={armyNotes}
              onChangeText={setArmyNotes}
              maxLength={450}
              multiline
              editable={busyKey === null}
              accessibilityLabel={t('personalArmyNotes')}
              style={[
                styles.editInput,
                styles.notesInput,
                { color: theme.onSurface, backgroundColor: theme.surfaceContainerHighest },
              ]}
            />
            {editError ? <CKText style={{ color: theme.error }}>{t('generalError')}</CKText> : null}
            <View style={styles.confirmationActions}>
              <ActionButton
                disabled={busyKey !== null}
                label={t('generalCancel')}
                icon={<X />}
                onPress={() => setEditingArmy(null)}
              />
              <ActionButton
                disabled={busyKey !== null || !armyName.trim()}
                label={t('gameAssetsSave')}
                icon={<Bookmark />}
                onPress={() => {
                  if (!editingArmy) return;
                  setEditError(false);
                  void mutate(`army-edit:${editingArmy.shareCode}`, async () => {
                    try {
                      setArmyState(
                        await armyService.update(editingArmy.shareCode, {
                          name: armyName.trim(),
                          notes: armyNotes.trim() || null,
                        }),
                      );
                      setEditingArmy(null);
                    } catch (error) {
                      setEditError(true);
                      throw error;
                    }
                  });
                }}
              />
            </View>
          </Surface>
        </KeyboardAvoidingView>
      </Modal>
    </SafeAreaView>
  );
}

function ArmyCard({
  army: loadedArmy,
  style,
  expanded = false,
  onToggleExpanded = () => {},
  busy,
  onOpen,
  onRemove,
  onEdit,
}: {
  readonly army?: PersonalArmy;
  readonly style?: StyleProp<ViewStyle>;
  readonly expanded?: boolean;
  readonly onToggleExpanded?: () => void;
  readonly busy: boolean;
  readonly onOpen: () => void;
  readonly onRemove: () => void;
  readonly onEdit: () => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const army = loadedArmy ?? {
    name: 'Saved army',
    minimumTownHall: 1,
    shareCode: 'u20x0',
    armyLink: '',
    notes: null,
    savedAt: '2000-01-01',
  };
  const [copied, setCopied] = useState(false);
  const [copyFailed, setCopyFailed] = useState(false);
  useEffect(() => {
    if (!copied) return;
    const timer = setTimeout(() => setCopied(false), 2000);
    return () => clearTimeout(timer);
  }, [copied]);
  const copyLink = async () => {
    try {
      await Clipboard.setStringAsync(army.armyLink);
      setCopyFailed(false);
      setCopied(true);
    } catch {
      setCopyFailed(true);
    }
  };
  const expandLabel = t(expanded ? 'generalCollapse' : 'generalExpand');
  const copyAction = (
    <View style={{ marginLeft: 'auto' }}>
      <HeaderIconButton
        glass={false}
        label={copied ? t('generalCopiedToClipboard') : t('gameAssetsCopyUrl')}
        icon={
          copied ? (
            <Check size={21} color={theme.primary} />
          ) : (
            <Link2 size={21} color={theme.onSurface} />
          )
        }
        onPress={() => void copyLink()}
      />
    </View>
  );

  return (
    <Surface radius={18} style={[styles.armyCard, style]}>
      <View style={styles.armyIdentity}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={`${expandLabel}: ${army.name || t('personalArmyUnnamed')}`}
          accessibilityState={{ expanded }}
          onPress={onToggleExpanded}
          style={[styles.armyIdentity, styles.grow, { minHeight: 44 }]}
        >
          {army.minimumTownHall != null ? (
            <MobileWebImage
              imageUrl={ImageAssets.townHall(army.minimumTownHall)}
              accessibilityLabel={t('gameTownHallShortLevel', { level: army.minimumTownHall })}
              style={{ width: 38, height: 38 }}
              contentFit="contain"
            />
          ) : null}
          <CKText role="titleMedium" style={styles.grow}>
            {army.name || t('personalArmyUnnamed')}
          </CKText>
          {expanded ? (
            <ChevronUp size={18} color={theme.onSurfaceVariant} />
          ) : (
            <ChevronDown size={18} color={theme.onSurfaceVariant} />
          )}
        </Pressable>
      </View>
      {copyFailed ? (
        <CKText accessibilityRole="alert" style={{ color: theme.error }}>
          {t('generalError')}
        </CKText>
      ) : null}
      {expanded ? (
        <>
          {army.notes ? <CKText>{army.notes}</CKText> : null}
          <LegendArmy shareCode={army.shareCode} />
          <View style={styles.metaRow}>
            <Meta
              icon={<CalendarDays color={theme.onSurfaceVariant} />}
              label={new Date(army.savedAt).toLocaleDateString()}
            />
          </View>
          <View style={styles.actions}>
            <ActionButton
              icon={<ExternalLink color={theme.primary} />}
              label={t('generalOpen')}
              onPress={onOpen}
            />
            <View style={styles.grow} />
            <ActionButton
              disabled={busy}
              icon={<Pencil />}
              label={t('personalArmyEdit')}
              onPress={onEdit}
            />
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={t('generalRemoveBookmark')}
              accessibilityState={{ disabled: busy }}
              disabled={busy}
              onPress={onRemove}
              style={({ pressed }) => [
                styles.bookmarkButton,
                { opacity: busy ? 0.4 : pressed ? 0.6 : 1 },
              ]}
            >
              <Bookmark size={22} color={theme.onSurface} fill={theme.onSurface} />
            </Pressable>
            {copyAction}
          </View>
        </>
      ) : (
        <View style={[styles.armyIdentity, { alignItems: 'flex-end' }]}>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={`${expandLabel}: ${army.name || t('personalArmyUnnamed')}`}
            accessibilityState={{ expanded: false }}
            onPress={onToggleExpanded}
            style={styles.grow}
          >
            <LegendArmyPreview shareCode={army.shareCode} />
          </Pressable>
          {copyAction}
        </View>
      )}
    </Surface>
  );
}

function BaseCard({
  base: loadedBase,
  style,
  busy,
  onOpen,
  onToggleSaved,
}: {
  readonly base?: PersonalBase;
  readonly style?: StyleProp<ViewStyle>;
  readonly busy: boolean;
  readonly onOpen: () => void;
  readonly onToggleSaved?: () => void;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  const [preview, setPreview] = useState(false);
  const base = loadedBase ?? {
    images: [ImageAssets.clanCastle],
    upvotes: 100,
    downvotes: 10,
    downloadedAt: '2000-01-01',
    saved: false,
  };
  return (
    <Surface radius={20} style={[styles.baseCard, style]}>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={t('generalExpand')}
        onPress={() => setPreview(true)}
      >
        <MobileWebImage
          contentFit="contain"
          imageUrl={base.images[0] ?? ImageAssets.clanCastle}
          style={styles.baseImage}
        />
      </Pressable>
      <Modal
        supportedOrientations={modalOrientations}
        visible={preview}
        animationType="fade"
        onRequestClose={() => setPreview(false)}
      >
        {/* Modal content is hosted outside the page's native safe-area view.
            Apply the measured window insets explicitly so its toolbar never
            overlaps the status bar, Dynamic Island, or landscape cutout. */}
        <View
          style={[
            styles.basePreview,
            {
              backgroundColor: theme.background,
              paddingTop: insets.top + 8,
              paddingBottom: insets.bottom + 16,
              paddingLeft: insets.left + 16,
              paddingRight: insets.right + 16,
            },
          ]}
        >
          <View style={styles.previewActions}>
            <ActionButton icon={<ExternalLink />} label={t('generalOpen')} onPress={onOpen} />
            <HeaderIconButton
              glass={false}
              label={materialCloseLabel(locale)}
              onPress={() => setPreview(false)}
              icon={<X color={theme.onSurface} />}
            />
          </View>
          <MobileWebImage
            contentFit="contain"
            imageUrl={base.images[0] ?? ImageAssets.clanCastle}
            style={{ flex: 1, width: '100%' }}
          />
        </View>
      </Modal>
      <View style={styles.baseContent}>
        <View style={styles.metaRow}>
          <Meta icon={<ThumbsUp color={theme.onSurfaceVariant} />} label={String(base.upvotes)} />
          <Meta
            icon={<ThumbsDown color={theme.onSurfaceVariant} />}
            label={String(base.downvotes)}
          />
          <View style={styles.grow} />
          {base.downloadedAt !== null ? (
            <Meta
              icon={<Download color={theme.onSurfaceVariant} />}
              label={new Date(base.downloadedAt).toLocaleDateString()}
            />
          ) : null}
        </View>
        <View style={styles.actions}>
          <ActionButton
            icon={<ExternalLink color={theme.primary} />}
            label={t('generalOpen')}
            onPress={onOpen}
          />
          <View style={styles.grow} />
          {onToggleSaved ? (
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={base.saved ? t('generalRemoveBookmark') : t('gameAssetsSave')}
              accessibilityState={{ disabled: busy, selected: base.saved }}
              disabled={busy}
              onPress={onToggleSaved}
              style={({ pressed }) => [
                styles.bookmarkButton,
                { opacity: busy ? 0.4 : pressed ? 0.6 : 1 },
              ]}
            >
              <Bookmark
                size={22}
                color={theme.onSurface}
                fill={base.saved ? theme.onSurface : 'transparent'}
              />
            </Pressable>
          ) : null}
        </View>
      </View>
    </Surface>
  );
}

function Meta({
  icon,
  label,
}: {
  readonly icon: ReactElement<{ color?: string; size?: number }>;
  readonly label: string;
}) {
  const theme = useCKTheme();
  return (
    <View style={styles.meta}>
      {cloneElement(icon, { color: theme.onSurfaceVariant, size: 14 })}
      <CKText muted role="bodySmall">
        {label}
      </CKText>
    </View>
  );
}

function ActionButton({
  disabled = false,
  icon,
  label,
  onPress,
}: {
  readonly disabled?: boolean;
  readonly icon: ReactElement<{ color?: string; size?: number }>;
  readonly label: string;
  readonly onPress: () => void;
}) {
  const theme = useCKTheme();
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityState={{ disabled }}
      disabled={disabled}
      onPress={onPress}
      style={({ pressed }) => [
        styles.actionButton,
        { backgroundColor: colorWithAlpha(theme.primary, pressed ? 0.2 : 0.12) },
        disabled && styles.disabled,
      ]}
    >
      {cloneElement(icon, { color: theme.primary, size: 16 })}
      <CKText role="labelLarge" style={{ color: theme.primary }}>
        {label}
      </CKText>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  header: {
    minHeight: 56,
    flexDirection: 'row',
    alignItems: 'center',
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: 'rgba(128,128,128,0.2)',
  },
  headerText: { flex: 1 },
  headerSpacer: { width: 44 },
  feedbackWrap: { paddingTop: 16 },
  content: { width: '100%', maxWidth: 1200, alignSelf: 'center', paddingTop: 12 },
  mutationError: { marginTop: 12 },
  filters: {
    width: '100%',
    maxWidth: 1200,
    alignSelf: 'center',
    flexDirection: 'row',
    gap: 12,
    marginVertical: 12,
  },
  list: { flex: 1, minHeight: 0 },
  armyIdentity: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  libraryTabs: { width: '100%', maxWidth: 1200, alignSelf: 'center', paddingTop: 4 },
  libraryGrid: { flexDirection: 'row', flexWrap: 'wrap', alignItems: 'flex-start', gap: 12 },
  baseCard: { overflow: 'hidden' },
  armyCard: { padding: 14, gap: 14 },
  baseImage: { width: '100%', aspectRatio: 4 / 3 },
  basePreview: { flex: 1, padding: 16 },
  previewActions: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  baseContent: { padding: 10, gap: 6 },
  metaRow: { flexDirection: 'row', alignItems: 'center', flexWrap: 'wrap', gap: 8 },
  meta: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  actions: { flexDirection: 'row', alignItems: 'center', flexWrap: 'wrap', gap: 8 },
  bookmarkButton: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  actionButton: {
    minHeight: 40,
    paddingHorizontal: 12,
    borderRadius: 12,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  disabled: { opacity: 0.5 },
  modalBackdrop: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
    backgroundColor: '#00000088',
  },
  confirmation: { width: '100%', maxWidth: 440, padding: 20, gap: 16 },
  confirmationHeader: { flexDirection: 'row', alignItems: 'center' },
  confirmationActions: { flexDirection: 'row', justifyContent: 'flex-end', gap: 8 },
  closeButton: { width: 40, height: 40, alignItems: 'center', justifyContent: 'center' },
  editInput: { minHeight: 44, borderRadius: 12, padding: 12, fontSize: 16 },
  notesInput: { minHeight: 100, textAlignVertical: 'top' },
  grow: { flex: 1 },
});
