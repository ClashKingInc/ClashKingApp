/** Extrude the selected account-verified.svg strokes without redesigning them.
 * Reproduction: node scripts/generate-verified-accounts-model.mjs
 * The source SVG remains authoritative for outline, check, stroke, and color. */
import fs from 'node:fs';
import path from 'node:path';
import { Buffer } from 'node:buffer';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';

const directory = path.dirname(fileURLToPath(import.meta.url));
const svgPath =
  process.env.CLASHKING_VERIFIED_ICON ??
  path.resolve(
    directory,
    '../../../../PycharmProjects/clashking_bot/worker/src/assets/account-verified.svg',
  );
const svg = fs.readFileSync(svgPath, 'utf8');
const paths = [...svg.matchAll(/<path d="([^"]+)"/g)].map((match) => match[1]);
if (
  paths[0] !== 'M12 22s8-4 8-11V5l-8-3-8 3v6c0 7 8 11 8 11' ||
  paths[1] !== 'm9 12 2 2 4-4' ||
  !svg.includes('stroke-width="2.6"') ||
  !svg.includes('stroke="#14A37F"')
) {
  throw new Error('Authoritative verified SVG changed; update path sampling before rebuilding.');
}
const scale = 0.3,
  radius = 1.3 * scale,
  depth = 0.48,
  bevel = 0.105;
const convert = ([x, y]) => [(x - 12) * scale, (12 - y) * scale];
const cubic = (a, b, c, d, t) =>
  a.map(
    (_, i) =>
      (1 - t) ** 3 * a[i] +
      3 * (1 - t) ** 2 * t * b[i] +
      3 * (1 - t) * t * t * c[i] +
      t ** 3 * d[i],
  );
const shield = [convert([12, 22])];
for (let i = 1; i <= 96; i++)
  shield.push(convert(cubic([12, 22], [12, 22], [20, 18], [20, 11], i / 96)));
shield.push(convert([20, 5]), convert([12, 2]), convert([4, 5]), convert([4, 11]));
for (let i = 1; i <= 96; i++)
  shield.push(convert(cubic([4, 11], [4, 18], [12, 22], [12, 22], i / 96)));
const check = [
  [9, 12],
  [11, 14],
  [15, 10],
].map(convert);
const segments = [shield, check].flatMap((points) =>
  points.slice(1).map((b, i) => ({ a: points[i], b })),
);
function distance2(x, y) {
  let best = Infinity,
    dx = 0,
    dy = 0;
  for (const { a, b } of segments) {
    const ex = b[0] - a[0],
      ey = b[1] - a[1],
      length = ex * ex + ey * ey;
    const t = length ? Math.max(0, Math.min(1, ((x - a[0]) * ex + (y - a[1]) * ey) / length)) : 0;
    const xx = x - a[0] - t * ex,
      yy = y - a[1] - t * ey,
      d = xx * xx + yy * yy;
    if (d < best) {
      best = d;
      dx = xx;
      dy = yy;
    }
  }
  const length = Math.sqrt(best);
  return { distance: length - radius, normal: length ? [dx / length, dy / length] : [1, 0] };
}
function surface(x, y, z) {
  const base = distance2(x, y),
    a = base.distance + bevel,
    b = Math.abs(z) - depth / 2 + bevel;
  const aa = Math.max(0, a),
    bb = Math.max(0, b),
    outer = Math.hypot(aa, bb);
  const distance = Math.min(Math.max(a, b), 0) + outer - bevel;
  const xy = outer ? aa / outer : a > b ? 1 : 0,
    zz = outer ? bb / outer : b >= a ? 1 : 0;
  return { distance, normal: [base.normal[0] * xy, base.normal[1] * xy, Math.sign(z || 1) * zz] };
}
const low = [-2.85, -3.45, -0.3],
  high = [2.85, 3.45, 0.3],
  // Tile-sized mesh budget; analytic surface normals keep the same rounded
  // bevel under model-viewer lighting without a densely tessellated flat face.
  steps = [48, 58, 6];
const spacing = steps.map((n, i) => (high[i] - low[i]) / n),
  nx = steps[0] + 1,
  ny = steps[1] + 1;
const distances = new Float32Array(nx * ny * (steps[2] + 1));
for (let y = 0; y < ny; y++)
  for (let x = 0; x < nx; x++) {
    const d = distance2(low[0] + x * spacing[0], low[1] + y * spacing[1]).distance + bevel;
    for (let z = 0; z <= steps[2]; z++) {
      const q = Math.abs(low[2] + z * spacing[2]) - depth / 2 + bevel;
      distances[(z * ny + y) * nx + x] =
        Math.min(Math.max(d, q), 0) + Math.hypot(Math.max(d, 0), Math.max(q, 0)) - bevel;
    }
  }
const positions = [],
  normals = [];
const cross = (a, b) => [
  a[1] * b[2] - a[2] * b[1],
  a[2] * b[0] - a[0] * b[2],
  a[0] * b[1] - a[1] * b[0],
];
const sub = (a, b) => a.map((v, i) => v - b[i]);
const dot = (a, b) => a.reduce((n, v, i) => n + v * b[i], 0);
const unit = (a) => {
  const l = Math.hypot(...a);
  return a.map((v) => v / l);
};
function triangle(a, b, c) {
  const n = surface(...a).normal;
  if (dot(cross(sub(b, a), sub(c, a)), n) < 0) [b, c] = [c, b];
  positions.push(...a, ...b, ...c);
  normals.push(...surface(...a).normal, ...surface(...b).normal, ...surface(...c).normal);
}
const tetrahedra = [
  [0, 5, 1, 6],
  [0, 1, 2, 6],
  [0, 2, 3, 6],
  [0, 3, 7, 6],
  [0, 7, 4, 6],
  [0, 4, 5, 6],
];
const offsets = [
  [0, 0, 0],
  [1, 0, 0],
  [1, 1, 0],
  [0, 1, 0],
  [0, 0, 1],
  [1, 0, 1],
  [1, 1, 1],
  [0, 1, 1],
];
const edges = [
  [0, 1],
  [0, 2],
  [0, 3],
  [1, 2],
  [1, 3],
  [2, 3],
];
for (let z = 0; z < steps[2]; z++)
  for (let y = 0; y < steps[1]; y++)
    for (let x = 0; x < steps[0]; x++) {
      const ds = offsets.map(([dx, dy, dz]) => distances[((z + dz) * ny + y + dy) * nx + x + dx]);
      if (ds.every((d) => d >= 0) || ds.every((d) => d < 0)) continue;
      const points = offsets.map(([dx, dy, dz]) => [
        low[0] + (x + dx) * spacing[0],
        low[1] + (y + dy) * spacing[1],
        low[2] + (z + dz) * spacing[2],
      ]);
      for (const tetra of tetrahedra) {
        const intersections = [];
        for (const [aa, bb] of edges) {
          const a = tetra[aa],
            b = tetra[bb];
          if (ds[a] < 0 === ds[b] < 0) continue;
          const t = ds[a] / (ds[a] - ds[b]);
          intersections.push(points[a].map((v, i) => v + (points[b][i] - v) * t));
        }
        if (intersections.length < 3) continue;
        const center = [0, 1, 2].map(
            (i) => intersections.reduce((n, p) => n + p[i], 0) / intersections.length,
          ),
          normal = surface(...center).normal;
        const u = unit(sub(intersections[0], center)),
          v = cross(normal, u);
        intersections.sort(
          (a, b) =>
            Math.atan2(dot(sub(a, center), v), dot(sub(a, center), u)) -
            Math.atan2(dot(sub(b, center), v), dot(sub(b, center), u)),
        );
        for (let i = 1; i < intersections.length - 1; i++)
          triangle(intersections[0], intersections[i], intersections[i + 1]);
      }
    }
const bounds = (values) => {
  const min = [Infinity, Infinity, Infinity],
    max = [-Infinity, -Infinity, -Infinity];
  for (let i = 0; i < values.length; i++) {
    min[i % 3] = Math.min(min[i % 3], values[i]);
    max[i % 3] = Math.max(max[i % 3], values[i]);
  }
  return { min, max };
};
const indexedPositions = [],
  indexedNormals = [],
  indices = [],
  vertices = new Map();
for (let i = 0; i < positions.length; i += 9) {
  const face = [];
  for (let j = 0; j < 3; j++) {
    const p = positions.slice(i + j * 3, i + j * 3 + 3),
      key = p.map((v) => v.toFixed(7)).join(',');
    let index = vertices.get(key);
    if (index === undefined) {
      index = indexedPositions.length / 3;
      vertices.set(key, index);
      indexedPositions.push(...p);
      indexedNormals.push(...normals.slice(i + j * 3, i + j * 3 + 3));
    }
    face.push(index);
  }
  if (new Set(face).size === 3) indices.push(...face);
}
positions.length = 0;
normals.length = 0;
const positionBytes = Buffer.from(new Float32Array(indexedPositions).buffer),
  normalBytes = Buffer.from(new Float32Array(indexedNormals).buffer),
  indexBytes = Buffer.from(new Uint32Array(indices).buffer);
const linear = (v) => (v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4);
const model = {
  asset: { version: '2.0', generator: 'ClashKing exact verified-icon rounded extrusion' },
  scene: 0,
  scenes: [{ nodes: [0] }],
  nodes: [{ name: 'Verified account — exact ShieldCheck strokes', mesh: 0 }],
  meshes: [
    {
      name: 'Extruded original SVG stroke silhouette',
      primitives: [{ attributes: { POSITION: 0, NORMAL: 1 }, indices: 2, material: 0 }],
    },
  ],
  materials: [
    {
      name: 'ClashKing verified green #14A37F',
      pbrMetallicRoughness: {
        baseColorFactor: [20 / 255, 163 / 255, 127 / 255, 1].map((v, i) => (i < 3 ? linear(v) : v)),
        metallicFactor: 0.14,
        roughnessFactor: 0.25,
      },
      extensions: {
        KHR_materials_clearcoat: { clearcoatFactor: 0.72, clearcoatRoughnessFactor: 0.16 },
      },
    },
  ],
  extensionsUsed: ['KHR_materials_clearcoat'],
  buffers: [{ byteLength: positionBytes.length + normalBytes.length + indexBytes.length }],
  bufferViews: [
    { buffer: 0, byteOffset: 0, byteLength: positionBytes.length, target: 34962 },
    { buffer: 0, byteOffset: positionBytes.length, byteLength: normalBytes.length, target: 34962 },
    {
      buffer: 0,
      byteOffset: positionBytes.length + normalBytes.length,
      byteLength: indexBytes.length,
      target: 34963,
    },
  ],
  accessors: [
    {
      bufferView: 0,
      componentType: 5126,
      count: indexedPositions.length / 3,
      type: 'VEC3',
      ...bounds(indexedPositions),
    },
    {
      bufferView: 1,
      componentType: 5126,
      count: indexedNormals.length / 3,
      type: 'VEC3',
      ...bounds(indexedNormals),
    },
    {
      bufferView: 2,
      componentType: 5125,
      count: indices.length,
      type: 'SCALAR',
      min: [0],
      max: [indexedPositions.length / 3 - 1],
    },
  ],
  extras: {
    source: 'clashking_bot/worker/src/assets/account-verified.svg',
    sourceSha256: createHash('sha256').update(svg).digest('hex'),
    paths,
    stroke: '#14A37F',
    strokeWidth: 2.6,
    depth,
    bevel,
    method:
      'Exact sampled SVG centerlines, round stroke distance field, rounded bevel extrusion, deterministic marching tetrahedra. No background plate or added motif.',
  },
};
const json = Buffer.from(JSON.stringify(model)),
  padded = Buffer.alloc(Math.ceil(json.length / 4) * 4, 32);
json.copy(padded);
const bin = Buffer.concat([positionBytes, normalBytes, indexBytes]);
const header = Buffer.alloc(20);
header.writeUInt32LE(0x46546c67, 0);
header.writeUInt32LE(2, 4);
header.writeUInt32LE(28 + padded.length + bin.length, 8);
header.writeUInt32LE(padded.length, 12);
header.writeUInt32LE(0x4e4f534a, 16);
const binHeader = Buffer.alloc(8);
binHeader.writeUInt32LE(bin.length, 0);
binHeader.writeUInt32LE(0x004e4942, 4);
const output = path.resolve(directory, '../assets/clashking/achievements/verified-accounts.glb');
fs.writeFileSync(output, Buffer.concat([header, padded, binHeader, bin]));
console.log(
  JSON.stringify({
    output,
    triangles: indices.length / 3,
    vertices: indexedPositions.length / 3,
    bytes: fs.statSync(output).size,
    sourceSha256: model.extras.sourceSha256,
  }),
);
