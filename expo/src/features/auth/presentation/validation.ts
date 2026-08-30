export type PasswordCriteria = {
  minLength: boolean;
  uppercase: boolean;
  lowercase: boolean;
  number: boolean;
  special: boolean;
};

const EMAIL_PATTERN = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
// Flutter registration deliberately accepts this narrower set. Keep this
// separate from any server-side password policy so the two clients present
// the same validation result.
const SPECIAL_PATTERN = /[!@#$%^&*(),.?":{}|<>]/;
const RESET_PASSWORD_PATTERN = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/;

export function isValidEmail(value: string): boolean {
  return EMAIL_PATTERN.test(value);
}

export function passwordCriteria(value: string): PasswordCriteria {
  return {
    minLength: value.length >= 8,
    uppercase: /[A-Z]/.test(value),
    lowercase: /[a-z]/.test(value),
    number: /\d/.test(value),
    special: SPECIAL_PATTERN.test(value),
  };
}

export function isValidPassword(value: string): boolean {
  const criteria = passwordCriteria(value);
  return criteria.uppercase && criteria.lowercase && criteria.number && criteria.special;
}

/** Matches ResetPasswordPage's intentionally narrower TextFormField validator. */
export function isValidResetPassword(value: string): boolean {
  return RESET_PASSWORD_PATTERN.test(value);
}

export function normalizePlayerTag(value: string): string {
  const normalized = value
    .trim()
    .toUpperCase()
    .replace(/[^A-Z0-9#]/g, '');
  if (normalized.length === 0) return '';
  return normalized.startsWith('#') ? normalized : `#${normalized}`;
}

export function isSixDigitCode(value: string): boolean {
  return /^\d{6}$/.test(value);
}
