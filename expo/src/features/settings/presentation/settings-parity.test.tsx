import { fireEvent, render, waitFor } from '@testing-library/react-native';

import { I18nProvider, type SupportedLocale } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import type { ExternalSettingsActions, SettingsPresentationActions } from './contracts';
import { FaqScreen } from './faq-screen';
import { GENERATED_LICENSE_INVENTORY } from './generated-license-inventory';
import { LicensesScreen } from './licenses-screen';
import { NotificationSettingsScreen } from './notification-settings-screen';
import { SettingsScreen } from './settings-screen';

jest.mock('../../../ui/accessibility', () => ({
  useCKAccessibility: () => ({
    reduceMotion: false,
    reduceTransparency: false,
    highContrast: false,
  }),
}));

function wrapped(node: React.ReactNode) {
  return (
    <I18nProvider locale="en">
      <CKThemeProvider preference="light">{node}</CKThemeProvider>
    </I18nProvider>
  );
}

function wrappedWithLocale(node: React.ReactNode, locale: SupportedLocale) {
  return (
    <I18nProvider locale={locale}>
      <CKThemeProvider preference="light">{node}</CKThemeProvider>
    </I18nProvider>
  );
}

it('ships complete verbatim production dependency licenses and opens their text', async () => {
  const covered = GENERATED_LICENSE_INVENTORY.flatMap(({ packages }) => packages);
  expect(covered.length).toBeGreaterThan(850);
  expect(covered.some((name) => name.startsWith('react@'))).toBe(true);
  expect(covered.some((name) => name.startsWith('react-native@'))).toBe(true);
  expect(GENERATED_LICENSE_INVENTORY.every(({ text }) => text.length > 40)).toBe(true);

  const sample = GENERATED_LICENSE_INVENTORY[0]!;
  const screen = await render(
    wrapped(
      <LicensesScreen
        applicationName="ClashKing"
        applicationVersion="1.2.3"
        onBack={jest.fn()}
        packages={[sample]}
      />,
    ),
  );
  await fireEvent.press(screen.getAllByRole('button')[1]!);
  await waitFor(() => expect(screen.getByText(sample.text)).toBeTruthy());
});

it('keeps notification page chrome and skeletons while hydration is pending', async () => {
  const pending = new Promise<never>(() => undefined);
  const screen = await render(
    wrapped(
      <NotificationSettingsScreen
        onBack={jest.fn()}
        service={{
          loadLocal: () => pending,
          load: () => pending,
          save: () => pending,
          lastPushResult: () => null,
          initializePush: () => pending,
          requestPermissionAndRegister: () => pending,
          tokenPreview: () => pending,
        }}
      />,
    ),
  );
  expect(screen.getByText('Notifications')).toBeTruthy();
  expect(screen.getByLabelText('Loading...')).toBeTruthy();
  expect(screen.getByRole('button', { name: 'Back' })).toBeTruthy();
});

it('copies the version with Flutter-equivalent confirmation', async () => {
  const copyVersion = jest.fn();
  const actions: SettingsPresentationActions = {
    changeLocale: async () => undefined,
    changeTheme: async () => undefined,
    open: jest.fn(),
    openDiscord: jest.fn(),
    showLicenses: jest.fn(),
    copyVersion,
    logout: async () => undefined,
  };
  const screen = await render(
    wrapped(
      <SettingsScreen
        actions={actions}
        alternateIconsSupported={false}
        currentLocale="en"
        localeChoices={[]}
        notificationsEnabled={false}
        themeMode="system"
        user={{ username: 'Person', email: null, avatarUrl: '' }}
        versionLabel={'Version 1.2.3\nDevice'}
        warWidgetsEnabled={false}
      />,
    ),
  );
  await fireEvent.press(screen.getByText('Version & Device'));
  expect(copyVersion).toHaveBeenCalledWith('Version 1.2.3\nDevice');
  await waitFor(() => expect(screen.getByText('Copied to clipboard')).toBeTruthy());
});

it('localizes the iOS war widget setup dialog', async () => {
  const actions: SettingsPresentationActions = {
    changeLocale: async () => undefined,
    changeTheme: async () => undefined,
    open: jest.fn(),
    openDiscord: jest.fn(),
    showLicenses: jest.fn(),
    copyVersion: jest.fn(),
    logout: async () => undefined,
  };
  const screen = await render(
    wrappedWithLocale(
      <SettingsScreen
        actions={actions}
        alternateIconsSupported={false}
        currentLocale="fr"
        localeChoices={[]}
        notificationsEnabled={false}
        platform="ios"
        themeMode="system"
        user={{ username: 'Personne', email: null, avatarUrl: '' }}
        versionLabel="Version 1.2.3"
        warWidgetClans={[]}
        warWidgetsEnabled
      />,
      'fr',
    ),
  );

  await fireEvent.press(screen.getByText('Ajouter un widget guerre'));
  expect(screen.getByText(/Après avoir ajouté le widget/)).toBeTruthy();
  expect(screen.getByText(/Aucun de vos comptes liés/)).toBeTruthy();
  expect(screen.getByText(/Ajoutez plusieurs widgets de guerre/)).toBeTruthy();
});

it('uses structured FAQ search and copies support email when mail launch fails', async () => {
  const copySupportEmail = jest.fn(async () => undefined);
  const actions: ExternalSettingsActions = {
    openCrowdin: jest.fn(),
    openDiscord: jest.fn(),
    openGitHub: jest.fn(),
    inviteBot: jest.fn(),
    openFanContentPolicy: jest.fn(),
    openPatreon: jest.fn(),
    useCreatorCode: jest.fn(),
    sendEmail: () => false,
    copySupportEmail,
    openPrivacy: jest.fn(),
  };
  const screen = await render(wrapped(<FaqScreen actions={actions} onBack={jest.fn()} />));
  const search = screen.getByLabelText('Search FAQ...');
  await fireEvent.changeText(search, 'Crowdin');
  expect(screen.getByText('Is a translation missing or incorrect?')).toBeTruthy();
  expect(screen.queryByText('Troubleshooting')).toBeNull();
  await fireEvent.changeText(search, 'contact you');
  await fireEvent.press(
    screen.getByRole('button', {
      name: 'I need help or want to make a suggestion. How can I contact you?',
    }),
  );
  await fireEvent.press(screen.getByRole('link', { name: 'Send an email' }));
  await waitFor(() => expect(screen.getByText(/we can't open your mail client/i)).toBeTruthy());
  await fireEvent.press(screen.getByRole('button', { name: 'OK' }));
  await waitFor(() => expect(copySupportEmail).toHaveBeenCalledTimes(1));
  expect(screen.getByText('Copied to clipboard')).toBeTruthy();
});
