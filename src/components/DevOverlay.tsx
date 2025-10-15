import { buildTime, commitSHA } from "@lib/shims";
import clsx from "clsx";
import { useEffect, useState } from "react";

const DEV_HOST_KEY = "dev-server-host";
const DEFAULT_DEV_HOST = "http://localhost:8080";
const MINIMIZE_KEY = "dev-overlay-minimized";

const normalizeDevHost = (url: string) => {
  // Replace 0.0.0.0 with localhost for macOS sandbox compatibility
  return url.replace("://0.0.0.0:", "://localhost:");
};

const testLocalhostConnect = async (baseUrl: string) => {
  try {
    const normalizedUrl = normalizeDevHost(baseUrl);
    const resp = await fetch(normalizedUrl, { method: "HEAD" });
    return resp.ok;
  } catch {
    return false;
  }
};

export function DevOverlay() {
  const [isDevServer, setIsDevServer] = useState(false);
  const [devHost, setDevHost] = useState(() => {
    return localStorage.getItem(DEV_HOST_KEY) || DEFAULT_DEV_HOST;
  });
  const [isEditing, setIsEditing] = useState(false);
  const [editValue, setEditValue] = useState(devHost);
  const [isMinimized, setIsMinimized] = useState(() => {
    return localStorage.getItem(MINIMIZE_KEY) === "true";
  });

  useEffect(() => {
    const checkDevServer = async () => {
      const result = await testLocalhostConnect(devHost);
      setIsDevServer(result);
    };
    checkDevServer();
    const interval = setInterval(checkDevServer, 5000);
    return () => clearInterval(interval);
  }, [devHost]);

  const handleSaveHost = () => {
    const trimmed = editValue.trim();
    if (trimmed) {
      setDevHost(trimmed);
      localStorage.setItem(DEV_HOST_KEY, trimmed);
      setIsEditing(false);

      // Notify Swift/native code about the dev server URL change
      if (window.webkit?.messageHandlers?.controller) {
        window.webkit.messageHandlers.controller.postMessage({
          action: "set-dev-server-url",
          url: trimmed,
        });
      }
    }
  };

  const handleReload = () => location.reload();

  const toggleMinimize = () => {
    const newState = !isMinimized;
    setIsMinimized(newState);
    localStorage.setItem(MINIMIZE_KEY, String(newState));
  };

  if (isMinimized) {
    return (
      <div
        className="fixed top-2 right-2 z-50 text-xs font-mono rounded bg-slate-900/80 text-slate-100 dark:bg-slate-700/80 backdrop-blur px-2 py-1 shadow-lg select-none cursor-pointer hover:bg-slate-800/90"
        onClick={toggleMinimize}
        title="Click to expand"
      >
        <div className="flex items-center gap-2">
          <span
            className={clsx(
              "inline-block size-2 rounded-full",
              isDevServer ? "bg-green-400 animate-pulse" : "bg-yellow-400",
            )}
          />
          <span className="opacity-60 text-[11px]">
            {commitSHA.slice(0, 8)}
          </span>
        </div>
      </div>
    );
  }

  return (
    <div className="fixed top-2 right-2 z-50 text-xs font-mono rounded bg-slate-900/80 text-slate-100 dark:bg-slate-700/80 backdrop-blur px-3 py-2 shadow-lg space-y-1 select-none max-w-xs">
      <div className="flex items-center gap-2">
        <span
          className={clsx(
            "inline-block size-2 rounded-full",
            isDevServer ? "bg-green-400 animate-pulse" : "bg-yellow-400",
          )}
        />
        <span>{isDevServer ? "Dev Server" : "Bundled HTML"}</span>
        <button
          onClick={toggleMinimize}
          className="ml-auto text-slate-400 hover:text-slate-200"
          title="Minimize"
        >
          <svg
            className="size-4"
            fill="none"
            stroke="currentColor"
            strokeWidth={2}
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M19.5 12h-15"
            />
          </svg>
        </button>
      </div>

      {isEditing ? (
        <div className="space-y-1">
          <input
            type="text"
            value={editValue}
            onChange={(e) => setEditValue(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter") {
                handleSaveHost();
              }
              if (e.key === "Escape") {
                setEditValue(devHost);
                setIsEditing(false);
              }
            }}
            className="w-full bg-slate-800 border border-slate-600 rounded px-2 py-1 text-[11px] focus:outline-none focus:border-blue-400"
            placeholder="http://localhost:8080"
            autoFocus
          />
          <div className="flex gap-1">
            <button
              onClick={handleSaveHost}
              className="flex-1 rounded bg-blue-600 hover:bg-blue-500 text-white py-1 text-[11px]"
            >
              Save
            </button>
            <button
              onClick={() => {
                setEditValue(devHost);
                setIsEditing(false);
              }}
              className="flex-1 rounded bg-slate-700 hover:bg-slate-600 text-slate-200 py-1 text-[11px]"
            >
              Cancel
            </button>
          </div>
        </div>
      ) : (
        <div
          className="opacity-70 text-[11px] cursor-pointer hover:opacity-100 truncate flex items-center gap-1"
          onClick={() => setIsEditing(true)}
          title={`Click to edit dev server URL\nCurrent: ${devHost}`}
        >
          <span className="truncate">{devHost}</span>
          <svg
            className="size-3 shrink-0"
            fill="none"
            stroke="currentColor"
            strokeWidth={2}
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L10.582 16.07a4.5 4.5 0 01-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 011.13-1.897l8.932-8.931zm0 0L19.5 7.125M18 14v4.75A2.25 2.25 0 0115.75 21H5.25A2.25 2.25 0 013 18.75V8.25A2.25 2.25 0 015.25 6H10"
            />
          </svg>
        </div>
      )}

      <div className="opacity-80">Build: {buildTime}</div>
      <div className="opacity-60 truncate" title={commitSHA}>
        SHA: {commitSHA.slice(0, 8)}
      </div>
      <button
        className="mt-1 w-full rounded bg-slate-800 hover:bg-slate-700 active:bg-slate-600 text-slate-100 py-1 text-[11px] border border-slate-600"
        onClick={handleReload}
      >
        Reload (Cmd+R)
      </button>
    </div>
  );
}
