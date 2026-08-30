import { useEffect, useMemo, useState } from 'react';
import {
  BackHandler,
  Platform,
  Pressable,
  StyleSheet,
  View,
  useWindowDimensions,
} from 'react-native';
import {
  ChevronLeft,
  GripVertical,
  LogOut,
  PlusCircle,
  Shield,
  Trash2,
  UserRound,
} from 'lucide-react-native';
import DraggableFlatList, {
  ScaleDecorator,
  type DragEndParams,
  type RenderItemParams,
} from 'react-native-draggable-flatlist';
import { SafeAreaView } from 'react-native-safe-area-context';

import { ImageAssets } from '../../../core/assets/image-assets';
import { canonicalTag } from '../../../core/domain/tags';
import { materialBackLabel, useI18n } from '../../../i18n';
import {
  CKText,
  EmptyState,
  LoadingIndicator,
  MobileWebImage,
  PillSurface,
  SkeletonLoadingDialog,
  Snackbar,
  Surface,
  ckRadius,
  colorWithAlpha,
  statColors,
  useCKTheme,
  useCKThemeMode,
} from '../../../ui';
import { AuthField, InlineError, PrimaryAction } from '../../auth/presentation';
import { normalizePlayerTag } from '../../auth/presentation/validation';
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
  user,
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
  user?: { readonly username: string; readonly avatarUrl: string } | null;
  playerProfiles?: readonly PlayerProfileIdentity[];
  viewportWidth?: number;
  platform?: string;
  firstConnection?: boolean;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const mode = useCKThemeMode();
  const measuredWidth = useWindowDimensions().width;
  const desktopWeb = platform === 'web' && (viewportWidth ?? measuredWidth) >= 900;
  const [accounts, setAccounts] = useState([...initialAccounts]);
  const [tag, setTag] = useState('');
  const [adding, setAdding] = useState(false);
  const [deleting, setDeleting] = useState<string>();
  const [orderChanged, setOrderChanged] = useState(false);
  const [continuing, setContinuing] = useState(false);
  const [error, setError] = useState<string>();
  const [verification, setVerification] = useState<LinkedAccountItem>();
  const [notice, setNotice] = useState<string>();
  const [addServerFailure, setAddServerFailure] = useState(false);
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
    const normalized = normalizePlayerTag(tag);
    if (!normalized) {
      setError(t('accountsEnterPlayerTag'));
      return;
    }
    if (byTag.has(normalized)) {
      setError(t('accountsErrorAlreadyLinkedToYou'));
      return;
    }
    setAdding(true);
    setError(undefined);
    const result = await service.addAccount(normalized);
    setAdding(false);
    if (result.code === 200 && result.account) {
      setAccounts((current) => [...current, presentAccount(result.account!)]);
      setTag('');
      await onRefresh?.();
      return;
    }
    if (result.code === 409 && result.account) {
      setVerification(presentAccount(result.account));
      return;
    }
    if (result.code === 500) setAddServerFailure(true);
    else
      setError(
        result.code === 404 ? t('accountsErrorTagNotExists') : t('accountsErrorFailedToAdd'),
      );
  };
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
      const message = failure instanceof Error ? failure.message : String(failure);
      setError(t('generalRefreshFailed', { error: message.replace('Exception: ', '') }));
    } finally {
      setContinuing(false);
    }
  };
  const leaveAfterPersist = async () => {
    if (!onBack || continuing) return;
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
      const message = failure instanceof Error ? failure.message : String(failure);
      setError(t('generalRefreshFailed', { error: message.replace('Exception: ', '') }));
    } finally {
      setContinuing(false);
    }
  };
  useEffect(() => {
    if (!onBack) return;
    const subscription = BackHandler.addEventListener('hardwareBackPress', () => {
      void leaveAfterPersist();
      return true;
    });
    return () => subscription.remove();
  });
  const verified = async () => {
    if (!verification) return;
    setAccounts(service.accounts.map((account) => presentAccount(account)));
    setVerification(undefined);
    setTag('');
    setNotice(t('accountVerificationSuccess'));
    await onRefresh?.();
  };
  if (addServerFailure) {
    return (
      <SafeAreaView style={[styles.safe, { backgroundColor: theme.background }]}>
        <View style={styles.retryError}>
          <EmptyState
            title={t('errorTitle')}
            body={t('errorSubtitle')}
            actionLabel={t('generalRetry')}
            onAction={() => {
              setAddServerFailure(false);
              void add();
            }}
          />
        </View>
      </SafeAreaView>
    );
  }
  return (
    <SafeAreaView style={[styles.safe, { backgroundColor: theme.background }]}>
      {!desktopWeb ? (
        <View style={styles.appBar}>
          <Pressable
            accessibilityLabel={onBack ? materialBackLabel(locale) : t('authLogout')}
            accessibilityRole="button"
            onPress={() => {
              if (onBack) void leaveAfterPersist();
              else void onLogout?.();
            }}
            style={({ pressed }) => [styles.appBarAction, pressed && styles.pressed]}
          >
            {onBack ? (
              <ChevronLeft color={theme.onSurface} size={25} />
            ) : (
              <LogOut color={theme.onSurface} size={24} />
            )}
          </Pressable>
          <View style={styles.appBarUser}>
            <CKText numberOfLines={1} role="bodyMedium">
              {user?.username ?? t('generalLoading')}
            </CKText>
            <View style={styles.appBarAvatar}>
              {user?.avatarUrl ? (
                <MobileWebImage
                  imageUrl={user.avatarUrl}
                  errorFallback={<UserRound color={theme.onSurfaceVariant} size={24} />}
                  style={styles.appBarAvatar}
                />
              ) : (
                <UserRound color={theme.onSurfaceVariant} size={24} />
              )}
            </View>
          </View>
        </View>
      ) : null}
      <View style={styles.container}>
        <DraggableFlatList
          data={presentedAccounts}
          keyExtractor={(account) => account.playerTag}
          onDragEnd={finishReorder}
          keyboardDismissMode="on-drag"
          contentContainerStyle={styles.scroll}
          ListHeaderComponent={
            <>
              <View style={styles.intro}>
                {requiresVerifiedAccount ? (
                  <>
                    <MobileWebImage
                      imageUrl={
                        mode === 'dark' ? ImageAssets.darkModeLogo : ImageAssets.lightModeLogo
                      }
                      errorFallback={<Shield color={theme.primary} size={64} style={styles.logo} />}
                      style={styles.logo}
                    />
                    <MobileWebImage
                      imageUrl={
                        mode === 'dark'
                          ? ImageAssets.darkModeTextLogo
                          : ImageAssets.lightModeTextLogo
                      }
                      contentFit="contain"
                      errorFallback={<CKText role="screenTitle">{t('appTitle')}</CKText>}
                      style={styles.textLogo}
                    />
                    <CKText role="titleSmall" style={styles.center}>
                      {t('accountsWelcome')}
                    </CKText>
                    <CKText style={styles.center}>{t('accountsWelcomeMessage')}</CKText>
                  </>
                ) : (
                  <>
                    <CKText role="titleLarge" style={styles.strong}>
                      {t('accountsManageTitle')}
                    </CKText>
                    <CKText muted>{t('authAccountManagement')}</CKText>
                  </>
                )}
              </View>
              <View style={[styles.sticky, { backgroundColor: theme.background }]}>
                <AuthField
                  label={t('accountsPlayerTag')}
                  value={tag}
                  autoCapitalize="characters"
                  editable={!adding}
                  onChangeText={setTag}
                  onSubmitEditing={() => void add()}
                />
                <Pressable
                  accessibilityLabel={t('accountsAdd')}
                  accessibilityRole="button"
                  disabled={adding}
                  onPress={() => void add()}
                  style={styles.add}
                >
                  {adding ? <LoadingIndicator /> : <PlusCircle color={theme.primary} size={28} />}
                </Pressable>
                <InlineError message={error} />
                <CKText muted role="bodySmall">
                  {t('accountsAddInstruction')}
                </CKText>
              </View>
            </>
          }
          ListEmptyComponent={<EmptyState title={t('accountsNoneFound')} />}
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
          <View style={styles.continue}>
            <PrimaryAction
              label={continueLabel}
              disabled={!hasVerified}
              onPress={() => void continueAfterPersist()}
            />
          </View>
        ) : null}
      </View>
      <AccountVerificationDialog
        visible={verification !== undefined}
        playerTag={verification?.playerTag ?? ''}
        playerName={verification?.name ?? ''}
        townHallLevel={verification?.townHallLevel ?? 1}
        onVerify={(token) =>
          verification
            ? service.addAccountWithToken(verification.playerTag, token)
            : Promise.resolve({ success: false, message: null })
        }
        onOpenSettings={onOpenGameSettings}
        onCancel={() => setVerification(undefined)}
        onVerified={() => void verified()}
      />
      <SkeletonLoadingDialog visible={continuing} />
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
  return (
    <ScaleDecorator activeScale={1.02}>
      <Surface radius={ckRadius.chip} style={[styles.account, isActive && styles.activeAccount]}>
        <MobileWebImage
          imageUrl={ImageAssets.townHall(account.townHallLevel)}
          errorFallback={
            <Shield color={theme.onSurfaceVariant} size={32} style={styles.townHall} />
          }
          style={styles.townHall}
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
              role="labelMedium"
              style={{
                color: account.isVerified ? statColors.win : statColors.capitalProjected,
                fontWeight: '700',
              }}
            >
              {account.isVerified ? t('accountVerified') : t('accountVerify')}
            </CKText>
          </PillSurface>
        </Pressable>
        <Pressable
          accessibilityRole="button"
          onLongPress={drag}
          delayLongPress={150}
          disabled={isActive}
          style={styles.dragHandle}
          testID={`account-drag-handle-${account.playerTag}`}
        >
          <GripVertical color={theme.onSurfaceVariant} size={20} />
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
    </ScaleDecorator>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1 },
  appBar: {
    height: 60,
    paddingHorizontal: 4,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  appBarAction: { width: 48, height: 48, alignItems: 'center', justifyContent: 'center' },
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
  container: { flex: 1, width: '100%', maxWidth: 1040, alignSelf: 'center' },
  retryError: { flex: 1, justifyContent: 'center', padding: 24 },
  scroll: { paddingBottom: 24 },
  intro: { paddingHorizontal: 16, paddingTop: 16, paddingBottom: 16, gap: 4, alignItems: 'center' },
  logo: { width: 70, height: 70, resizeMode: 'contain' },
  textLogo: { width: 150, height: 48, marginTop: 12, marginBottom: 28 },
  center: { textAlign: 'center' },
  strong: { fontWeight: '800' },
  sticky: { paddingHorizontal: 16, paddingBottom: 10 },
  add: {
    position: 'absolute',
    right: 22,
    top: 24,
    width: 44,
    height: 44,
    alignItems: 'center',
    justifyContent: 'center',
  },
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
  status: { paddingHorizontal: 8, paddingVertical: 5 },
  dragHandle: { width: 32, height: 44, alignItems: 'center', justifyContent: 'center' },
  iconButton: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  continue: { paddingHorizontal: 16, paddingBottom: 16 },
});
