import { fireEvent, render, waitFor } from '@testing-library/react-native';
import { Linking } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { I18nProvider } from '../../i18n';
import { CKThemeProvider } from '../../ui';
import { BasesArmiesScreen } from './bases-armies-root';
import type { PersonalBasesServiceContract, PersonalBasesState } from './personal-bases-service';

jest.mock('../../core/app/runtime-context', () => ({ useAppRuntime: jest.fn() }));

const base = {
  id: '9223372036854775807',
  baseLink: 'https://link.clashofclans.com/en?action=OpenLayout&id=TH17',
  images: ['https://api.clashk.ing/v2/media/base.png'],
  description: 'First base',
  createdAt: '2026-09-11T00:00:00.000Z',
  serverId: '1',
  channelId: '2',
  messageId: '3',
  discordMessageUrl: 'https://discord.com/channels/1/2/3',
  downloadCount: 4,
  upvotes: 3,
  downvotes: 0,
  kind: null,
  saved: false,
  savedAt: null,
  downloadedAt: '2026-09-11T01:00:00.000Z',
} as const;

const empty: PersonalBasesState = { items: [] };
const downloaded: PersonalBasesState = { items: [base] };
const saved: PersonalBasesState = {
  items: [{ ...base, kind: 'war', saved: true, savedAt: '2026-09-11T02:00:00.000Z' }],
};

function service(
  overrides: Partial<PersonalBasesServiceContract> = {},
): PersonalBasesServiceContract {
  return {
    load: jest.fn().mockResolvedValue(downloaded),
    save: jest.fn().mockResolvedValue(saved),
    unsave: jest.fn().mockResolvedValue(downloaded),
    deleteOld: jest.fn().mockResolvedValue(saved),
    ...overrides,
  };
}

function screen(api: PersonalBasesServiceContract) {
  return render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <BasesArmiesScreen onBack={jest.fn()} service={api} />
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );
}

test('loads downloaded bases and opens the canonical layout link', async () => {
  const api = service();
  const view = await screen(api);
  expect(await view.findByText('First base')).toBeTruthy();
  expect(api.load).toHaveBeenCalledTimes(1);

  const open = jest.spyOn(Linking, 'openURL').mockResolvedValue(true);
  await fireEvent.press(view.getByText('Open'));
  expect(open).toHaveBeenCalledWith(base.baseLink);
  open.mockRestore();
  await view.unmount();
});

test('renders empty base and account states', async () => {
  const emptyView = await screen(service({ load: jest.fn().mockResolvedValue(empty) }));
  await waitFor(() => expect(emptyView.getAllByTestId('empty-state')).toHaveLength(2));
  await emptyView.unmount();
});

test('renders failed loads with a retry action', async () => {
  const load = jest.fn().mockRejectedValueOnce(new Error('offline')).mockResolvedValue(empty);
  const errorView = await screen(service({ load }));
  expect(await errorView.findByText('Error')).toBeTruthy();
  await fireEvent.press(errorView.getByText('Retry'));
  await waitFor(() => expect(load).toHaveBeenCalledTimes(2));
  await errorView.unmount();
});

test('uses authoritative save and unsave responses', async () => {
  const api = service();
  const view = await screen(api);
  await view.findAllByText('First base');
  await fireEvent.press(view.getByText('Save'));
  await waitFor(() => expect(api.save).toHaveBeenCalledWith(base.id, null));
  expect(await view.findByText('Remove bookmark')).toBeTruthy();
  await fireEvent.press(view.getByText('Remove bookmark'));
  await waitFor(() => expect(api.unsave).toHaveBeenCalledWith(base.id));
  await view.unmount();
});

test('relabels and clears the optional kind on a saved base', async () => {
  const api = service({
    load: jest.fn().mockResolvedValue(saved),
    save: jest.fn().mockResolvedValue(saved),
  });
  const view = await screen(api);
  await view.findAllByText('First base');

  await fireEvent.press(view.getByLabelText(`#${base.id} kind`));
  await fireEvent.press(view.getByRole('radio', { name: 'Legend League' }));
  await waitFor(() => expect(api.save).toHaveBeenCalledWith(base.id, 'legend'));

  await fireEvent.press(view.getByLabelText(`#${base.id} kind`));
  await fireEvent.press(view.getByRole('radio', { name: 'Clear' }));
  await waitFor(() => expect(api.save).toHaveBeenCalledWith(base.id, null));
  await view.unmount();
});

test('confirms the exact old-base count, runs fixed cleanup, and refreshes history', async () => {
  const oldSaved: PersonalBasesState = {
    items: [
      { ...base, id: '1', saved: true, savedAt: '2026-01-01T00:00:00.000Z' },
      { ...base, id: '2', saved: true, savedAt: '2026-02-01T00:00:00.000Z' },
      { ...base, id: '3', saved: false, savedAt: null },
    ],
  };
  const load = jest.fn().mockResolvedValue(oldSaved);
  const deleteOld = jest.fn().mockResolvedValue({ items: [oldSaved.items[2]!] });
  const api = service({ load, deleteOld });
  const view = await screen(api);
  await view.findAllByText('First base');

  fireEvent.press(view.getByRole('button', { name: 'Remove bases older than 90 days' }));
  expect(
    await view.findByText(
      '2 saved bases older than 90 days will be removed. Download history and shared bases will remain.',
    ),
  ).toBeTruthy();
  fireEvent.press(view.getByRole('button', { name: 'Confirm' }));
  await waitFor(() => expect(deleteOld).toHaveBeenCalledTimes(1));
  await waitFor(() => expect(load).toHaveBeenCalledTimes(2));
  await view.unmount();
});
