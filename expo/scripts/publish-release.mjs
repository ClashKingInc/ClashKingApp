import { createHash, createPublicKey, createSign, X509Certificate } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import { extname, join } from 'node:path';
import {
  GetObjectCommand,
  ListObjectsV2Command,
  PutObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';
import mime from 'mime-types';
import { republishManifest, rollbackDescriptorKey } from './release-manifest.mjs';

const required = [
  'CK_RELEASE_VERSION',
  'CK_APP_VERSION',
  'CK_RELEASE_TRACK',
  'CK_RELEASE_TYPE',
  'CK_GIT_SHA',
  'CK_IOS_FINGERPRINT',
  'CK_ANDROID_FINGERPRINT',
  'R2_ACCOUNT_ID',
  'R2_ACCESS_KEY_ID',
  'R2_SECRET_ACCESS_KEY',
  'R2_UPDATES_BUCKET_NAME',
  'R2_UPDATES_PUBLIC_ORIGIN',
];
for (const name of required) if (!process.env[name]) throw new Error(`${name} is required.`);

const version = process.env.CK_RELEASE_VERSION;
const appVersion = process.env.CK_APP_VERSION;
const track = process.env.CK_RELEASE_TRACK;
const releaseType = process.env.CK_RELEASE_TYPE;
if (!/^(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)(?:-beta)?$/.test(version)) {
  throw new Error('CK_RELEASE_VERSION is invalid.');
}
if (!/^(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)$/.test(appVersion)) {
  throw new Error('CK_APP_VERSION must be a numeric semantic version.');
}
if (!['beta', 'production'].includes(track)) throw new Error('CK_RELEASE_TRACK is invalid.');
if (!['native', 'ota'].includes(releaseType)) throw new Error('CK_RELEASE_TYPE is invalid.');
if ((track === 'beta') !== version.endsWith('-beta')) {
  throw new Error('Beta versions must use -beta and production versions must not.');
}
const patchVersion = Number(version.replace(/-beta$/, '').split('.')[2]);
if (
  (releaseType === 'native' && patchVersion !== 0) ||
  (releaseType === 'ota' && patchVersion === 0)
) {
  throw new Error('Native releases must use patch 0 and OTA releases must use a positive patch.');
}

const client = new S3Client({
  region: 'auto',
  endpoint: `https://${process.env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
  credentials: {
    accessKeyId: process.env.R2_ACCESS_KEY_ID,
    secretAccessKey: process.env.R2_SECRET_ACCESS_KEY,
  },
});
const bucket = process.env.R2_UPDATES_BUCKET_NAME;
const origin = process.env.R2_UPDATES_PUBLIC_ORIGIN.replace(/\/+$/, '');
const createdAt = new Date().toISOString();

function digest(data, algorithm, encoding) {
  return createHash(algorithm).update(data).digest(encoding);
}
function uuidFromHash(value) {
  const bytes = value.slice(0, 32).split('');
  bytes[12] = '4';
  bytes[16] = ((Number.parseInt(bytes[16], 16) & 0x3) | 0x8).toString(16);
  const normalized = bytes.join('');
  return `${normalized.slice(0, 8)}-${normalized.slice(8, 12)}-${normalized.slice(12, 16)}-${normalized.slice(16, 20)}-${normalized.slice(20, 32)}`;
}
function publicURL(key) {
  return `${origin}/${key.split('/').map(encodeURIComponent).join('/')}`;
}

async function putImmutable(key, body, contentType) {
  await client.send(
    new PutObjectCommand({
      Bucket: bucket,
      Key: key,
      Body: body,
      ContentType: contentType,
      CacheControl: 'public, max-age=31536000, immutable',
      IfNoneMatch: '*',
    }),
  );
}

async function assetMetadata(outputDirectory, relativePath, extension, launchAsset) {
  const body = await readFile(join(outputDirectory, relativePath));
  const normalizedExtension = extension.replace(/^\./, '');
  const sha256Hex = digest(body, 'sha256', 'hex');
  const objectKey = `objects/${sha256Hex}`;
  const contentType = launchAsset
    ? 'application/javascript'
    : mime.lookup(normalizedExtension) || 'application/octet-stream';
  try {
    await putImmutable(objectKey, body, contentType);
  } catch (error) {
    if (error?.$metadata?.httpStatusCode !== 412) throw error;
  }
  return {
    hash: digest(body, 'sha256', 'base64url'),
    key: digest(body, 'md5', 'hex'),
    fileExtension: launchAsset ? '.bundle' : `.${normalizedExtension}`,
    contentType,
    url: publicURL(objectKey),
  };
}

function signManifest(manifest, privateKey) {
  const signer = createSign('RSA-SHA256');
  signer.update(JSON.stringify(manifest), 'utf8');
  signer.end();
  return `sig="${signer.sign(privateKey, 'base64')}", keyid="main"`;
}

async function listRollbackSourceMarkers() {
  const releases = [];
  let ContinuationToken;
  const markerPattern = new RegExp(`^releases/${track}/[^/]+/release\\.json$`);
  do {
    const page = await client.send(
      new ListObjectsV2Command({
        Bucket: bucket,
        Prefix: `releases/${track}/`,
        ContinuationToken,
      }),
    );
    for (const object of page.Contents ?? []) {
      if (!object.Key || !markerPattern.test(object.Key)) continue;
      const response = await client.send(new GetObjectCommand({ Bucket: bucket, Key: object.Key }));
      const body = await response.Body?.transformToString();
      if (!body) continue;
      const marker = JSON.parse(body);
      const belongsToNativeLine =
        (marker.type === 'native' && marker.version === process.env.CK_BASE_NATIVE_VERSION) ||
        (marker.type === 'ota' && marker.baseNativeVersion === process.env.CK_BASE_NATIVE_VERSION);
      if (
        marker.schemaVersion === 1 &&
        marker.track === track &&
        ['native', 'ota'].includes(marker.type) &&
        marker.version !== version &&
        belongsToNativeLine
      ) {
        releases.push(marker);
      }
    }
    ContinuationToken = page.IsTruncated ? page.NextContinuationToken : undefined;
  } while (ContinuationToken);
  return releases;
}

async function buildRollbackTargets(releases, privateKey, fingerprints) {
  const rollbackCreatedAt = new Date(Date.parse(createdAt) + 1).toISOString();
  const targets = {};
  for (const release of releases) {
    const targetPlatforms = {};
    for (const platform of ['ios', 'android']) {
      const source = release.platforms?.[platform];
      if (
        source?.runtimeVersion !== fingerprints[platform] ||
        !source.manifest?.launchAsset ||
        !Array.isArray(source.manifest?.assets)
      ) {
        continue;
      }
      const rollbackHash = digest(
        JSON.stringify({ from: version, to: release.version, platform, rollbackCreatedAt }),
        'sha256',
        'hex',
      );
      const manifest = republishManifest(source.manifest, {
        id: uuidFromHash(rollbackHash),
        createdAt: rollbackCreatedAt,
        track,
        targetVersion: release.version,
        rollbackFrom: version,
      });
      const descriptor = {
        runtimeVersion: source.runtimeVersion,
        manifest,
        signature: signManifest(manifest, privateKey),
      };
      const key = rollbackDescriptorKey({
        track,
        fromVersion: version,
        targetVersion: release.version,
        platform,
        updateId: manifest.id,
      });
      await putImmutable(
        key,
        `${JSON.stringify(descriptor, null, 2)}\n`,
        'application/json; charset=utf-8',
      );
      targetPlatforms[platform] = {
        runtimeVersion: source.runtimeVersion,
        key,
      };
    }
    if (Object.keys(targetPlatforms).length) {
      targets[release.version] = {
        type: release.type,
        gitSha: release.gitSha,
        platforms: targetPlatforms,
      };
    }
  }
  return targets;
}

async function buildUpdateManifests(includeRollbackTargets) {
  const privateKeyPath = process.env.CK_UPDATES_PRIVATE_KEY_PATH;
  const certificatePath = process.env.CK_UPDATES_CERTIFICATE_PATH;
  if (!privateKeyPath || !certificatePath) {
    throw new Error('Update publication requires a signing key and its verification certificate.');
  }
  const privateKey = await readFile(privateKeyPath, 'utf8');
  const certificate = new X509Certificate(await readFile(certificatePath, 'utf8'));
  const certificateKey = certificate.publicKey.export({ type: 'spki', format: 'pem' });
  const signingKey = createPublicKey(privateKey).export({ type: 'spki', format: 'pem' });
  if (certificateKey !== signingKey) {
    throw new Error(
      'The OTA private key does not match the certificate embedded in native builds.',
    );
  }
  const now = Date.now();
  if (now < Date.parse(certificate.validFrom) || now > Date.parse(certificate.validTo)) {
    throw new Error('The OTA code-signing certificate is not currently valid.');
  }
  const platforms = {};
  const fingerprints = {
    ios: process.env.CK_IOS_FINGERPRINT,
    android: process.env.CK_ANDROID_FINGERPRINT,
  };
  for (const platform of ['ios', 'android']) {
    const prefix = platform.toUpperCase();
    const outputDirectory = process.env[`CK_${prefix}_UPDATE_OUTPUT_DIR`];
    const expoConfigPath = process.env[`CK_${prefix}_EXPO_CONFIG_PATH`];
    if (!outputDirectory || !expoConfigPath)
      throw new Error(
        `Update publication requires the ${platform} export directory and Expo config.`,
      );
    const metadata = JSON.parse(await readFile(join(outputDirectory, 'metadata.json'), 'utf8'));
    const expoConfig = JSON.parse(await readFile(expoConfigPath, 'utf8'));
    const files = metadata.fileMetadata?.[platform];
    if (!files) throw new Error(`Export metadata is missing ${platform}.`);
    const assets = await Promise.all(
      files.assets.map((asset) => assetMetadata(outputDirectory, asset.path, asset.ext, false)),
    );
    const launchAsset = await assetMetadata(
      outputDirectory,
      files.bundle,
      extname(files.bundle).slice(1),
      true,
    );
    const updateHash = digest(
      JSON.stringify({
        version,
        platform,
        launchAsset: launchAsset.hash,
        assets: assets.map((asset) => asset.hash),
      }),
      'sha256',
      'hex',
    );
    const runtimeVersion =
      platform === 'ios' ? process.env.CK_IOS_FINGERPRINT : process.env.CK_ANDROID_FINGERPRINT;
    const manifest = {
      id: uuidFromHash(updateHash),
      createdAt,
      runtimeVersion,
      assets,
      launchAsset,
      metadata: { channel: track, version },
      extra: { expoClient: expoConfig },
    };
    platforms[platform] = {
      runtimeVersion,
      fingerprint: runtimeVersion,
      manifest,
      signature: signManifest(manifest, privateKey),
    };
  }
  return {
    platforms,
    rollbackTargets: includeRollbackTargets
      ? await buildRollbackTargets(await listRollbackSourceMarkers(), privateKey, fingerprints)
      : {},
  };
}

const fingerprints = {
  ios: process.env.CK_IOS_FINGERPRINT,
  android: process.env.CK_ANDROID_FINGERPRINT,
};
const exportedRelease = await buildUpdateManifests(releaseType === 'ota');
const platforms = exportedRelease.platforms ?? {
  ios: { runtimeVersion: fingerprints.ios, fingerprint: fingerprints.ios },
  android: { runtimeVersion: fingerprints.android, fingerprint: fingerprints.android },
};
const marker = {
  schemaVersion: 1,
  version,
  appVersion,
  track,
  type: releaseType,
  baseNativeVersion: process.env.CK_BASE_NATIVE_VERSION || null,
  gitSha: process.env.CK_GIT_SHA,
  createdAt,
  releaseNotes: process.env.CK_RELEASE_NOTES || '',
  platforms,
  rollbackTargets: exportedRelease.rollbackTargets,
};

// The marker is intentionally the final write. A listing can never expose a release
// whose content-addressed assets have not all finished uploading.
const markerKey = `releases/${track}/${version}/release.json`;
await putImmutable(
  markerKey,
  `${JSON.stringify(marker, null, 2)}\n`,
  'application/json; charset=utf-8',
);
console.log(JSON.stringify({ markerKey, version, track, type: releaseType }));
