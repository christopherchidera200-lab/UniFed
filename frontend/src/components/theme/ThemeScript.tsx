/** Inline script that applies the persisted theme (light/dark) to <html>
 *  BEFORE first paint, preventing a flash of the wrong theme. */
export function ThemeScript() {
  const code = `(function(){try{var t=localStorage.getItem('unifed-theme');if(t==='dark'||(!t&&window.matchMedia('(prefers-color-scheme: dark)').matches)){document.documentElement.classList.add('dark');}}catch(e){}})();`;
  return <script dangerouslySetInnerHTML={{ __html: code }} />;
}
