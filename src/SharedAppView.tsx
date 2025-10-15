import { AppWebView } from "@components/AppWebView";
import { DevOverlay } from "@components/DevOverlay";
import { isDev, verbose } from "@lib/shims";
import { StrictMode } from "react";
import { createRoot } from "react-dom/client";

if (verbose) {
  console.log(`Build time: ${process.env.BUILD_TS}`);
  console.log(`Commit SHA: ${process.env.COMMIT_SHA || "unknown"}`);
  console.log(`Current host: ${location.host}`);
}

export const doRender = () => {
  if (verbose) {
    console.log("Starting initial render of SharedAppView…");
  }
  const root = createRoot(document.getElementById("root")!);
  root.render(
    <StrictMode>
      <>
        <AppWebView />
        {isDev ? <DevOverlay /> : null}
      </>
    </StrictMode>,
  );
  if (verbose) {
    console.log("Created root and called render: SharedAppView.");
  }
};

doRender();
