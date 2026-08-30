import * as Linking from 'expo-linking';
import { useCallback, useEffect, useMemo, useRef, useState, type ReactNode } from 'react';

import { EmailVerificationRequiredException } from '../api/client';
import { canonicalTag } from '../domain/tags';
import { reportException } from '../observability/observability';
import {
  accountPresentationItem,
  ManageLinkedAccountsScreen,
} from '../../features/accounts/presentation';
import {
  EmailVerificationScreen,
  ForgotPasswordScreen,
  LoginScreen,
  RegisterScreen,
  ResetPasswordScreen,
  type PostAuthDestination,
} from '../../features/auth/presentation';
import { initializeAccountsForCurrentAuth } from '../../features/auth/startup';
import { materialContinueLabel, useI18n } from '../../i18n';
import {
  sceneForPostAuthDestination,
  sceneForStartupResult,
  type ApplicationScene,
} from './application-flow';
import { AuthenticatedRoot } from './authenticated-root';
import { NotificationPermissionPrimer } from './notification-primer';
import { useAppRuntime } from './runtime-context';
import {
  defaultIsMaintenanceError,
  defaultIsNetworkError,
  initializeApplication,
  initializeAuthenticatedPush,
} from './startup-coordinator';
import { StartupErrorScreen, MaintenanceScreen } from './startup-feedback';
import { StartupLoadingScreen } from './startup-loading';

const DISCORD_URL = 'https://discord.gg/clashking';
const SUPPORT_EMAIL_URL = 'mailto:devs@clashk.ing?subject=ClashKing%20App%20Support';
const CLASH_SETTINGS_URL = 'https://link.clashofclans.com/?action=OpenMoreSettings';

export function ApplicationRoot() {
  const runtime = useAppRuntime();
  const { locale, t } = useI18n();
  const [scene, setScene] = useState<ApplicationScene>({ kind: 'startup' });
  const [retrying, setRetrying] = useState(false);
  const [primerVisible, setPrimerVisible] = useState(false);
  const sceneRef = useRef(scene);
  const startupGeneration = useRef(0);
  const permissionTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const primerResolver = useRef<((enabled: boolean) => void) | null>(null);

  useEffect(() => {
    sceneRef.current = scene;
  }, [scene]);

  const loadAccounts = useCallback(async () => {
    const result = await initializeAccountsForCurrentAuth(runtime.auth, runtime.accounts);
    if (!result.authenticated) throw new Error('Authentication expired.');
    runtime.achievements.bindSession(runtime.auth.state.currentUser?.userId ?? null);
    void runtime.achievements
      .check()
      .catch((error) => reportException(error, 'startup.achievements'));
    const shouldPrompt = await initializeAuthenticatedPush({
      notificationsEnabled: runtime.appState.getState().isFeatureEnabled('notifications'),
      push: runtime.push,
    });
    if (shouldPrompt) {
      if (permissionTimer.current !== null) clearTimeout(permissionTimer.current);
      permissionTimer.current = setTimeout(() => {
        void runtime.push.showPermissionPrimerOnce(() =>
          runtime.notificationPreferences.setDeviceEnabled(true).then(() => undefined),
        );
      }, 1000);
    }
    return runtime.accounts.accounts;
  }, [runtime]);

  const postAuth = useMemo(
    () => ({
      loadAccounts,
      onDestination: (destination: PostAuthDestination) =>
        setScene(sceneForPostAuthDestination(destination)),
      onFailure: (error: unknown) =>
        setScene(
          defaultIsMaintenanceError(error)
            ? { kind: 'maintenance' }
            : { kind: 'error', networkError: defaultIsNetworkError(error) },
        ),
    }),
    [loadAccounts],
  );

  const runStartup = useCallback(async () => {
    const generation = ++startupGeneration.current;
    setRetrying(true);
    setScene({ kind: 'startup' });
    try {
      const result = await initializeApplication({
        preferenceMigration: runtime.preferenceMigration,
        appState: runtime.appState,
        auth: runtime.auth,
        accounts: runtime.accounts,
        gameData: runtime.gameData,
        push: runtime.push,
        initializeAuthenticatedData: async () => {
          runtime.achievements.bindSession(runtime.auth.state.currentUser?.userId ?? null);
          void runtime.achievements
            .check()
            .catch((error) => reportException(error, 'startup.achievements'));
          await runtime.warWidgets.migrateLegacyWidgetValues();
          if (runtime.appState.getState().isFeatureEnabled('war_widgets')) {
            await runtime.warWidgets.registerPeriodicRefresh();
            await runtime.warWidgets.consumePendingWidgetAction();
          }
        },
        reportError: (operation, error) => reportException(error, operation),
      });
      if (generation !== startupGeneration.current) return;
      setScene(sceneForStartupResult(result));
      if (result.requestPushPermission) {
        if (permissionTimer.current !== null) clearTimeout(permissionTimer.current);
        permissionTimer.current = setTimeout(() => {
          void runtime.push.showPermissionPrimerOnce(() =>
            runtime.notificationPreferences.setDeviceEnabled(true).then(() => undefined),
          );
        }, 1000);
      }
    } catch (error) {
      reportException(error, 'startup.bootstrap');
      if (generation === startupGeneration.current) {
        setScene({ kind: 'error', networkError: false });
      }
    } finally {
      if (generation === startupGeneration.current) setRetrying(false);
    }
  }, [runtime]);

  useEffect(() => {
    // Mounting the application root is the external event that begins bootstrap.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    void runStartup();
    return () => {
      startupGeneration.current += 1;
      if (permissionTimer.current !== null) clearTimeout(permissionTimer.current);
    };
  }, [runStartup]);

  useEffect(
    () =>
      runtime.effects.bindPermissionPrimer(
        () =>
          new Promise<boolean>((resolve) => {
            primerResolver.current?.(false);
            primerResolver.current = resolve;
            setPrimerVisible(true);
          }),
      ),
    [runtime],
  );

  useEffect(
    () =>
      runtime.auth.subscribe((authState) => {
        if (
          !authState.isAuthenticated &&
          (sceneRef.current.kind === 'home' || sceneRef.current.kind === 'account-setup')
        ) {
          setScene({ kind: 'login' });
        }
      }),
    [runtime],
  );

  useEffect(() => () => primerResolver.current?.(false), []);

  const closePrimer = (enabled: boolean) => {
    setPrimerVisible(false);
    const resolve = primerResolver.current;
    primerResolver.current = null;
    resolve?.(enabled);
  };

  let content: ReactNode;
  switch (scene.kind) {
    case 'startup':
      content = <StartupLoadingScreen />;
      break;
    case 'login':
      content = (
        <LoginScreen
          auth={runtime.auth}
          discordEnabled={runtime.discordSignInEnabled}
          isVerificationRequired={(error) => error instanceof EmailVerificationRequiredException}
          onEmailSupport={() => void openExternal(SUPPORT_EMAIL_URL)}
          onForgotPassword={() => setScene({ kind: 'forgot-password' })}
          onJoinDiscord={() => void openExternal(DISCORD_URL)}
          onMaintenance={() => setScene({ kind: 'maintenance' })}
          onRegister={() => setScene({ kind: 'register' })}
          onVerificationRequired={(email) => setScene({ kind: 'verify-email', email })}
          postAuth={postAuth}
          prefillEmail={scene.prefillEmail}
        />
      );
      break;
    case 'register':
      content = (
        <RegisterScreen
          auth={runtime.auth}
          onBackToLogin={() => setScene({ kind: 'login' })}
          onRedirect={(destination, email) => {
            if (destination === 'maintenance') setScene({ kind: 'maintenance' });
            else if (destination === 'verification') setScene({ kind: 'verify-email', email });
            else setScene({ kind: 'login', prefillEmail: email });
          }}
        />
      );
      break;
    case 'verify-email':
      content = (
        <EmailVerificationScreen
          auth={runtime.auth}
          email={scene.email}
          onBackToLogin={(prefillEmail) => setScene({ kind: 'login', prefillEmail })}
          onMaintenance={() => setScene({ kind: 'maintenance' })}
          postAuth={postAuth}
        />
      );
      break;
    case 'forgot-password':
      content = (
        <ForgotPasswordScreen
          auth={runtime.auth}
          onBackToLogin={() => setScene({ kind: 'login' })}
          onContinue={(email) => setScene({ kind: 'reset-password', email })}
        />
      );
      break;
    case 'reset-password':
      content = (
        <ResetPasswordScreen
          auth={runtime.auth}
          initialEmail={scene.email}
          onBackToLogin={() => setScene({ kind: 'login' })}
        />
      );
      break;
    case 'account-setup':
      content = (
        <ManageLinkedAccountsScreen
          continueLabel={materialContinueLabel(locale)}
          firstConnection
          initialAccounts={runtime.accounts.accounts.map((account) =>
            accountPresentationItem(
              account,
              runtime.players.profiles.find(
                (profile) => canonicalTag(profile.tag) === canonicalTag(account.playerTag),
              ),
            ),
          )}
          playerProfiles={runtime.players.profiles}
          onContinue={async () => {
            const accounts = await loadAccounts();
            if (!accounts.some((account) => account.isVerified)) {
              throw new Error(t('homeVerifiedAccountRequiredBody'));
            }
            setScene({ kind: 'home' });
          }}
          onOpenGameSettings={() => openExternal(CLASH_SETTINGS_URL)}
          onRefresh={async () => {
            await loadAccounts();
          }}
          onLogout={async () => {
            runtime.players.clearRankedLeagueCache();
            await runtime.auth.signOut();
          }}
          service={runtime.accounts}
          user={runtime.auth.state.currentUser}
        />
      );
      break;
    case 'home':
      content = <AuthenticatedRoot />;
      break;
    case 'maintenance':
      content = <MaintenanceScreen onRetry={() => void runStartup()} />;
      break;
    case 'error':
      content = (
        <StartupErrorScreen
          avatarUrl={runtime.auth.state.currentUser?.avatarUrl ?? null}
          isNetworkError={scene.networkError}
          onJoinDiscord={() => void openExternal(DISCORD_URL)}
          onLogout={() => {
            void runtime.auth.signOut().then(() => setScene({ kind: 'login' }));
          }}
          onRetry={() => void runStartup()}
          retrying={retrying}
          userName={runtime.auth.state.currentUser?.username ?? null}
        />
      );
      break;
  }

  return (
    <>
      {content}
      <NotificationPermissionPrimer
        onAllow={() => closePrimer(true)}
        onDecline={() => closePrimer(false)}
        visible={primerVisible}
      />
    </>
  );
}

async function openExternal(url: string): Promise<boolean> {
  try {
    await Linking.openURL(url);
    return true;
  } catch {
    // Flutter treats support and game links as best-effort navigation.
    return false;
  }
}
