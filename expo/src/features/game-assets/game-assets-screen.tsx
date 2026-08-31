import { useEffect, useMemo, useRef, useState, type ReactNode } from 'react';
import {
  ActivityIndicator,
  FlatList,
  Modal,
  Pressable,
  ScrollView,
  StyleSheet,
  TextInput,
  View,
  useWindowDimensions,
} from 'react-native';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import Animated, { useAnimatedStyle, useSharedValue } from 'react-native-reanimated';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';
import Svg, { Defs, LinearGradient, Rect, Stop } from 'react-native-svg';
import {
  ArrowLeft,
  ArrowRight,
  Check,
  ClipboardCopy,
  Download,
  FileImage,
  ImageOff,
  Images,
  Link2,
  PackageOpen,
  RefreshCw,
  Search,
  Share2,
  X,
} from 'lucide-react-native';

import { ImageAssets } from '../../core/assets/image-assets';
import { materialBackLabel, toIntlLocale, useI18n, type MessageKey } from '../../i18n';
import {
  CKText,
  EmptyState,
  ErrorState,
  GlassPill,
  HeaderIconButton,
  MobileWebImage,
  PillSurface,
  Skeleton,
  Surface,
  colorWithAlpha,
  useCKTheme,
  useCKThemeMode,
} from '../../ui';
import type { GameAssetActions } from './actions';
import { GameAssetImage } from './game-asset-image';
import {
  filterGameAssets,
  formatGameAssetCategory,
  type GameAsset,
  type GameAssetCategory,
  type GameAssetManifest,
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
  manifest,
  loading,
  error,
  actions,
  onBack,
  onRefresh,
}: GameAssetsScreenProps) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const { width } = useWindowDimensions();
  const categories = manifest?.categories ?? [];
  const [categoryId, setCategoryId] = useState<string>();
  const [query, setQuery] = useState('');
  const [extension, setExtension] = useState('');
  const [selectedAsset, setSelectedAsset] = useState<GameAsset>();
  const [snackbar, setSnackbar] = useState<string>();
  const snackbarTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const selectedCategory =
    categories.find((category) => category.id === categoryId) ?? categories[0] ?? null;
  const filteredAssets = useMemo(
    () => (selectedCategory ? filterGameAssets(selectedCategory.assets, { query, extension }) : []),
    [extension, query, selectedCategory],
  );
  useEffect(
    () => () => {
      if (snackbarTimer.current) clearTimeout(snackbarTimer.current);
    },
    [],
  );

  if (!manifest && loading) {
    return (
      <View style={[styles.screen, { backgroundColor: theme.background }]}>
        <GameAssetsHero category={null} loading onBack={onBack} onRefresh={onRefresh} />
        <LoadingSkeleton width={width} />
      </View>
    );
  }
  if (!manifest && error) {
    return (
      <SafeAreaView style={[styles.screen, { backgroundColor: theme.background }]}>
        <SimpleHeader onBack={onBack} />
        <View style={styles.feedbackWrap}>
          <ErrorState
            title={t('gameAssetsLoadError')}
            body={String(error)}
            actionLabel={t('generalRetry')}
            onAction={onRefresh}
          />
        </View>
      </SafeAreaView>
    );
  }
  if (!selectedCategory) {
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

  const columns = width >= 600 ? 4 : 3;
  const contentWidth = Math.min(width, 1120);
  const tileWidth = Math.max(0, (contentWidth - 24 - (columns - 1) * 10) / columns);
  const chooseCategory = (next: string) => {
    setCategoryId(next);
    setQuery('');
    setExtension('');
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
        columnWrapperStyle={styles.gridRow}
        contentContainerStyle={styles.listContent}
        ListHeaderComponent={
          <>
            <GameAssetsHero
              category={selectedCategory}
              loading={loading}
              onBack={onBack}
              onRefresh={onRefresh}
            />
            <View style={[styles.controlsBound, { width: contentWidth }]}>
              <AssetControls
                category={selectedCategory}
                categories={categories}
                extension={extension}
                query={query}
                onCategoryChange={chooseCategory}
                onExtensionChange={setExtension}
                onQueryChange={setQuery}
              />
              <CKText muted role="bodySmall" style={styles.resultCount}>
                {formatResultCount(filteredAssets.length, locale, t)}
              </CKText>
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
        <PillSurface style={[styles.snackbar, { backgroundColor: theme.snackbar }]}>
          <CKText>{snackbar}</CKText>
        </PillSurface>
      ) : null}
    </View>
  );
}

function GameAssetsHero({
  category,
  loading,
  onBack,
  onRefresh,
}: {
  category: GameAssetCategory | null;
  loading: boolean;
  onBack: () => void;
  onRefresh: () => void;
}) {
  const { t, locale, isRtl } = useI18n();
  const theme = useCKTheme();
  const mode = useCKThemeMode();
  const insets = useSafeAreaInsets();
  const { width, height } = useWindowDimensions();
  const desktop = width >= 900;
  const compactLandscape = width >= 600 && height < 600;
  const heroHeight = insets.top + (compactLandscape ? 144 : desktop ? 240 : 264);
  const extensions = category?.extensions ?? [];
  const extensionText = extensions.length
    ? extensions
        .slice(0, 2)
        .map((value) => value.toUpperCase())
        .join(' / ')
    : t('gameAssetsAllFormats');
  const imageCount = category ? formatImageCount(category.count, locale, t) : null;
  const stats = imageCount ? (
    <View style={styles.heroStats}>
      <HeroStat icon={<Images size={19} color={theme.onSurface} />} value={imageCount} />
      <HeroStat icon={<FileImage size={19} color={theme.onSurface} />} value={extensionText} />
    </View>
  ) : (
    <View style={styles.heroStats}>
      <Skeleton width={122} height={31} radius={999} />
      <Skeleton width={82} height={31} radius={999} />
    </View>
  );
  return (
    <View style={[styles.hero, { height: heroHeight }]}>
      <MobileWebImage
        imageUrl={ImageAssets.homeBaseBackground}
        contentFit="cover"
        contentPosition="bottom center"
        style={StyleSheet.absoluteFill}
      />
      <View style={[StyleSheet.absoluteFill, styles.heroAdditionalDarken]} />
      <Svg pointerEvents="none" style={StyleSheet.absoluteFill} width="100%" height="100%">
        <Defs>
          <LinearGradient id="gameAssetsHeroGradient" x1="0" y1="0" x2="0" y2="1">
            <Stop offset="0" stopColor="#000" stopOpacity={mode === 'dark' ? 0.5 : 0.34} />
            <Stop offset="0.5" stopColor="#000" stopOpacity={mode === 'dark' ? 0.72 : 0.52} />
            <Stop offset="1" stopColor="#000" stopOpacity={mode === 'dark' ? 0.94 : 0.72} />
          </LinearGradient>
        </Defs>
        <Rect width="100%" height="100%" fill="url(#gameAssetsHeroGradient)" />
      </Svg>
      <SafeAreaView
        edges={['top', 'left', 'right']}
        style={[styles.heroSafe, { paddingHorizontal: desktop ? 24 : 12 }]}
      >
        <View style={styles.heroTopRow}>
          <HeaderIconButton
            glass={false}
            label={materialBackLabel(locale)}
            onPress={onBack}
            icon={isRtl ? <ArrowRight color="#fff" /> : <ArrowLeft color="#fff" />}
          />
          <HeaderIconButton
            glass={false}
            label={t('sideRefresh')}
            onPress={loading ? () => undefined : onRefresh}
            icon={loading ? <ActivityIndicator color="#fff" /> : <RefreshCw color="#fff" />}
          />
        </View>
        {compactLandscape ? (
          <View
            style={[
              styles.compactHeroIdentity,
              desktop ? styles.desktopHeroIdentityWidth : undefined,
            ]}
          >
            <View style={styles.compactHeroImage}>
              {category ? (
                <GameAssetImage asset={category.representativeAsset} style={styles.fill} />
              ) : (
                <Skeleton width={48} height={48} radius={14} />
              )}
            </View>
            <View style={styles.heroCopy}>
              <CKText
                role="titleLarge"
                numberOfLines={1}
                style={[styles.heroTitle, styles.compactHeroText]}
              >
                {t('sideGameAssetsTitle')}
              </CKText>
              <CKText
                role="bodySmall"
                numberOfLines={1}
                style={[styles.heroSubtitle, styles.compactHeroText]}
              >
                {t('sideGameAssetsSubtitle')}
              </CKText>
            </View>
            <View style={styles.compactHeroStats}>{stats}</View>
          </View>
        ) : (
          <View
            style={[
              styles.heroIdentity,
              desktop ? styles.desktopHeroIdentityWidth : undefined,
              { marginTop: desktop ? 4 : 8 },
            ]}
          >
            <View style={styles.heroImage}>
              {category ? (
                <GameAssetImage asset={category.representativeAsset} style={styles.fill} />
              ) : (
                <Skeleton width={64} height={64} radius={18} />
              )}
            </View>
            <CKText role="screenTitle" numberOfLines={1} style={styles.heroTitle}>
              {t('sideGameAssetsTitle')}
            </CKText>
            <CKText role="bodySmall" numberOfLines={1} style={styles.heroSubtitle}>
              {t('sideGameAssetsSubtitle')}
            </CKText>
            {stats}
          </View>
        )}
      </SafeAreaView>
    </View>
  );
}

function HeroStat({ icon, value }: { icon: ReactNode; value: string }) {
  const theme = useCKTheme();
  return (
    <View style={[styles.heroStat, { backgroundColor: colorWithAlpha(theme.surface, 0.58) }]}>
      {icon}
      <CKText role="labelLarge" numberOfLines={1}>
        {value}
      </CKText>
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
        <CKText role="screenTitle">{t('sideGameAssetsTitle')}</CKText>
        <CKText muted>{t('sideGameAssetsSubtitle')}</CKText>
      </View>
    </View>
  );
}

function AssetControls({
  category,
  categories,
  query,
  extension,
  onCategoryChange,
  onExtensionChange,
  onQueryChange,
}: {
  category: GameAssetCategory;
  categories: readonly GameAssetCategory[];
  query: string;
  extension: string;
  onCategoryChange: (value: string) => void;
  onExtensionChange: (value: string) => void;
  onQueryChange: (value: string) => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const { width } = useWindowDimensions();
  const categoryOptions = categories.map((item) => ({
    value: item.id,
    label: localizedCategory(item.id, t),
    asset: item.representativeAsset,
  }));
  const formatOptions = [
    { value: '', label: t('gameAssetsAllFormats') },
    ...category.extensions.map((value) => ({ value, label: value.toUpperCase() })),
  ];
  const categorySelector = (
    <AssetSelector
      value={category.id}
      options={categoryOptions}
      height={width >= 600 ? 44 : 36}
      onChange={onCategoryChange}
    />
  );
  const formatSelector = (
    <AssetSelector
      value={extension}
      options={formatOptions}
      leading={<FileImage size={18} color={theme.onSurfaceVariant} />}
      height={width >= 600 ? 44 : 36}
      onChange={onExtensionChange}
    />
  );
  const search = (
    <GlassPill style={styles.searchField}>
      <Search size={20} color={theme.onSurfaceVariant} />
      <TextInput
        accessibilityLabel={t('gameAssetsSearchHint')}
        autoCapitalize="none"
        autoCorrect={false}
        onChangeText={onQueryChange}
        placeholder={t('gameAssetsSearchHint')}
        placeholderTextColor={theme.onSurfaceVariant}
        style={[styles.searchInput, { color: theme.onSurface }]}
        value={query}
      />
      {query ? (
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={t('searchClear')}
          onPress={() => onQueryChange('')}
        >
          <X size={20} color={theme.onSurfaceVariant} />
        </Pressable>
      ) : null}
    </GlassPill>
  );
  return width >= 600 ? (
    <View style={styles.desktopControls}>
      <View style={styles.desktopCategory}>{categorySelector}</View>
      <View style={styles.desktopFormat}>{formatSelector}</View>
      <View style={styles.desktopSearch}>{search}</View>
    </View>
  ) : (
    <View style={styles.compactControls}>
      <View style={styles.selectorRow}>
        <View style={styles.selectorGrow}>{categorySelector}</View>
        <View style={styles.selectorGrow}>{formatSelector}</View>
      </View>
      {search}
    </View>
  );
}

interface SelectorOption {
  readonly value: string;
  readonly label: string;
  readonly asset?: GameAsset;
}

function AssetSelector({
  value,
  options,
  leading,
  height,
  onChange,
}: {
  value: string;
  options: readonly SelectorOption[];
  leading?: ReactNode;
  height: number;
  onChange: (value: string) => void;
}) {
  const theme = useCKTheme();
  const [visible, setVisible] = useState(false);
  const selected = options.find((option) => option.value === value) ?? options[0];
  return (
    <>
      <Pressable
        onPress={() => setVisible(true)}
        accessibilityRole="button"
        accessibilityLabel={selected?.label}
      >
        <Surface radius={12} style={[styles.selector, { minHeight: height }]}>
          {selected?.asset ? (
            <GameAssetImage asset={selected.asset} style={styles.selectorImage} />
          ) : (
            leading
          )}
          <CKText numberOfLines={1} style={styles.selectorText}>
            {selected?.label}
          </CKText>
          <CKText muted>▾</CKText>
        </Surface>
      </Pressable>
      <Modal
        transparent
        animationType="fade"
        visible={visible}
        onRequestClose={() => setVisible(false)}
      >
        <Pressable style={styles.modalBackdrop} onPress={() => setVisible(false)}>
          <Surface style={styles.selectorSheet}>
            <ScrollView contentContainerStyle={styles.selectorList}>
              {options.map((option) => (
                <Pressable
                  key={option.value || 'all'}
                  accessibilityRole="radio"
                  accessibilityState={{ checked: option.value === value }}
                  onPress={() => {
                    onChange(option.value);
                    setVisible(false);
                  }}
                  style={styles.selectorOption}
                >
                  {option.asset ? (
                    <GameAssetImage asset={option.asset} style={styles.selectorImage} />
                  ) : leading ? (
                    leading
                  ) : null}
                  <CKText style={styles.selectorText}>{option.label}</CKText>
                  {option.value === value ? <Check size={20} color={theme.primary} /> : null}
                </Pressable>
              ))}
            </ScrollView>
          </Surface>
        </Pressable>
      </Modal>
    </>
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
  const theme = useCKTheme();
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={asset.tileDisplayName}
      accessibilityHint={t('gameAssetsLongPressHint')}
      onPress={onOpen}
      onLongPress={onLongPress}
      style={{ width }}
    >
      <View
        style={[
          styles.tile,
          { backgroundColor: colorWithAlpha(theme.surfaceContainerHighest, 0.34) },
        ]}
      >
        <GameAssetImage asset={asset} style={styles.tileImage} />
        <CKText role="labelLarge" numberOfLines={2} style={styles.tileName}>
          {asset.tileDisplayName}
        </CKText>
      </View>
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
  const [saving, setSaving] = useState(false);
  const scale = useSharedValue(1);
  const savedScale = useSharedValue(1);
  const translateX = useSharedValue(0);
  const translateY = useSharedValue(0);
  const savedX = useSharedValue(0);
  const savedY = useSharedValue(0);
  const pinch = Gesture.Pinch()
    .onUpdate((event) => {
      scale.value = Math.max(0.5, Math.min(5, savedScale.value * event.scale));
    })
    .onEnd(() => {
      savedScale.value = scale.value;
    });
  const pan = Gesture.Pan()
    .onUpdate((event) => {
      translateX.value = savedX.value + event.translationX;
      translateY.value = savedY.value + event.translationY;
    })
    .onEnd(() => {
      savedX.value = translateX.value;
      savedY.value = translateY.value;
    });
  const gesture = Gesture.Simultaneous(pinch, pan);
  const animatedStyle = useAnimatedStyle(() => ({
    transform: [
      { translateX: translateX.value },
      { translateY: translateY.value },
      { scale: scale.value },
    ],
  }));
  if (!asset) return null;
  const copy = async (value: string, confirmation: string) => {
    try {
      await actions.copy(value);
      showMessage(confirmation);
    } catch {
      showMessage(t('gameAssetsCopyError'));
    }
  };
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
  const save = async () => {
    setSaving(true);
    try {
      const path = await actions.save(asset);
      showMessage(path ? t('gameAssetsSavedTo', { path }) : t('gameAssetsSaved'));
    } catch {
      showMessage(t('gameAssetsSaveError'));
    } finally {
      setSaving(false);
    }
  };
  return (
    <Modal visible transparent={false} animationType="slide" onRequestClose={onClose}>
      <SafeAreaView style={[styles.preview, { backgroundColor: theme.background }]}>
        <View style={[styles.previewHeader, { backgroundColor: theme.surface }]}>
          <HeaderIconButton
            label={materialBackLabel(locale)}
            onPress={onClose}
            icon={
              isRtl ? <ArrowRight color={theme.onSurface} /> : <ArrowLeft color={theme.onSurface} />
            }
          />
          <CKText role="titleMedium" numberOfLines={1} style={styles.previewTitle}>
            {asset.displayName}
          </CKText>
        </View>
        <View
          style={[
            styles.previewImagePanel,
            { backgroundColor: colorWithAlpha(theme.surfaceContainerHighest, 0.34) },
          ]}
        >
          <GestureDetector gesture={gesture}>
            <Animated.View style={[styles.previewImage, animatedStyle]}>
              <GameAssetImage asset={asset} style={styles.fill} />
            </Animated.View>
          </GestureDetector>
        </View>
        <View style={styles.previewDetails}>
          <CKText role="bodyMedium" selectable style={styles.previewPath}>
            {asset.path}
          </CKText>
          <CKText role="labelSmall" muted style={styles.previewExtension}>
            {asset.extension.toUpperCase()}
          </CKText>
          <View style={styles.actionWrap}>
            <ActionButton
              label={t('gameAssetsCopyUrl')}
              icon={<Link2 size={18} color={theme.onSurface} />}
              onPress={() => void copy(asset.url, t('gameAssetsUrlCopied'))}
            />
            <ActionButton
              label={t('gameAssetsCopyPath')}
              icon={<ClipboardCopy size={18} color={theme.onSurface} />}
              onPress={() => void copy(asset.path, t('gameAssetsPathCopied'))}
            />
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
            <ActionButton
              label={saving ? t('gameAssetsSaving') : t('gameAssetsSave')}
              icon={
                saving ? (
                  <ActivityIndicator color={theme.onPrimary} />
                ) : (
                  <Download size={18} color={theme.onPrimary} />
                )
              }
              disabled={saving}
              filled
              onPress={() => void save()}
            />
          </View>
        </View>
        {message ? (
          <PillSurface style={[styles.snackbar, { backgroundColor: theme.snackbar }]}>
            <CKText>{message}</CKText>
          </PillSurface>
        ) : null}
      </SafeAreaView>
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

function LoadingSkeleton({ width }: { width: number }) {
  const columns = width >= 600 ? 4 : 3;
  const contentWidth = Math.min(width, 1120) - 32;
  const tileWidth = Math.max(0, (contentWidth - (columns - 1) * 10) / columns);
  return (
    <View style={styles.loadingWrap}>
      <View style={styles.selectorRow}>
        <Skeleton height={36} radius={16} style={styles.selectorGrow} />
        <Skeleton height={36} radius={16} style={styles.selectorGrow} />
      </View>
      <Skeleton height={44} radius={16} />
      <Skeleton width={118} height={12} radius={8} />
      <View style={styles.loadingGrid}>
        {Array.from({ length: columns * 4 }, (_, index) => (
          <Surface key={index} radius={16} style={[styles.loadingTile, { width: tileWidth }]}>
            <Skeleton width={70} height={70} radius={18} />
            <Skeleton height={13} radius={8} />
            <Skeleton width={58} height={11} radius={8} />
          </Surface>
        ))}
      </View>
    </View>
  );
}

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
  return key ? t(key) : formatGameAssetCategory(category);
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
  hero: { width: '100%' },
  heroAdditionalDarken: { backgroundColor: '#00000014' },
  heroSafe: { flex: 1, paddingBottom: 14 },
  heroTopRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  heroIdentity: { width: '100%', alignItems: 'center', justifyContent: 'center' },
  desktopHeroIdentityWidth: { maxWidth: 1120, alignSelf: 'center' },
  compactHeroIdentity: {
    width: '100%',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 12,
  },
  heroImage: { width: 80, height: 80, marginBottom: 4 },
  compactHeroImage: { width: 56, height: 56 },
  compactHeroStats: { marginStart: 8, marginTop: -10 },
  fill: { width: '100%', height: '100%' },
  heroCopy: { flex: 1 },
  heroTitle: { color: '#fff', fontWeight: '800', textAlign: 'center', lineHeight: 25 },
  heroSubtitle: { color: '#FFFFFFB8', fontWeight: '700', textAlign: 'center', marginTop: 2 },
  compactHeroText: { textAlign: 'left' },
  heroStats: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    flexWrap: 'wrap',
    gap: 7,
    marginTop: 10,
  },
  heroStat: {
    maxWidth: 132,
    minHeight: 31,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 999,
  },
  simpleHeader: {
    minHeight: 72,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingHorizontal: 16,
  },
  feedbackWrap: { flex: 1, padding: 16 },
  controlsBound: { alignSelf: 'center', paddingHorizontal: 16, paddingTop: 8, paddingBottom: 7 },
  desktopControls: { flexDirection: 'row', gap: 8 },
  desktopCategory: { flex: 3 },
  desktopFormat: { width: 190 },
  desktopSearch: { flex: 4 },
  compactControls: { gap: 7 },
  selectorRow: { flexDirection: 'row', gap: 8 },
  selectorGrow: { flex: 1 },
  selector: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 7,
    paddingHorizontal: 10,
  },
  selectorImage: { width: 22, height: 22 },
  selectorText: { minWidth: 0, flex: 1 },
  searchField: {
    height: 44,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 12,
  },
  searchInput: { flex: 1, height: 44, paddingVertical: 0, fontFamily: 'ClashKing', fontSize: 14 },
  resultCount: { paddingHorizontal: 2, paddingTop: 7 },
  gridRow: { justifyContent: 'center', gap: 10, marginBottom: 10 },
  tile: { height: 154, padding: 10, borderRadius: 16 },
  tileImage: { flex: 1, width: '100%' },
  tileName: { minHeight: 30, marginTop: 9, fontWeight: '800' },
  emptyResults: { alignSelf: 'center', paddingHorizontal: 18 },
  modalBackdrop: { flex: 1, justifyContent: 'center', padding: 24, backgroundColor: '#00000088' },
  selectorSheet: { maxHeight: '70%' },
  selectorList: { padding: 8 },
  selectorOption: {
    minHeight: 48,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 7,
    paddingHorizontal: 12,
  },
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
  previewDetails: { paddingHorizontal: 16, paddingTop: 14, paddingBottom: 18 },
  previewPath: { fontWeight: '700' },
  previewExtension: { fontWeight: '800', marginTop: 4 },
  actionWrap: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginTop: 12 },
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
  loadingWrap: { width: '100%', maxWidth: 1120, alignSelf: 'center', padding: 16, gap: 10 },
  loadingGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 10 },
  loadingTile: { height: 154, justifyContent: 'space-between', padding: 10 },
});
