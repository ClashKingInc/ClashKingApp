/** English-first tutorial editorial copy, separate from the translated app controls. */
export const tutorialCopy = {
  tutorialWelcomeTitle: 'Welcome to your village',
  tutorialWelcomeBody:
    'Your accounts are linked. Let me show you a few shortcuts. You can try each one, continue without changing anything, or leave the tour whenever you like.',
  tutorialReorderTitle: 'Make Home your own',
  tutorialReorderBody:
    'Hold a card for a moment, then drag it to a new spot. This also works in the Players, Clans and War lists. Your order is saved.',
  tutorialSidebarTitle: 'There is more in the sidebar',
  tutorialSidebarBody:
    'Tap your avatar and menu badge to open the sidebar. You can also swipe in from the edge where supported.',
  tutorialExploreTitle: 'Your tools live here',
  tutorialExploreBody:
    'Find rankings, calculators and settings here. Next, let us visit notification settings. Nothing will be enabled automatically.',
  tutorialWebExploreBody:
    'Find rankings, calculators and settings here. Notifications are available in the mobile app. Next, let’s try a clan page.',
  tutorialPermissionTitle: 'Notifications are your choice',
  tutorialPermissionBody:
    'Use this control if you want alerts on this device. You can say no and still use the app. You decide which alerts to receive below.',
  tutorialEntitiesTitle: 'Choose players and clans',
  tutorialEntitiesBody:
    'Use the Players and Clans tabs to manage linked players, their clans and bookmarked clans. Open a clan for its notification options.',
  tutorialRemindersTitle: 'Set reminders that help you',
  tutorialRemindersBody:
    'Choose your alert types and war or raid reminder times. Try the controls if you like; only your own changes are saved. You can return here from Settings anytime.',
  tutorialBookmarksTitle: 'Bookmarking clans',
  tutorialBookmarksBody:
    'Bookmarks give you quick access to a clan’s wars and notification settings. You can try the button here, or just continue.',
  tutorialClanPagesTitle: 'One clan, more pages',
  tutorialClanPagesBody:
    'This menu switches between a clan’s members, wars, statistics and history. Try another page here.',
  tutorialExampleClan: 'Open example clan',
  tutorialNotNow: 'Not now',
  tutorialResetTitle: 'Reset Tutorials',
  tutorialResetDone: 'Tutorials reset. They will appear on your next visits.',
} as const;
export type TutorialTextKey = keyof typeof tutorialCopy;
