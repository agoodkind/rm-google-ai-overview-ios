/**
 * Safari WebKit message handler types
 */
type Platform = 'ios' | 'mac';

declare global {
  interface Window {
    webkit?: {
      messageHandlers?: {
        controller?: {
          postMessage: (message: string) => void;
        };
      };
    };
    show?: (platform: Platform, enabled?: boolean, useSettings?: boolean) => void;
  }
}
