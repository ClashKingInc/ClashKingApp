export function hideWebLaunchScreen(): void {
  document.getElementById('splash')?.remove();
  document.body.style.background = 'transparent';
}
