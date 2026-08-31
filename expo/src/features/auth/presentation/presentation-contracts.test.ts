import { verifiedAccountDestination } from './contracts';
import {
  isSixDigitCode,
  isValidEmail,
  isValidPassword,
  isValidResetPassword,
  normalizePlayerTag,
  passwordCriteria,
} from './validation';
import { localizedRegistrationError } from './register-screen';

const account = (isVerified: boolean) => ({
  playerTag: isVerified ? '#VERIFIED' : '#PENDING',
  isVerified,
  hidden: false,
  raw: {},
});

describe('auth presentation contracts', () => {
  it('uses a verified link for every post-auth home destination', () => {
    expect(verifiedAccountDestination([])).toBe('account-setup');
    expect(verifiedAccountDestination([account(false)])).toBe('account-setup');
    expect(verifiedAccountDestination([account(false), account(true)])).toBe('home');
  });

  it('matches Flutter email, password, code, and tag validation', () => {
    expect(isValidEmail('person@example.com')).toBe(true);
    expect(isValidEmail('person@localhost')).toBe(false);
    expect(passwordCriteria('Aa1!aaaa')).toEqual({
      minLength: true,
      uppercase: true,
      lowercase: true,
      number: true,
      special: true,
    });
    expect(isValidPassword('Aa1!aaaa')).toBe(true);
    expect(isValidPassword('Aa1!')).toBe(true);
    expect(isValidPassword('Aa1_aaaa')).toBe(false);
    expect(isValidPassword('password')).toBe(false);
    expect(isValidResetPassword('Aa1!')).toBe(true);
    expect(isValidResetPassword('Aa1^')).toBe(false);
    expect(isSixDigitCode('123456')).toBe(true);
    expect(isSixDigitCode('12345x')).toBe(false);
    expect(normalizePlayerTag(' abc-123 ')).toBe('#ABC123');
  });

  it('maps every reachable Flutter registration error without leaking API copy', () => {
    const translate = (key: string) => `translated:${key}`;
    expect(
      localizedRegistrationError('{"detail":"invalid email format"}', translate as never),
    ).toBe('translated:authErrorEmailInvalidFormat');
    expect(
      localizedRegistrationError('password must be at least 8 characters', translate as never),
    ).toBe('translated:authPasswordTooShort');
    expect(
      localizedRegistrationError('username can only contain letters', translate as never),
    ).toBe('translated:authErrorUsernameInvalid');
    expect(localizedRegistrationError('too many attempts', translate as never)).toBe(
      'translated:authErrorRateLimited',
    );
    expect(localizedRegistrationError('unrecognized backend wording', translate as never)).toBe(
      'translated:authErrorRegistrationFailed',
    );
  });
});
