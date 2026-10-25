# Bundled hero renderer

Pinned upstream source: https://unpkg.com/@google/model-viewer@4.1.0/dist/model-viewer.min.js
Fetched 2026-10-24, unchanged, saved as `model-viewer-4.1.0.txt` for Metro asset delivery.
Upstream package license: `model-viewer-LICENSE.txt`; bundled third-party notices remain in the source.

Hero GLBs already contain their geometry and textures. The calculator now loads one local renderer in one WebView and shares it across its six model-viewer elements. Selected model decodes first, then adjacent heroes; hidden animations are paused. Source strings are reused in memory on later visits. There is no CDN runtime request on the calculator path. This does not eliminate native WebView startup or GPU/model decoding after leaving and reopening the page.
