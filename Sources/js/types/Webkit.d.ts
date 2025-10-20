/**
 * Safari WebKit message handler types
 */
export type Platform = "ios" | "mac";

declare global {
  interface Window {
    webkit?: {
      messageHandlers: {
        [x: string]: {
          postMessage: (data: unknown) => void;
        };
      };
    };
  }
}
export global {}
