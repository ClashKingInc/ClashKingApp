import { ScrollViewStyleReset, useServerDocumentContext } from 'expo-router/html';
import type { ReactNode } from 'react';

/**
 * Static web document matching the metadata and standalone behavior of the
 * Flutter web build while leaving runtime navigation to Expo Router.
 */
export default function RootHtml({ children }: { readonly children: ReactNode }) {
  const { bodyAttributes, bodyNodes, htmlAttributes, headNodes } = useServerDocumentContext();

  return (
    <html lang="en" {...htmlAttributes}>
      <head>
        <meta charSet="utf-8" />
        <meta httpEquiv="X-UA-Compatible" content="IE=edge" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <meta
          name="description"
          content="ClashKing helps players and clans track wars, upgrades, rankings, and account progress."
        />
        <meta name="apple-mobile-web-app-capable" content="yes" />
        <meta name="apple-mobile-web-app-status-bar-style" content="black" />
        <meta name="apple-mobile-web-app-title" content="ClashKing" />
        <meta name="theme-color" content="#0175C2" />
        <link rel="apple-touch-icon" href="/icons/Icon-192.png" />
        <link rel="icon" type="image/png" href="/favicon.png" />
        <link rel="manifest" href="/manifest.webmanifest" />
        <title>ClashKing</title>
        <ScrollViewStyleReset />
        {headNodes}
        <style
          dangerouslySetInnerHTML={{
            __html: `html,body,#root{height:100%;min-height:100%;margin:0}
body{background-color:#fff}
.center{margin:0;position:absolute;top:50%;left:50%;transform:translate(-50%,-50%)}
@media(prefers-color-scheme:dark){body{background-color:#000}}`,
          }}
        />
      </head>
      <body {...bodyAttributes}>
        <picture id="splash">
          <source
            srcSet="/splash/img/light-1x.png 1x, /splash/img/light-2x.png 2x, /splash/img/light-3x.png 3x, /splash/img/light-4x.png 4x"
            media="(prefers-color-scheme: light)"
          />
          <source
            srcSet="/splash/img/dark-1x.png 1x, /splash/img/dark-2x.png 2x, /splash/img/dark-3x.png 3x, /splash/img/dark-4x.png 4x"
            media="(prefers-color-scheme: dark)"
          />
          <img className="center" aria-hidden="true" src="/splash/img/light-1x.png" alt="" />
        </picture>
        {children}
        {bodyNodes}
        <script
          dangerouslySetInnerHTML={{
            __html:
              "if('serviceWorker' in navigator){window.addEventListener('load',function(){navigator.serviceWorker.register('/sw.js').catch(function(error){console.warn('ClashKing service worker registration failed',error);});});}",
          }}
        />
      </body>
    </html>
  );
}
