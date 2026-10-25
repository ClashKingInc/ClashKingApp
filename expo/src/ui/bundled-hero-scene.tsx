import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { Platform, StyleSheet, View } from 'react-native';
import { Asset } from 'expo-asset';
import { File } from 'expo-file-system';
import { WebView } from 'react-native-webview';
import { loadModel } from './bundled-model-source';
import { Skeleton } from './feedback';

export interface HeroSceneModel {
  source: number;
  label: string;
  target?: string;
  orbit?: string;
}
let renderer: Promise<string> | undefined;
function loadRenderer() {
  // The renderer is part of the app, just like the GLBs. Never make a CDN
  // round trip each time this calculator opens (including offline visits).
  return (renderer ??= (async () => {
    // eslint-disable-next-line @typescript-eslint/no-require-imports -- Metro requires a static bundled asset.
    const asset = Asset.fromModule(require('../../assets/clashking/heroes/model-viewer-4.1.0.txt'));
    if (Platform.OS === 'web') {
      const result = await fetch(asset.uri);
      if (!result.ok) throw new Error('Bundled renderer unavailable');
      return result.text();
    }
    await asset.downloadAsync();
    return new File(asset.localUri ?? asset.uri).text();
  })().catch((error: unknown) => {
    renderer = undefined;
    throw error;
  }));
}

export function BundledHeroScene({
  models,
  selected,
  playing,
}: {
  models: readonly HeroSceneModel[];
  selected: number;
  playing: boolean;
}) {
  const webview = useRef<WebView<object>>(null);
  const frame = useRef<HTMLIFrameElement>(null);
  const [engine, setEngine] = useState<string>();
  const [ready, setReady] = useState(false);
  const [failed, setFailed] = useState(false);
  const descriptor = JSON.stringify(
    models.map(({ label, target, orbit }) => ({ label, target, orbit })),
  );
  const sources = models.map(({ source }) => source).join(',');
  const document = useMemo(
    () => (engine ? buildScene(engine, descriptor) : undefined),
    [engine, descriptor],
  );
  const webSource = useMemo(() => ({ html: document ?? '' }), [document]);
  const initialSelected = useRef(selected);
  const pendingLoads = useRef(new Map<number, () => void>());
  const handleSceneMessage = useCallback((data: string) => {
    if (data === 'ck-hero-ready') {
      setReady(true);
      return;
    }
    try {
      const message = JSON.parse(data) as { type?: string; index?: number };
      if (message.type === 'loaded' && typeof message.index === 'number')
        pendingLoads.current.get(message.index)?.();
    } catch {
      /* Ignore messages unrelated to the local scene. */
    }
  }, []);
  useEffect(() => {
    let active = true;
    void loadRenderer()
      .then((script) => {
        if (active) setEngine(script);
      })
      .catch(() => {
        if (active) setFailed(true);
      });
    return () => {
      active = false;
    };
  }, []);
  const send = (value: object) => {
    const message = JSON.stringify(value);
    if (Platform.OS === 'web') frame.current?.contentWindow?.postMessage(message, '*');
    else webview.current?.postMessage(message);
  };
  useEffect(() => {
    if (!ready) return;
    send({ type: 'selection', selected, playing });
  }, [ready, selected, playing]);
  useEffect(() => {
    if (!ready) return;
    let active = true;
    const loads = pendingLoads.current;
    const entries = sources.split(',').map(Number);
    const first = initialSelected.current;
    const order = [
      first,
      (first + 1) % entries.length,
      (first + entries.length - 1) % entries.length,
      ...entries.map((_, index) => index),
    ];
    // One WebView/renderer serves every hero. Warm the visible hero first,
    // then its neighbors, instead of competing with six browser startups.
    void (async () => {
      for (const index of new Set(order)) {
        try {
          const uri = await loadModel(entries[index]!);
          if (!active) return;
          // Decode one at a time so later heroes cannot delay the visible hero.
          await new Promise<void>((resolve) => {
            const timer = setTimeout(done, 8000);
            function done() {
              clearTimeout(timer);
              loads.delete(index);
              resolve();
            }
            loads.set(index, done);
            send({ type: 'model', index, uri });
          });
        } catch {
          if (active) send({ type: 'failed', index });
        }
      }
    })();
    return () => {
      active = false;
      for (const finish of loads.values()) finish();
    };
  }, [ready, sources]);
  useEffect(() => {
    if (Platform.OS !== 'web') return;
    const receive = (event: MessageEvent) => {
      if (event.source === frame.current?.contentWindow && typeof event.data === 'string')
        handleSceneMessage(event.data);
    };
    window.addEventListener('message', receive);
    return () => window.removeEventListener('message', receive);
  }, [handleSceneMessage]);
  return (
    <View style={StyleSheet.absoluteFill} pointerEvents="none">
      {!document && !failed ? <Skeleton height="100%" radius={16} /> : null}
      {document ? (
        Platform.OS === 'web' ? (
          <iframe
            ref={frame}
            title={models[selected]?.label}
            sandbox="allow-scripts allow-same-origin"
            srcDoc={document}
            tabIndex={-1}
            aria-hidden
            style={{
              width: '100%',
              height: '100%',
              border: 0,
              background: 'transparent',
              pointerEvents: 'none',
            }}
          />
        ) : (
          <WebView<object>
            ref={webview}
            source={webSource}
            style={styles.webview}
            javaScriptEnabled
            cacheEnabled
            scrollEnabled={false}
            bounces={false}
            pointerEvents="none"
            originWhitelist={['about:*']}
            androidLayerType="hardware"
            setSupportMultipleWindows={false}
            onMessage={(event) => {
              handleSceneMessage(event.nativeEvent.data);
            }}
            onError={() => setFailed(true)}
            accessibilityElementsHidden
            importantForAccessibility="no-hide-descendants"
          />
        )
      ) : null}
    </View>
  );
}
const styles = StyleSheet.create({ webview: { flex: 1, backgroundColor: 'transparent' } });

function buildScene(engine: string, descriptor: string) {
  const metadata = descriptor.replaceAll('<', '\\u003c');
  return `<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<style>html,body{width:100%;height:100%;margin:0;overflow:hidden;background:transparent}model-viewer{position:absolute;top:0;height:100%;left:18%;width:64%;opacity:0;pointer-events:none;--poster-color:transparent}model-viewer[data-position="center"][data-ready]{opacity:1;z-index:2}model-viewer[data-position="previous"]{left:-15%;width:55%;transform:scale(.7)}model-viewer[data-position="next"]{left:60%;width:55%;transform:scale(.7)}model-viewer[data-position="previous"][data-ready],model-viewer[data-position="next"][data-ready]{opacity:.38;z-index:1}</style>
<script type="module">${engine.replace(/<\/script/gi, '<\\/script')}</script></head><body><script>
const metadata=${metadata};let selected=0,playing=false;function send(message){const data=JSON.stringify(message);if(window.ReactNativeWebView)window.ReactNativeWebView.postMessage(data);else window.parent.postMessage(data,'*');}
const viewers=metadata.map((item,index)=>{const v=document.createElement('model-viewer');const attrs={alt:item.label,loading:'eager',reveal:'auto','camera-orbit':item.orbit||'0deg 75deg 105%','camera-target':item.target||'auto auto auto','field-of-view':'32deg','environment-image':'neutral','shadow-intensity':'.7','shadow-softness':'.9','tone-mapping':'neutral',exposure:'1.2','interaction-prompt':'none'};for(const[k,value]of Object.entries(attrs))v.setAttribute(k,value);const bar=document.createElement('span');bar.slot='progress-bar';bar.style.display='none';v.append(bar);v.addEventListener('error',()=>send({type:'loaded',index}));v.addEventListener('load',async()=>{const idle=v.availableAnimations?.find(n=>/idle|stand/i.test(n));if(idle)v.animationName=idle;v.currentTime=0;update();await v.updateComplete;requestAnimationFrame(()=>requestAnimationFrame(()=>{v.dataset.ready='true';send({type:'loaded',index});}));});document.body.append(v);return v;});
function update(){viewers.forEach((v,index)=>{const relative=(index-selected+viewers.length)%viewers.length;v.dataset.position=relative===0?'center':relative===1?'next':relative===viewers.length-1?'previous':'parked';if(typeof v.play==='function'){if(index===selected&&playing)v.play();else v.pause();}});}
function receive(event){let m=event.data;try{if(typeof m==='string')m=JSON.parse(m);}catch{return;}if(m?.type==='selection'){selected=m.selected;playing=m.playing;update();}if(m?.type==='model'&&viewers[m.index])viewers[m.index].src=m.uri;}
window.addEventListener('message',receive);document.addEventListener('message',receive);customElements.whenDefined('model-viewer').then(()=>{update();if(window.ReactNativeWebView)window.ReactNativeWebView.postMessage('ck-hero-ready');else window.parent.postMessage('ck-hero-ready','*');});</script></body></html>`;
}
