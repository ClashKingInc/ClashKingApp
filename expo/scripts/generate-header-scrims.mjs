import { deflateSync } from 'node:zlib';
import { writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

// Tiny bundled gradients resize in the same native layout pass as the artwork.
const profiles = {
  'header-standard-dark': [[0, .5], [.5, .72], [1, .94]],
  'header-standard-light': [[0, .34], [.5, .52], [1, .72]],
  // Match the tracker above, but finish at opaque black before the chip gutter.
  'header-clan-dark': [[0, .5], [.5, .72], [.9, 1], [1, 1]],
  'header-clan-light': [[0, .34], [.5, .52], [.9, 1], [1, 1]],
  'header-player-dark': [[0, .36], [.5, .64], [1, .92]],
  'header-player-light': [[0, .2], [.5, .4], [1, .65]],
  'header-war-dark': [[0, .36], [.55, .64], [1, .92]],
  'header-war-light': [[0, .2], [.55, .4], [1, .65]],
  'header-ranked': [[0, .34], [.6, .52], [.84, .76], [1, 1]],
  'header-atmosphere': [[0, .28], [.5, .1], [1, 0]],
  'header-calculator': [[0, .2], [.45, .32], [.7, .65], [1, .94]],
  'header-calculator-disabled': [[0, .35], [.45, .32], [.7, .65], [1, .94]],
};
function crc32(bytes) {
  let crc = 0xffffffff;
  for (const byte of bytes) {
    crc ^= byte;
    for (let bit = 0; bit < 8; bit++) crc = (crc >>> 1) ^ ((crc & 1) ? 0xedb88320 : 0);
  }
  return (crc ^ 0xffffffff) >>> 0;
}
function chunk(type, data) {
  const name = Buffer.from(type);
  const length = Buffer.alloc(4), crc = Buffer.alloc(4);
  length.writeUInt32BE(data.length);
  crc.writeUInt32BE(crc32(Buffer.concat([name, data])));
  return Buffer.concat([length, name, data, crc]);
}
for (const [name, stops] of Object.entries(profiles)) {
  const width = 2, height = 256;
  const rows = Buffer.alloc(height * (1 + width * 4));
  for (let y = 0; y < height; y++) {
    const t = y / (height - 1);
    const end = stops.findIndex(([position]) => position >= t);
    const [a, av] = stops[Math.max(0, end - 1)];
    const [b, bv] = stops[end];
    const alpha = Math.round(255 * (av + (bv - av) * (b === a ? 0 : (t - a) / (b - a))));
    for (let x = 0; x < width; x++) {
      const start = y * 9 + 1 + x * 4;
      if (name === 'header-atmosphere') rows.fill(255, start, start + 3);
      if (name.startsWith('header-calculator')) {
        rows[start] = 3; rows[start + 1] = 3; rows[start + 2] = 4;
      }
      rows[start + 3] = alpha;
    }
  }
  const header = Buffer.alloc(13);
  header.writeUInt32BE(width, 0); header.writeUInt32BE(height, 4);
  header[8] = 8; header[9] = 6;
  writeFileSync(fileURLToPath(new URL('../assets/clashking/backgrounds/' + name + '.png', import.meta.url)),
    Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]), chunk('IHDR', header), chunk('IDAT', deflateSync(rows)), chunk('IEND', Buffer.alloc(0))]));
}
