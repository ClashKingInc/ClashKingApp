/** Resume and login share the service's one-minute request throttling. */
export function startGameDataRefresh(
  refresh: () => Promise<void>,
  isActive: () => boolean,
  listen: (callback: () => void) => () => void,
): () => void {
  const check = () => {
    if (isActive()) void refresh().catch(() => undefined);
  };
  check();
  const unsubscribe = listen(check);
  const timer = setInterval(check, 60_000);
  return () => {
    unsubscribe();
    clearInterval(timer);
  };
}
