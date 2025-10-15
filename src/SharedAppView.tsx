import { AppWebView } from "@components/AppWebView";
import { DevOverlay } from "@components/DevOverlay";
import { isDev } from "@lib/shims";
import { StrictMode } from "react";
import { createRoot } from "react-dom/client";

if (isDev) {
  console.log(`Build time: ${process.env.BUILD_TS}`);
  console.log(`Commit SHA: ${process.env.COMMIT_SHA || "unknown"}`);
  console.log(`Platform: ${window.platform}`);
  console.log(`Enabled: ${window.enabled}`);
  console.log(`Use Settings: ${window.useSettings}`);
  const devServerActive = /localhost:5173/.test(location.host);
  console.log(`Current host: ${location.host}`);
  console.log(`Dev Server (localhost:5173) Active: ${devServerActive}`);
}

export const doRender = () => {
  if (isDev) {
    console.log("Starting initial rend of SharedAppView…");
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
  if (isDev) {
    console.log("Created root and called render: SharedAppView.");
  }
};

doRender();

// Dev: add Cmd+R listener for manual reload when using dev server
if (isDev && /localhost:5173/.test(location.host)) {
  window.addEventListener("keydown", (e) => {
    if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "r") {
      e.preventDefault();
      location.reload();
    }
  });
}
