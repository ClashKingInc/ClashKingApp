import { cloneElement, useCallback, useEffect, useState, type ReactElement } from 'react';
import { SlidingSegmentControl } from '../../ui/sliding-segment-control';
import {
  ArrowLeft,
  Bookmark,
  CalendarDays,
  Download,
  ExternalLink,
  ThumbsUp,
  ThumbsDown,
  Trash2,
  X,
} from 'lucide-react-native';
import {
  Linking,
  Modal,
  Platform,
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  View,
  useWindowDimensions,
} from 'react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';

import { useAppRuntime } from '../../core/app/runtime-context';
import { ImageAssets } from '../../core/assets/image-assets';
import { PlayerBattlelogArmyCatalog } from '../player/models/player-battlelog';
import { materialBackLabel, useI18n } from '../../i18n';
import {
  CKText,
  EmptyState,
  ErrorState,
  HeaderIconButton,
  LoadingScreen,
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
import { armyDisplayItems } from './army-presentation';

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
  const { width } = useWindowDimensions();
  const horizontal = Platform.OS === 'web' && width >= 900 ? Math.max(16, (width - 1200) / 2) : 16;
  const [state, setState] = useState<PersonalBasesState | null>(null);
  const [armyState, setArmyState] = useState<PersonalArmiesState | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [loadError, setLoadError] = useState(false);
  const [mutationError, setMutationError] = useState(false);
  const [busyKey, setBusyKey] = useState<string | null>(null);
  const [cleanupVisible, setCleanupVisible] = useState(false);
  const [cleanupNow, setCleanupNow] = useState(Date.now);
  const [section, setSection] = useState('bases');
  const [collection, setCollection] = useState('all');
  const [townHallFilter, setTownHallFilter] = useState('all');

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
      (collection === 'all' ||
        (collection === 'saved' ? base.saved : base.downloadedAt !== null)) &&
      (townHallFilter === 'all' ||
        townHallLevelFromBaseLink(base.baseLink) === Number(townHallFilter)),
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
      <View style={[styles.header, { backgroundColor: theme.surface, paddingTop: insets.top }]}>
        <HeaderIconButton
          glass={false}
          icon={<ArrowLeft color={theme.onSurface} size={24} />}
          label={materialBackLabel(locale)}
          onPress={onBack}
        />
        <View style={styles.headerText}>
          <CKText role="sectionTitle" numberOfLines={1}>
            {t('sideBasesArmiesTitle')}
          </CKText>
        </View>
        {section === 'bases' && oldSavedCount > 0 ? (
          <HeaderIconButton
            glass={false}
            icon={<Trash2 color={theme.onSurfaceVariant} size={20} />}
            label={t('personalBasesDeleteOld')}
            onPress={() => {
              if (busyKey !== null) return;
              setCleanupNow(Date.now());
              setCleanupVisible(true);
            }}
          />
        ) : (
          <View style={styles.headerSpacer} />
        )}
      </View>

      {loading && state === null ? (
        <LoadingScreen label={t('generalLoading')} />
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
          <SlidingSegmentControl
            value={section}
            isRtl={isRtl}
            onChange={setSection}
            options={[
              { value: 'bases', label: t('sideSavedBases') },
              { value: 'armies', label: t('sideSavedArmies') },
            ]}
          />
          {section === 'bases' ? (
            <>
              <View style={styles.filters}>
                <SelectionPicker
                  fillWidth
                  title={t('sideFilter')}
                  accessibilityLabel={t('sideFilter')}
                  selectedKey={collection}
                  onSelect={setCollection}
                  options={[
                    { key: 'all', label: t('generalAll') },
                    { key: 'saved', label: t('sideSavedBases') },
                    { key: 'history', label: t('generalHistory') },
                  ]}
                />
                <SelectionPicker
                  fillWidth
                  title={t('filtersTownHall')}
                  accessibilityLabel={t('filtersTownHall')}
                  selectedKey={townHallFilter}
                  onSelect={setTownHallFilter}
                  options={[
                    { key: 'all', label: t('statsAllTownHalls') },
                    ...townHallLevels.map((level) => ({
                      key: String(level),
                      label: t('gameTownHallShortLevel', { level }),
                    })),
                  ]}
                />
              </View>
              {visibleItems.length === 0 ? (
                <EmptyState title={t('generalNoDataAvailable')} />
              ) : (
                visibleItems.map((base) => (
                  <BaseCard
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
                ))
              )}
            </>
          ) : armies.length === 0 ? (
            <EmptyState title={t('generalNoDataAvailable')} />
          ) : (
            armies.map((army) => (
              <ArmyCard
                army={army}
                busy={busyKey !== null}
                key={army.shareCode}
                onOpen={() => void Linking.openURL(army.armyLink)}
                onRemove={() =>
                  void mutate(`army:${army.shareCode}`, async () => {
                    setArmyState(await armyService.remove(army.shareCode));
                  })
                }
              />
            ))
          )}
        </ScrollView>
      )}
      <Modal transparent visible={cleanupVisible} onRequestClose={() => setCleanupVisible(false)}>
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
    </SafeAreaView>
  );
}

function ArmyCard({
  army,
  busy,
  onOpen,
  onRemove,
}: {
  readonly army: PersonalArmy;
  readonly busy: boolean;
  readonly onOpen: () => void;
  readonly onRemove: () => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const items = armyDisplayItems(army);

  return (
    <Surface radius={18} style={styles.armyCard}>
      <View style={styles.armyItems}>
        {items.map(({ code, quantity }, index) => {
          const item = PlayerBattlelogArmyCatalog.resolve(code);
          return (
            <View key={`${code}:${index}`} style={styles.armyItem}>
              <MobileWebImage imageUrl={item.imageUrl} style={styles.armyItemImage} />
              {quantity > 1 ? (
                <View style={[styles.quantityBadge, { backgroundColor: theme.surface }]}>
                  <CKText role="labelSmall">{quantity}</CKText>
                </View>
              ) : null}
            </View>
          );
        })}
      </View>
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
      </View>
    </Surface>
  );
}

function BaseCard({
  base,
  busy,
  onOpen,
  onToggleSaved,
}: {
  readonly base: PersonalBase;
  readonly busy: boolean;
  readonly onOpen: () => void;
  readonly onToggleSaved?: () => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  return (
    <Surface radius={18} style={styles.baseCard}>
      <MobileWebImage
        contentFit="contain"
        imageUrl={base.images[0] ?? ImageAssets.clanCastle}
        style={styles.baseImage}
      />
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
      <CKText muted role="labelSmall">
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
  filters: { flexDirection: 'row', gap: 12, marginVertical: 16 },
  baseCard: { overflow: 'hidden', marginBottom: 20 },
  armyCard: { marginBottom: 16, padding: 14, gap: 14 },
  armyItems: { flexDirection: 'row', flexWrap: 'wrap', gap: 10 },
  armyItem: { width: 52, height: 52 },
  armyItemImage: { width: 52, height: 52 },
  quantityBadge: {
    position: 'absolute',
    right: -3,
    bottom: -3,
    minWidth: 20,
    height: 20,
    paddingHorizontal: 4,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
  },
  baseImage: { width: '100%', aspectRatio: 4 / 3 },
  baseContent: { padding: 12, gap: 12 },
  metaRow: { flexDirection: 'row', alignItems: 'center', flexWrap: 'wrap', gap: 10 },
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
  grow: { flex: 1 },
});
