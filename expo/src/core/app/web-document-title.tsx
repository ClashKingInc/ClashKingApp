// Native must not render Expo Head: it enables handoff and requires a build-time
// origin. Browser titles belong only in the platform-specific web implementation.
export function WebDocumentTitle() {
  return null;
}
