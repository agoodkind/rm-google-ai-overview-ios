import { verbose } from "@/lib/shims";
import type { Platform } from "@components/AppWebView";
import { useEffect, useState } from "react";

export interface SafariExtensionState {
  platform: Platform | null;
  enabled: boolean | null;
  useSettings: boolean | null;
}

const containsDetails = (detail: unknown): detail is SafariExtensionState => {
  return (
    typeof detail === "object" &&
    detail !== null &&
    "platform" in detail &&
    "enabled" in detail &&
    "useSettings" in detail
  );
};

export function useSafariExtensionState(): SafariExtensionState {
  const [platform, setPlatform] = useState<Platform | null>(null);
  const [enabled, setEnabled] = useState<boolean | null>(null);
  const [useSettings, setUseSettings] = useState<boolean | null>(null);

  useEffect(() => {
    const onStateEvent = (e: Event) => {
      if (!(e instanceof CustomEvent)) {
        return;
      }

      if (e.type !== "safari-extension-state" || !containsDetails(e.detail)) {
        return;
      }

      if (verbose) {
        console.debug("Received safari-extension-state event:", e.detail, {
          full: e,
        });
      }

      const {
        detail: { platform, enabled, useSettings },
      } = e;

      setPlatform(platform);
      setEnabled(enabled);
      setUseSettings(useSettings);
    };

    // add the listener
    window.addEventListener("safari-extension-state", onStateEvent);

    // request the state if we don't have it yet
    // the app will respond by emitting a "safari-extension-state" event
    if (![platform, enabled, useSettings].filter(Boolean).length) {
      window.webkit?.messageHandlers?.controller?.postMessage("request-state");
    }

    return () => {
      window.removeEventListener("safari-extension-state", onStateEvent);
    };
  }, []);

  return { platform, enabled, useSettings };
}
