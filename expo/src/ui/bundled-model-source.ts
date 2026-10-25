import { useEffect, useState } from 'react';
import { Asset } from 'expo-asset';
import { File } from 'expo-file-system';
import { Platform } from 'react-native';
const resolved = new Map<number, string>();
const pending = new Map<number, Promise<string>>();
export interface BundledModelSceneProps {
  source: number;
  label: string;
  playing: boolean;
  cameraOrbit?: string;
  cameraTarget?: string;
}
export async function loadModel(module: number): Promise<string> {
  const cached = resolved.get(module);
  if (cached) return cached;
  const inflight = pending.get(module);
  if (inflight) return inflight;
  const request = (async () => {
    const asset = Asset.fromModule(module);
    let encoded: string;
    if (Platform.OS === 'web') {
      // Metro may advertise HTTP even when the app is reached via HTTPS.
      // Fetch its identical path through this origin to avoid mixed content.
      const original = new URL(asset.uri, globalThis.location?.href);
      const uri = globalThis.location?.origin
        ? new URL(`${original.pathname}${original.search}`, globalThis.location.origin).href
        : original.href;
      const response = await fetch(uri, { signal: AbortSignal.timeout(15_000) });
      if (!response.ok) throw new Error(`Bundled model unavailable (${response.status})`);
      const bytes = new Uint8Array(await response.arrayBuffer());
      let binary = '';
      for (let offset = 0; offset < bytes.length; offset += 8192)
        binary += String.fromCharCode(...bytes.subarray(offset, offset + 8192));
      encoded = btoa(binary);
    } else {
      await asset.downloadAsync();
      encoded = await new File(asset.localUri ?? asset.uri).base64();
    }
    const uri = `data:model/gltf-binary;base64,${encoded}`;
    resolved.set(module, uri);
    return uri;
  })();
  pending.set(module, request);
  try {
    return await request;
  } finally {
    pending.delete(module);
  }
}
export function useBundledModelSource(module: number) {
  const [state, setState] = useState<{ module: number; uri?: string; failed?: boolean }>(() => ({
    module,
    uri: resolved.get(module),
  }));
  useEffect(() => {
    let active = true;
    void loadModel(module)
      .then((uri) => {
        if (active) setState({ module, uri });
      })
      .catch(() => {
        if (active) setState({ module, failed: true });
      });
    return () => {
      active = false;
    };
  }, [module]);
  return state.module === module ? state : { module, uri: resolved.get(module) };
}
