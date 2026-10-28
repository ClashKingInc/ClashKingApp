import { useAdaptiveLayout } from '../../ui/adaptive-layout';
import { InlineBackControl } from '../../ui/native-back-context';
import { ResponsiveGrid } from '../../ui/responsive-grid';
import { useState, type ReactNode } from 'react';
import { Pressable, ScrollView, StyleSheet, View } from 'react-native';
import * as Linking from 'expo-linking';
import { SafeAreaView } from 'react-native-safe-area-context';
import { ChevronLeft, ChevronRight, Plus, UserPlus } from 'lucide-react-native';
import {
  discordServerInstallUrl,
  DISCORD_PERSONAL_INSTALL_URL,
} from '../../core/config/api-config';
import { CKText, MobileWebImage, SkeletonContent, colorWithAlpha, useCKTheme } from '../../ui';
import { useI18n } from '../../i18n';
import type { DashboardServer, DiscordServersState } from './use-discord-servers';

export type { DashboardServer } from './use-discord-servers';

export function ServersRoot({
  onBack,
  onOpenServer,
  directory,
}: {
  onBack: () => void;
  onOpenServer: (server: DashboardServer) => void;
  directory: DiscordServersState;
}) {
  const theme = useCKTheme();
  const layout = useAdaptiveLayout();
  const { t } = useI18n();
  const { servers, loading, error, hasDiscordIdentity, refresh } = directory;
  const [viewportHeight, setViewportHeight] = useState(0);
  const [contentHeight, setContentHeight] = useState(0);
  const installed = servers.filter((server) => server.has_bot);
  const installable = servers.filter((server) => !server.has_bot);
  const openInstall = (url: string) => {
    void Linking.openURL(url).catch(() => undefined);
  };
  const row = (server: DashboardServer) => (
    <Pressable
      key={server.id}
      accessibilityRole="button"
      onPress={() =>
        server.has_bot ? onOpenServer(server) : openInstall(discordServerInstallUrl(server.id))
      }
      style={[
        styles.server,
        { backgroundColor: theme.card },
        layout.isExpanded && { minHeight: 104, padding: 22, gap: 18 },
      ]}
    >
      {server.icon ? (
        <MobileWebImage
          imageUrl={server.icon}
          style={[styles.icon, layout.isExpanded && { width: 52, height: 52 }]}
        />
      ) : null}
      <View style={styles.identity}>
        <CKText role="titleSmall">{server.name}</CKText>
        <CKText muted role="labelMedium">
          {server.role}
        </CKText>
      </View>
      {server.has_bot ? (
        <ChevronRight color={theme.onSurfaceVariant} size={20} />
      ) : (
        <View style={styles.addLabel}>
          <Plus color={theme.primary} size={16} />
          <CKText skeleton={false} role="labelLarge" style={{ color: theme.primary }}>
            {t('discordAddBot')}
          </CKText>
        </View>
      )}
    </Pressable>
  );
  const cards = (children: ReactNode) =>
    layout.isExpanded ? (
      <ResponsiveGrid minItemWidth={420} maxColumns={layout.columns(420, 2)} gap={12}>
        {children}
      </ResponsiveGrid>
    ) : (
      children
    );
  const pageWidth = layout.isExpanded
    ? {
        width: '100%' as const,
        maxWidth: Math.min(1040, layout.contentMaxWidth),
        alignSelf: 'center' as const,
      }
    : undefined;
  return (
    <SafeAreaView
      edges={['top', 'left', 'right', 'bottom']}
      style={{ flex: 1, backgroundColor: theme.background }}
    >
      <View style={[styles.header, pageWidth]}>
        <InlineBackControl onBack={onBack}>
          <Pressable accessibilityRole="button" onPress={onBack} style={styles.headerAction}>
            <ChevronLeft color={theme.onSurface} />
          </Pressable>
        </InlineBackControl>
        <CKText skeleton={false} role="titleMedium" style={styles.identity}>
          {t('homeWidgetsServers')}
        </CKText>
      </View>
      <ScrollView
        contentContainerStyle={[styles.content, pageWidth]}
        onLayout={(event) => setViewportHeight(event.nativeEvent.layout.height)}
        onContentSizeChange={(_, height) => setContentHeight(height)}
        scrollEnabled={contentHeight > viewportHeight + 1}
        bounces={false}
        overScrollMode="never"
      >
        {loading && !servers.length ? (
          <SkeletonContent loading style={styles.section}>
            {[0, 1, 2].map((key) =>
              row({
                id: `loading-${key}`,
                has_bot: true,
                icon: 'loading',
                name: 'Discord server',
                role: 'Administrator',
                owner: false,
                features: [],
                inactive: false,
                permissions: '0',
                delegated: false,
              }),
            )}
          </SkeletonContent>
        ) : (
          <>
            {!hasDiscordIdentity ? (
              <View
                testID="discord-account-not-connected"
                style={[styles.connection, { backgroundColor: theme.card }]}
              >
                <CKText role="titleSmall">
                  {t('generalDiscord')} · {t('authAccountNotConnected')}
                </CKText>
                <CKText muted role="bodyMedium">
                  {t('authAccountAddDiscordAuth')}
                </CKText>
              </View>
            ) : null}
            {hasDiscordIdentity && error ? (
              <Pressable accessibilityRole="button" onPress={refresh} style={styles.headerAction}>
                <CKText>
                  {t('apiErrorServer')} · {t('generalRetry')}
                </CKText>
              </Pressable>
            ) : null}
            {installed.length > 0 ? (
              <View style={styles.section}>{cards(installed.map(row))}</View>
            ) : null}
            <View style={styles.actions}>
              <Pressable
                accessibilityRole="button"
                onPress={() => openInstall(discordServerInstallUrl())}
                style={[styles.action, { backgroundColor: colorWithAlpha(theme.primary, 0.12) }]}
              >
                <Plus color={theme.primary} size={20} />
                <CKText role="bodyMedium" style={{ color: theme.primary }}>
                  {t('drawerInviteDiscordBot')}
                </CKText>
              </Pressable>
              <Pressable
                accessibilityRole="button"
                onPress={() => openInstall(DISCORD_PERSONAL_INSTALL_URL)}
                style={[styles.action, { backgroundColor: theme.card }]}
              >
                <UserPlus color={theme.onSurface} size={20} />
                <CKText role="bodyMedium">{t('discordAddToMyDiscord')}</CKText>
              </Pressable>
            </View>
            {installable.length > 0 ? (
              <View style={styles.section}>
                <CKText skeleton={false} role="titleSmall">
                  {t('discordServersWithoutBot')}
                </CKText>
                {cards(installable.map(row))}
              </View>
            ) : null}
          </>
        )}
      </ScrollView>
    </SafeAreaView>
  );
}
const styles = StyleSheet.create({
  header: { flexDirection: 'row', alignItems: 'center', gap: 12, padding: 16 },
  headerAction: { padding: 10 },
  content: { padding: 16, gap: 20 },
  section: { gap: 12 },
  connection: { padding: 20, borderRadius: 24, gap: 8 },
  identity: { flex: 1 },
  server: { flexDirection: 'row', alignItems: 'center', gap: 14, padding: 18, borderRadius: 24 },
  icon: { width: 40, height: 40, borderRadius: 12 },
  addLabel: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  actions: { gap: 8 },
  action: {
    minHeight: 48,
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderRadius: 16,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
});
