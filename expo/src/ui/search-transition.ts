export interface SearchFieldBounds {
  x: number;
  y: number;
  width: number;
  height: number;
}

// This is a one-shot navigation handoff, not persistent layout state. Direct
// links must never reuse the origin of an earlier search session.
let pendingOrigin: SearchFieldBounds | null = null;
export function setSearchFieldOrigin(bounds: SearchFieldBounds) {
  pendingOrigin = bounds;
}
export function getSearchFieldOrigin() {
  return pendingOrigin;
}
export function clearSearchFieldOrigin() {
  pendingOrigin = null;
}
