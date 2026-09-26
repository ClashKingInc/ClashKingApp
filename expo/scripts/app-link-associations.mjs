import { mkdir, writeFile } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

export function androidAssociation(raw) {
  const fingerprints = [
    ...new Set(
      (raw ?? '')
        .split(',')
        .map((value) => value.trim().toUpperCase())
        .filter(Boolean),
    ),
  ];
  if (!fingerprints.length) return null;
  if (fingerprints.some((value) => !/^([A-F0-9]{2}:){31}[A-F0-9]{2}$/.test(value)))
    throw new Error(
      'CK_ANDROID_APP_LINKS_SHA256 must contain comma-separated SHA-256 certificate fingerprints.',
    );
  return [
    {
      relation: ['delegate_permission/common.handle_all_urls'],
      target: {
        namespace: 'android_app',
        package_name: 'com.clashking.clashkingapp',
        sha256_cert_fingerprints: fingerprints,
      },
    },
  ];
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const association = androidAssociation(process.env.CK_ANDROID_APP_LINKS_SHA256);
  if (association) {
    const directory = join(resolve(process.argv[2] ?? 'dist'), '.well-known');
    await mkdir(directory, { recursive: true });
    await writeFile(
      join(directory, 'assetlinks.json'),
      JSON.stringify(association, null, 2) + '\n',
    );
  } else
    process.stderr.write(
      'Android HTTPS auto-opening is not enabled: set CK_ANDROID_APP_LINKS_SHA256 to the Play app-signing certificate fingerprint.\n',
    );
}
