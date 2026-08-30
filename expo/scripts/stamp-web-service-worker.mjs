import { createHash } from 'node:crypto';
import { readdir, readFile, rename, writeFile } from 'node:fs/promises';
import { basename, join, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const CACHE_TOKEN = '__CLASHKING_WEB_BUILD__';

async function listFiles(root, directory = root) {
  const entries = await readdir(directory, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) files.push(...(await listFiles(root, path)));
    else if (entry.isFile() && relative(root, path) !== 'sw.js') files.push(path);
  }
  return files;
}

export async function webExportFingerprint(outputDirectory) {
  const root = resolve(outputDirectory);
  const files = (await listFiles(root)).sort((left, right) =>
    relative(root, left).localeCompare(relative(root, right)),
  );
  const digest = createHash('sha256');
  for (const file of files) {
    digest.update(relative(root, file));
    digest.update('\0');
    digest.update(await readFile(file));
    digest.update('\0');
  }
  return digest.digest('hex').slice(0, 16);
}

export async function stampWebServiceWorker(outputDirectory) {
  const root = resolve(outputDirectory);
  const serviceWorkerPath = join(root, 'sw.js');
  const source = await readFile(serviceWorkerPath, 'utf8');
  if (!source.includes(CACHE_TOKEN)) {
    throw new Error(`${serviceWorkerPath} does not contain ${CACHE_TOKEN}.`);
  }
  const fingerprint = await webExportFingerprint(root);
  const stamped = source.replaceAll(CACHE_TOKEN, fingerprint);
  const temporaryPath = join(root, `.${basename(serviceWorkerPath)}.tmp`);
  await writeFile(temporaryPath, stamped, 'utf8');
  await rename(temporaryPath, serviceWorkerPath);
  return fingerprint;
}

const entrypoint = process.argv[1] === undefined ? '' : resolve(process.argv[1]);
if (entrypoint === fileURLToPath(import.meta.url)) {
  const outputDirectory = process.argv[2] ?? 'dist';
  const fingerprint = await stampWebServiceWorker(outputDirectory);
  process.stdout.write(`Stamped web service worker cache ${fingerprint}.\n`);
}
