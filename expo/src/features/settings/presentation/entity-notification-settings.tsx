import { useEffect, useState } from 'react';
import { Pressable, View } from 'react-native';
import { ChevronDown, ChevronUp, Bell } from 'lucide-react-native';
import { useAppRuntime } from '../../../core/app/runtime-context';
import type { NotificationPreferences } from '../../../core/dto/notification-preferences';
import { ImageAssets } from '../../../core/assets/image-assets';
import { useI18n } from '../../../i18n';
import { CKText, ErrorState, MobileWebImage, Skeleton, useCKTheme, ckColors } from '../../../ui';
import { SlidingSegmentControl } from '../../../ui/sliding-segment-control';
import { ProfileOptionSwitch } from '../../../ui/profile-option-switch';
import { ClanNotificationOptions } from '../../clan/presentation/clan-notification-options';
import type { WarWidgetClanOption } from '../../widgets/contracts';

/** One notification destination; the roster cards retain only display options. */
export function EntityNotificationSettings({ clans }: { clans: readonly WarWidgetClanOption[] }) {
  const runtime = useAppRuntime();
  const { t, isRtl } = useI18n();
  const theme = useCKTheme();
  const [tab, setTab] = useState('players');
  const [preferences, setPreferences] = useState<NotificationPreferences>();
  const [clanSettings, setClanSettings] = useState(runtime.notificationPreferences.clans);
  const [error, setError] = useState(false);
  const [busy, setBusy] = useState<string>();
  const [expanded, setExpanded] = useState<string>();
  const load = async () => {
    try {
      const [players, savedClans] = await Promise.all([
        runtime.notificationPreferences.load(),
        runtime.notificationPreferences.loadClans(),
      ]);
      setPreferences(players);
      setClanSettings(savedClans);
      setError(false);
    } catch {
      setError(true);
    }
  };
  useEffect(() => {
    // Opening this destination starts an external preference load.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    void load();
    return runtime.notificationPreferences.subscribeClans(() =>
      setClanSettings(runtime.notificationPreferences.clans),
    );
    // The service is stable for this signed-in runtime.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [runtime]);
  const players = runtime.accounts.accounts.map((link) => ({
    link,
    player: runtime.players.profiles.find((player) => player.tag === link.playerTag),
  }));
  const changePlayer = async (tag: string, enabled: boolean) => {
    if (busy) return;
    setBusy(tag);
    setError(false);
    try {
      const saved = await runtime.notificationPreferences.setAccountEnabled(tag, enabled);
      setPreferences((current) =>
        current
          ? {
              ...current,
              accounts: [...current.accounts.filter((account) => account.tag !== tag), saved],
            }
          : current,
      );
    } catch {
      setError(true);
    } finally {
      setBusy(undefined);
    }
  };
  return (
    <View style={{ gap: 12 }}>
      <SlidingSegmentControl
        isRtl={isRtl}
        value={tab}
        onChange={setTab}
        options={[
          { value: 'players', label: t('searchTabPlayers') },
          { value: 'clans', label: t('searchTabClans') },
        ]}
      />
      {error ? (
        <ErrorState
          title={t('notifSettingsSaveFailed')}
          actionLabel={t('generalRetry')}
          onAction={() => void load()}
        />
      ) : null}
      {!preferences || !clanSettings ? (
        <Skeleton height={72} radius={20} />
      ) : tab === 'players' ? (
        players.map(({ player, link }) => (
          <ProfileOptionSwitch
            key={link.playerTag}
            icon={
              <MobileWebImage
                imageUrl={player?.townHallPic ?? ImageAssets.townHall(1)}
                style={{ width: 30, height: 30 }}
              />
            }
            title={player?.name ?? link.playerTag}
            subtitle={t(
              link.isVerified
                ? 'playerOptionNotificationsSubtitle'
                : 'playerOptionNotificationsVerifyFirst',
            )}
            value={preferences.accounts.some(
              (account) => account.tag === link.playerTag && account.enabled,
            )}
            enabled={link.isVerified && !busy}
            loading={busy === link.playerTag}
            onChange={(enabled) => void changePlayer(link.playerTag, enabled)}
          />
        ))
      ) : (
        clans.map((clan) => (
          <View
            key={clan.tag}
            style={{ borderRadius: 20, backgroundColor: theme.surface, overflow: 'hidden' }}
          >
            <Pressable
              accessibilityRole="button"
              accessibilityState={{ expanded: expanded === clan.tag }}
              onPress={() =>
                setExpanded((current) => (current === clan.tag ? undefined : clan.tag))
              }
              style={{
                minHeight: 64,
                padding: 12,
                flexDirection: 'row',
                gap: 12,
                alignItems: 'center',
              }}
            >
              {clan.badgeUrl ? (
                <MobileWebImage imageUrl={clan.badgeUrl} style={{ width: 36, height: 36 }} />
              ) : (
                <Bell size={26} color={theme.onSurfaceVariant} />
              )}
              <CKText role="rowTitle" numberOfLines={1} style={{ flex: 1, minWidth: 0 }}>
                {clan.name}
              </CKText>
              {(() => {
                const setting = clanSettings.clans.find((entry) => entry.tag === clan.tag);
                return setting?.warEnabled || setting?.raidEnabled ? (
                  <View
                    accessibilityLabel={t('clanNotificationsEnabled')}
                    style={{ flexDirection: 'row', alignItems: 'center', gap: 4 }}
                  >
                    <Bell size={15} color={ckColors.donationGreen} />
                    {setting.warEnabled ? (
                      <MobileWebImage
                        imageUrl={ImageAssets.war}
                        style={{ width: 20, height: 20 }}
                      />
                    ) : null}
                    {setting.raidEnabled ? (
                      <MobileWebImage
                        imageUrl={ImageAssets.raidAttacks}
                        style={{ width: 20, height: 20 }}
                      />
                    ) : null}
                  </View>
                ) : null;
              })()}
              {expanded === clan.tag ? (
                <ChevronUp size={20} color={theme.onSurfaceVariant} />
              ) : (
                <ChevronDown size={20} color={theme.onSurfaceVariant} />
              )}
            </Pressable>
            {expanded === clan.tag ? (
              <ClanNotificationOptions
                tag={clan.tag}
                expanded
                controls={{
                  settings: clanSettings,
                  setEnabled: async (tag, type, enabled) => {
                    await runtime.notificationPreferences.setClanEnabled(tag, type, enabled);
                    await runtime.bookmarks.load();
                  },
                  showMessage: () => setError(true),
                }}
              />
            ) : null}
          </View>
        ))
      )}
      {(tab === 'players' ? players.length : clans.length) === 0 ? (
        <CKText muted>{t('generalNoDataAvailable')}</CKText>
      ) : null}
    </View>
  );
}
