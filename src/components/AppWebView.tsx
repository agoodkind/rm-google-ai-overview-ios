import { useState } from "react";

export type Platform = "ios" | "mac";

export function AppWebView() {
  const [platform, setPlatform] = useState<Platform | null>(
    window.platform ?? null,
  );
  const [state, setState] = useState<boolean | null>(window.enabled ?? null);
  const [useSettingsInsteadOfPreferences, setUseSettingsInsteadOfPreferences] =
    useState<boolean | null>(window.useSettings ?? null);

  const getButtonText = () => {
    return useSettingsInsteadOfPreferences
      ? "Quit and Open Safari Settings…"
      : "Quit and Open Safari Extensions Preferences…";
  };

  const getStateMessage = () => {
    if (platform === "ios") {
      return "You can turn on Remove Google AI Overview's Safari extension in Settings.";
    }

    const location = useSettingsInsteadOfPreferences
      ? "the Extensions section of Safari Settings"
      : "Safari Extensions preferences";

    if (state === null) {
      return `You can turn on Remove Google AI Overview's extension in ${location}.`;
    }
    if (state === true) {
      return `Remove Google AI Overview's extension is currently on. You can turn it off in ${location}.`;
    }
    if (state === false) {
      return `Remove Google AI Overview's extension is currently off. You can turn it on in ${location}.`;
    }
  };

  const handleOpenPreferences = () => {
    if (window.webkit?.messageHandlers?.controller) {
      window.webkit.messageHandlers.controller.postMessage("open-preferences");
    }
  };

  return (
    <div className="flex h-screen items-center justify-center flex-col gap-5 mx-10 text-center select-none bg-white text-slate-900 dark:bg-slate-800 dark:text-slate-100 transition-colors">
      <img
        src="../icon.png"
        width="128"
        height="128"
        alt="Remove Google AI Overview Icon"
        className="pointer-events-none drop-shadow-sm dark:drop-shadow md:transition-opacity"
      />
      <p className="font-system text-base leading-relaxed max-w-xs text-slate-700 dark:text-slate-200">
        {getStateMessage()}
      </p>
      {platform === "mac" && (
        <button
          onClick={handleOpenPreferences}
          className="text-base cursor-default px-4 py-2 rounded-md bg-slate-200/80 dark:bg-slate-700/70 backdrop-blur border border-slate-300 dark:border-slate-600 hover:bg-slate-200 dark:hover:bg-slate-600/80 focus-visible:outline focus-visible:outline-2 focus-visible:outline-blue-500 transition-colors"
        >
          {getButtonText()}
        </button>
      )}
    </div>
  );
}
