import { fireEvent, render, waitFor } from '@testing-library/react-native';
import lockfile from '../../../../package-lock.json';

import { I18nProvider, type SupportedLocale } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import type { ExternalSettingsActions, SettingsPresentationActions } from './contracts';
import { FaqScreen } from './faq-screen';
import { GENERATED_LICENSE_INVENTORY } from './generated-license-inventory';
import { LicensesScreen } from './licenses-screen';
import { NotificationSettingsScreen } from './notification-settings-screen';
import { SettingsScreen } from './settings-screen';
import { LinkParametersContext } from '../../../core/deep-links/link-parameters';

jest.mock('../../../core/assets/local-asset-cache', () => ({ localImageCache: { subscribe: () => () => {}, getRevision: () => 0, peek: () => undefined, clear: jest.fn() } }));

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

it('opens the requested dependency license directly without a tap', async () => {
  const view = await render(
    wrapped(
      <LinkParametersContext.Provider value={{ package: 'example' }}>
        <LicensesScreen
          applicationName="ClashKing"
          applicationVersion="0.4.2"
          onBack={jest.fn()}
          packages={[
            { packages: ['example@1.0.0'], license: 'MIT', text: 'The requested license text' },
          ]}
        />
      </LinkParametersContext.Provider>,
    ),
  );
  expect(view.getByText('The requested license text')).toBeTruthy();
});

function wrappedWithLocale(node: React.ReactNode, locale: SupportedLocale) {
  return (
    <I18nProvider locale={locale}>
      <CKThemeProvider preference="light">{node}</CKThemeProvider>
    </I18nProvider>
  );
}

it('ships complete verbatim production dependency licenses and opens their text', async () => {
  const covered = GENERATED_LICENSE_INVENTORY.flatMap(({ packages }) => packages);
  const productionPackages = Object.entries(lockfile.packages)
    .filter(
      ([path, metadata]) =>
        path.startsWith('node_modules/') &&
        !(metadata as { dev?: boolean }).dev &&
        !path.endsWith('/@clashking/native'),
    )
    .map(([path, metadata]) => {
      // npm aliases retain the actual licensed package name in lock metadata.
      // For example, @jest/react-is-18 installs the react-is package.
      const { name, version } = metadata as { name?: string; version?: string };
      return `${name ?? path.split('node_modules/').at(-1)}@${version}`;
    });
  expect([...new Set(covered)].sort()).toEqual([...new Set(productionPackages)].sort());
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

it.each(['en', 'en_GB'])('formats cache size for %s and clears images without signing out', async (currentLocale) => {
  const clearImageCache = jest.fn(async () => {});
  const logout = jest.fn(async () => {});
  const screen = await render(wrapped(
    <SettingsScreen
      actions={{ changeLocale: async () => {}, changeTheme: async () => {},
        open: jest.fn(), openDiscord: jest.fn(), showLicenses: jest.fn(),
        copyVersion: jest.fn(), logout, clearImageCache }}
      alternateIconsSupported={false} currentLocale={currentLocale} localeChoices={[]}
      notificationsEnabled={false} themeMode="dark"
      user={{ username: 'Person', email: null, avatarUrl: '' }}
      versionLabel="Version 1" imageCacheBytes={44_669_338} warWidgetsEnabled={false}
    />
  ));
  expect(screen.getByText('42.6 MB')).toBeTruthy();
  expect(screen.queryByText('Remove downloaded images from this phone. Your accounts and saved data stay unchanged.')).toBeNull();
  await fireEvent.press(screen.getByText('Clear image cache'));
  await waitFor(() => expect(screen.getByText('Image cache cleared.')).toBeTruthy());
  expect(clearImageCache).toHaveBeenCalledTimes(1);
  expect(logout).not.toHaveBeenCalled();
});

it('hides notifications on web even when enabled by the feature flag', async () => {
  const screen = await render(
    wrapped(
      <SettingsScreen
        actions={{
          changeLocale: async () => undefined,
          changeTheme: async () => undefined,
          open: jest.fn(),
          openDiscord: jest.fn(),
          showLicenses: jest.fn(),
          copyVersion: jest.fn(),
          logout: async () => undefined,
        }}
        alternateIconsSupported={false}
        currentLocale="en"
        localeChoices={[]}
        notificationsEnabled
        platform="web"
        themeMode="system"
        user={{ username: 'Person', email: null, avatarUrl: '' }}
        versionLabel="Version 0.4.2"
        warWidgetsEnabled={false}
      />,
    ),
  );
  expect(screen.queryByText('Notifications')).toBeNull();
  expect(screen.getByText('Version & Device')).toBeTruthy();
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
