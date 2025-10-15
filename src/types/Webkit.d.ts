/**
 * Safari WebKit message handler types
 */
export type Platform = "ios" | "mac";

interface SafariExtensionStateDetail {
  platform?: Platform;
  enabled?: boolean | null;
  useSettings?: boolean | null;
}

type SafariExtensionStateEvent = CustomEvent<SafariExtensionStateDetail>;

interface DevServerMessage {
  action: "set-dev-server-url";
  url: string;
}

declare global {
  interface Window {
    webkit?: {
      messageHandlers?: {
        controller?: {
          postMessage: (message: string | DevServerMessage) => void;
        };
      };
    };
    platform: Platform | null;
    enabled: boolean | null; // unified name for extension enabled state
    extensionState?: boolean | null; // legacy alias if older injection used it
    useSettings: boolean | null;
    // Event dispatch helper (injected by native via evaluateJavaScript)
    dispatchEvent: (event: Event) => boolean;
    addEventListener: (
      type: "safari-extension-state" | string,
      listener: (this: Window, ev: Event | SafariExtensionStateEvent) => void,
      options?: boolean | AddEventListenerOptions,
    ) => void;
  }
  interface DocumentEventMap {
    "safari-extension-state": SafariExtensionStateEvent;
  }
  interface WindowEventMap {
    "safari-extension-state": SafariExtensionStateEvent;
  }
}

export global {}
