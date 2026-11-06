import { readFile, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
const bot = process.argv[2];
if (!bot) throw new Error('Pass the clashking_bot checkout path.');
const source = resolve(bot, 'worker/src/commands/ranked-poster-layout.ts');
const destination = resolve(root, 'src/core/graphics/ranked-poster-layout.ts');
const generated =
  '// Generated from clashking_bot; run scripts/sync-ranked-poster.mjs to update.\n' +
  (await readFile(source, 'utf8'));
if (process.argv.includes('--check')) {
  if ((await readFile(destination, 'utf8')) !== generated)
    throw new Error('Ranked poster layout is out of sync.');
} else await writeFile(destination, generated);
console.log('Bot/app Ranked poster layout matches.');
