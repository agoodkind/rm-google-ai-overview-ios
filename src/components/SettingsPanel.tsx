import clsx from "clsx";
import { useState } from "react";

const DISPLAY_MODE_KEY = "rm-ai-display-mode";
type DisplayMode = "hide" | "highlight";

export function SettingsPanel() {
  const [displayMode, setDisplayMode] = useState<DisplayMode>(() => {
    const saved = localStorage.getItem(DISPLAY_MODE_KEY);
    return saved === "highlight" ? "highlight" : "hide";
  });

  const handleDisplayModeChange = async (mode: DisplayMode) => {
    setDisplayMode(mode);
    localStorage.setItem(DISPLAY_MODE_KEY, mode);

    // Send to native app via webkit message handler
    try {
      window.webkit?.messageHandlers?.controller?.postMessage({
        action: "set-display-mode",
        mode: mode,
      });
    } catch (err) {
      console.warn("Failed to send display mode to native:", err);
    }
  };
  return (
    <div className="bg-white dark:bg-slate-800 rounded-lg shadow-lg p-6 max-w-md w-full">
      <h2 className="text-lg font-semibold text-slate-900 dark:text-slate-100 mb-4">
        Extension Settings
      </h2>

      <div className="space-y-4">
        <div>
          <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
            Display Mode
          </label>
          <p className="text-xs text-slate-500 dark:text-slate-400 mb-3">
            Choose whether to hide AI overview elements completely or highlight
            them with an orange border.
          </p>
          <div className="flex gap-2">
            <button
              onClick={() => handleDisplayModeChange("hide")}
              className={clsx(
                "flex-1 rounded-lg py-3 px-4 text-sm font-medium border-2 transition-all",
                displayMode === "hide"
                  ? "bg-blue-600 border-blue-600 text-white shadow-md"
                  : "bg-white dark:bg-slate-700 border-slate-300 dark:border-slate-600 text-slate-700 dark:text-slate-300 hover:border-blue-400 dark:hover:border-blue-500",
              )}
            >
              <div className="flex flex-col items-center gap-1">
                <svg
                  className="w-5 h-5"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth={2}
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    d="M3.98 8.223A10.477 10.477 0 001.934 12C3.226 16.338 7.244 19.5 12 19.5c.993 0 1.953-.138 2.863-.395M6.228 6.228A10.45 10.45 0 0112 4.5c4.756 0 8.773 3.162 10.065 7.498a10.523 10.523 0 01-4.293 5.774M6.228 6.228L3 3m3.228 3.228l3.65 3.65m7.894 7.894L21 21m-3.228-3.228l-3.65-3.65m0 0a3 3 0 10-4.243-4.243m4.242 4.242L9.88 9.88"
                  />
                </svg>
                <span>Hide</span>
              </div>
            </button>

            <button
              onClick={() => handleDisplayModeChange("highlight")}
              className={clsx(
                "flex-1 rounded-lg py-3 px-4 text-sm font-medium border-2 transition-all",
                displayMode === "highlight"
                  ? "bg-orange-600 border-orange-600 text-white shadow-md"
                  : "bg-white dark:bg-slate-700 border-slate-300 dark:border-slate-600 text-slate-700 dark:text-slate-300 hover:border-orange-400 dark:hover:border-orange-500",
              )}
            >
              <div className="flex flex-col items-center gap-1">
                <svg
                  className="w-5 h-5"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth={2}
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
                <span>Highlight</span>
              </div>
            </button>
          </div>
        </div>

        <div className="pt-4 border-t border-slate-200 dark:border-slate-700">
          <p className="text-xs text-slate-500 dark:text-slate-400">
            <strong>Hide:</strong> Completely removes AI overview sections from
            view.
          </p>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-2">
            <strong>Highlight:</strong> Shows AI overview sections with an
            orange border so you can see what's being detected.
          </p>
        </div>
      </div>
    </div>
  );
}
