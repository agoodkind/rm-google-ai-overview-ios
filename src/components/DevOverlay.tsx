import { buildTime, commitSHA } from "@lib/shims";
import clsx from "clsx";
import { useEffect, useState } from "react";

const testLocalhostConnect = async () => {
  try {
    const resp = await fetch("http://localhost:5173/", { method: "HEAD" });
    return resp.ok;
  } catch {
    return false;
  }
};

/** Simple corner overlay showing dev server status + manual reload */
export function DevOverlay() {
  const [isDevServer, setIsDevServer] = useState(false);

  useEffect(() => {
    const checkDevServer = async () => {
      const result = await testLocalhostConnect();
      setIsDevServer(result);
    };
    checkDevServer();
  }, []);

  const handleReload = () => location.reload();

  return (
    <div className="fixed top-2 right-2 z-50 text-xs font-mono rounded bg-slate-900/80 text-slate-100 dark:bg-slate-700/80 backdrop-blur px-3 py-2 shadow-lg space-y-1 select-none">
      <div className="flex items-center gap-2">
        <span
          className={clsx(
            "inline-block size-2 rounded-full",
            isDevServer ? "bg-green-400 animate-pulse" : "bg-yellow-400",
          )}
        />
        <span>{isDevServer ? "Dev Server" : "Bundled HTML"}</span>
      </div>
      <div className="opacity-80">Build: {buildTime}</div>
      <div className="opacity-60 max-w-[16rem]">SHA: {commitSHA}</div>
      <button
        className="mt-1 w-full rounded bg-slate-800 hover:bg-slate-700 active:bg-slate-600 text-slate-100 py-1 text-[11px] border border-slate-600"
        onClick={handleReload}
      >
        Reload (Cmd+R)
      </button>
    </div>
  );
}
