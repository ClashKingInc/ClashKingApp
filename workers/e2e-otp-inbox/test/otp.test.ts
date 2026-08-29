import { describe, expect, it } from 'vitest';
import { extractOtp, extractOtpFromText, isRecipientForDomain, normalizeEmail, secretsMatch } from '../src/otp';

describe('OTP inbox helpers', () => {
  it('normalizes and validates E2E recipients', () => {
    expect(normalizeEmail(' Run-123@E2E-Mail.ClashK.ing ')).toBe('run-123@e2e-mail.clashk.ing');
    expect(isRecipientForDomain('run-123@e2e-mail.clashk.ing', 'e2e-mail.clashk.ing')).toBe(true);
    expect(isRecipientForDomain('run-123@example.com', 'e2e-mail.clashk.ing')).toBe(false);
  });

  it('extracts a standalone six-digit OTP from verification copy', () => {
    expect(extractOtpFromText('Verify your email', 'Your verification code is 482731.')).toBe('482731');
    expect(extractOtpFromText('Order 1234567 is ready')).toBeNull();
  });

  it('parses a MIME email once and extracts the OTP', async () => {
    const raw = await new Blob([
      'From: noreply@clashk.ing\r\nTo: run-1@e2e-mail.clashk.ing\r\nSubject: Email verification\r\n\r\nYour code is 938201.\r\n',
    ]).arrayBuffer();
    expect(await extractOtp(raw)).toBe('938201');
  });

  it('compares API tokens without an early length check', async () => {
    expect(await secretsMatch('same-token', 'same-token')).toBe(true);
    expect(await secretsMatch('wrong', 'same-token')).toBe(false);
  });
});
