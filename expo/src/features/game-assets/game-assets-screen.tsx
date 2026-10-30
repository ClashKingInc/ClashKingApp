import { useAdaptiveLayout } from '../../ui/adaptive-layout';
import { modalOrientations } from '../../ui/modal-orientations';
import { useEffect, useMemo, useRef, useState, useSyncExternalStore, type ReactNode } from 'react';
import {
  ActivityIndicator,
  FlatList,
  Modal,
  Pressable,
  StyleSheet,
  View,
  useWindowDimensions,
} from 'react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';
import {
  ArrowLeft,
  ArrowRight,
  Images,
  ImageOff,
  PackageOpen,
  Search,
  Share2,
} from 'lucide-react-native';

import { ImageAssets } from '../../core/assets/image-assets';
import { gameDataState, subscribeToGameDataRevision } from '../../core/game-data/game-data-state';
import { materialBackLabel, toIntlLocale, useI18n, type MessageKey } from '../../i18n';
import {
  CKText,
  EmptyState,
  ErrorState,
  HeaderIconButton,
  MobileWebImage,
  ProfilePageHeader,
  SearchField,
  SelectionPicker,
  PillSurface,
  SkeletonContent,
  Surface,
  colorWithAlpha,
  useCKTheme,
} from '../../ui';
import type { GameAssetActions } from './actions';
import { GameAssetImage } from './game-asset-image';
import { useLinkParameters } from '../../core/deep-links/link-parameters';
import {
  filterGameAssets,
  formatGameAssetCategory,
  GameAsset,
  type GameAssetCategory,
  GameAssetManifest,
} from './models';

export interface GameAssetsScreenProps {
  readonly manifest: GameAssetManifest | null;
  readonly loading: boolean;
  readonly error: unknown;
  readonly actions: GameAssetActions;
  readonly onBack: () => void;
  readonly onRefresh: () => void;
}

export function GameAssetsScreen({
  manifest: loadedManifest,
  loading,
  error,
  actions,
  onBack,
  onRefresh,
}: GameAssetsScreenProps) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const { width } = useWindowDimensions();
  const layout = useAdaptiveLayout();
  const insets = useSafeAreaInsets();
  const contentLoading = !loadedManifest && loading;
  const manifest = loadedManifest ?? (contentLoading ? loadingManifest : null);
  const categories = manifest?.categories ?? [];
  const link = useLinkParameters();
  const [categoryId, setCategoryId] = useState(link.category ?? 'all');
  const [query, setQuery] = useState(link.q ?? '');
  const [selectedAssetOverride, setSelectedAssetOverride] = useState<GameAsset | null>();
  const selectedAsset =
    selectedAssetOverride === undefined
      ? manifest?.assets.find((asset) => asset.path === link.asset)
      : (selectedAssetOverride ?? undefined);
  const setSelectedAsset = (asset?: GameAsset) => setSelectedAssetOverride(asset ?? null);
  const [snackbar, setSnackbar] = useState<string>();
  const snackbarTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const dataRevision = useSyncExternalStore(
    subscribeToGameDataRevision,
    () => gameDataState.revision,
    () => gameDataState.revision,
  );
  const selectedCategory = categories.find((category) => category.id === categoryId) ?? null;
  const filteredAssets = useMemo(
    // All is a view over the complete manifest, never just its first category.
    // Old format links must not silently narrow results after the picker is removed.
    () => {
      void dataRevision;
      return filterGameAssets(
        selectedCategory?.assets ?? manifest?.assets ?? [],
        contentLoading ? {} : { query },
      );
    },
    [query, selectedCategory, manifest, contentLoading, dataRevision],
  );
  useEffect(
    () => () => {
      if (snackbarTimer.current) clearTimeout(snackbarTimer.current);
    },
    [],
  );

  if (!manifest && error) {
    return (
      <SafeAreaView style={[styles.screen, { backgroundColor: theme.background }]}>
        <SimpleHeader onBack={onBack} />
        <View style={styles.feedbackWrap}>
          <ErrorState
            title={t('gameAssetsLoadError')}
            body={t('generalTryAgain')}
            actionLabel={t('generalRetry')}
            onAction={onRefresh}
          />
        </View>
      </SafeAreaView>
    );
  }
  if (!manifest || manifest.assets.length === 0) {
    return (
      <SafeAreaView style={[styles.screen, { backgroundColor: theme.background }]}>
        <SimpleHeader onBack={onBack} />
        <View style={styles.feedbackWrap}>
          <EmptyState
            icon={<PackageOpen color={theme.onSurfaceVariant} />}
            title={t('gameAssetsEmptyTitle')}
            body={t('gameAssetsEmptyBody')}
          />
        </View>
      </SafeAreaView>
    );
  }

  const phoneWidth =
    layout.isDuo && !layout.isExpanded
      ? Math.min(layout.width, layout.contentMaxWidth)
      : layout.isDuo || layout.isTablet
        ? layout.width
        : width;
  const columns = layout.isExpanded
    ? layout.columns(220, 4)
    : layout.isDuo
      ? 3
      : phoneWidth >= 600
        ? 4
        : 3;
  const contentWidth = layout.isExpanded
    ? Math.min(layout.usableWidth, layout.contentMaxWidth)
    : Math.min(phoneWidth, 1120);
  const tileWidth = Math.max(0, (contentWidth - 32 - (columns - 1) * 12) / columns);
  const chooseCategory = (next: string) => {
    setCategoryId(next);
    // Keep the search phrase when changing category so All can widen the same search.
  };
  const showMessage = (message: string) => {
    setSnackbar(message);
    if (snackbarTimer.current) clearTimeout(snackbarTimer.current);
    snackbarTimer.current = setTimeout(
      () => setSnackbar((current) => (current === message ? undefined : current)),
      3000,
    );
  };
  return (
    <View style={[styles.screen, { backgroundColor: theme.background }]}>
      <FlatList
        key={`game-assets-${columns}`}
        data={filteredAssets}
        numColumns={columns}
        keyExtractor={(asset) => asset.path}
        keyboardDismissMode="on-drag"
        keyboardShouldPersistTaps="handled"
        columnWrapperStyle={columns > 1 ? styles.gridRow : undefined}
        contentContainerStyle={styles.listContent}
        ListHeaderComponent={
          <>
            <GameAssetsHero onBack={onBack} />
            <View style={[styles.controlsBound, { width: contentWidth }]}>
              <SkeletonContent loading={contentLoading}>
                <AssetControls
                  category={selectedCategory}
                  categories={categories}
                  query={query}
                  onCategoryChange={chooseCategory}
                  onQueryChange={setQuery}
                />
                <CKText muted role="bodySmall" style={styles.resultCount}>
                  {formatResultCount(filteredAssets.length, locale, t)}
                </CKText>
              </SkeletonContent>
            </View>
          </>
        }
        ListEmptyComponent={
          <View style={[styles.emptyResults, { width: contentWidth }]}>
            <EmptyState
              icon={<ImageOff color={theme.onSurfaceVariant} />}
              title={t('gameAssetsNoResultsTitle')}
              body={t('gameAssetsNoResultsBody')}
            />
          </View>
        }
        renderItem={({ item }) => (
          <SkeletonContent
            loading={contentLoading}
            style={columns === 1 ? { alignSelf: 'center', marginBottom: 12 } : undefined}
          >
            <GameAssetTile
              asset={item}
              width={tileWidth}
              onOpen={() => setSelectedAsset(item)}
              onLongPress={async () => {
                try {
                  await actions.copy(item.url);
                  showMessage(t('gameAssetsUrlCopied'));
                } catch {
                  showMessage(t('gameAssetsCopyError'));
                }
              }}
            />
          </SkeletonContent>
        )}
      />
      <GameAssetPreview
        key={selectedAsset?.path ?? 'closed'}
        asset={selectedAsset}
        actions={actions}
        message={snackbar}
        onClose={() => setSelectedAsset(undefined)}
        showMessage={showMessage}
      />
      {snackbar && !selectedAsset ? (
        <PillSurface
          style={[
            styles.snackbar,
            { backgroundColor: theme.snackbar },
            (layout.isDuo || layout.isTablet) && {
              left: insets.left + 16,
              right: insets.right + 16,
              bottom: insets.bottom + 18,
            },
          ]}
        >
          <CKText>{snackbar}</CKText>
        </PillSurface>
      ) : null}
    </View>
  );
}

function GameAssetsHero({ onBack }: { onBack: () => void }) {
  const { t, locale } = useI18n();
  const insets = useSafeAreaInsets();
  return (
    <ProfilePageHeader
      title={t('sideGameAssetsTitle')}
      imageUrl={`${ImageAssets.baseUrl}/resources/starry_ore.webp`}
      imageElement={<OreHeaderIcon />}
      imageSize={48}
      identityOffsetY={-16}
      backgroundSource={require('../../../assets/clashking/backgrounds/assets-goblin-v2.webp')}
      safeTop={insets.top}
      bottomPadding={16}
      onBack={onBack}
      backLabel={materialBackLabel(locale)}
    />
  );
}

function OreHeaderIcon() {
  return (
    <View pointerEvents="none" accessible={false} style={styles.oreCluster}>
      <MobileWebImage
        imageUrl={`${ImageAssets.baseUrl}/resources/shiny_ore.webp`}
        contentFit="contain"
        style={[styles.oreRear, { left: 0 }]}
      />
      <MobileWebImage
        imageUrl={`${ImageAssets.baseUrl}/resources/glowy_ore.webp`}
        contentFit="contain"
        style={[styles.oreRear, { right: 0 }]}
      />
      <MobileWebImage
        imageUrl={`${ImageAssets.baseUrl}/resources/starry_ore.webp`}
        contentFit="contain"
        style={styles.oreFront}
      />
    </View>
  );
}

function SimpleHeader({ onBack }: { onBack: () => void }) {
  const { t, isRtl, locale } = useI18n();
  const theme = useCKTheme();
  return (
    <View style={styles.simpleHeader}>
      <HeaderIconButton
        label={materialBackLabel(locale)}
        onPress={onBack}
        icon={
          isRtl ? <ArrowRight color={theme.onSurface} /> : <ArrowLeft color={theme.onSurface} />
        }
      />
      <View style={styles.heroCopy}>
        <CKText skeleton={false} role="screenTitle">
          {t('sideGameAssetsTitle')}
        </CKText>
        <CKText skeleton={false} muted>
          {t('sideGameAssetsSubtitle')}
        </CKText>
      </View>
    </View>
  );
}

function AssetControls({
  category,
  categories,
  query,
  onCategoryChange,
  onQueryChange,
}: {
  category: GameAssetCategory | null;
  categories: readonly GameAssetCategory[];
  query: string;
  onCategoryChange: (value: string) => void;
  onQueryChange: (value: string) => void;
}) {
  const { t } = useI18n();
  const { width: windowWidth, fontScale } = useWindowDimensions();
  const layout = useAdaptiveLayout();
  const width = layout.isDuo || layout.isTablet ? layout.width : windowWidth;
  const stackControls = width < 350 || fontScale > 1.35;
  const categorySelector = (
    <SelectionPicker
      fillWidth
      iconOnly
      title={formatGameAssetCategory(t('sideGameAssetsTitle'))}
      selectedKey={category?.id ?? 'all'}
      onSelect={onCategoryChange}
      options={[
        { key: 'all', label: formatGameAssetCategory(t('generalAll')), icon: <Images size={20} /> },
        ...categories.map((item) => ({
          key: item.id,
          label: localizedCategory(item.id, t),
          icon: <GameAssetImage asset={item.representativeAsset} style={styles.selectorImage} />,
        })),
      ]}
    />
  );
  const search = (
    <SearchField
      value={query}
      onChangeText={onQueryChange}
      placeholder={t('gameAssetsSearchHint')}
      searchIcon={<Search size={20} />}
    />
  );
  return (
    <View style={[styles.controlsRow, stackControls && { flexDirection: 'column' }]}>
      <View style={!stackControls && styles.searchGrow}>{search}</View>
      <View style={{ width: 76 }}>{categorySelector}</View>
    </View>
  );
}

function GameAssetTile({
  asset,
  width,
  onOpen,
  onLongPress,
}: {
  asset: GameAsset;
  width: number;
  onOpen: () => void;
  onLongPress: () => void;
}) {
  const { t } = useI18n();
  const layout = useAdaptiveLayout();
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={asset.tileDisplayName}
      accessibilityHint={t('gameAssetsLongPressHint')}
      onPress={onOpen}
      onLongPress={onLongPress}
      style={{ width }}
    >
      <Surface radius={20} style={[styles.tile, layout.isExpanded && { height: 226, padding: 18 }]}>
        <GameAssetImage asset={asset} style={styles.tileImage} />
        <CKText role="labelLarge" numberOfLines={2} style={styles.tileName}>
          {asset.tileDisplayName}
        </CKText>
      </Surface>
    </Pressable>
  );
}

function GameAssetPreview({
  asset,
  actions,
  message,
  onClose,
  showMessage,
}: {
  asset?: GameAsset;
  actions: GameAssetActions;
  message?: string;
  onClose: () => void;
  showMessage: (message: string) => void;
}) {
  const { t, isRtl, locale } = useI18n();
  const theme = useCKTheme();
  const [sharing, setSharing] = useState(false);
  const insets = useSafeAreaInsets();
  if (!asset) return null;
  const share = async () => {
    setSharing(true);
    try {
      await actions.share(asset);
    } catch {
      showMessage(t('gameAssetsShareError'));
    } finally {
      setSharing(false);
    }
  };
  return (
    <Modal
      supportedOrientations={modalOrientations}
      visible
      transparent={false}
      animationType="slide"
      onRequestClose={onClose}
    >
      {/* A full-screen Modal has its own native host; explicit window insets
          keep its controls below the status bar and clear of landscape cutouts. */}
      <View
        style={[
          styles.preview,
          {
            backgroundColor: theme.background,
            paddingTop: insets.top,
            paddingBottom: insets.bottom,
            paddingLeft: insets.left,
            paddingRight: insets.right,
          },
        ]}
      >
        <View style={[styles.previewHeader, { backgroundColor: theme.surface }]}>
          <HeaderIconButton
            label={materialBackLabel(locale)}
            onPress={onClose}
            icon={
              isRtl ? <ArrowRight color={theme.onSurface} /> : <ArrowLeft color={theme.onSurface} />
            }
          />
          <CKText role="titleMedium" numberOfLines={1} style={styles.previewTitle}>
            {asset.tileDisplayName}
          </CKText>
        </View>
        <View
          style={[
            styles.previewImagePanel,
            { backgroundColor: colorWithAlpha(theme.surfaceContainerHighest, 0.34) },
          ]}
        >
          <GameAssetImage asset={asset} style={styles.previewImage} />
        </View>
        <View style={styles.previewDetails}>
          {message ? (
            <PillSurface style={{ backgroundColor: theme.snackbar, padding: 12 }}>
              <CKText accessibilityRole="alert">{message}</CKText>
            </PillSurface>
          ) : null}
          <View style={styles.actionWrap}>
            <ActionButton
              label={t('gameAssetsShare')}
              icon={
                sharing ? (
                  <ActivityIndicator color={theme.primary} />
                ) : (
                  <Share2 size={18} color={theme.primary} />
                )
              }
              disabled={sharing}
              tonal
              onPress={() => void share()}
            />
          </View>
        </View>
      </View>
    </Modal>
  );
}

function ActionButton({
  label,
  icon,
  disabled,
  tonal,
  filled,
  onPress,
}: {
  label: string;
  icon: ReactNode;
  disabled?: boolean;
  tonal?: boolean;
  filled?: boolean;
  onPress: () => void;
}) {
  const theme = useCKTheme();
  return (
    <Pressable
      disabled={disabled}
      accessibilityRole="button"
      accessibilityLabel={label}
      onPress={onPress}
    >
      <View
        style={[
          styles.actionButton,
          {
            backgroundColor: filled
              ? theme.primary
              : tonal
                ? colorWithAlpha(theme.primary, 0.14)
                : 'transparent',
            borderColor: filled || tonal ? 'transparent' : theme.outlineVariant,
            opacity: disabled ? 0.6 : 1,
          },
        ]}
      >
        {icon}
        <CKText role="labelLarge" style={filled ? { color: theme.onPrimary } : undefined}>
          {label}
        </CKText>
      </View>
    </Pressable>
  );
}

// Presentation-only rows; they never enter the manifest cache or asset actions.
const loadingManifest = new GameAssetManifest(
  2,
  Array.from(
    { length: 12 },
    (_, index) =>
      new GameAsset({
        path: `buildings/loading-${index}.webp`,
        category: 'buildings',
        displayName: 'Game artwork',
        extension: 'webp',
        url: 'https://assets.clashk.ing/loading.webp',
      }),
  ),
);

type Translator = ReturnType<typeof useI18n>['t'];

export function localizedCategory(category: string, t: Translator): string {
  const key: MessageKey | null =
    category === 'buildings'
      ? 'gameAssetsCategoryBuildings'
      : category === 'capital_base' || category === 'capital-base'
        ? 'gameAssetsCategoryCapitalBase'
        : ['capital_house_parts', 'capital-house-parts', 'capital_house-parts'].includes(category)
          ? 'gameAssetsCategoryCapitalHouseParts'
          : category === 'chests'
            ? 'gameAssetsCategoryChests'
            : category === 'clan_labels' || category === 'clan-labels'
              ? 'gameAssetsCategoryClanLabels'
              : category === 'country_flags' || category === 'country-flags'
                ? 'gameAssetsCategoryCountryFlags'
                : category === 'decorations'
                  ? 'gameAssetsCategoryDecorations'
                  : category === 'equipment'
                    ? 'gameAssetsCategoryEquipment'
                    : category === 'guardians'
                      ? 'gameAssetsCategoryGuardians'
                      : category === 'heroes'
                        ? 'gameAssetsCategoryHeroes'
                        : category === 'pets'
                          ? 'gameAssetsCategoryPets'
                          : category === 'skins'
                            ? 'gameAssetsCategorySkins'
                            : category === 'spells'
                              ? 'gameAssetsCategorySpells'
                              : category === 'troops'
                                ? 'gameAssetsCategoryTroops'
                                : null;
  return formatGameAssetCategory(key ? t(key) : category);
}

export function formatImageCount(count: number, locale: string, t: Translator): string {
  return count === 1
    ? t('gameAssetsOneImage')
    : t('gameAssetsImageCount', {
        count: new Intl.NumberFormat(toIntlLocale(locale)).format(count),
      });
}

export function formatResultCount(count: number, locale: string, t: Translator): string {
  return count === 1
    ? t('gameAssetsOneResult')
    : t('gameAssetsResultCount', {
        count: new Intl.NumberFormat(toIntlLocale(locale)).format(count),
      });
}

const styles = StyleSheet.create({
  screen: { flex: 1 },
  listContent: { paddingBottom: 28 },
  fill: { width: '100%', height: '100%' },
  heroCopy: { flex: 1 },
  oreCluster: { width: 48, height: 48 },
  oreRear: { position: 'absolute', top: 0, width: 26, height: 26 },
  oreFront: { position: 'absolute', bottom: 0, left: 7, width: 34, height: 34 },
  simpleHeader: {
    minHeight: 72,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingHorizontal: 16,
  },
  feedbackWrap: { flex: 1, padding: 16 },
  controlsBound: { alignSelf: 'center', paddingHorizontal: 16, paddingTop: 8, paddingBottom: 7 },
  controlsRow: { flexDirection: 'row', gap: 8 },
  searchGrow: { flex: 1, minWidth: 0 },
  selectorImage: { width: 22, height: 22 },
  resultCount: { paddingHorizontal: 2, paddingTop: 7 },
  gridRow: { justifyContent: 'center', gap: 12, marginBottom: 12 },
  tile: { height: 142, padding: 12 },
  tileImage: { flex: 1, width: '100%' },
  tileName: { minHeight: 30, marginTop: 8 },
  emptyResults: { alignSelf: 'center', paddingHorizontal: 18 },
  preview: { flex: 1 },
  previewHeader: {
    minHeight: 56,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 8,
  },
  previewTitle: { flex: 1, marginHorizontal: 8 },
  previewImagePanel: {
    flex: 1,
    marginHorizontal: 16,
    marginTop: 12,
    padding: 12,
    borderRadius: 18,
    overflow: 'hidden',
  },
  previewImage: { width: '100%', height: '100%' },
  previewDetails: { paddingHorizontal: 16, paddingTop: 14, paddingBottom: 18, gap: 12 },
  actionWrap: { flexDirection: 'row', justifyContent: 'center' },
  actionButton: {
    minHeight: 44,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 7,
    paddingHorizontal: 14,
    borderRadius: 999,
    borderWidth: StyleSheet.hairlineWidth,
  },
  snackbar: {
    position: 'absolute',
    left: 16,
    right: 16,
    bottom: 18,
    minHeight: 48,
    justifyContent: 'center',
    paddingHorizontal: 16,
  },
});
