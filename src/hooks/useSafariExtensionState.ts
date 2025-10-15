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

export function useSafariExtensionState(): SafariExtensionState {
  const [platform, setPlatform] = useState<Platform | null>(
    window.platform ?? readPlatform(),
  );
  const [enabled, setEnabled] = useState<boolean | null>(
    window.enabled ?? readBoolean(STORAGE_KEYS.enabled),
  );
  const [useSettings, setUseSettings] = useState<boolean | null>(
    window.useSettings ?? readBoolean(STORAGE_KEYS.useSettings),
  );

  useEffect(() => {
    const onStateEvent = (e: Event) => {
      const detail = (e as CustomEvent).detail as {
        platform?: Platform;
        enabled?: boolean | null;
        useSettings?: boolean | null;
      };
      if (detail.platform !== undefined) {
        setPlatform(detail.platform);
      }
      if (detail.enabled !== undefined) {
        setEnabled(detail.enabled);
      }
      if (detail.useSettings !== undefined) {
        setUseSettings(detail.useSettings);
      }
    };
    window.addEventListener(
      "safari-extension-state",
      onStateEvent as EventListener,
    );

    if ([platform, enabled, useSettings].some((v) => v == null)) {
      try {
        window.webkit?.messageHandlers?.controller?.postMessage(
          "request-state",
        );
      } catch {
        /* ignore */
      }
    }
    return () => {
      window.removeEventListener(
        "safari-extension-state",
        onStateEvent as EventListener,
      );
    };
    // mount only (request triggers handled by native)
  }, []);

  useEffect(() => {
    try {
      if (platform != null) {
        localStorage.setItem(STORAGE_KEYS.platform, platform);
      }
      if (enabled != null) {
        localStorage.setItem(STORAGE_KEYS.enabled, String(enabled));
      }
      if (useSettings != null) {
        localStorage.setItem(STORAGE_KEYS.useSettings, String(useSettings));
      }
    } catch {
      /* ignore */
    }
  }, [platform, enabled, useSettings]);

  return { platform, enabled, useSettings };
}
