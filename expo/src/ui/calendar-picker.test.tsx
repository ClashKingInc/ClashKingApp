import { fireEvent, render } from '@testing-library/react-native';
import { I18nProvider } from '../i18n';
import { CKThemeProvider } from './theme';
import { CalendarPicker } from './calendar-picker';

test('disables unsupported snapshot days and keeps valid Mondays selectable', async () => {
  const onChange = jest.fn();
  const screen = await render(
    <I18nProvider locale="en">
      <CKThemeProvider preference="dark">
        <CalendarPicker
          start={new Date(2026, 8, 23)}
          minimum={new Date(2026, 8, 1)}
          maximum={new Date(2026, 8, 23)}
          isDateSelectable={(date) => date.getDay() === 1}
          onChange={onChange}
        />
      </CKThemeProvider>
    </I18nProvider>,
  );
  expect(screen.getByRole('button', { name: '22' }).props.accessibilityState).toMatchObject({
    disabled: true,
    selected: false,
  });
  expect(screen.getByRole('button', { name: '23' }).props.accessibilityState).toMatchObject({
    disabled: true,
    selected: false,
  });
  await fireEvent.press(screen.getByRole('button', { name: '22' }));
  expect(onChange).not.toHaveBeenCalled();
  await fireEvent.press(screen.getByRole('button', { name: '21' }));
  expect(onChange).toHaveBeenCalledWith(new Date(2026, 8, 21));
  expect(screen.getByRole('button', { name: '28' }).props.accessibilityState).toMatchObject({
    disabled: true,
  });
});
