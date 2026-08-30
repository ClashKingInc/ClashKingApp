import { ArrowLeft, ArrowRight, Heart } from 'lucide-react-native';
import { useEffect, useState } from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';

import { useAppRuntime } from '../../core/app/runtime-context';
import { materialBackLabel, useI18n } from '../../i18n';
import { CKText, HeaderIconButton, Surface, ckSpacing, colorWithAlpha, useCKTheme } from '../../ui';
import type { SubscriptionStatus } from './subscription-status';

/** Exact replacement for Flutter's intentionally read-only subscription page. */
export function SubscriptionRoot({ onBack }: { readonly onBack: () => void }) {
  const runtime = useAppRuntime();
  const { t, isRtl, locale } = useI18n();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  const [status, setStatus] = useState<SubscriptionStatus>();
  const backDirection = subscriptionBackDirection(isRtl);

  useEffect(() => {
    let current = true;
    void runtime.subscription
      .load()
      .then((value) => {
        if (current) setStatus(value);
      })
      .catch(() => {
        // Flutter leaves the public price visible when status loading fails.
      });
    return () => {
      current = false;
    };
  }, [runtime]);

  return (
    <SafeAreaView style={[styles.safe, { backgroundColor: theme.background }]}>
      <View style={[styles.header, { backgroundColor: theme.surface }]}>
        <HeaderIconButton
          glass={false}
          icon={
            backDirection === 'rtl' ? (
              <ArrowRight color={theme.onSurface} size={24} />
            ) : (
              <ArrowLeft color={theme.onSurface} size={24} />
            )
          }
          label={materialBackLabel(locale)}
          onPress={onBack}
        />
        <CKText role="sectionTitle" numberOfLines={1} style={styles.title}>
          {t('drawerSubscription')}
        </CKText>
        <View style={styles.headerSpacer} />
      </View>
      <ScrollView
        contentContainerStyle={[styles.scroll, { paddingBottom: insets.bottom + ckSpacing.xl }]}
      >
        <Surface radius={18} style={styles.card}>
          <CKText role="screenTitle">
            {status?.active === true ? 'Active subscription' : '$6.99/month'}
          </CKText>
          <View style={styles.benefit}>
            <Heart color={theme.primary} size={22} />
            <CKText style={styles.benefitCopy}>
              Notifications for up to 10 bookmarked players and $5 of roster assistant usage each
              month.
            </CKText>
          </View>
          <CKText muted role="bodySmall">
            Subscriptions cannot be purchased or managed in the app right now.
          </CKText>
        </Surface>
      </ScrollView>
    </SafeAreaView>
  );
}

export function subscriptionBackDirection(isRtl: boolean): 'ltr' | 'rtl' {
  return isRtl ? 'rtl' : 'ltr';
}

const styles = StyleSheet.create({
  safe: { flex: 1 },
  header: {
    minHeight: 56,
    flexDirection: 'row',
    alignItems: 'center',
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: colorWithAlpha('#808080', 0.2),
  },
  title: { flex: 1 },
  headerSpacer: { width: 44 },
  scroll: {
    width: '100%',
    maxWidth: 1200,
    alignSelf: 'center',
    paddingHorizontal: 16,
    paddingTop: 12,
  },
  card: { padding: 18, gap: 14 },
  benefit: { flexDirection: 'row', alignItems: 'flex-start', gap: 10 },
  benefitCopy: { flex: 1, lineHeight: 24 },
});
