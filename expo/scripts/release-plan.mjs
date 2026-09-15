import { execFileSync } from 'node:child_process';
import { writeFileSync } from 'node:fs';
import { GetObjectCommand, ListObjectsV2Command, S3Client } from '@aws-sdk/client-s3';

export function parseVersion(value) {
  const match = /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(-beta)?$/.exec(value ?? '');
  if (!match) return null;
  return {
    major: Number(match[1]),
    minor: Number(match[2]),
    patch: Number(match[3]),
    beta: Boolean(match[4]),
  };
}

export function compareVersions(left, right) {
  const a = parseVersion(left);
  const b = parseVersion(right);
  if (!a || !b) throw new Error('Cannot compare invalid release versions.');
  return (
    a.major - b.major || a.minor - b.minor || a.patch - b.patch || Number(!a.beta) - Number(!b.beta)
  );
}

function validMarker(marker) {
  const version = parseVersion(marker?.version);
  if (!version || !['beta', 'production'].includes(marker.track)) return false;
  if (!['native', 'ota'].includes(marker.type)) return false;
  if (version.beta !== (marker.track === 'beta')) return false;
  return marker.type === 'native' ? version.patch === 0 : version.patch > 0;
}

export function decideRelease({ markers, track, version: requestedVersion, fingerprints }) {
  if (track !== 'beta' && track !== 'production') {
    throw new Error('Release track must be beta or production.');
  }
  if (!/^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$/.test(requestedVersion ?? '')) {
    throw new Error('Release version must be a semantic x.y.z version without a suffix.');
  }
  const suffix = track === 'beta' ? '-beta' : '';
  const version = `${requestedVersion}${suffix}`;
  const requested = parseVersion(version);
  const valid = markers.filter(validMarker);
  const trackMarkers = valid
    .filter((marker) => marker.track === track)
    .sort((a, b) => compareVersions(b.version, a.version));
  if (trackMarkers.some((marker) => marker.version === version)) {
    throw new Error(`Release ${version} already exists and immutable versions cannot be reused.`);
  }
  if (trackMarkers[0] && compareVersions(version, trackMarkers[0].version) <= 0) {
    throw new Error(`Release ${version} must be newer than ${trackMarkers[0].version}.`);
  }
  if (requested.patch === 0) {
    return {
      type: 'native',
      version,
      appVersion: requestedVersion,
      baseNativeVersion: null,
    };
  }

  const baseNativeVersion = `${requested.major}.${requested.minor}.0${suffix}`;
  const baseNative = trackMarkers.find(
    (marker) => marker.type === 'native' && marker.version === baseNativeVersion,
  );
  if (!baseNative) {
    throw new Error(`OTA release ${version} requires native release ${baseNativeVersion}.`);
  }
  const fingerprintsMatch = ['ios', 'android'].every(
    (platform) => baseNative.platforms?.[platform]?.fingerprint === fingerprints[platform],
  );
  if (!fingerprintsMatch) {
    throw new Error(
      `Native fingerprints changed since ${baseNativeVersion}; choose a newer x.y.0 native version.`,
    );
  }
  return {
    type: 'ota',
    version,
    appVersion: requestedVersion,
    baseNativeVersion,
  };
}

async function listMarkers(client, bucket) {
  const markers = [];
  let ContinuationToken;
  do {
    const page = await client.send(
      new ListObjectsV2Command({ Bucket: bucket, Prefix: 'releases/', ContinuationToken }),
    );
    for (const object of page.Contents ?? []) {
      if (!object.Key?.endsWith('/release.json')) continue;
      const response = await client.send(new GetObjectCommand({ Bucket: bucket, Key: object.Key }));
      const body = await response.Body?.transformToString();
      if (body) markers.push(JSON.parse(body));
    }
    ContinuationToken = page.IsTruncated ? page.NextContinuationToken : undefined;
  } while (ContinuationToken);
  return markers;
}

function fingerprint(platform) {
  const output = execFileSync(
    'npx',
    ['--no-install', 'fingerprint', 'fingerprint:generate', '--platform', platform],
    {
      encoding: 'utf8',
      env: {
        ...process.env,
        CK_APP_VERSION: '0.0.0',
        CK_BUILD_NUMBER: '1',
        CK_RELEASE_TRACK: 'production',
        CK_RUNTIME_VERSION: 'native-fingerprint-input',
      },
    },
  );
  return JSON.parse(output).hash;
}

async function main() {
  const track = process.env.CK_RELEASE_TRACK;
  if (track !== 'beta' && track !== 'production')
    throw new Error('CK_RELEASE_TRACK must be beta or production.');
  const required = [
    'R2_ACCOUNT_ID',
    'R2_ACCESS_KEY_ID',
    'R2_SECRET_ACCESS_KEY',
    'R2_UPDATES_BUCKET_NAME',
  ];
  for (const name of required) if (!process.env[name]) throw new Error(`${name} is required.`);
  const client = new S3Client({
    region: 'auto',
    endpoint: `https://${process.env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
    credentials: {
      accessKeyId: process.env.R2_ACCESS_KEY_ID,
      secretAccessKey: process.env.R2_SECRET_ACCESS_KEY,
    },
  });
  const fingerprints = { ios: fingerprint('ios'), android: fingerprint('android') };
  const plan = decideRelease({
    markers: await listMarkers(client, process.env.R2_UPDATES_BUCKET_NAME),
    track,
    version: process.env.CK_RELEASE_VERSION,
    fingerprints,
  });
  const result = {
    ...plan,
    track,
    fingerprints,
    iosFingerprint: fingerprints.ios,
    androidFingerprint: fingerprints.android,
    buildNumber: String(Math.floor(Date.now() / 1000)),
  };
  writeFileSync(
    process.env.CK_RELEASE_PLAN_PATH || 'release-plan.json',
    `${JSON.stringify(result, null, 2)}\n`,
  );
  if (process.env.GITHUB_OUTPUT) {
    writeFileSync(
      process.env.GITHUB_OUTPUT,
      Object.entries(result)
        .map(
          ([key, value]) =>
            `${key}=${typeof value === 'object' ? JSON.stringify(value) : (value ?? '')}`,
        )
        .join('\n') + '\n',
      { flag: 'a' },
    );
  }
  console.log(JSON.stringify(result, null, 2));
}

if (import.meta.url === `file://${process.argv[1]}`) await main();
