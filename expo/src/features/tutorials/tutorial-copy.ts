import type { MessageKey } from '../../i18n/catalogs.generated';

/** Tutorial copy uses the same generated locale catalog as all other controls. */
export const tutorialCopy = {
  tutorialWelcomeTitle: 'accountsWelcome',
  tutorialWelcomeBody: 'tutorialWelcomeBody',
  tutorialReorderTitle: 'homeWidgetsEdit',
  tutorialReorderBody: 'tutorialReorderBody',
  tutorialSidebarTitle: 'navigationOpenProfileMenu',
  tutorialSidebarBody: 'tutorialSidebarBody',
  tutorialExploreTitle: 'generalSettings',
  tutorialExploreBody: 'tutorialExploreBody',
  tutorialWebExploreBody: 'settingsNotificationsSubtitle',
  tutorialPermissionTitle: 'settingsNotificationsTitle',
  tutorialPermissionBody: 'notificationPrimerBody',
  tutorialEntitiesTitle: 'settingsNotificationsTitle',
  tutorialEntitiesBody: 'faqNotificationsAnswer',
  tutorialRemindersTitle: 'notifGroupReminders',
  tutorialRemindersBody: 'tutorialRemindersBody',
  tutorialNotNow: 'notificationPrimerNotNow',
  tutorialResetTitle: 'tutorialResetTitle',
  tutorialResetDone: 'generalSuccess',
} as const satisfies Record<string, MessageKey>;
export type TutorialTextKey = keyof typeof tutorialCopy;
