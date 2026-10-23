# Badge delivery contract

Compatible with ClashKingAPI PR #59, reviewed at `177e889cfc4ec4c322513c5ec00834d04cc8fad2`.

App badges use `https://badges.clashk.ing/TAG.avif?size=N`, with PNG as the decoding/error fallback at the same size. `N` rounds rendered width/height times device scale up to 64, 128, 256, or 512. Unknown dimensions use 512; requests never exceed the upstream 512px badge.

Widgets use explicit `.png?size=256`. The iOS widget's largest badge is 56 points (168 pixels at 3x); 256 also covers typical Android widget densities. Native loaders normalize old saved badge URLs to PNG with this supported size. In-app widget selection continues to use AVIF. Cache keys contain only tag, format, and size; no cache-busters or hints are embedded in URLs.

## Optional token hints

Native Expo Image requests attach `X-ClashKing-Badge-Token` when the owning clan API data provides `badgeToken` or an authoritative `https://api-assets.clashofclans.com/badges/{70|200|512}/TOKEN.png` URL. Model parsing retains the hint in a bounded in-memory tag map while generating canonical badge URLs. Requests to any other origin receive no hint.

The token is never part of a URL or cache key. Expo Image explicitly uses the canonical URL as its cache key. The managed filesystem downloader also passes the optional header without changing its URL-based key; currently that downloader manages manifest assets, while badge images use Expo Image directly.

There is no signature or shared secret. Web image paths omit the optional header. Native widget loaders retain PNG URLs but do not currently receive the JavaScript token map, so their requests rely on the Worker's normal mapping lookup. Hints are unavailable when an API response provides only a first-party badge URL with no token or official upstream badge URL.
