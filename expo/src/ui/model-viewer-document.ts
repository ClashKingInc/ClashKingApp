// Share the pinned renderer and camera behavior across badges and hero scenes.
export const MODEL_VIEWER_SCRIPT =
  'https://unpkg.com/@google/model-viewer@4.1.0/dist/model-viewer.min.js';
export interface ModelViewerDocumentOptions {
  label: string;
  interactive?: boolean;
  idleRotation?: boolean;
  locked?: boolean;
  eager?: boolean;
  animated?: boolean;
  cameraOrbit?: string;
  cameraTarget?: string;
}
export function buildModelViewerDocument(
  source: string,
  options: ModelViewerDocumentOptions,
): string {
  const {
    label,
    interactive = false,
    idleRotation = false,
    locked = false,
    eager = false,
    animated = false,
  } = options;
  const attributes = [
    `src="${escapeAttribute(source)}"`,
    `alt="${escapeAttribute(label)}"`,
    `loading="${interactive || eager ? 'eager' : 'lazy'}"`,
    'reveal="auto"',
    'disable-pan',
    'disable-tap',
    'disable-zoom',
    'interaction-prompt="none"',
    `camera-orbit="${escapeAttribute(options.cameraOrbit ?? '0deg 75deg 105%')}"`,
    'field-of-view="32deg"',
    'environment-image="neutral"',
    'shadow-intensity="0.7"',
    'shadow-softness="0.9"',
  ];
  // Hero albedo should stay colorful under studio light. Keep this scoped to
  // animated hero scenes; badge lighting and locked states are independent.
  if (animated) attributes.push('tone-mapping="neutral"', 'exposure="1.2"');
  if (options.cameraTarget)
    attributes.push(`camera-target="${escapeAttribute(options.cameraTarget)}"`);
  if (interactive) {
    attributes.push(
      'camera-controls',
      'min-camera-orbit="auto 75deg 105%"',
      'max-camera-orbit="auto 75deg 105%"',
      'interpolation-decay="200"',
    );
    if (idleRotation)
      attributes.push('auto-rotate', 'auto-rotate-delay="3000"', 'rotation-per-second="18deg"');
  }
  const filter = locked ? 'filter:grayscale(1) saturate(0) opacity(0.44);' : '';
  // Playback messages never enable camera gestures. The containing carousel
  // owns all input while the selected hero can play its intrinsic animation.
  const playback = animated
    ? // The GLB bind pose is not its idle pose. Hide the first canvas until the
      // idle clip and skin matrices have rendered, so hero switches cannot flash
      // detached props or a previous backing surface through the transparent scene.
      `let playing=false;const apply=()=>{if(!viewer.play)return;if(playing)viewer.play();else viewer.pause();};const receive=event=>{let value=event.data;try{if(typeof value==='string')value=JSON.parse(value);}catch{return;}if(value?.type==='ck-model-playback'){playing=value.playing===true;apply();}};window.addEventListener('message',receive);document.addEventListener('message',receive);viewer.addEventListener('load',async()=>{const idle=viewer.availableAnimations?.find(name=>/idle|stand/i.test(name));if(idle)viewer.animationName=idle;viewer.currentTime=0;apply();await viewer.updateComplete;requestAnimationFrame(()=>requestAnimationFrame(()=>{viewer.style.opacity='1';}));});`
    : '';
  // Replace model-viewer's default 5px black loading strip through its public
  // slot. Our skeleton already signals loading; the strip flashes above every
  // transparent hero canvas and is unrelated to the native scroll edge effect.
  return `<!doctype html>
<html><head><meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<style>html,body{width:100%;height:100%;margin:0;overflow:hidden;background:transparent}model-viewer{width:100%;height:100%;--poster-color:transparent;touch-action:none;${animated ? 'opacity:0;' : ''}${filter}}#loading{position:absolute;inset:0;display:grid;place-items:center;pointer-events:none}#loading:after{content:"";width:85%;height:85%;border-radius:24px;background:#8884;animation:pulse 1.8s ease-in-out infinite}@keyframes pulse{0%,100%{opacity:.42}50%{opacity:.82}}@media(prefers-reduced-motion:reduce){#loading:after{animation:none;opacity:.62}}</style>
<script type="module" src="${MODEL_VIEWER_SCRIPT}"></script></head>
<body><model-viewer ${attributes.join(' ')}><span slot="progress-bar" style="display:none"></span></model-viewer><div id="loading" role="progressbar" aria-label="${escapeAttribute(label)}"></div><script>const viewer=document.querySelector('model-viewer');const done=()=>document.getElementById('loading')?.remove();viewer.addEventListener('load',done);viewer.addEventListener('error',done);${playback}</script></body></html>`;
}
function escapeAttribute(value: string): string {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('"', '&quot;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');
}
