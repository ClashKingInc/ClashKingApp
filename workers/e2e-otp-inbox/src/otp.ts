import PostalMime from 'postal-mime';

const OTP_PATTERN = /(?:^|\D)(\d{6})(?!\d)/g;
const OTP_CONTEXT_PATTERN = /(?:verification|verify|security|one[- ]time|otp|code|password)/i;

export function normalizeEmail(value: string): string | null {
  const normalized = value.trim().toLowerCase();
  if (normalized.length > 254 || !/^[a-z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-z0-9.-]+$/.test(normalized)) {
    return null;
  }
  return normalized;
}

export function isRecipientForDomain(recipient: string, domain: string): boolean {
  const normalized = normalizeEmail(recipient);
  return normalized !== null && normalized.endsWith(`@${domain.toLowerCase()}`);
}

export function extractOtpFromText(...parts: Array<string | null | undefined>): string | null {
  const candidates = parts.filter((part): part is string => Boolean(part));
  const contextual = candidates.find((part) => OTP_CONTEXT_PATTERN.test(part));

  for (const part of contextual ? [contextual, ...candidates] : candidates) {
    OTP_PATTERN.lastIndex = 0;
    const match = OTP_PATTERN.exec(part);
    if (match) return match[1];
  }
  return null;
}

export async function extractOtp(raw: ArrayBuffer): Promise<string | null> {
  const parsed = await PostalMime.parse(raw);
  return extractOtpFromText(parsed.subject, parsed.text, parsed.html);
}

export async function secretsMatch(provided: string, expected: string): Promise<boolean> {
  const encoder = new TextEncoder();
  const [providedHash, expectedHash] = await Promise.all([
    crypto.subtle.digest('SHA-256', encoder.encode(provided)),
    crypto.subtle.digest('SHA-256', encoder.encode(expected)),
  ]);
  return crypto.subtle.timingSafeEqual(providedHash, expectedHash);
}
