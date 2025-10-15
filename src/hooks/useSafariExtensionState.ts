import type { Platform } from "@components/AppWebView";
import { useEffect, useState } from "react";

const STORAGE_KEYS = {
  platform: "safari.platform",
  enabled: "safari.extensionEnabled",
  useSettings: "safari.useSettings",
} as const;

function readBoolean(key: string): boolean | null {
  try {
    const v = localStorage.getItem(key);
    return v == null ? null : v === "true";
  } catch {
    return null;
  }
}
function readPlatform(): Platform | null {
  try {
    return (
      (localStorage.getItem(STORAGE_KEYS.platform) as Platform | null) ?? null
    );
  } catch {
    return null;
  }
}

export interface SafariExtensionState {
  platform: Platform | null;
  enabled: boolean | null;
  // true => show "Safari Settings" wording
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
  const [platform, setPlatform] = useState<Platform | null>(readPlatform());
  const [enabled, setEnabled] = useState<boolean | null>(
    readBoolean(STORAGE_KEYS.enabled),
  );
  const [useSettings, setUseSettings] = useState<boolean | null>(
    readBoolean(STORAGE_KEYS.useSettings),
  );

  useEffect(() => {
    const onStateEvent = (e: Event) => {
      if (!(e instanceof CustomEvent)) {
        return;
      }

      if (!containsDetails(e.detail)) {
        return;
      }

      const {
        detail: { platform, enabled, useSettings },
      } = e;

      setPlatform(platform);
      setEnabled(enabled);
      setUseSettings(useSettings);
    };

    window.addEventListener(
      "safari-extension-state",
      onStateEvent as EventListener,
    );

    if ([platform, enabled, useSettings].some((v) => v == null)) {
      window.webkit?.messageHandlers?.controller?.postMessage("request-state");
    }

    return () => {
      window.removeEventListener(
        "safari-extension-state",
        onStateEvent as EventListener,
      );
    };
  }, []);

  return { platform, enabled, useSettings };
}
