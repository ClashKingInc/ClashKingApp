import { cloneElement, useCallback, useEffect, useState, type ReactElement } from 'react';
import { ArrowLeft, Bookmark, Download, ExternalLink, Tag, Trash2, X } from 'lucide-react-native';
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
  PersonalBase,
  PersonalBasesServiceContract,
  PersonalBasesState,
  PersonalBaseKind,
} from './personal-bases-service';

const CLEAR_KIND = '__clear__';

export function BasesArmiesRoot({ onBack }: { readonly onBack: () => void }) {
  const runtime = useAppRuntime();
  return <BasesArmiesScreen onBack={onBack} service={runtime.personalBases} />;
}

export function BasesArmiesScreen({
  onBack,
  service,
}: {
  readonly onBack: () => void;
  readonly service: PersonalBasesServiceContract;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  const { width } = useWindowDimensions();
  const horizontal = Platform.OS === 'web' && width >= 900 ? Math.max(16, (width - 1200) / 2) : 16;
  const [state, setState] = useState<PersonalBasesState | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [loadError, setLoadError] = useState(false);
  const [mutationError, setMutationError] = useState(false);
  const [busyKey, setBusyKey] = useState<string | null>(null);
  const [cleanupVisible, setCleanupVisible] = useState(false);
  const [cleanupNow, setCleanupNow] = useState(Date.now);

  const load = useCallback(
    async (refresh = false) => {
      if (refresh) setRefreshing(true);
      else setLoading(true);
      setLoadError(false);
      try {
        setState(await service.load());
      } catch {
        setLoadError(true);
      } finally {
        setLoading(false);
        setRefreshing(false);
      }
    },
    [service],
  );

  useEffect(() => {
    let current = true;
    void service
      .load()
      .then((value) => {
        if (current) setState(value);
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
  }, [service]);

  const mutate = useCallback(
    async (key: string, operation: () => Promise<PersonalBasesState>) => {
      if (busyKey !== null) return;
      setBusyKey(key);
      setMutationError(false);
      try {
        setState(await operation());
      } catch {
        setMutationError(true);
      } finally {
        setBusyKey(null);
      }
    },
    [busyKey],
  );
  const savedItems = state?.items.filter((base) => base.saved) ?? [];
  const historyItems = state?.items.filter((base) => base.downloadedAt !== null) ?? [];
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
          <CKText muted role="bodySmall" numberOfLines={1}>
            {t('sideBasesArmiesSubtitle')}
          </CKText>
        </View>
        <View style={styles.headerSpacer} />
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

          <SectionTitle title={t('sideSavedBases')} />
          <ActionButton
            disabled={busyKey !== null || oldSavedCount === 0}
            icon={<Trash2 color={theme.primary} />}
            label={t('personalBasesDeleteOld')}
            onPress={() => {
              setCleanupNow(Date.now());
              setCleanupVisible(true);
            }}
          />
          {savedItems.length === 0 ? (
            <EmptyState title={t('sideSavedBases')} />
          ) : (
            savedItems.map((base) => (
              <BaseCard
                base={base}
                busy={busyKey === `base:${base.id}`}
                key={base.id}
                onOpen={() => void Linking.openURL(base.baseLink)}
                onKind={(kind) => void mutate(`base:${base.id}`, () => service.save(base.id, kind))}
                onToggleSaved={() => void mutate(`base:${base.id}`, () => service.unsave(base.id))}
              />
            ))
          )}

          <SectionTitle title={t('generalHistory')} />
          {historyItems.length === 0 ? (
            <EmptyState title={t('generalHistory')} />
          ) : (
            historyItems.map((base) => (
              <BaseCard
                base={base}
                busy={busyKey === `history:${base.id}`}
                key={`history:${base.id}`}
                onOpen={() => void Linking.openURL(base.baseLink)}
                onToggleSaved={
                  base.saved
                    ? undefined
                    : () => void mutate(`history:${base.id}`, () => service.save(base.id, null))
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
                    await service.deleteOld();
                    return service.load();
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

function SectionTitle({ title }: { readonly title: string }) {
  return (
    <CKText role="sectionTitle" style={styles.sectionTitle}>
      {title}
    </CKText>
  );
}

function BaseCard({
  base,
  busy,
  onOpen,
  onKind,
  onToggleSaved,
}: {
  readonly base: PersonalBase;
  readonly busy: boolean;
  readonly onOpen: () => void;
  readonly onKind?: (kind: PersonalBaseKind | null) => void;
  readonly onToggleSaved?: () => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  return (
    <Surface radius={18} style={styles.baseCard}>
      <MobileWebImage
        contentFit="cover"
        imageUrl={base.images[0] ?? ImageAssets.clanCastle}
        style={styles.baseImage}
      />
      <View style={styles.baseContent}>
        <CKText role="rowTitle" numberOfLines={2}>
          {base.description || `#${base.id}`}
        </CKText>
        <View style={styles.metaRow}>
          {base.downloadedAt !== null ? (
            <Meta
              icon={<Download color={theme.onSurfaceVariant} />}
              label={new Date(base.downloadedAt).toLocaleDateString()}
            />
          ) : null}
          {base.saved ? (
            <Meta icon={<Bookmark color={theme.onSurfaceVariant} />} label={t('gameAssetsSaved')} />
          ) : null}
          <CKText muted role="labelSmall">
            #{base.id}
          </CKText>
        </View>
        <View style={styles.actions}>
          <ActionButton
            icon={<ExternalLink color={theme.primary} />}
            label={t('generalOpen')}
            onPress={onOpen}
          />
          {onKind ? (
            <View style={styles.kindPicker}>
              <Tag color={theme.onSurfaceVariant} size={16} />
              <SelectionPicker
                accessibilityLabel={`#${base.id} kind`}
                onSelect={(kind) => {
                  if (!busy) onKind(kind === CLEAR_KIND ? null : (kind as PersonalBaseKind));
                }}
                options={[
                  { key: CLEAR_KIND, label: t('searchClear'), disabled: busy },
                  { key: 'war', label: t('warTitle'), disabled: busy },
                  { key: 'legend', label: t('legendsTitle'), disabled: busy },
                ]}
                selectedKey={base.kind ?? CLEAR_KIND}
                title={t('sideSavedBases')}
              />
            </View>
          ) : null}
          {onToggleSaved ? (
            <ActionButton
              disabled={busy}
              icon={<Bookmark color={theme.primary} />}
              label={base.saved ? t('generalRemoveBookmark') : t('gameAssetsSave')}
              onPress={onToggleSaved}
            />
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
  sectionTitle: { marginTop: 18, marginBottom: 8 },
  baseCard: { flexDirection: 'row', padding: 12, marginBottom: 10, gap: 12 },
  baseImage: { width: 104, minHeight: 104, borderRadius: 12 },
  baseContent: { flex: 1, gap: 8 },
  metaRow: { flexDirection: 'row', alignItems: 'center', flexWrap: 'wrap', gap: 10 },
  meta: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  actions: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginTop: 'auto' },
  actionButton: {
    minHeight: 40,
    paddingHorizontal: 12,
    borderRadius: 12,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  disabled: { opacity: 0.5 },
  kindPicker: { flexDirection: 'row', alignItems: 'center', gap: 6, minWidth: 170 },
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
