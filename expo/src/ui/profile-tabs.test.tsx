import { fireEvent, render } from '@testing-library/react-native';

import { ProfileTabs } from './profile-tabs';

const tabs = [
  'Troops', 'Spells', 'Siege Machines', 'Heroes', 'Pets',
  'Equipment', 'Equipment pairs', 'Pet combinations', 'Pet → Hero',
].map((label, index) => ({ key: String(index), label }));

test('keeps every category available in a horizontally scrollable underline tab bar', async () => {
  const onSelect = jest.fn();
  const view = await render(
    <ProfileTabs
      variant="underline"
      overflow="scroll"
      tabs={tabs}
      selectedKey="0"
      onSelect={onSelect}
    />,
  );
  expect(view.getByTestId('profile-tabs-underline-scroll').props.horizontal).toBe(true);
  expect(view.getAllByRole('tab')).toHaveLength(9);
  expect(view.getByRole('tab', { name: 'Troops' }).props.accessibilityState.selected).toBe(true);
  fireEvent.press(view.getByRole('tab', { name: 'Pet combinations' }));
  expect(onSelect).toHaveBeenCalledWith('7');
});

test('retains the regular fixed-width underline layout for short tab groups', async () => {
  const view = await render(
    <ProfileTabs
      variant="underline"
      tabs={tabs.slice(0, 3)}
      selectedKey="1"
      onSelect={jest.fn()}
    />,
  );
  expect(view.getByTestId('profile-tabs-underline')).toBeTruthy();
  expect(view.queryByTestId('profile-tabs-underline-scroll')).toBeNull();
  expect(view.getByRole('tab', { name: 'Spells' }).props.accessibilityState.selected).toBe(true);
});
