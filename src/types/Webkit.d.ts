/**
 * Safari WebKit message handler types
 */
export type Platform = "ios" | "mac";

declare global {
  interface Window {
    webkit?: {
      messageHandlers?: {
        controller?: {
          postMessage: (message: string) => void;
        };
      };
    };
    platform: Platform | null;
    enabled: boolean | null;
    useSettings: boolean | null;
  }
}

export global {}
