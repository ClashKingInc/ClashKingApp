import type { ReactNode } from 'react';

/** Browser development has the same landing-only boundary as the static site. */
export default function RootHtml({ children }: { readonly children: ReactNode }) {
  return (
    <html lang="en">
      <head>
        <meta charSet="utf-8" />
        <meta name="viewport" content="width=device-width,initial-scale=1" />
        <meta name="theme-color" content="#09090b" />
        <title>Open ClashKing</title>
      </head>
      <body style={{ margin: 0, background: '#09090b' }}>{children}</body>
    </html>
  );
}
