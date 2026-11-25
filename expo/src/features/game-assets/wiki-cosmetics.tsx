import { ImageAssets } from '../../core/assets/image-assets';
import { useMemo, useState } from 'react';
import { FlatList, Pressable, View } from 'react-native';
import { useAdaptiveLayout } from '../../ui/adaptive-layout';
import { SafeAreaView } from 'react-native-safe-area-context';
import { ChevronRight, SlidersHorizontal, Search } from '@/ui/icons';
import { CKText, MobileWebImage, SearchField, HeaderIconButton, useCKTheme } from '../../ui';
import { MorphFilterSheet } from '../../ui/morph-filter-sheet';
import { useI18n } from '../../i18n';
import { useWikiNavigation } from './wiki-navigation';
import { WikiEntryLink } from './wiki-entry-link';
import { WikiHeader } from './wiki-layout';
import type { WikiEntry } from './wiki-catalogue';

type Filters = { village: string; sort: string };
const defaults: Filters = { village: '', sort: 'newest' };
export function WikiCosmetics({
  entries,
  section,
  title,
  onBack,
}: {
  entries: readonly WikiEntry[];
  section: string;
  title: string;
  onBack: () => void;
}) {
  const wiki = useWikiNavigation();
  const { t } = useI18n(),
    theme = useCKTheme();
  const layout = useAdaptiveLayout();
  const [contentWidth, setContentWidth] = useState(layout.usableWidth);
  const [query, setQuery] = useState(''),
    [filters, setFilters] = useState(defaults),
    [draft, setDraft] = useState(defaults),
    [filtering, setFiltering] = useState(false);
  const shown = useMemo(
    () =>
      entries
        .filter(
          (entry) =>
            (!query || entry.name.toLocaleLowerCase().includes(query.toLocaleLowerCase())) &&
            (!filters.village || String(entry.meta.type ?? entry.meta.village) === filters.village),
        )
        .sort((a, b) =>
          filters.sort === 'name'
            ? a.name.localeCompare(b.name)
            : (filters.sort === 'oldest' ? 1 : -1) * (Number(a.meta._id) - Number(b.meta._id)),
        ),
    [entries, query, filters],
  );
  // A fold or system rail can make the content pane narrower than the window.
  // Base the grid on its measured space, including after live format changes.
  const columns = contentWidth < 340 ? 2 : 3;
  const filterRow = (label: string, value: string, onPress: () => void) => (
    <Pressable
      accessibilityRole="button"
      onPress={onPress}
      style={{ flexDirection: 'row', minHeight: 56, alignItems: 'center', gap: 10 }}
    >
      <CKText style={{ flex: 1 }}>{label}</CKText>
      <CKText muted>{value || t('generalAll')}</CKText>
      <ChevronRight size={20} color={theme.onSurfaceVariant} />
    </Pressable>
  );
  const picture = (entry: WikiEntry, height: number) => (
    <WikiEntryLink
      entryKey={entry.key}
      label={entry.name}
      onFallback={() => wiki?.openEntry(entry.key)}
      style={{ flex: 1, backgroundColor: theme.card, borderRadius: 16, overflow: 'hidden' }}
    >
      <MobileWebImage
        imageUrl={entry.image}
        fallbackImageUrls={typeof entry.meta.icon === 'string' ? [entry.meta.icon] : []}
        contentFit="contain"
        cachePolicy="memory-disk"
        style={{ width: '100%', height }}
      />
      <View style={{ padding: 12, gap: 5, flex: 1 }}>
        <CKText role="bodySmall" numberOfLines={2}>
          {entry.name}
        </CKText>
      </View>
    </WikiEntryLink>
  );
  return (
    <SafeAreaView
      style={{ flex: 1, backgroundColor: theme.background }}
      onLayout={({ nativeEvent: { layout } }) => setContentWidth(layout.width)}
    >
      <FlatList
        key={columns}
        numColumns={columns}
        data={shown}
        keyExtractor={(entry) => entry.key}
        keyboardShouldPersistTaps="handled"
        contentContainerStyle={{ paddingHorizontal: 18, paddingBottom: 36, gap: 12 }}
        columnWrapperStyle={{ gap: 10, alignItems: 'stretch' }}
        ListHeaderComponent={
          <View style={{ marginHorizontal: -18 }}>
            <WikiHeader
              title={title}
              image={
                section === 'sceneries'
                  ? `${ImageAssets.baseUrl}/sceneries/pixel_scenery/icon.webp`
                  : entries[0]?.image
              }
              compact
              onBack={onBack}
              shareParams={{ category: section }}
            />
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8, padding: 18 }}>
              <SearchField
                value={query}
                onChangeText={setQuery}
                placeholder={t('calcSearch')}
                searchIcon={<Search size={20} />}
                style={{ flex: 1 }}
              />
              <HeaderIconButton
                label={t('searchFilters')}
                icon={<SlidersHorizontal color={theme.onSurface} />}
                onPress={() => {
                  setDraft(filters);
                  setFiltering(true);
                }}
              />
            </View>
          </View>
        }
        renderItem={({ item }) => (
          <View style={{ flex: 1, maxWidth: `${100 / columns}%`, alignSelf: 'stretch' }}>
            {picture(item, 96)}
          </View>
        )}
        ListEmptyComponent={<CKText muted>{t('searchNoResult')}</CKText>}
      />
      {filtering ? (
        <MorphFilterSheet
          title={t('searchFilters')}
          applyLabel={t('calcSearch')}
          onClose={() => setFiltering(false)}
          onReset={() => setDraft(defaults)}
          onApply={() => setFilters(draft)}
        >
          {(open) => (
            <>
              {section !== 'skins'
                ? filterRow(
                    t('dashboardUpgradeTrackerVillage'),
                    draft.village === 'home'
                      ? t('upgradeTrackerHomeVillage')
                      : draft.village === 'builderBase' || draft.village === 'builder'
                        ? t('gameBaseBuilder')
                        : draft.village === 'war'
                          ? t('warTitle')
                          : '',
                    () =>
                      open({
                        title: t('dashboardUpgradeTrackerVillage'),
                        value: draft.village,
                        options: [
                          { value: '', label: t('generalAll') },
                          ...[
                            ...new Set(
                              entries
                                .map((e) => String(e.meta.type ?? e.meta.village ?? ''))
                                .filter(Boolean),
                            ),
                          ].map((value) => ({
                            value,
                            label:
                              value === 'home'
                                ? t('upgradeTrackerHomeVillage')
                                : value === 'war'
                                  ? t('warTitle')
                                  : t('gameBaseBuilder'),
                          })),
                        ],
                        onChange: (village) => setDraft((d) => ({ ...d, village })),
                      }),
                  )
                : null}
              {filterRow(
                t('wikiSort'),
                t(
                  draft.sort === 'name'
                    ? 'wikiNameOrder'
                    : draft.sort === 'oldest'
                      ? 'wikiOldest'
                      : 'wikiNewest',
                ),
                () =>
                  open({
                    title: t('wikiSort'),
                    value: draft.sort,
                    options: [
                      { value: 'newest', label: t('wikiNewest') },
                      { value: 'oldest', label: t('wikiOldest') },
                      { value: 'name', label: t('wikiNameOrder') },
                    ],
                    onChange: (sort) => setDraft((d) => ({ ...d, sort })),
                  }),
              )}
            </>
          )}
        </MorphFilterSheet>
      ) : null}
    </SafeAreaView>
  );
}
