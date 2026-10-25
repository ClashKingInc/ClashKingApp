import { useState } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { ChevronDown, ChevronUp, SlidersHorizontal } from 'lucide-react-native';
import { useI18n } from '../../../i18n';
import { CKText, MobileWebImage, useCKTheme } from '../../../ui';
import { ImageAssets } from '../../../core/assets/image-assets';
import { ProfileOptionSwitch, profileOptionStyles } from '../../../ui/profile-option-switch';
import type { ClanNotificationSettings } from '../../notifications/data/notification-preferences-service';

export interface ClanNotificationControls {
  settings?: ClanNotificationSettings;
  setEnabled(tag: string, type: 'war' | 'raid', enabled: boolean): Promise<void>;
  showMessage(message: string): void;
}

export function ClanNotificationOptions({
  tag,
  controls,
  expanded: alwaysExpanded = false,
}: {
  tag: string;
  controls: ClanNotificationControls;
  expanded?: boolean;
}) {
  const theme = useCKTheme();
  const { t } = useI18n();
  const [expanded, setExpanded] = useState(false);
  const [busy, setBusy] = useState(false);
  const selected = controls.settings?.clans.find((clan) => clan.tag === tag);
  const change = async (type: 'war' | 'raid', value: boolean) => {
    if (busy || !controls.settings) return;
    if (value && controls.settings.usage[type] >= controls.settings.limits[type]) {
      controls.showMessage(t('playerOptionNotificationsLimitReached'));
      return;
    }
    setBusy(true);
    try {
      await controls.setEnabled(tag, type, value);
    } catch {
      controls.showMessage(t('generalFailed'));
    } finally {
      setBusy(false);
    }
  };
  return (
    <View>
      {!alwaysExpanded ? (
        <Pressable
          accessibilityRole="button"
          accessibilityState={{ expanded }}
          accessibilityLabel={t('filtersOptions')}
          hitSlop={{ top: 2, bottom: 2 }}
          onPress={() => setExpanded(!expanded)}
          style={profileOptionStyles.optionsToggle}
        >
          <SlidersHorizontal size={16} color={theme.onSurfaceVariant} />
          <CKText role="labelLarge" muted style={profileOptionStyles.optionTitle}>
            {t('filtersOptions')}
          </CKText>
          {expanded ? (
            <ChevronUp size={20} color={theme.onSurfaceVariant} />
          ) : (
            <ChevronDown size={20} color={theme.onSurfaceVariant} />
          )}
        </Pressable>
      ) : null}
      {expanded || alwaysExpanded ? (
        <View style={profileOptionStyles.options}>
          {(['war', 'raid'] as const).map((type) => (
            <ProfileOptionSwitch
              key={type}
              icon={
                <MobileWebImage
                  imageUrl={type === 'war' ? ImageAssets.war : ImageAssets.raidAttacks}
                  style={styles.image}
                />
              }
              title={
                type === 'war' ? t('clanWarNotificationsTitle') : t('clanCapitalNotificationsTitle')
              }
              subtitle={
                type === 'war' ? t('clanWarNotificationsBody') : t('clanCapitalNotificationsBody')
              }
              trailing={
                controls.settings ? (
                  <CKText muted role="metadata">
                    {controls.settings.usage[type]}/{controls.settings.limits[type]}
                  </CKText>
                ) : null
              }
              value={
                type === 'war' ? (selected?.warEnabled ?? false) : (selected?.raidEnabled ?? false)
              }
              enabled={!busy && !!controls.settings}
              loading={busy}
              onChange={(value) => void change(type, value)}
            />
          ))}
        </View>
      ) : null}
    </View>
  );
}
const styles = StyleSheet.create({
  image: { width: 24, height: 24, resizeMode: 'contain' },
});
