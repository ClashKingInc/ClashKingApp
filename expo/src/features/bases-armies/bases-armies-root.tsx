import { cloneElement, useCallback, useEffect, useState, type ReactElement } from 'react';
import { ArrowLeft, Bookmark, Download, ExternalLink } from 'lucide-react-native';
import {
  Linking,
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
  PersonalBaseSlotKind,
  PersonalBaseSlotNumber,
} from './personal-bases-service';

const SLOT_NUMBERS = [1, 2, 3] as const;
const EMPTY_SLOT = '__empty__';

export function BasesArmiesRoot({ onBack }: { readonly onBack: () => void }) {
  const runtime = useAppRuntime();
  return (
    <BasesArmiesScreen
      onBack={onBack}
      playerTags={runtime.accounts.verifiedAccounts.map((account) => account.playerTag)}
      service={runtime.personalBases}
    />
  );
}

export function BasesArmiesScreen({
  onBack,
  playerTags,
  service,
}: {
  readonly onBack: () => void;
  readonly playerTags: readonly string[];
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
          {(state?.items.length ?? 0) === 0 ? (
            <EmptyState title={t('sideSavedBases')} />
          ) : (
            state?.items.map((base) => (
              <BaseCard
                base={base}
                busy={busyKey === `base:${base.id}`}
                key={base.id}
                onOpen={() => void Linking.openURL(base.baseLink)}
                onToggleSaved={() =>
                  void mutate(`base:${base.id}`, () =>
                    base.saved ? service.unsave(base.id) : service.save(base.id),
                  )
                }
              />
            ))
          )}

          {playerTags.length === 0 ? (
            <EmptyState
              showSticker={false}
              title={t('dashboardNoLinkedAccountsTitle')}
              body={t('dashboardNoLinkedAccountsBody')}
            />
          ) : (
            playerTags.map((playerTag) => (
              <AccountSlots
                bases={state?.items.filter((base) => base.saved) ?? []}
                busy={busyKey !== null}
                key={playerTag}
                playerTag={playerTag}
                slots={state?.slots ?? []}
                onSelect={(kind, number, baseId) => {
                  const key = `slot:${playerTag}:${kind}:${number}`;
                  void mutate(key, () =>
                    baseId === null
                      ? service.clear(playerTag, kind, number)
                      : service.assign(playerTag, kind, number, baseId),
                  );
                }}
              />
            ))
          )}
        </ScrollView>
      )}
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
  onToggleSaved,
}: {
  readonly base: PersonalBase;
  readonly busy: boolean;
  readonly onOpen: () => void;
  readonly onToggleSaved: () => void;
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
          <ActionButton
            disabled={busy}
            icon={<Bookmark color={theme.primary} />}
            label={base.saved ? t('generalRemoveBookmark') : t('gameAssetsSave')}
            onPress={onToggleSaved}
          />
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

function AccountSlots({
  bases,
  busy,
  playerTag,
  slots,
  onSelect,
}: {
  readonly bases: readonly PersonalBase[];
  readonly busy: boolean;
  readonly playerTag: string;
  readonly slots: PersonalBasesState['slots'];
  readonly onSelect: (
    kind: PersonalBaseSlotKind,
    number: PersonalBaseSlotNumber,
    baseId: string | null,
  ) => void;
}) {
  const { t } = useI18n();
  return (
    <Surface radius={18} style={styles.accountSlots}>
      <CKText role="rowTitle">{playerTag}</CKText>
      {(['war', 'legend'] as const).map((kind) => (
        <View key={kind} style={styles.slotGroup}>
          <CKText muted role="labelLarge">
            {kind === 'war' ? t('sideWarBaseSlots') : t('sideLegendBaseSlots')}
          </CKText>
          {SLOT_NUMBERS.map((number) => {
            const assigned = slots.find(
              (slot) =>
                slot.playerTag === playerTag && slot.kind === kind && slot.number === number,
            );
            const options = [
              { key: EMPTY_SLOT, label: t('searchClear') },
              ...bases.map((base) => ({
                key: base.id,
                label: base.description || `#${base.id}`,
                subtitle: `#${base.id}`,
                disabled:
                  busy ||
                  slots.some(
                    (slot) =>
                      slot.playerTag === playerTag &&
                      slot.kind === kind &&
                      slot.baseId === base.id &&
                      slot.number !== number,
                  ),
              })),
            ];
            return (
              <View key={number} style={styles.slotRow}>
                <CKText role="labelLarge" style={styles.slotNumber}>
                  {number}
                </CKText>
                <SelectionPicker
                  accessibilityLabel={`${playerTag} ${kind} ${number}`}
                  fillWidth
                  onSelect={(baseId) => {
                    if (!busy) onSelect(kind, number, baseId === EMPTY_SLOT ? null : baseId);
                  }}
                  options={options}
                  selectedKey={assigned?.baseId ?? EMPTY_SLOT}
                  title={kind === 'war' ? t('sideWarBaseSlots') : t('sideLegendBaseSlots')}
                />
              </View>
            );
          })}
        </View>
      ))}
    </Surface>
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
  accountSlots: { padding: 14, marginBottom: 12, gap: 14 },
  slotGroup: { gap: 8 },
  slotRow: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  slotNumber: { width: 18, textAlign: 'center' },
});
