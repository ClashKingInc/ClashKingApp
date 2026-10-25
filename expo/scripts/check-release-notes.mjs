import { readdirSync, readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const directory = fileURLToPath(new URL('../../update-news/', import.meta.url));
const files = readdirSync(directory).filter((name) => name.startsWith('whatsnew-'));
if (!files.length) throw new Error('No Play release notes found.');
for (const name of files) {
  const text = readFileSync(`${directory}/${name}`, 'utf8');
  // Play rejects the release, after the binary has built, if notes exceed 500 characters.
  // Include whitespace in the limit and validate the actual uploaded file.
  if (!text.trim() || text.length > 500) {
    throw new Error(`${name}: ${text.length} characters; Play release notes must contain 1–500 characters.`);
  }
  console.log(`${name}: ${text.length}/500 characters`);
}
