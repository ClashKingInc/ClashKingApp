const FTYP = 0x66747970;
const AVIF = 0x61766966;
const META = 0x6d657461;
const IPRP = 0x69707270;
const IPCO = 0x6970636f;
const ISPE = 0x69737065;

interface Box {
  readonly type: number;
  readonly start: number;
  readonly end: number;
}

function* boxes(view: DataView, start: number, end: number): Generator<Box, void> {
  while (start + 8 <= end) {
    const size = view.getUint32(start);
    // Unknown or extended sizes are deliberately left to the native decoder.
    if (size < 8 || start + size > end) return;
    yield { type: view.getUint32(start + 4), start: start + 8, end: start + size };
    start += size;
  }
}

/** Returns an upper bound on the still image's long edge from a complete AVIF metadata box. */
export function avifPixelBound(bytes: Uint8Array): number | undefined {
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  const top = boxes(view, 0, view.byteLength);
  const fileType = top.next().value;
  if (!fileType || fileType.type !== FTYP || fileType.end - fileType.start < 8) return undefined;
  if (view.getUint32(fileType.start) !== AVIF) return undefined;

  for (const meta of top) {
    if (meta.type !== META) continue;
    for (const properties of boxes(view, meta.start + 4, meta.end)) {
      if (properties.type !== IPRP) continue;
      for (const container of boxes(view, properties.start, properties.end)) {
        if (container.type !== IPCO) continue;
        let pixels = 0;
        let end = container.start;
        // Use the maximum across the primary, auxiliary, and tile properties.
        // This can miss reuse for an unusual file, but never assumes any one tile is the image.
        for (const item of boxes(view, container.start, container.end)) {
          end = item.end;
          if (item.type !== ISPE) continue;
          if (item.end - item.start !== 12 || view.getUint32(item.start) !== 0) return undefined;
          const width = view.getUint32(item.start + 4);
          const height = view.getUint32(item.start + 8);
          if (!width || !height) return undefined;
          pixels = Math.max(pixels, width, height);
        }
        return end === container.end && pixels ? pixels : undefined;
      }
    }
  }
  return undefined;
}
