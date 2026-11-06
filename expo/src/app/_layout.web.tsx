/** The browser is only a handoff surface. Do not mount native app providers,
 * authentication, data fetching, or the route Slot on web. */
export default function WebLandingLayout() {
  const destination =
    typeof window === 'undefined' ? '/' : window.location.pathname + window.location.search;
  return (
    <iframe
      title="Open ClashKing"
      src={'/app-landing.html?destination=' + encodeURIComponent(destination)}
      style={{
        position: 'fixed',
        inset: 0,
        width: '100%',
        height: '100%',
        border: 0,
        background: '#09090b',
      }}
    />
  );
}
