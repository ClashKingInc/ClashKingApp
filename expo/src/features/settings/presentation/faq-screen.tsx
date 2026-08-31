import { useMemo, useState } from 'react';
import { Modal, Pressable, StyleSheet, TextInput, View } from 'react-native';
import {
  Bot,
  BellRing,
  Bug,
  ChartNoAxesColumn,
  ChevronDown,
  ChevronUp,
  Circle,
  CloudOff,
  Hammer,
  Heart,
  HelpCircle,
  Info,
  Languages,
  ListChecks,
  PanelsTopLeft,
  Search,
  Shield,
  ShieldQuestion,
  Smartphone,
  Swords,
  Terminal,
  TriangleAlert,
  Trophy,
  UserCog,
  UserRound,
  UserRoundCheck,
  UsersRound,
  X,
} from 'lucide-react-native';

import { useI18n, type MessageKey } from '../../../i18n';
import { CKText, Snackbar, Surface, ckRadius, ckSpacing, useCKTheme } from '../../../ui';
import type { ExternalSettingsActions } from './contracts';
import { SettingsPage } from './settings-components';

type FaqAction = { action: keyof ExternalSettingsActions; label: MessageKey };
type FaqEntry = {
  id: string;
  section: MessageKey;
  question: MessageKey;
  body: readonly MessageKey[];
  action?: keyof ExternalSettingsActions;
  actionLabel?: MessageKey;
  actions?: readonly FaqAction[];
  keywords?: readonly string[];
};
export const FAQ_ENTRIES: readonly FaqEntry[] = [
  {
    id: 'project',
    section: 'faqSectionGettingStarted',
    question: 'faqWhatIsClashKingProject',
    body: ['faqWhatIsClashKingProjectAnswer'],
    action: 'openGitHub',
    actionLabel: 'faqViewOnGitHub',
  },
  {
    id: 'features',
    section: 'faqSectionGettingStarted',
    question: 'faqFeaturesGuide',
    body: [
      'faqFeaturesGuideDescription',
      'faqFeaturesPlayerTitle',
      'faqFeaturesPlayerDescription',
      'faqFeaturesClanTitle',
      'faqFeaturesClanDescription',
      'faqFeaturesWarTitle',
      'faqFeaturesWarDescription',
      'faqFeaturesLegendsTitle',
      'faqFeaturesLegendsDescription',
      'faqFeaturesCwlTitle',
      'faqFeaturesCwlDescription',
      'faqFeaturesTodoTitle',
      'faqFeaturesTodoDescription',
      'faqFeaturesUpgradeTrackerTitle',
      'faqFeaturesUpgradeTrackerDescription',
      'faqFeaturesNotificationsTitle',
      'faqFeaturesNotificationsDescription',
      'faqFeaturesWidgetsTitle',
      'faqFeaturesWidgetsDescription',
      'faqAppDevelopmentNotice',
    ],
  },
  {
    id: 'bot',
    section: 'faqSectionGettingStarted',
    question: 'faqWhatCanBotDo',
    body: [
      'faqWhatCanBotDoAnswer',
      'faqBotFeatureTracking',
      'faqBotFeatureTrackingDesc',
      'faqBotFeatureWars',
      'faqBotFeatureWarsDesc',
      'faqBotFeatureNotifications',
      'faqBotFeatureNotificationsDesc',
      'faqBotFeatureCommands',
      'faqBotFeatureCommandsDesc',
    ],
    action: 'inviteBot',
    actionLabel: 'faqInviteBotToServer',
  },
  {
    id: 'supercell',
    section: 'faqSectionGettingStarted',
    question: 'faqIsThisFromSupercell',
    body: ['faqFanContentPolicy'],
    action: 'openFanContentPolicy',
    actionLabel: 'faqSupercellFanContentPolicyLink',
  },
  {
    id: 'accounts',
    section: 'faqSectionAccountsAlertsWidgets',
    question: 'faqLinkedAccountsTitle',
    body: ['faqLinkedAccountsAnswer', 'faqLinkedAccountsSolution1', 'faqLinkedAccountsSolution2'],
  },
  {
    id: 'notifications',
    section: 'faqSectionAccountsAlertsWidgets',
    question: 'faqNotificationsTitle',
    body: [
      'faqNotificationsAnswer',
      'faqNotificationsSolution1',
      'faqNotificationsSolution2',
      'faqNotificationsSolution3',
    ],
  },
  {
    id: 'widgets',
    section: 'faqSectionAccountsAlertsWidgets',
    question: 'faqWidgetsTitle',
    body: ['faqWidgetsAnswer', 'faqWidgetsSolution1', 'faqWidgetsSolution2', 'faqWidgetsSolution3'],
  },
  {
    id: 'support',
    section: 'faqSectionSupportAndContact',
    question: 'faqSupportWork',
    body: ['faqSupportWorkAnswer', 'faqWaysToSupport'],
    actions: [
      { action: 'useCreatorCode', label: 'faqUseCodeClashKing' },
      { action: 'openPatreon', label: 'faqSupportUsOnPatreon' },
      { action: 'openDiscord', label: 'faqJoinDiscord' },
    ],
  },
  {
    id: 'contact',
    section: 'faqSectionSupportAndContact',
    question: 'faqNeedHelp',
    body: ['faqNeedHelpAnswer'],
    actions: [
      { action: 'sendEmail', label: 'faqSendEmail' },
      { action: 'openDiscord', label: 'faqJoinDiscord' },
    ],
    keywords: ['devs@clashk.ing'],
  },
  {
    id: 'privacy',
    section: 'faqSectionSupportAndContact',
    question: 'faqPrivacyDataTitle',
    body: ['faqPrivacyDataAnswer'],
    action: 'openPrivacy',
    actionLabel: 'settingsPrivacyPolicy',
  },
  {
    id: 'accuracy',
    section: 'faqTroubleshooting',
    question: 'faqWhyNotAccurate',
    body: [
      'faqClanNotTracked',
      'faqClanNotTrackedAnswer',
      'faqTrackingDown',
      'faqTrackingDownAnswer',
      'faqApiLimitation',
      'faqApiLimitationAnswer',
    ],
  },
  {
    id: 'translation',
    section: 'faqTroubleshooting',
    question: 'faqTranslationIssue',
    body: ['faqTranslationIssueAnswer'],
    action: 'openCrowdin',
    actionLabel: 'translationHelpUsTranslate',
    keywords: ['Crowdin'],
  },
  {
    id: 'sync',
    section: 'faqTroubleshooting',
    question: 'faqTroubleshootingDataTitle',
    body: [
      'faqTroubleshootingDataDescription',
      'faqTroubleshootingSolutions',
      'faqTroubleshootingDataSolution1',
      'faqTroubleshootingDataSolution2',
      'faqTroubleshootingDataSolution3',
    ],
  },
  {
    id: 'crash',
    section: 'faqTroubleshooting',
    question: 'faqTroubleshootingCrashTitle',
    body: [
      'faqTroubleshootingCrashDescription',
      'faqTroubleshootingSolutions',
      'faqTroubleshootingCrashSolution1',
      'faqTroubleshootingCrashSolution2',
      'faqTroubleshootingCrashSolution3',
      'faqTroubleshootingCrashSolution4',
      'faqContactSupport',
    ],
  },
  {
    id: 'verify',
    section: 'faqTroubleshooting',
    question: 'faqTroubleshootingAccountTitle',
    body: [
      'faqTroubleshootingAccountDescription',
      'faqTroubleshootingSolutions',
      'faqTroubleshootingAccountSolution1',
      'faqTroubleshootingAccountSolution2',
      'faqContactSupport',
    ],
  },
];

export function filterFaqEntries(
  entries: readonly FaqEntry[],
  query: string,
  translate: (key: MessageKey) => string,
): readonly FaqEntry[] {
  const needle = query.trim().toLocaleLowerCase();
  if (!needle) return entries;
  return entries.filter((entry) =>
    [
      ...[
        entry.question,
        ...entry.body,
        ...(entry.actionLabel ? [entry.actionLabel] : []),
        ...(entry.actions?.map(({ label }) => label) ?? []),
      ].map(translate),
      ...(entry.keywords ?? []),
    ].some((value) => value.toLocaleLowerCase().includes(needle)),
  );
}

export function FaqScreen({
  actions,
  onBack,
}: {
  actions: ExternalSettingsActions;
  onBack?: () => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [query, setQuery] = useState('');
  const [expanded, setExpanded] = useState<ReadonlySet<string>>(() => new Set());
  const [mailFallback, setMailFallback] = useState(false);
  const [notice, setNotice] = useState<string>();
  const showMailFallback = () => {
    setMailFallback(true);
    void actions
      .copySupportEmail()
      .then(() => setNotice(t('generalCopiedToClipboard')))
      .catch(() => undefined);
  };
  const entries = useMemo(() => filterFaqEntries(FAQ_ENTRIES, query, t), [query, t]);
  const sections = [...new Set(entries.map((entry) => entry.section))];
  return (
    <SettingsPage title={t('faqTitle')} onBack={onBack}>
      <View style={[styles.search, { borderColor: theme.outlineVariant }]}>
        <Search color={theme.onSurfaceVariant} />
        <TextInput
          accessibilityLabel={t('faqSearchHint')}
          placeholder={t('faqSearchHint')}
          placeholderTextColor={theme.onSurfaceVariant}
          value={query}
          onChangeText={setQuery}
          style={[styles.input, { color: theme.onSurface }]}
        />
        {query ? (
          <Pressable
            accessibilityLabel={t('searchClear')}
            accessibilityRole="button"
            onPress={() => setQuery('')}
          >
            <X color={theme.onSurfaceVariant} />
          </Pressable>
        ) : null}
      </View>
      {sections.map((section) => (
        <View key={section} style={styles.section}>
          {!query.trim() ? (
            <CKText muted role="titleSmall" style={styles.sectionTitle}>
              {t(section)}
            </CKText>
          ) : null}
          {entries
            .filter((entry) => entry.section === section)
            .map((entry) => {
              const open = expanded.has(entry.id);
              return (
                <Surface key={entry.id} radius={ckRadius.chip} style={styles.item}>
                  <Pressable
                    accessibilityRole="button"
                    accessibilityState={{ expanded: open }}
                    onPress={() =>
                      setExpanded((current) => {
                        const next = new Set(current);
                        if (open) next.delete(entry.id);
                        else next.add(entry.id);
                        return next;
                      })
                    }
                    style={styles.question}
                  >
                    <View style={styles.questionIcon}>
                      {faqIcon(entry.id, theme.onSurfaceVariant)}
                    </View>
                    <CKText role="bodyLarge" style={styles.questionText}>
                      {t(entry.question)}
                    </CKText>
                    {open ? (
                      <ChevronUp color={theme.onSurfaceVariant} />
                    ) : (
                      <ChevronDown color={theme.onSurfaceVariant} />
                    )}
                  </Pressable>
                  {open ? (
                    <View style={styles.answer}>
                      <FaqBody entry={entry} />
                      {entry.action && entry.actionLabel ? (
                        <Pressable
                          accessibilityRole="link"
                          onPress={actions[entry.action]}
                          style={[styles.action, { backgroundColor: theme.primary }]}
                        >
                          <CKText style={{ color: theme.onPrimary, fontWeight: '700' }}>
                            {t(entry.actionLabel)}
                          </CKText>
                        </Pressable>
                      ) : null}
                      {entry.actions ? (
                        <View style={styles.actionRow}>
                          {entry.actions.map((item) => (
                            <Pressable
                              key={item.action}
                              accessibilityRole="link"
                              onPress={() => {
                                if (item.action !== 'sendEmail') {
                                  actions[item.action]();
                                  return;
                                }
                                void Promise.resolve(actions.sendEmail())
                                  .then((opened) => {
                                    if (opened === false) showMailFallback();
                                  })
                                  .catch(showMailFallback);
                              }}
                              style={[styles.action, { backgroundColor: theme.primary }]}
                            >
                              <CKText style={{ color: theme.onPrimary, fontWeight: '700' }}>
                                {t(item.label)}
                              </CKText>
                            </Pressable>
                          ))}
                        </View>
                      ) : null}
                    </View>
                  ) : null}
                </Surface>
              );
            })}
        </View>
      ))}
      <Modal
        transparent
        animationType="fade"
        visible={mailFallback}
        onRequestClose={() => setMailFallback(false)}
      >
        <View style={styles.modalOverlay}>
          <Surface style={styles.mailDialog} accessibilityViewIsModal>
            <CKText>{t('faqCannotOpenMailClient')}</CKText>
            <Pressable
              accessibilityRole="button"
              onPress={() => {
                setMailFallback(false);
              }}
              style={styles.dialogAction}
            >
              <CKText style={{ color: theme.primary }}>{t('generalOk')}</CKText>
            </Pressable>
          </Surface>
        </View>
      </Modal>
      <Snackbar message={notice} onDismiss={() => setNotice(undefined)} />
    </SettingsPage>
  );
}

function FaqBody({ entry }: { entry: FaqEntry }) {
  const { t } = useI18n();
  const theme = useCKTheme();
  if (entry.id === 'features' || entry.id === 'bot') {
    const finalIndex = entry.id === 'features' ? entry.body.length - 1 : entry.body.length;
    return (
      <View style={styles.structuredBody}>
        <CKText>{t(entry.body[0]!)}</CKText>
        {Array.from({ length: (finalIndex - 1) / 2 }, (_, index) => {
          const title = entry.body[index * 2 + 1]!;
          const description = entry.body[index * 2 + 2]!;
          return (
            <View key={title} style={styles.featureRow}>
              <View style={[styles.featureIcon, { borderColor: theme.outlineVariant }]}>
                {featureIcon(entry.id, index, theme.onSurfaceVariant)}
              </View>
              <View style={styles.featureCopy}>
                <CKText style={styles.bold}>{t(title)}</CKText>
                <CKText muted>{t(description)}</CKText>
              </View>
            </View>
          );
        })}
        {entry.id === 'features' ? (
          <Surface muted style={styles.developmentNotice}>
            <Info color={theme.onSurfaceVariant} size={20} />
            <CKText muted role="bodySmall" style={styles.featureCopy}>
              {t(entry.body.at(-1)!)}
            </CKText>
          </Surface>
        ) : null}
      </View>
    );
  }
  if (entry.id === 'accuracy') {
    return (
      <View style={styles.structuredBody}>
        {Array.from({ length: entry.body.length / 2 }, (_, index) => (
          <View key={entry.body[index * 2]}>
            <CKText style={styles.subheading}>{t(entry.body[index * 2]!)}</CKText>
            <CKText muted>{t(entry.body[index * 2 + 1]!)}</CKText>
          </View>
        ))}
      </View>
    );
  }
  if (['sync', 'crash', 'verify'].includes(entry.id)) {
    return (
      <View style={styles.structuredBody}>
        <CKText>{t(entry.body[0]!)}</CKText>
        <CKText style={styles.bold}>{t(entry.body[1]!)}</CKText>
        {entry.body.slice(2).map((key) => (
          <View key={key} style={styles.bulletRow}>
            <Circle color={theme.primary} fill={theme.primary} size={7} />
            <CKText muted style={styles.featureCopy}>
              {t(key)}
            </CKText>
          </View>
        ))}
      </View>
    );
  }
  return (
    <View style={styles.structuredBody}>
      {entry.body.map((key, index) => (
        <CKText key={key} muted={index !== 0}>
          {t(key)}
        </CKText>
      ))}
    </View>
  );
}

function faqIcon(id: string, color: string) {
  const props = { color, size: 22 };
  if (id === 'features') return <Smartphone {...props} />;
  if (id === 'bot') return <Bot {...props} />;
  if (id === 'support') return <Heart {...props} />;
  if (id === 'contact') return <HelpCircle {...props} />;
  if (id === 'accounts') return <UserCog {...props} />;
  if (id === 'notifications') return <BellRing {...props} />;
  if (id === 'widgets') return <PanelsTopLeft {...props} />;
  if (id === 'accuracy') return <TriangleAlert {...props} />;
  if (id === 'translation') return <Languages {...props} />;
  if (id === 'sync') return <CloudOff {...props} />;
  if (id === 'crash') return <Bug {...props} />;
  if (id === 'verify') return <UserRoundCheck {...props} />;
  if (id === 'privacy') return <ShieldQuestion {...props} />;
  return <Info {...props} />;
}

function featureIcon(id: string, index: number, color: string) {
  const props = { color, size: 22 };
  if (id === 'bot') {
    return [
      <ChartNoAxesColumn key="tracking" {...props} />,
      <Swords key="wars" {...props} />,
      <BellRing key="notifications" {...props} />,
      <Terminal key="commands" {...props} />,
    ][index];
  }
  return [
    <UserRound key="player" {...props} />,
    <UsersRound key="clan" {...props} />,
    <Swords key="war" {...props} />,
    <Trophy key="legends" {...props} />,
    <Shield key="cwl" {...props} />,
    <ListChecks key="todo" {...props} />,
    <Hammer key="upgrade" {...props} />,
    <BellRing key="notifications" {...props} />,
    <PanelsTopLeft key="widgets" {...props} />,
  ][index];
}

const styles = StyleSheet.create({
  search: {
    height: 52,
    borderWidth: StyleSheet.hairlineWidth,
    borderRadius: ckRadius.control,
    paddingHorizontal: 14,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 18,
  },
  input: { flex: 1, fontSize: 16 },
  section: { gap: 8, marginBottom: 20 },
  sectionTitle: { fontWeight: '800', paddingHorizontal: 4 },
  item: { overflow: 'hidden' },
  question: {
    minHeight: 58,
    paddingHorizontal: 14,
    paddingVertical: 10,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  questionIcon: { width: 28, alignItems: 'center' },
  questionText: { flex: 1, fontWeight: '700' },
  answer: { paddingHorizontal: 14, paddingBottom: 14, gap: ckSpacing.sm },
  action: {
    alignSelf: 'flex-start',
    minHeight: 44,
    borderRadius: ckRadius.control,
    paddingHorizontal: 14,
    justifyContent: 'center',
    marginTop: 4,
  },
  actionRow: { flexDirection: 'row', flexWrap: 'wrap', gap: ckSpacing.sm },
  structuredBody: { gap: ckSpacing.md },
  featureRow: { flexDirection: 'row', alignItems: 'flex-start', gap: 12 },
  featureIcon: {
    width: 40,
    height: 40,
    borderRadius: 12,
    borderWidth: StyleSheet.hairlineWidth,
    alignItems: 'center',
    justifyContent: 'center',
  },
  featureCopy: { flex: 1 },
  bold: { fontWeight: '700' },
  subheading: { fontWeight: '700', textDecorationLine: 'underline', marginBottom: 2 },
  bulletRow: { flexDirection: 'row', alignItems: 'flex-start', gap: 10 },
  developmentNotice: { padding: 12, flexDirection: 'row', alignItems: 'center', gap: 8 },
  modalOverlay: { flex: 1, backgroundColor: '#00000066', justifyContent: 'center', padding: 24 },
  mailDialog: {
    padding: ckSpacing.lg,
    gap: ckSpacing.lg,
    maxWidth: 520,
    width: '100%',
    alignSelf: 'center',
  },
  dialogAction: {
    minHeight: 44,
    alignSelf: 'flex-end',
    justifyContent: 'center',
    paddingHorizontal: 12,
  },
});
