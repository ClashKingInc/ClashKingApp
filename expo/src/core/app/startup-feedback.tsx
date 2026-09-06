import { Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { Hammer, LogOut, MessageCircle, RefreshCcw, UserRound, WifiOff } from 'lucide-react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { ImageAssets } from '../assets/image-assets';
import { useI18n } from '../../i18n';
import {
  CKText,
  LoadingIndicator,
  MobileWebImage,
  ckRadius,
  ckSpacing,
  colorWithAlpha,
  useCKTheme,
} from '../../ui';

export function MaintenanceScreen({ onRetry }: { onRetry: () => void }) {
  const { t } = useI18n();
  const theme = useCKTheme();
  return (
    <SafeAreaView style={[styles.safe, { backgroundColor: theme.surface }]}>
      <View style={styles.maintenance}>
        <MobileWebImage
          accessibilityIgnoresInvertColors
          imageUrl={ImageAssets.sleepingApprenticeBuilder}
          errorFallback={<Hammer color={theme.onSurfaceVariant} size={72} />}
          style={styles.maintenanceImage}
          contentFit="contain"
        />
        <CKText role="screenTitle" style={[styles.center, { color: theme.primary }]}>
          {t('maintenanceTitle')}
        </CKText>
        <CKText style={styles.center}>{t('maintenanceDescription')}</CKText>
        <TextButton label={t('generalTryAgain')} onPress={onRetry} />
      </View>
    </SafeAreaView>
  );
}

export function StartupErrorScreen({
  isNetworkError,
  retrying,
  onRetry,
  onJoinDiscord,
  onLogout,
  userName,
  avatarUrl,
}: {
  isNetworkError: boolean;
  retrying: boolean;
  onRetry: () => void;
  onJoinDiscord: () => void;
  onLogout: () => void;
  userName: string | null;
  avatarUrl: string | null;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  return (
    <SafeAreaView style={[styles.safe, { backgroundColor: theme.surface }]}>
      <View style={styles.accountHeader}>
        <Pressable
          accessibilityLabel={t('authLogout')}
          accessibilityRole="button"
          onPress={onLogout}
          style={styles.headerButton}
        >
          <LogOut color={theme.onSurface} size={22} />
        </Pressable>
        <View style={styles.accountIdentity}>
          <CKText role="bodyMedium" numberOfLines={1} style={styles.accountName}>
            {userName ?? t('generalLoading')}
          </CKText>
          <View style={[styles.accountAvatar, { backgroundColor: theme.surfaceContainerHighest }]}>
            {avatarUrl ? (
              <MobileWebImage
                contentFit="cover"
                imageUrl={avatarUrl}
                style={styles.accountAvatarImage}
                errorFallback={<UserRound color={theme.onSurfaceVariant} size={22} />}
              />
            ) : (
              <UserRound color={theme.onSurfaceVariant} size={22} />
            )}
          </View>
        </View>
      </View>
      <ScrollView contentContainerStyle={styles.errorScroll}>
        <View style={styles.illustration}>
          {isNetworkError ? (
            <View
              style={[
                styles.networkCircle,
                {
                  backgroundColor: colorWithAlpha(theme.error, 0.1),
                  borderColor: colorWithAlpha(theme.error, 0.2),
                },
              ]}
            />
          ) : null}
          <MobileWebImage
            accessibilityIgnoresInvertColors
            imageUrl={ImageAssets.sleepingApprenticeBuilder}
            errorFallback={<Hammer color={theme.onSurfaceVariant} size={72} />}
            style={styles.errorImage}
            contentFit="contain"
          />
          {isNetworkError ? (
            <View style={[styles.networkBadge, { backgroundColor: theme.error }]}>
              <WifiOff color="#FFFFFF" size={20} />
            </View>
          ) : null}
        </View>
        <CKText role="screenTitle" style={styles.center}>
          {isNetworkError ? t('errorNetworkTitle') : t('errorTitle')}
        </CKText>
        {isNetworkError ? (
          <CKText muted style={styles.center}>
            {t('errorNetworkMessage')}
          </CKText>
        ) : null}
        <Pressable
          accessibilityRole="button"
          disabled={retrying}
          onPress={onRetry}
          style={[
            styles.retry,
            { backgroundColor: colorWithAlpha(theme.primary, retrying ? 0.7 : 1) },
          ]}
        >
          {retrying ? <LoadingIndicator /> : <RefreshCcw color={theme.onPrimary} size={20} />}
          <CKText role="rowTitle" style={{ color: theme.onPrimary }}>
            {retrying ? t('generalRetrying') : t('generalRetry')}
          </CKText>
        </Pressable>
        <View style={styles.support}>
          <CKText muted style={styles.center}>
            {t('errorSubtitle')}
          </CKText>
          <Pressable accessibilityRole="link" onPress={onJoinDiscord} style={styles.discord}>
            <MessageCircle color={theme.primary} size={16} />
            <CKText role="bodySmall" style={{ color: theme.primary }}>
              {t('helpJoinDiscord')}
            </CKText>
          </Pressable>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

function TextButton({ label, onPress }: { label: string; onPress: () => void }) {
  const theme = useCKTheme();
  return (
    <Pressable accessibilityRole="button" onPress={onPress} style={styles.textButton}>
      <RefreshCcw color={theme.primary} size={20} />
      <CKText role="bodyLarge" style={{ color: theme.primary }}>
        {label}
      </CKText>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1 },
  accountHeader: {
    height: 60,
    paddingHorizontal: ckSpacing.md,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  headerButton: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  accountIdentity: { minWidth: 0, flexDirection: 'row', alignItems: 'center', gap: 5 },
  accountName: { maxWidth: 220 },
  accountAvatar: {
    width: 40,
    height: 40,
    borderRadius: 20,
    overflow: 'hidden',
    alignItems: 'center',
    justifyContent: 'center',
  },
  accountAvatarImage: { width: 40, height: 40 },
  center: { textAlign: 'center' },
  maintenance: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 20,
    paddingHorizontal: 20,
  },
  maintenanceImage: { width: 250, height: 250 },
  textButton: {
    minHeight: 44,
    marginTop: 20,
    paddingHorizontal: ckSpacing.md,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: ckSpacing.sm,
  },
  errorScroll: {
    minHeight: '80%',
    flexGrow: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: ckSpacing.lg,
    padding: ckSpacing.xl,
  },
  illustration: { width: 200, height: 200, alignItems: 'center', justifyContent: 'center' },
  networkCircle: {
    position: 'absolute',
    width: 180,
    height: 180,
    borderRadius: 90,
    borderWidth: 2,
  },
  errorImage: { width: 200, height: 200 },
  networkBadge: {
    position: 'absolute',
    right: 10,
    bottom: 10,
    padding: 8,
    borderRadius: 999,
    shadowColor: '#000000',
    shadowOpacity: 0.2,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 2 },
    elevation: 3,
  },
  retry: {
    width: '100%',
    maxWidth: 300,
    minHeight: 52,
    marginTop: ckSpacing.lg,
    borderRadius: ckRadius.control,
    paddingHorizontal: ckSpacing.xl,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: ckSpacing.sm,
  },
  support: { alignItems: 'center', gap: ckSpacing.sm, marginTop: ckSpacing.sm },
  discord: {
    minHeight: 44,
    paddingHorizontal: ckSpacing.sm,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: ckSpacing.sm,
  },
});
