import { createElement } from 'react';
import { StyleSheet, View } from 'react-native';

import { isTrustedHttpsUrl } from '../data';
import type { AnnouncementWebViewProps } from './announcement-webview-contract';

export function AnnouncementWebView({ html, url, onPageFinished }: AnnouncementWebViewProps) {
  const trustedUrl = isTrustedHttpsUrl(url) ? url : undefined;
  return (
    <View style={styles.container}>
      {createElement('iframe', {
        onLoad: () => onPageFinished?.(trustedUrl ?? 'about:srcdoc'),
        referrerPolicy: 'no-referrer',
        sandbox: '',
        src: trustedUrl,
        srcDoc: trustedUrl ? undefined : (html ?? ''),
        style: {
          width: '100%',
          height: '100%',
          border: 0,
          background: 'transparent',
        },
        title: 'ClashKing announcement',
      })}
    </View>
  );
}

const styles = StyleSheet.create({ container: { flex: 1 } });
