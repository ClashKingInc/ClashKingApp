/** Only bounded categories leave the device; native messages can contain URLs or credentials. */
export type NetworkFailure =
  'timeout' | 'cancelled' | 'dns' | 'tls' | 'connection' | 'network' | 'unknown';
export interface RequestDiagnostics {
  readonly request_stage:
    'transport' | 'http_response' | 'response_decode' | 'request_build' | 'unknown';
  readonly network_failure?: NetworkFailure;
  readonly network_error_code?: string;
  readonly request_duration_ms?: number;
  readonly http_status?: number;
}

const NETWORK_CODES = new Set([
  'ETIMEDOUT',
  'ESOCKETTIMEDOUT',
  'ECONNABORTED',
  'ECONNRESET',
  'ECONNREFUSED',
  'ENETUNREACH',
  'EHOSTUNREACH',
  'EPIPE',
  'ENOTFOUND',
  'EAI_AGAIN',
  'ERR_NETWORK',
  'ERR_CANCELED',
  'ERR_CERT_AUTHORITY_INVALID',
  'ERR_CERT_DATE_INVALID',
  'CERT_HAS_EXPIRED',
  'UNABLE_TO_VERIFY_LEAF_SIGNATURE',
  '-999',
  '-1001',
  '-1003',
  '-1004',
  '-1005',
  '-1009',
  '-1200',
  '-1202',
]);
const STAGES = new Set([
  'transport',
  'http_response',
  'response_decode',
  'request_build',
  'unknown',
]);
const FAILURES = new Set([
  'timeout',
  'cancelled',
  'dns',
  'tls',
  'connection',
  'network',
  'unknown',
]);

export function classifyNetworkFailure(
  error: unknown,
): Pick<RequestDiagnostics, 'network_failure' | 'network_error_code'> {
  const messages: string[] = [];
  let code: string | undefined;
  const seen = new Set<object>();
  // Traverse wrapped causes without serializing objects, request bodies or native userInfo.
  for (let current = error, depth = 0; current != null && depth < 6; depth++) {
    if (typeof current === 'string') {
      messages.push(current.slice(0, 2_000));
      break;
    }
    if (typeof current !== 'object' || seen.has(current)) break;
    seen.add(current);
    const value = current as Record<string, unknown>;
    for (const key of ['name', 'message']) {
      if (typeof value[key] === 'string') messages.push(value[key].slice(0, 2_000));
    }
    const rawCode =
      typeof value.code === 'string' || typeof value.code === 'number' ? String(value.code) : '';
    if (!code && NETWORK_CODES.has(rawCode)) code = rawCode;
    current = value.cause;
  }
  const message = messages.join(' ');
  let network_failure: NetworkFailure = 'unknown';
  if (
    ['ETIMEDOUT', 'ESOCKETTIMEDOUT', '-1001'].includes(code ?? '') ||
    /timed?\s*out|timeout/i.test(message)
  )
    network_failure = 'timeout';
  else if (
    ['ERR_CANCELED', '-999'].includes(code ?? '') ||
    /AbortError|cancelled|canceled|operation was aborted/i.test(message)
  )
    network_failure = 'cancelled';
  else if (
    ['ENOTFOUND', 'EAI_AGAIN', '-1003'].includes(code ?? '') ||
    /UnknownHostException|unable to resolve host|name.*not resolved|DNS|hostname could not be found/i.test(
      message,
    )
  )
    network_failure = 'dns';
  else if (
    [
      'ERR_CERT_AUTHORITY_INVALID',
      'ERR_CERT_DATE_INVALID',
      'CERT_HAS_EXPIRED',
      'UNABLE_TO_VERIFY_LEAF_SIGNATURE',
      '-1200',
      '-1202',
    ].includes(code ?? '') ||
    /SSLHandshakeException|SSLPeerUnverifiedException|certificate|TLS|SSL handshake/i.test(message)
  )
    network_failure = 'tls';
  else if (
    [
      'ECONNABORTED',
      'ECONNRESET',
      'ECONNREFUSED',
      'ENETUNREACH',
      'EHOSTUNREACH',
      'EPIPE',
      '-1004',
      '-1005',
      '-1009',
    ].includes(code ?? '') ||
    /connection.*(?:reset|refused|lost)|network.*unreachable|ConnectException/i.test(message)
  )
    network_failure = 'connection';
  else if (
    code === 'ERR_NETWORK' ||
    /network request failed|failed to fetch|network error/i.test(message)
  )
    network_failure = 'network';
  // A generic Android "Network request failed" must not be presented as confirmed DNS/TLS failure.
  return { network_failure, ...(code ? { network_error_code: code } : {}) };
}

export function safeRequestTags(input: Record<string, unknown>): Record<string, string> {
  const tags: Record<string, string> = {};
  if (typeof input.request_stage === 'string' && STAGES.has(input.request_stage))
    tags.request_stage = input.request_stage;
  if (typeof input.network_failure === 'string' && FAILURES.has(input.network_failure))
    tags.network_failure = input.network_failure;
  if (typeof input.network_error_code === 'string' && NETWORK_CODES.has(input.network_error_code))
    tags.network_error_code = input.network_error_code;
  for (const [key, maximum] of [
    ['request_duration_ms', 300_000],
    ['http_status', 599],
  ] as const) {
    const value = input[key];
    const number =
      typeof value === 'number'
        ? value
        : typeof value === 'string' && /^\d{1,6}$/.test(value)
          ? Number(value)
          : NaN;
    if (Number.isFinite(number) && number >= (key === 'http_status' ? 100 : 0) && number <= maximum)
      tags[key] = String(Math.round(number));
  }
  return tags;
}
