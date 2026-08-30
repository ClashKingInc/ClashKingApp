import { Buffer } from 'node:buffer';
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

export function isParitySourcePath(path) {
  return (
    path === 'pubspec.yaml' ||
    path === 'l10n.yaml' ||
    path === 'firebase.json' ||
    path === 'sonar-project.properties' ||
    path.startsWith('lib/') ||
    path.startsWith('test/') ||
    path.startsWith('ios/') ||
    path.startsWith('android/') ||
    path.startsWith('web/') ||
    path.startsWith('assets/') ||
    path.startsWith('fonts/') ||
    path.startsWith('e2e/') ||
    path.startsWith('docs/') ||
    path.startsWith('design-system/') ||
    path.startsWith('.github/workflows/')
  );
}

export function paritySourceFingerprint(repositoryRoot, paths) {
  const hash = createHash('sha256');
  const sources = paths.filter(isParitySourcePath).sort((left, right) => left.localeCompare(right));

  for (const source of sources) {
    const pathBytes = Buffer.from(source);
    const content = readFileSync(resolve(repositoryRoot, source));
    hash.update(`${pathBytes.length}:`);
    hash.update(pathBytes);
    hash.update(`${content.length}:`);
    hash.update(content);
  }

  return hash.digest('hex');
}
