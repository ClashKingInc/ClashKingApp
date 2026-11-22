// Bundle an exported first-page image with an existing self-contained story.
// The Admin uploader reads this inert metadata and uses the normal media API.
import { readFile, writeFile } from 'node:fs/promises';
import { extname, resolve } from 'node:path';
import ts from 'typescript';

const [storyPath, coverPath, outputPath] = process.argv.slice(2);
if (!storyPath || !coverPath || !outputPath) {
  throw new Error(
    'Usage: node scripts/package-story-cover.mjs story.html first-page.webp output.html',
  );
}
if (resolve(storyPath) === resolve(outputPath)) throw new Error('Use a separate output file.');
const image = await readFile(coverPath);
const format = { '.png': 'png', '.jpg': 'jpeg', '.jpeg': 'jpeg', '.webp': 'webp' }[
  extname(coverPath).toLowerCase()
];
if (!format || image.length > 2 * 1024 * 1024)
  throw new Error('Use a PNG, JPEG or WebP cover smaller than 2 MB.');
let html = await readFile(storyPath, 'utf8');
if (!/<\/head\s*>/i.test(html)) throw new Error('Story must contain a closing head element.');
html = html.replace(/<meta\b(?=[^>]*name=["']clashking-story-preview["'])[^>]*>\s*/gi, '');
// Carry the same fit protection in the file so existing app installs benefit
// when a new story revision is uploaded, before their next compatible OTA.
const contract = await readFile(
  new URL('../src/features/home/presentation/announcement-webview-contract.ts', import.meta.url),
  'utf8',
);
const module = ts.transpileModule(contract, {
  compilerOptions: { target: ts.ScriptTarget.ES2022, module: ts.ModuleKind.ES2022 },
}).outputText;
const { ANNOUNCEMENT_STORY_VIEWPORT_JAVASCRIPT } = await import(
  `data:text/javascript;base64,${Buffer.from(module).toString('base64')}`
);
html = html.replace(
  /<\/head\s*>/i,
  `<meta name="clashking-story-preview" content="data:image/${format};base64,${image.toString('base64')}"><script>${ANNOUNCEMENT_STORY_VIEWPORT_JAVASCRIPT}</script></head>`,
);
if (Buffer.byteLength(html) > 25 * 1024 * 1024)
  throw new Error('Packaged story exceeds the 25 MB upload limit.');
await writeFile(outputPath, html);
console.log(`Packaged story cover: ${outputPath}`);
