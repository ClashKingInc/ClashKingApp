import { fireEvent, render, waitFor } from '@testing-library/react-native';

import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import type { ConnectedApplicationGrantItem, ConnectedApplicationsServiceContract } from '../data';
import { ConnectedApplicationsScreen } from './connected-applications-screen';

jest.mock('../../../ui/accessibility', () => ({
  useCKAccessibility: () => ({
    reduceMotion: false,
    reduceTransparency: false,
    highContrast: false,
  }),
}));

const selected: ConnectedApplicationGrantItem = {
  application: { id: 'selected-app', name: 'War Planner', developerName: 'Example Studio' },
  grant: {
    accessMode: 'selected',
    selectedPlayerTags: ['#ONE', '#TWO'],
    connectedAt: '2026-08-31T12:00:00Z',
    updatedAt: '2026-09-01T12:00:00Z',
  },
};
const allAccounts: ConnectedApplicationGrantItem = {
  application: { id: 'all-app', name: 'Clan Tools' },
  grant: {
    accessMode: 'all_current_and_future',
    selectedPlayerTags: [],
    connectedAt: '2026-08-30T12:00:00Z',
    updatedAt: '2026-08-30T12:00:00Z',
  },
};

function wrapped(service: ConnectedApplicationsServiceContract) {
  return (
    <I18nProvider locale="en">
      <CKThemeProvider preference="light">
        <ConnectedApplicationsScreen onBack={jest.fn()} service={service} />
      </CKThemeProvider>
    </I18nProvider>
  );
}

it('shows application, developer, selected tags, and all-account access summaries', async () => {
  const screen = await render(
    wrapped({ load: async () => [selected, allAccounts], revoke: async () => undefined }),
  );
  await waitFor(() => expect(screen.getByText('War Planner')).toBeTruthy());
  expect(screen.getByText('Example Studio')).toBeTruthy();
  expect(screen.getByText('2 selected accounts')).toBeTruthy();
  expect(screen.getByText('#ONE, #TWO')).toBeTruthy();
  expect(screen.getByText('Clan Tools')).toBeTruthy();
  expect(screen.getByText('All current and future linked accounts')).toBeTruthy();
});

it('shows a useful empty state', async () => {
  const screen = await render(wrapped({ load: async () => [], revoke: async () => undefined }));
  await waitFor(() => expect(screen.getByText('No connected apps')).toBeTruthy());
  expect(screen.getByText('Applications you connect will appear here.')).toBeTruthy();
});

it('retries an initial loading error', async () => {
  const load = jest.fn<Promise<readonly ConnectedApplicationGrantItem[]>, []>();
  load.mockRejectedValueOnce(new Error('offline')).mockResolvedValueOnce([]);
  const screen = await render(wrapped({ load, revoke: async () => undefined }));
  await waitFor(() => expect(screen.getByText('Could not load connected apps')).toBeTruthy());
  await fireEvent.press(screen.getByRole('button', { name: 'Retry' }));
  await waitFor(() => expect(screen.getByText('No connected apps')).toBeTruthy());
  expect(load).toHaveBeenCalledTimes(2);
});

it('removes a connection only after a successful revoke and blocks duplicate confirmation', async () => {
  let resolveRevoke!: () => void;
  const revoke = jest.fn(
    () =>
      new Promise<void>((resolve) => {
        resolveRevoke = resolve;
      }),
  );
  const screen = await render(wrapped({ load: async () => [selected], revoke }));
  await waitFor(() => expect(screen.getByText('War Planner')).toBeTruthy());
  await fireEvent.press(screen.getByRole('button', { name: 'Disconnect' }));
  const confirm = screen.getAllByRole('button', { name: 'Disconnect' }).at(-1)!;
  await fireEvent.press(confirm);
  await fireEvent.press(confirm);
  expect(revoke).toHaveBeenCalledTimes(1);
  expect(screen.getByText('War Planner')).toBeTruthy();
  resolveRevoke();
  await waitFor(() => expect(screen.queryByText('War Planner')).toBeNull());
  expect(screen.getByText('Disconnected War Planner.')).toBeTruthy();
});

it('keeps the connection and reports a failed revoke', async () => {
  const revoke = jest.fn(async () => {
    throw new Error('server failed');
  });
  const screen = await render(wrapped({ load: async () => [selected], revoke }));
  await waitFor(() => expect(screen.getByText('War Planner')).toBeTruthy());
  await fireEvent.press(screen.getByRole('button', { name: 'Disconnect' }));
  await fireEvent.press(screen.getAllByRole('button', { name: 'Disconnect' }).at(-1)!);
  await waitFor(() =>
    expect(screen.getByText('Could not disconnect War Planner. Try again.')).toBeTruthy(),
  );
  expect(screen.getByText('War Planner')).toBeTruthy();
});
