import { DraggableArtworkBubble } from '../../../ui/draggable-artwork-bubble';
import { useCKAccessibility } from '../../../ui/accessibility';
import { useAdaptiveLayout } from '../../../ui/adaptive-layout';
import { useEffect, useMemo, useRef, useState } from 'react';
import {
  BackHandler,
  Platform,
  Pressable,
  StyleSheet,
  View,
  useWindowDimensions,
} from 'react-native';
import { ChevronLeft, LogOut, Search, ArrowRight, Shield, Trash2 } from 'lucide-react-native';
import DraggableFlatList, {
  ScaleDecorator,
  type DragEndParams,
  type RenderItemParams,
} from 'react-native-draggable-flatlist';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';

import { ImageAssets } from '../../../core/assets/image-assets';
import { canonicalTag } from '../../../core/domain/tags';
import { materialBackLabel, useI18n } from '../../../i18n';
import {
  CKText,
  EmptyState,
  LoadingIndicator,
  MobileWebImage,
  PillSurface,
  Snackbar,
  Surface,
  ckRadius,
  colorWithAlpha,
  statColors,
  useCKTheme,
} from '../../../ui';
import { InlineError, PrimaryAction } from '../../auth/presentation';
import { ApiResponseError } from '@clashking/api-client';
import { SearchField } from '../../../ui/search-sort';
import { AccountVerificationDialog } from './account-verification-dialog';
import {
  accountPresentationItem,
  linkedAccountTags,
  type LinkedAccountItem,
  type LinkedAccountPresentationService,
} from './contracts';

type PlayerProfileIdentity = {
  readonly tag: string;
  readonly name: string;
  readonly townHallLevel: number;
  readonly clanOverview?: { readonly name: string; readonly badgeUrls: { readonly small: string } };
};

const EMPTY_PLAYER_PROFILES: readonly PlayerProfileIdentity[] = [];

export function ManageLinkedAccountsScreen({
  initialAccounts,
  service,
  continueLabel,
  onContinue,
  onOrderChanged,
  onOpenGameSettings,
  onBack,
  onLogout,
  onRefresh,
  lookupPlayer,
  playerProfiles = EMPTY_PLAYER_PROFILES,
  viewportWidth,
  platform = Platform.OS,
  firstConnection = !initialAccounts.some((account) => account.isVerified),
}: {
  initialAccounts: readonly LinkedAccountItem[];
  service: LinkedAccountPresentationService;
  continueLabel: string;
  onContinue: () => void | Promise<void>;
  onOrderChanged?: (orderedTags: readonly string[]) => void;
  onOpenGameSettings: () => boolean | void | Promise<boolean | void>;
  onBack?: () => void | Promise<void>;
  onLogout?: () => void | Promise<void>;
  onRefresh?: () => void | Promise<void>;
  lookupPlayer: (tag: string) => Promise<PlayerProfileIdentity>;
  user?: { readonly username: string; readonly avatarUrl: string } | null;
  playerProfiles?: readonly PlayerProfileIdentity[];
  viewportWidth?: number;
  platform?: string;
  firstConnection?: boolean;
}) {
  const { t, locale } = useI18n();
  const layout = useAdaptiveLayout();
  const theme = useCKTheme();
  const { reduceMotion } = useCKAccessibility();
  const insets = useSafeAreaInsets();
  const measuredWidth = useWindowDimensions().width;
  const desktopWeb = platform === 'web' && (viewportWidth ?? measuredWidth) >= 900;
  const [accounts, setAccounts] = useState([...initialAccounts]);
  const [tag, setTag] = useState('');
  const [deleting, setDeleting] = useState<string>();
  const [orderChanged, setOrderChanged] = useState(false);
  const [continuing, setContinuing] = useState(false);
  const [error, setError] = useState<string>();
  const [verification, setVerification] = useState<LinkedAccountItem>();
  const [pendingPlayer, setPendingPlayer] = useState<PlayerProfileIdentity>();
  const [lookingUp, setLookingUp] = useState(false);
  const lookupGeneration = useRef(0);
  const [notice, setNotice] = useState<string>();
  const refreshVersion = useRef(0);
  const initialAccountsSignature = JSON.stringify(
    initialAccounts.map((account) => [
      canonicalTag(account.playerTag),
      account.name,
      account.townHallLevel,
      account.isVerified,
      account.hidden,
    ]),
  );
  const synchronizedAccountsSignature = useRef(initialAccountsSignature);
  const refreshError = (failure: unknown) => {
    const message =
      failure instanceof Error ? failure.message : typeof failure === 'string' ? failure : '';
    return t('generalRefreshFailed', {
      error: message.replace('Exception: ', '').trim() || t('apiErrorOperationFailed'),
    });
  };
  const refreshAfterMutation = async () => {
    const version = ++refreshVersion.current;
    setError(undefined);
    try {
      await onRefresh?.();
      if (version === refreshVersion.current) setError(undefined);
    } catch (failure) {
      if (version === refreshVersion.current) setError(refreshError(failure));
    }
  };
  const hasVerified = accounts.some((account) => account.isVerified);
  const requiresVerifiedAccount = firstConnection || !hasVerified;
  const byTag = useMemo(
    () => new Set(accounts.map((account) => account.playerTag.toUpperCase())),
    [accounts],
  );
  const presentAccount = (account: Parameters<typeof accountPresentationItem>[0]) =>
    accountPresentationItem(
      account,
      playerProfiles.find(
        (profile) => canonicalTag(profile.tag) === canonicalTag(account.playerTag),
      ),
    );
  const profilesByTag = useMemo(
    () => new Map(playerProfiles.map((profile) => [canonicalTag(profile.tag), profile] as const)),
    [playerProfiles],
  );
  const presentedAccounts = useMemo(
    () =>
      accounts.map((account) => {
        const profile = profilesByTag.get(canonicalTag(account.playerTag));
        const hasRawName =
          typeof account.raw.name === 'string' && account.raw.name.trim().length > 0;
        const hasRawTownHall =
          typeof account.raw.townHallLevel === 'number' && account.raw.townHallLevel > 0;
        const name = hasRawName ? account.name : (profile?.name ?? account.name);
        const townHallLevel = hasRawTownHall
          ? account.townHallLevel
          : (profile?.townHallLevel ?? account.townHallLevel);
        if (!profile || (account.name === name && account.townHallLevel === townHallLevel))
          return account;
        return { ...account, name, townHallLevel };
      }),
    [accounts, profilesByTag],
  );
  const add = async () => {
    const input = tag.trim().toUpperCase().replace(/O/g, '0');
    // Validate before canonicalization: stripping arbitrary characters can
    // turn an invalid input into a different, apparently valid player tag.
    if (!/^#?[0289PYLQGRJCUV]{3,15}$/.test(input)) {
      setError(t('accountsErrorTagNotExists'));
      return;
    }
    const normalized = canonicalTag(input);
    if (byTag.has(normalized)) {
      setError(t('accountsErrorAlreadyLinkedToYou'));
      return;
    }
    const generation = ++lookupGeneration.current;
    setLookingUp(true);
    setError(undefined);
    try {
      const player = await lookupPlayer(normalized);
      if (generation === lookupGeneration.current) setPendingPlayer(player);
    } catch (error) {
      if (generation !== lookupGeneration.current) return;
      setError(
        t(
          error instanceof ApiResponseError && (error.status === 404 || error.status === 400)
            ? 'accountsErrorTagNotExists'
            : 'searchErrorPlayerLoadFailed',
        ),
      );
    } finally {
      if (generation === lookupGeneration.current) setLookingUp(false);
    }
  };
  const changeTag = (value: string) => {
    lookupGeneration.current += 1;
    setLookingUp(false);
    setPendingPlayer(undefined);
    setTag(value);
    setError(undefined);
  };
  useEffect(
    () => () => {
      lookupGeneration.current += 1;
    },
    [],
  );
  const finishReorder = ({ data, from, to }: DragEndParams<LinkedAccountItem>) => {
    if (from === to) return;
    setAccounts(data);
    setOrderChanged(true);
    onOrderChanged?.(linkedAccountTags(data));
  };
  const remove = async (playerTag: string) => {
    setDeleting(playerTag);
    setError(undefined);
    const removed = await service.removeAccount(playerTag);
    setDeleting(undefined);
    if (removed)
      setAccounts((current) => current.filter((account) => account.playerTag !== playerTag));
    else setError(t('accountsErrorFailedToAdd'));
  };
  const continueAfterPersist = async () => {
    if (continuing) return;
    const version = ++refreshVersion.current;
    setError(undefined);
    if (!hasVerified) {
      setError(t('homeVerifiedAccountRequiredBody'));
      return;
    }
    setContinuing(true);
    try {
      if (orderChanged) {
        const saved = await service.updateAccountOrder(linkedAccountTags(accounts));
        if (!saved) {
          setError(t('accountsErrorFailedToUpdateOrder'));
          return;
        }
        setOrderChanged(false);
      }
      await onContinue();
    } catch (failure) {
      if (version === refreshVersion.current) setError(refreshError(failure));
    } finally {
      setContinuing(false);
    }
  };
  const leaveAfterPersist = async () => {
    if (!onBack || continuing) return;
    const version = ++refreshVersion.current;
    setError(undefined);
    setContinuing(true);
    try {
      if (orderChanged) {
        const saved = await service.updateAccountOrder(linkedAccountTags(accounts));
        if (!saved) {
          setError(t('accountsErrorFailedToUpdateOrder'));
          return;
        }
        setOrderChanged(false);
      }
      if (!hasVerified) {
        setError(t('homeVerifiedAccountRequiredBody'));
        return;
      }
      await onBack();
    } catch (failure) {
      if (version === refreshVersion.current) setError(refreshError(failure));
    } finally {
      setContinuing(false);
    }
  };
  useEffect(() => {
    if (synchronizedAccountsSignature.current === initialAccountsSignature) return;
    synchronizedAccountsSignature.current = initialAccountsSignature;
    setAccounts([...initialAccounts]);
    setOrderChanged(false);
  }, [initialAccounts, initialAccountsSignature]);
  useEffect(() => {
    if (!onBack) return;
    const subscription = BackHandler.addEventListener('hardwareBackPress', () => {
      void leaveAfterPersist();
      return true;
    });
    return () => subscription.remove();
  });
  const verificationProfile = verification
    ? profilesByTag.get(canonicalTag(verification.playerTag))
    : pendingPlayer;
  const verified = async () => {
    if (!verification && !pendingPlayer) return;
    setAccounts(service.accounts.map((account) => presentAccount(account)));
    setVerification(undefined);
    setPendingPlayer(undefined);
    setTag('');
    setNotice(t('accountVerificationSuccess'));
    await refreshAfterMutation();
  };
  return (
    <SafeAreaView
      edges={['left', 'right']}
      style={[styles.safe, { backgroundColor: theme.background }]}
    >
      {!desktopWeb ? (
        <View style={{ paddingTop: insets.top }}>
          <View style={styles.appBar}>
            <Pressable
              accessibilityLabel={onBack ? materialBackLabel(locale) : t('authLogout')}
              accessibilityRole="button"
              onPress={() => {
                if (onBack) void leaveAfterPersist();
                else void onLogout?.();
              }}
              style={({ pressed }) => [
                styles.appBarAction,
                { backgroundColor: colorWithAlpha(theme.onSurface, 0.07) },
                pressed && styles.pressed,
              ]}
            >
              {onBack ? (
                <ChevronLeft color={theme.onSurface} size={25} />
              ) : (
                <LogOut color={theme.onSurface} size={24} />
              )}
            </Pressable>
            <CKText
              role="screenTitle"
              accessibilityRole="header"
              skeleton={false}
              style={styles.appBarTitle}
            >
              {t('accountsMyTitle')}
            </CKText>
            {/* Balance the back action so the title centers on the whole screen. */}
            <View style={styles.appBarBalance} />
          </View>
        </View>
      ) : null}
      <View
        style={[
          styles.container,
          layout.isExpanded && { maxWidth: layout.readableMaxWidth, paddingTop: 16 },
          layout.isDuo && !layout.isExpanded && { maxWidth: layout.contentMaxWidth },
        ]}
      >
        <DraggableFlatList
          activationDistance={8}
          data={presentedAccounts}
          keyExtractor={(account) => account.playerTag}
          onDragEnd={finishReorder}
          keyboardDismissMode="on-drag"
          keyboardShouldPersistTaps="handled"
          // The draggable list has its own outer View; size it as well as the list
          // so the linking form remains visible even before the first account.
          containerStyle={styles.accountList}
          style={styles.accountList}
          contentContainerStyle={[
            styles.scroll,
            !requiresVerifiedAccount && { paddingBottom: insets.bottom + 24 },
          ]}
          ListHeaderComponent={
            <>
              <View style={styles.intro}>
                {desktopWeb ? (
                  <CKText role="screenTitle" skeleton={false} style={styles.setupTitle}>
                    {t('accountsMyTitle')}
                  </CKText>
                ) : null}
                <View
                  style={styles.accountArtwork}
                  accessibilityElementsHidden
                  importantForAccessibility="no-hide-descendants"
                >
                  <DraggableArtworkBubble
                    source={require('../../../../assets/clashking/legend-poster/th10.png')}
                    size={60}
                    maxTravel={16}
                    reduceMotion={reduceMotion}
                    style={styles.townHallTen}
                  />
                  <DraggableArtworkBubble
                    source={require('../../../../assets/clashking/legend-poster/th14.png')}
                    size={60}
                    maxTravel={16}
                    reduceMotion={reduceMotion}
                    style={styles.townHallFourteen}
                  />
                  <DraggableArtworkBubble
                    source={require('../../../../assets/clashking/legend-poster/th18.png')}
                    size={76}
                    maxTravel={16}
                    reduceMotion={reduceMotion}
                    style={styles.townHallEighteen}
                  />
                </View>
              </View>
              <View style={styles.sticky}>
                <View style={{ flexDirection: 'row' }}>
                  <SearchField
                    value={tag}
                    onChangeText={changeTag}
                    placeholder={t('accountsEnterPlayerTag')}
                    onSubmit={() => {
                      if (!lookingUp && tag.trim()) void add();
                    }}
                    searchIcon={
                      <Pressable
                        accessibilityRole="button"
                        accessibilityLabel={t('accountsAdd')}
                        disabled={lookingUp || !tag.trim()}
                        hitSlop={10}
                        onPress={() => void add()}
                      >
                        {lookingUp ? (
                          <LoadingIndicator />
                        ) : (
                          <Search size={18} color={theme.onSurfaceVariant} />
                        )}
                      </Pressable>
                    }
                  />
                </View>
                <InlineError message={error} />
                {presentedAccounts.length ? (
                  <CKText
                    role="bodySmall"
                    muted
                    skeleton={false}
                    style={{ marginTop: 24, marginBottom: 6 }}
                  >
                    {t('accountsMenuTitle')} · {presentedAccounts.length}
                  </CKText>
                ) : null}
              </View>
            </>
          }
          ListEmptyComponent={
            firstConnection ? undefined : <EmptyState title={t('accountsNoneFound')} />
          }
          renderItem={(params) => (
            <AccountRow
              {...params}
              deleting={deleting === params.item.playerTag}
              onRemove={() => void remove(params.item.playerTag)}
              onVerify={() => setVerification(params.item)}
            />
          )}
        />
        {requiresVerifiedAccount ? (
          <View
            testID="linked-accounts-continue"
            style={[styles.continue, { paddingBottom: Math.max(16, insets.bottom + 8) }]}
          >
            <PrimaryAction
              label={continueLabel}
              disabled={!hasVerified || continuing}
              loading={continuing}
              color={!hasVerified ? theme.surfaceContainerHighest : undefined}
              foregroundColor={!hasVerified ? theme.onSurfaceVariant : undefined}
              onPress={() => void continueAfterPersist()}
            />
          </View>
        ) : null}
      </View>
      <AccountVerificationDialog
        visible={verification !== undefined || pendingPlayer !== undefined}
        playerTag={verification?.playerTag ?? pendingPlayer?.tag ?? ''}
        playerName={verification?.name ?? pendingPlayer?.name ?? ''}
        townHallLevel={verification?.townHallLevel ?? pendingPlayer?.townHallLevel ?? 0}
        clanName={verificationProfile?.clanOverview?.name}
        clanBadgeUrl={verificationProfile?.clanOverview?.badgeUrls.small}
        onVerify={(token) =>
          verification || pendingPlayer
            ? service.addAccountWithToken(verification?.playerTag ?? pendingPlayer!.tag, token)
            : Promise.resolve({ success: false, message: null })
        }
        onOpenSettings={onOpenGameSettings}
        onCancel={() => {
          setVerification(undefined);
          setPendingPlayer(undefined);
        }}
        onVerified={() => void verified()}
      />
      <Snackbar message={notice} onDismiss={() => setNotice(undefined)} />
    </SafeAreaView>
  );
}

export function AccountRow({
  item: account,
  drag,
  isActive,
  deleting,
  onRemove,
  onVerify,
}: RenderItemParams<LinkedAccountItem> & {
  deleting: boolean;
  onRemove: () => void;
  onVerify: () => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const layout = useAdaptiveLayout();
  return (
    <ScaleDecorator activeScale={1.02}>
      <Pressable
        delayLongPress={300}
        onLongPress={isActive ? undefined : drag}
        testID={`account-card-${account.playerTag}`}
      >
        <Surface
          radius={ckRadius.chip}
          style={[
            styles.account,
            layout.isExpanded && { minHeight: 98, padding: 18, gap: 16 },
            isActive && styles.activeAccount,
          ]}
        >
          <MobileWebImage
            imageUrl={ImageAssets.townHall(account.townHallLevel)}
            errorFallback={
              <Shield
                color={theme.onSurfaceVariant}
                size={32}
                style={[styles.townHall, layout.isExpanded && { width: 56, height: 56 }]}
              />
            }
            style={[styles.townHall, layout.isExpanded && { width: 56, height: 56 }]}
          />
          <View style={styles.accountCopy}>
            <CKText style={styles.strong} numberOfLines={1}>
              {account.name}
            </CKText>
            <CKText muted role="bodySmall" numberOfLines={1}>
              {account.playerTag}
            </CKText>
          </View>
          <Pressable
            accessibilityLabel={
              account.isVerified ? t('accountVerified') : `${t('accountVerify')} ${account.name}`
            }
            disabled={account.isVerified}
            accessibilityRole={account.isVerified ? undefined : 'button'}
            onPress={onVerify}
          >
            <PillSurface
              style={[
                styles.status,
                {
                  backgroundColor: colorWithAlpha(
                    account.isVerified ? statColors.win : statColors.capitalProjected,
                    0.14,
                  ),
                },
              ]}
            >
              <CKText
                role="bodySmall"
                style={{
                  color: account.isVerified ? statColors.win : statColors.capitalProjected,
                  fontWeight: '700',
                }}
              >
                {account.isVerified ? t('accountVerified') : t('accountVerify')}
              </CKText>
              {!account.isVerified ? (
                <ArrowRight size={15} color={statColors.capitalProjected} />
              ) : null}
            </PillSurface>
          </Pressable>
          <Pressable
            accessibilityLabel={t('tooltipRemoveAccount')}
            accessibilityRole="button"
            disabled={deleting}
            onPress={onRemove}
            style={styles.iconButton}
          >
            {deleting ? <LoadingIndicator /> : <Trash2 color={theme.primary} />}
          </Pressable>
        </Surface>
      </Pressable>
    </ScaleDecorator>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1 },
  appBar: {
    height: 44,
    paddingHorizontal: 20,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 12,
  },
  appBarTitle: { flex: 1, textAlign: 'center', fontSize: 24, lineHeight: 30 },
  appBarBalance: { width: 42 },
  appBarAction: {
    width: 42,
    height: 42,
    borderRadius: 21,
    alignItems: 'center',
    justifyContent: 'center',
  },
  appBarUser: {
    minWidth: 0,
    maxWidth: '72%',
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    paddingRight: 12,
  },
  appBarAvatar: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
  },
  pressed: { opacity: 0.72 },
  container: { flex: 1, minHeight: 0, width: '100%', maxWidth: 1040, alignSelf: 'center' },
  accountList: { flex: 1, minHeight: 0 },
  scroll: { paddingBottom: 24 },
  // Reserve the bounded upward drag inside the scroll viewport. Letting the
  // whole list overflow would also expose scrolled account rows behind Back.
  intro: {
    paddingHorizontal: 24,
    paddingTop: 20,
    paddingBottom: 20,
    alignItems: 'center',
    gap: 10,
  },
  accountArtwork: { width: 232, height: 104 },
  townHallTen: { position: 'absolute', left: 16, top: 27, transform: [{ rotate: '-13deg' }] },
  townHallFourteen: { position: 'absolute', right: 16, top: 27, transform: [{ rotate: '13deg' }] },
  townHallEighteen: { position: 'absolute', left: 78, top: 8 },
  setupTitle: { fontSize: 32, lineHeight: 38, fontWeight: '700', textAlign: 'center' },
  setupSkip: { minHeight: 44, alignItems: 'center', justifyContent: 'center' },
  strong: { fontWeight: '800' },
  sticky: { paddingHorizontal: 16, paddingBottom: 10 },
  searchRow: { flexDirection: 'row', alignItems: 'flex-end', gap: 10 },

  list: { paddingHorizontal: 16, paddingTop: 8, gap: 8 },
  account: {
    marginHorizontal: 16,
    marginBottom: 8,
    paddingHorizontal: 10,
    paddingVertical: 10,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  activeAccount: { opacity: 0.96 },
  townHall: { width: 44, height: 44, resizeMode: 'contain' },
  accountCopy: { flex: 1 },
  status: {
    paddingHorizontal: 12,
    paddingVertical: 9,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  iconButton: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  continue: { flexShrink: 0, paddingHorizontal: 16, paddingTop: 8 },
});
