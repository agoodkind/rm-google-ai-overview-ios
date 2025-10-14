import { AppWebView } from '@components/AppWebView';
import '@lib/shims';
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';

const root = createRoot(document.getElementById('root')!);

root.render(
  <StrictMode>
    <>
      <AppWebView />
    </>
  </StrictMode>,
);
