import { useAdaptiveLayout } from '../../../ui/adaptive-layout';
import { InlineBackControl } from '../../../ui/native-back-context';
import { ChevronLeft, ChevronRight, Check, CloudOff, FileText, Play } from '@/ui/icons';
import { memo, useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  ActivityIndicator,
  FlatList,
  Image,
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  View,
  useWindowDimensions,
} from 'react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';

import { materialBackLabel, toIntlLocale, useI18n } from '../../../i18n';
import {
  CKText,
  EmptyState,
  MobileWebImage,
  PressableSurface,
  ResponsiveGrid,
  SkeletonContent,
  Skeleton,
  centeredContentPadding,
  ckRadius,
  ckSpacing,
  useCKTheme,
} from '../../../ui';
import { AppAnnouncement, type AnnouncementService } from '../data';
import type { AnnouncementPresentationService } from '../data/announcement-presentation-service';
import { OfficialBlogService } from '../data/official-blog-service';
import { HeroHeaderScrim } from '../../../ui/hero-header-scrim';
import { colorWithAlpha } from '../../../ui/tokens';
import { PostDateLabel } from './announcement-article-screen';
import { useAnnouncementPresentation } from './announcement-presenter';

export interface PostsScreenProps {
  readonly service: AnnouncementService;
  readonly readHistory: AnnouncementPresentationService;
  readonly onBack?: () => void;
  readonly initialPostId?: string;
}

export function PostsScreen({ service, readHistory, onBack, initialPostId }: PostsScreenProps) {
  const { t, isRtl, locale } = useI18n();
  const theme = useCKTheme();
  const { width: windowWidth } = useWindowDimensions();
  const layout = useAdaptiveLayout();
  const insets = useSafeAreaInsets();
  const [contentWidth, setContentWidth] = useState(windowWidth);
  const [readKeys, setReadKeys] = useState<ReadonlySet<string>>(new Set());
  useEffect(() => {
    let active = true;
    const refreshReadKeys = () => {
      void readHistory.getReadKeys().then((keys) => {
        if (active) setReadKeys((current) => new Set([...keys, ...current]));
      });
    };
    refreshReadKeys();
    const unsubscribe = readHistory.subscribe(refreshReadKeys);
    return () => {
      active = false;
      unsubscribe();
    };
  }, [readHistory]);
  const markRead = useCallback(
    (post: AppAnnouncement) => {
      setReadKeys((current) => new Set([...current, post.presentationKey]));
      // Reading and navigation still work if device preferences cannot be saved.
      void readHistory.markRead(post).catch(() => {});
    },
    [readHistory],
  );
  const [stories, setStories] = useState<readonly AppAnnouncement[]>([]);
  const [storiesLoading, setStoriesLoading] = useState(false);
  const [openingStory, setOpeningStory] = useState<string>();
  const openingStoryRef = useRef(false);
  const [storyError, setStoryError] = useState(false);
  const [posts, setPosts] = useState<readonly AppAnnouncement[]>([]);
  const [loading, setLoading] = useState(false);
  const [hasMore, setHasMore] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const displayedIds = useRef(new Set<string>());
  const pendingOwn = useRef<AppAnnouncement[]>([]);
  const pendingOfficial = useRef<AppAnnouncement[]>([]);
  const feedStarted = useRef(false);
  const nextOffset = useRef(0);
  const [error, setError] = useState<unknown>();
  const loadingRef = useRef(false);
  const scrollMetrics = useRef({ height: 0, viewport: 0, offset: 0 });
  const generation = useRef(0);
  const officialBlog = useRef(new OfficialBlogService()).current;
  const officialPage = useRef(1);
  const officialHasMore = useRef(true);
  const ownHasMore = useRef(true);
  const articleRequest = useRef(0);
  const openingArticleRef = useRef(false);
  const dark = theme.background === '#030304';
  const feedBackground = dark ? '#000000' : '#E8E8EA';
  useEffect(
    () => () => {
      articleRequest.current += 1;
    },
    [],
  );
  const { openAnnouncement, presentation } = useAnnouncementPresentation();
  const isGrid = contentWidth - 2 * ckSpacing.lg >= 340;
  // Measure the list after safe-area/rail insets; never subtract those
  // insets a second time or the right edge drifts inward on wider devices.
  const horizontalPadding = centeredContentPadding(
    contentWidth,
    layout.isExpanded ? layout.contentMaxWidth : layout.isDuo ? layout.contentMaxWidth : 1200,
    ckSpacing.lg,
  );
  const localeTag = toIntlLocale(locale);

  const load = useCallback(
    async (reset = false) => {
      if (loadingRef.current && !reset) return;
      const requestGeneration = reset ? ++generation.current : generation.current;
      loadingRef.current = true;
      setLoading(true);
      setError(undefined);
      const current = () => requestGeneration === generation.current;
      if (reset) {
        articleRequest.current += 1;
        openingArticleRef.current = false;
        setRefreshing(true);
        displayedIds.current = new Set();
        feedStarted.current = false;
        pendingOwn.current = [];
        pendingOfficial.current = [];
        setStoriesLoading(true);
        setStoryError(false);
        void service
          .getPublishedPosts(5, 0, 'story')
          .then((page) => {
            if (current()) setStories(page.items.filter((item) => item.isStory));
          })
          .catch(() => {
            if (current()) setStoryError(true);
          })
          .finally(() => {
            if (current()) setStoriesLoading(false);
          });
        officialPage.current = 1;
        officialHasMore.current = true;
        ownHasMore.current = true;
        nextOffset.current = 0;
        setHasMore(true);
      }
      const newestFirst = (a: AppAnnouncement, b: AppAnnouncement) =>
        (b.publishedAt?.getTime() ?? 0) - (a.publishedAt?.getTime() ?? 0) ||
        a.id.localeCompare(b.id);
      const next: AppAnnouncement[] = [];
      let ownError: unknown;
      // Each source is newest-first. Keep its unused tail until its next page
      // is needed: publishing all of a fast source first puts old posts above
      // newer Supercell articles. Nothing is persisted or synced here.
      while (current() && next.length < 20) {
        await Promise.all([
          !pendingOwn.current.length && ownHasMore.current
            ? service
                .getPublishedPosts(20, nextOffset.current, 'article')
                .then((page) => {
                  if (!current()) return;
                  nextOffset.current = page.nextOffset;
                  pendingOwn.current = page.items.filter((item) => !item.isStory).sort(newestFirst);
                  ownHasMore.current = page.hasMore && pendingOwn.current.length > 0;
                })
                .catch((reason: unknown) => {
                  if (!current()) return;
                  ownError = reason;
                  ownHasMore.current = false;
                })
            : Promise.resolve(),
          !pendingOfficial.current.length && officialHasMore.current
            ? officialBlog
                .getPage(officialPage.current, locale)
                .then((page) => {
                  if (!current()) return;
                  officialPage.current += 1;
                  pendingOfficial.current = [...page.items].sort(newestFirst);
                  officialHasMore.current = page.hasMore && pendingOfficial.current.length > 0;
                })
                .catch(() => {
                  // A failed source does not block the other one. Retry it on refresh.
                  if (current()) officialHasMore.current = false;
                })
            : Promise.resolve(),
        ]);
        if (!current()) return;
        // Stop as soon as a live source needs another page. Its unseen head
        // must be known before choosing the next chronological item.
        while (next.length < 20) {
          if (
            (!pendingOwn.current.length && ownHasMore.current) ||
            (!pendingOfficial.current.length && officialHasMore.current)
          )
            break;
          const own = pendingOwn.current[0];
          const official = pendingOfficial.current[0];
          if (!own && !official) break;
          const queue =
            own && (!official || newestFirst(own, official) <= 0)
              ? pendingOwn.current
              : pendingOfficial.current;
          const item = queue.shift()!;
          if (!displayedIds.current.has(item.id)) {
            displayedIds.current.add(item.id);
            next.push(item);
          }
        }
        // Publish the safe prefix now; scrolling will fetch the next source
        // head. Do not wait for extra pages merely to fill a 20-card batch.
        if (next.length > 0) break;
        if (
          !pendingOwn.current.length &&
          !ownHasMore.current &&
          !pendingOfficial.current.length &&
          !officialHasMore.current
        )
          break;
      }
      if (current()) {
        // Commit one merged batch; a refresh keeps the old feed in place
        // until the replacement is ready, instead of inserting one source early.
        const append = feedStarted.current;
        if (next.length || !append) {
          setPosts((previous) => (append ? [...previous, ...next] : next));
          feedStarted.current = true;
        }
        setError(ownError);
        setHasMore(
          ownHasMore.current ||
            officialHasMore.current ||
            pendingOwn.current.length > 0 ||
            pendingOfficial.current.length > 0,
        );
        setLoading(false);
        setRefreshing(false);
        loadingRef.current = false;
      }
    },
    [locale, service, officialBlog],
  );

  useEffect(() => {
    const timer = setTimeout(() => void load(true), 0);
    return () => {
      clearTimeout(timer);
      generation.current += 1;
      articleRequest.current += 1;
    };
  }, [load]);

  useEffect(() => {
    if (!initialPostId) return;
    let active = true;
    void service.getAnnouncement(initialPostId).then((post) => {
      if (active && post)
        void openAnnouncement(post, () => active).then((opened) => {
          if (opened && active) markRead(post);
        });
      else if (active) setStoryError(true);
    });
    return () => {
      active = false;
    };
  }, [initialPostId, markRead, openAnnouncement, service]);

  const replayStory = async (id: string) => {
    if (openingStoryRef.current) return;
    openingStoryRef.current = true;
    setOpeningStory(id);
    setStoryError(false);
    try {
      // Revalidate public availability before replaying cached HTML.
      const current = await service.getAnnouncement(id);
      if (current && (await openAnnouncement(current))) {
        markRead(current);
      } else {
        setStoryError(true);
        // The service also returns null for transport failures. Keep the cached row
        // so a temporary outage does not erase a story the user can retry.
      }
    } catch {
      setStoryError(true);
    } finally {
      openingStoryRef.current = false;
      setOpeningStory(undefined);
    }
  };

  const openPost = useCallback(
    async (post: AppAnnouncement) => {
      if (openingArticleRef.current) return;
      openingArticleRef.current = true;
      const request = ++articleRequest.current;
      setStoryError(false);
      try {
        const article = post.id.startsWith('supercell:')
          ? await officialBlog.getArticle(post)
          : post;
        if (request === articleRequest.current) {
          const opened = await openAnnouncement(article, () => request === articleRequest.current);
          if (opened && request === articleRequest.current) markRead(post);
        }
      } catch {
        if (request === articleRequest.current && !post.id.startsWith('supercell:'))
          setStoryError(true);
      } finally {
        if (request === articleRequest.current) {
          openingArticleRef.current = false;
        }
      }
    },
    [markRead, officialBlog, openAnnouncement],
  );

  const loadNearEnd = useCallback(() => {
    const { height, viewport, offset } = scrollMetrics.current;
    // A short first page may not produce a scroll event; keep filling the
    // single combined feed until its content extends beyond the viewport.
    if (
      !loadingRef.current &&
      !error &&
      hasMore &&
      viewport > 0 &&
      height - viewport - offset < viewport * 1.5
    )
      void load();
  }, [error, hasMore, load]);

  useEffect(() => {
    if (loading) return;
    const timer = setTimeout(loadNearEnd, 0);
    return () => clearTimeout(timer);
  }, [loading, loadNearEnd]);

  const columnCount = Math.max(
    1,
    Math.min(
      layout.isExpanded ? 3 : 2,
      Math.floor((contentWidth - horizontalPadding * 2 + 14) / 174),
    ),
  );
  const rows = useMemo(() => {
    const result: { key: string; items: readonly AppAnnouncement[]; featured: boolean }[] = [];
    if (posts[0]) result.push({ key: posts[0].id, items: [posts[0]], featured: true });
    for (let i = 1; i < posts.length; i += columnCount) {
      result.push({ key: posts[i]!.id, items: posts.slice(i, i + columnCount), featured: false });
    }
    return result;
  }, [posts, columnCount]);
  const handleOpenPost = openPost;
  const renderRow = useCallback(
    ({ item }: { item: (typeof rows)[number] }) => (
      <View style={[styles.feedRow, isRtl && styles.rowRtl]}>
        {item.items.map((post) => (
          <View key={post.id} style={styles.feedCell}>
            <PostArchiveCard
              post={post}
              featured={item.featured}
              read={readKeys.has(post.presentationKey)}
              intlLocale={localeTag}
              onOpen={handleOpenPost}
            />
          </View>
        ))}
        {!item.featured &&
          Array.from({ length: columnCount - item.items.length }, (_, i) => (
            <View key={`empty-${i}`} style={styles.feedCell} />
          ))}
      </View>
    ),
    [columnCount, handleOpenPost, isRtl, localeTag, readKeys],
  );

  return (
    <View style={[styles.safe, { backgroundColor: feedBackground }]}>
      {/* Paint outside the safe area; only interactive content is inset. */}
      <PostsBackdrop background={feedBackground} dark={dark} />
      <SafeAreaView edges={['top', 'left', 'right']} style={styles.safe}>
        <View style={styles.feed}>
          <FlatList
            data={rows}
            keyExtractor={(row) => row.key}
            renderItem={renderRow}
            extraData={readKeys}
            initialNumToRender={5}
            maxToRenderPerBatch={4}
            windowSize={7}
            updateCellsBatchingPeriod={50}
            removeClippedSubviews={false}
            onEndReached={loadNearEnd}
            onEndReachedThreshold={1.5}
            onLayout={({ nativeEvent }) => {
              setContentWidth(nativeEvent.layout.width);
              scrollMetrics.current.viewport = nativeEvent.layout.height;
              loadNearEnd();
            }}
            onContentSizeChange={(_width, height) => {
              scrollMetrics.current.height = height;
              loadNearEnd();
            }}
            onScroll={({ nativeEvent }) => {
              scrollMetrics.current.offset = Math.max(0, nativeEvent.contentOffset.y);
            }}
            scrollEventThrottle={100}
            contentInsetAdjustmentBehavior="never"
            style={styles.feed}
            contentContainerStyle={[
              styles.content,
              { paddingHorizontal: horizontalPadding, paddingBottom: insets.bottom + 2 },
            ]}
            refreshControl={
              <RefreshControl
                refreshing={refreshing && posts.length > 0}
                onRefresh={() => void load(true)}
              />
            }
            ListHeaderComponent={
              <View>
                <View
                  style={[
                    styles.feedHeader,
                    {
                      marginHorizontal: -horizontalPadding,
                      marginTop: -4,
                      paddingTop: 4,
                      paddingHorizontal: horizontalPadding,
                    },
                  ]}
                >
                  {/* Equal side slots center the title independently of Back, including
            when the native rail owns navigation. Stories scroll with the feed. */}
                  <View style={[styles.header, isRtl && styles.rowRtl]}>
                    <View style={styles.headerSide}>
                      {onBack ? (
                        <InlineBackControl onBack={onBack}>
                          <Pressable
                            accessibilityLabel={materialBackLabel(locale)}
                            accessibilityRole="button"
                            hitSlop={8}
                            onPress={onBack}
                            style={({ pressed }) => [styles.back, pressed && styles.pressed]}
                          >
                            {isRtl ? (
                              <ChevronRight color={theme.onSurfaceVariant} size={21} />
                            ) : (
                              <ChevronLeft color={theme.onSurfaceVariant} size={21} />
                            )}
                          </Pressable>
                        </InlineBackControl>
                      ) : null}
                    </View>
                    <CKText
                      role="titleMedium"
                      accessibilityRole="header"
                      style={styles.headerTitle}
                    >
                      {t('postsArticlesTitle')}
                    </CKText>
                    <View style={styles.headerSide} />
                  </View>
                  {storiesLoading && stories.length === 0 ? (
                    <View
                      style={styles.storySkeletons}
                      accessibilityLabel={t('generalLoading')}
                      accessibilityRole="progressbar"
                    >
                      {[0, 1, 2].map((key) => (
                        <Skeleton key={key} height={62} width={62} radius={31} />
                      ))}
                    </View>
                  ) : null}
                  {stories.length > 0 ? (
                    <ScrollView
                      horizontal
                      contentInsetAdjustmentBehavior="never"
                      style={[styles.stories, { marginHorizontal: -horizontalPadding }]}
                      showsHorizontalScrollIndicator={false}
                      contentContainerStyle={[
                        styles.storyRow,
                        { paddingHorizontal: horizontalPadding },
                        isRtl && styles.rowRtl,
                      ]}
                    >
                      {stories.map((story) => (
                        <Pressable
                          key={story.id}
                          accessibilityRole="button"
                          accessibilityLabel={story.title}
                          accessibilityState={{
                            disabled: !!openingStory,
                            busy: openingStory === story.id,
                          }}
                          disabled={!!openingStory}
                          onPress={() => void replayStory(story.id)}
                          style={({ pressed }) => [styles.storyCircle, pressed && styles.pressed]}
                        >
                          <View
                            style={[
                              styles.storyImage,
                              {
                                // Read stories retain their layout and title but lose the bright ring.
                                borderColor: readKeys.has(story.presentationKey)
                                  ? 'transparent'
                                  : theme.primary,
                                backgroundColor: theme.surfaceContainerHighest,
                              },
                            ]}
                          >
                            {story.bannerImageUrl ? (
                              <MobileWebImage
                                imageUrl={story.bannerImageUrl}
                                contentFit="cover"
                                style={styles.storyArtwork}
                              />
                            ) : (
                              <Play size={24} color={theme.onSurface} />
                            )}
                          </View>
                          <CKText role="labelSmall" style={styles.storyTitle}>
                            {story.title}
                          </CKText>
                        </Pressable>
                      ))}
                    </ScrollView>
                  ) : null}
                </View>
              </View>
            }
            ListEmptyComponent={
              loading ? (
                <PostsLoadingSkeleton isGrid={isGrid} />
              ) : (
                <EmptyState
                  icon={<FileText color={theme.onSurfaceVariant} size={28} />}
                  title={error ? t('postsLoadFailed') : t('postsEmpty')}
                  actionLabel={error ? t('generalRetry') : undefined}
                  onAction={error ? () => void load(true) : undefined}
                />
              )
            }
            ListFooterComponent={
              hasMore || error || storyError ? (
                <View style={styles.feedFooter}>
                  {error ? (
                    <EmptyState
                      actionLabel={t('generalRetry')}
                      icon={<CloudOff color={theme.onSurfaceVariant} size={28} />}
                      onAction={() => void load()}
                      title={t('postsLoadFailed')}
                    />
                  ) : (
                    <ActivityIndicator
                      animating={loading}
                      hidesWhenStopped
                      color={theme.primary}
                      accessibilityLabel={t('generalLoading')}
                    />
                  )}
                  {storyError ? (
                    <CKText muted role="bodySmall">
                      {t('postsLoadFailed')}
                    </CKText>
                  ) : undefined}
                </View>
              ) : undefined
            }
          />
        </View>
      </SafeAreaView>
      {presentation}
    </View>
  );
}

// Static, non-interactive atmosphere: no animation or large blur layers while scrolling.
const PostsBackdrop = memo(function PostsBackdrop({
  background,
  dark,
}: {
  background: string;
  dark: boolean;
}) {
  const { width, height } = useWindowDimensions();
  const tileSize = 87;
  const columns = Math.ceil(width / tileSize);
  const tileCount = columns * Math.ceil(height / tileSize);
  return (
    <View
      pointerEvents="none"
      accessible={false}
      style={[StyleSheet.absoluteFill, { overflow: 'hidden', backgroundColor: background }]}
    >
      {/* The source motif has faint baked-in alpha. Composite three static
          copies in dark mode to strengthen the shields without lightening the
          transparent areas or introducing an offscreen SVG mask. Each image
          needs explicit dimensions: React Native otherwise uses the bundled
          image's intrinsic size even inside an absolute-fill wrapper. */}
      <View style={[StyleSheet.absoluteFill, { opacity: 0.85 }]}>
        {Array.from({ length: tileCount }, (_, index) => (
          <View
            key={index}
            style={{
              position: 'absolute',
              width: tileSize,
              height: tileSize,
              left: (index % columns) * tileSize,
              top: Math.floor(index / columns) * tileSize,
            }}
          >
            {Array.from({ length: dark ? 3 : 1 }, (_, layer) => (
              <Image
                key={layer}
                source={require('../../../../assets/clashking/backgrounds/posts-pattern.webp')}
                resizeMode="stretch"
                style={[
                  StyleSheet.absoluteFill,
                  {
                    width: tileSize,
                    height: tileSize,
                    tintColor: dark ? '#FFFFFF' : '#8B8B91',
                    opacity: dark ? 1 : 0.55,
                  },
                ]}
              />
            ))}
          </View>
        ))}
      </View>
    </View>
  );
});

const PostArchiveCard = memo(function PostArchiveCard({
  post,
  intlLocale,
  onOpen,
  featured = false,
  read = false,
}: {
  post: AppAnnouncement;
  intlLocale: string;
  onOpen: (post: AppAnnouncement) => void;
  featured?: boolean;
  read?: boolean;
}) {
  const { t, isRtl } = useI18n();
  const theme = useCKTheme();
  const official = post.id.startsWith('supercell:');
  const cardBackground = theme.surface;
  const dateLabel = post.publishedAt
    ? new Intl.DateTimeFormat(intlLocale, { dateStyle: 'medium' }).format(post.publishedAt)
    : null;
  const sourceLabel = official ? 'Clash of Clans' : 'ClashKing';
  if (featured && post.bannerImageUrl)
    return (
      <PressableSurface
        accessibilityLabel={read ? `${post.title}, ${t('postsRead')}` : post.title}
        accessibilityRole="button"
        onPress={() => onOpen(post)}
        radius={ckRadius.card}
        style={styles.featured}
      >
        <View style={StyleSheet.absoluteFill}>
          <MobileWebImage
            imageUrl={post.bannerImageUrl}
            contentFit="cover"
            style={StyleSheet.absoluteFill}
          />
          <HeroHeaderScrim edgeColor="#0B0B0C" strength={0.8} />
        </View>
        <View style={styles.featuredCopy}>
          <View style={[styles.cardMetadata, isRtl && styles.rowRtl]}>
            <CKText role="metadata" style={[styles.heroMetadata, { flex: 1 }]}>
              {sourceLabel}
              {dateLabel ? ` · ${dateLabel}` : ''}
            </CKText>
            {read ? <Check size={16} color="#E5E5EA" /> : null}
          </View>
          <CKText role="screenTitle" style={[styles.heroTitle, read && { color: '#C5C6D0' }]}>
            {post.title}
          </CKText>
        </View>
      </PressableSurface>
    );
  return (
    <PressableSurface
      accessibilityLabel={read ? `${post.title}, ${t('postsRead')}` : post.title}
      accessibilityRole="button"
      onPress={() => onOpen(post)}
      radius={ckRadius.tile}
      style={[
        styles.card,
        {
          backgroundColor: cardBackground,
          borderColor: colorWithAlpha(theme.outlineVariant, 0.16),
        },
      ]}
    >
      {post.bannerImageUrl ? (
        <MobileWebImage
          contentFit="cover"
          imageUrl={post.bannerImageUrl}
          style={[styles.cardImage, { backgroundColor: theme.surfaceContainerHighest }]}
          testID="post-archive-image"
          transition={0}
        />
      ) : (
        <View
          style={[
            styles.cardImage,
            styles.coverPlaceholder,
            { backgroundColor: theme.surfaceContainerHighest },
          ]}
        >
          <FileText size={32} color={theme.onSurfaceVariant} />
        </View>
      )}
      <View style={styles.cardCopy}>
        <View style={[styles.cardMetadata, isRtl && styles.rowRtl]}>
          <CKText
            role="metadata"
            style={{
              color: read ? theme.onSurfaceVariant : official ? theme.secondary : theme.primary,
            }}
          >
            {sourceLabel}
          </CKText>
          {read ? (
            <Check size={16} color={theme.onSurfaceVariant} accessibilityLabel={t('postsRead')} />
          ) : null}
        </View>
        <CKText
          role="rowTitle"
          numberOfLines={4}
          style={[
            styles.cardTitle,
            { color: read ? theme.onSurfaceVariant : theme.onSurface },
            isRtl && styles.rtlText,
          ]}
        >
          {post.title}
        </CKText>
        {post.pinnedOnHome ? <PostDotLabel color={theme.primary} label={t('postsPinned')} /> : null}
        <View style={styles.cardFooter}>
          {dateLabel ? <PostDateLabel label={dateLabel} /> : null}
        </View>
      </View>
    </PressableSurface>
  );
});

function PostDotLabel({ color, label }: { color: string; label: string }) {
  const { isRtl } = useI18n();
  return (
    <View style={[styles.dotLabel, isRtl && styles.rowRtl]}>
      <View style={[styles.dot, { backgroundColor: color }]} />
      <CKText muted role="labelSmall" style={styles.dotText}>
        {label}
      </CKText>
    </View>
  );
}

function PostsLoadingSkeleton({ isGrid }: { isGrid: boolean }) {
  const layout = useAdaptiveLayout();
  const cards = [true, false, true, false];
  return isGrid ? (
    <ResponsiveGrid
      gap={16}
      maxColumns={layout.isExpanded ? layout.columns(340, 3) : 2}
      minItemWidth={layout.isExpanded ? 340 : 360}
    >
      {cards.map((showImage, index) => (
        <PostSkeletonCard key={index} showImage={showImage} />
      ))}
    </ResponsiveGrid>
  ) : (
    <View style={styles.list}>
      {cards.slice(0, 3).map((_, index) => (
        <PostSkeletonCard key={index} showImage={index === 0} />
      ))}
    </View>
  );
}

function PostSkeletonCard({ showImage }: { showImage: boolean }) {
  const { t, locale } = useI18n();
  const placeholder = new AppAnnouncement(
    'pending',
    t('generalLoading'),
    t('generalLoading'),
    null,
    null,
    showImage ? 'pending' : null,
    null,
    null,
    null,
    'article',
    'pending',
    new Date(0),
  );
  return (
    <SkeletonContent>
      <PostArchiveCard post={placeholder} intlLocale={toIntlLocale(locale)} onOpen={() => {}} />
    </SkeletonContent>
  );
}

const styles = StyleSheet.create({
  // The story strip owns its natural content height inside the feed. Flex
  // here can allocate the viewport height and leave a large empty gap.
  stories: { flexGrow: 0, marginTop: 16 },
  storyRow: { flexDirection: 'row', gap: 12, paddingBottom: 4, paddingEnd: 4 },
  storySkeletons: {
    flexDirection: 'row',
    gap: 32,
    height: 94,
    paddingTop: 16,
    overflow: 'hidden',
  },
  feed: { flex: 1, alignSelf: 'stretch' },
  feedHeader: { paddingBottom: 16 },
  feedRow: { flexDirection: 'row', gap: 14, marginBottom: 14, alignItems: 'stretch' },
  feedCell: { flex: 1, minWidth: 0 },
  feedFooter: { minHeight: 64, justifyContent: 'center', alignItems: 'center' },
  storyCircle: { width: 100, alignItems: 'center', gap: 7 },
  storyImage: {
    width: 62,
    height: 62,
    borderRadius: 31,
    borderWidth: 2,
    padding: 3,
    alignItems: 'center',
    justifyContent: 'center',
  },
  storyArtwork: { width: 52, height: 52, borderRadius: 26 },
  storyTitle: { width: '100%', textAlign: 'center', fontSize: 11, lineHeight: 14, minHeight: 28 },
  safe: { flex: 1 },
  header: {
    minHeight: 44,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  back: {
    width: 32,
    height: 44,
    alignItems: 'center',
    justifyContent: 'center',
  },
  content: { paddingTop: 4 },
  headerSide: { width: 32 },
  headerTitle: { flex: 1, textAlign: 'center' },
  archive: { gap: ckSpacing.lg, paddingTop: ckSpacing.lg },
  featured: { minHeight: 300, justifyContent: 'flex-end', borderWidth: 0 },
  featuredCopy: { padding: 24, paddingTop: 120, gap: 12 },
  heroMetadata: { color: '#E5E5EA' },
  heroTitle: { color: '#FFFFFF', fontSize: 28, lineHeight: 33 },
  list: { gap: 14 },
  card: { width: '100%', flex: 1 },
  cardImage: { width: '100%', aspectRatio: 16 / 9 },
  coverPlaceholder: { alignItems: 'center', justifyContent: 'center' },
  cardCopy: { flex: 1, minWidth: 0, gap: 10, padding: 14 },
  // Equal-height row cards keep dates aligned independently of title length.
  cardFooter: { marginTop: 'auto', paddingTop: 4, minHeight: 20 },
  cardMetadata: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 8,
  },
  cardTitleRow: { flexDirection: 'row', alignItems: 'flex-start', gap: 12 },
  cardTitle: { fontWeight: '700', lineHeight: 20 },
  cardSubtitle: { lineHeight: 19 },
  labels: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginTop: 4 },
  rowRtl: { flexDirection: 'row-reverse' },
  rtlText: { textAlign: 'right' },
  dotLabel: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  dot: { width: 7, height: 7, borderRadius: 4 },
  dotText: { fontWeight: '700' },
  paginationProgress: { alignItems: 'center', paddingVertical: ckSpacing.lg },
  pressed: { opacity: 0.82 },
  disabled: { opacity: 0.5 },
  skeletonCard: { overflow: 'hidden', borderRadius: ckRadius.chip },
  skeletonCopy: { padding: 14, gap: 12 },
  skeletonTitle: { flex: 1, gap: 8 },
});
