import { act, fireEvent, render, waitFor } from '@testing-library/react-native';
import { AppState } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { createDefaultNotificationPreferences } from '../../../core/dto/notification-preferences';
import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import type { NotificationSettingsPresentationService } from './contracts';
import { NotificationSettingsScreen } from './notification-settings-screen';

function service(): jest.Mocked<NotificationSettingsPresentationService> {
  return {
    loadLocal: jest.fn(async () => createDefaultNotificationPreferences()),
    load: jest.fn(async () => createDefaultNotificationPreferences()),
    save: jest.fn(async (preferences) => preferences),
    initializePush: jest.fn(async () => ({ state: 'permissionRequired' as const })),
    enablePush: jest.fn(async () => ({ state: 'ready' as const, token: 'private-token' })),
    openSystemSettings: jest.fn(async () => undefined),
    testNotificationTypes: [
      { id: 'legend-defense', labelKey: 'notifGroupLegendDefenses' },
      { id: 'raid-reminder', labelKey: 'notifGroupRaidReminders' },
    ],
    sendTestNotification: jest.fn(async (id) => `Preview ${id}`),
  };
}

function screenFor(source: NotificationSettingsPresentationService, debugEnabled = false) {
  return render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 0, right: 0, bottom: 0, left: 0 },
      }}
    >
      <I18nProvider locale="en">
        <CKThemeProvider preference="dark">
          <NotificationSettingsScreen service={source} debugEnabled={debugEnabled} />
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );
}

beforeEach(() => {
  jest.spyOn(AppState, 'addEventListener').mockReturnValue({ remove: jest.fn() });
});

afterEach(() => jest.restoreAllMocks());

it('requests first permission only after a tap and never displays the device token', async () => {
  const source = service();
  const screen = await screenFor(source);
  await waitFor(() => expect(screen.getByText('Receive notifications')).toBeTruthy());
  expect(source.enablePush).not.toHaveBeenCalled();
  await fireEvent.press(screen.getByText('Receive notifications'));
  await waitFor(() => expect(source.enablePush).toHaveBeenCalledTimes(1));
  expect(screen.queryByText('private-token')).toBeNull();
  expect(
    screen.getAllByRole('switch').map((item) => item.props.accessibilityState.checked),
  ).toEqual([true, true, true, true, false, false]);
});

it('refreshes permission on return from system settings without asking again', async () => {
  let resume: ((state: 'active') => void) | undefined;
  const remove = jest.fn();
  const listener = jest
    .spyOn(AppState, 'addEventListener')
    .mockImplementation((_event, callback) => {
      resume = callback;
      return { remove };
    });
  const source = service();
  source.initializePush.mockResolvedValue({ state: 'permissionDenied' });
  const screen = await screenFor(source);
  await waitFor(() => expect(screen.getByText('Open notification settings')).toBeTruthy());
  await fireEvent.press(screen.getByText('Open notification settings'));
  expect(source.openSystemSettings).toHaveBeenCalledTimes(1);
  source.initializePush.mockResolvedValue({ state: 'ready', token: 'private-token' });
  await act(async () => resume?.('active'));
  await waitFor(() => expect(source.initializePush).toHaveBeenCalledTimes(2));
  expect(source.enablePush).not.toHaveBeenCalled();
  await screen.unmount();
  expect(remove).toHaveBeenCalled();
  listener.mockRestore();
});

it('sends the selected preview type and hides local testing outside debug builds', async () => {
  const source = service();
  const normal = await screenFor(source);
  await waitFor(() => expect(normal.getByText('Receive notifications')).toBeTruthy());
  expect(normal.queryByText('Notification type')).toBeNull();
  await normal.unmount();
  const debug = await screenFor(source, true);
  await waitFor(() =>
    expect(debug.getByRole('button', { name: 'Notification type' })).toBeTruthy(),
  );
  await fireEvent.press(debug.getByRole('button', { name: 'Notification type' }));
  const choices = debug.getAllByText('Raid Weekend reminders');
  await fireEvent.press(choices[choices.length - 1]!);
  await fireEvent.press(debug.getByText('Send test notification'));
  expect(source.sendTestNotification).toHaveBeenCalledWith('raid-reminder');
});
