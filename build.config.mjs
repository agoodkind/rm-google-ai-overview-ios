// esbuild entry points using in/out format for custom output paths
// See: https://esbuild.github.io/api/#entry-points

/** @type {Array<{in: string, out: string}>} */
export const entryPoints = [
  {
    in: "src/contexts/page/ContentScript.ts",
    out: "xcode/Shared (Extension)/Resources/content",
  },
  {
    in: "src/contexts/background/ServiceWorker.ts",
    out: "xcode/Shared (Extension)/Resources/service-worker",
  },
  {
    in: "src/contexts/app/AppSharedScript.ts",
    out: "xcode/Shared (App)/Resources/Script",
  },
  {
    in: "src/styles/App.css",
    out: "xcode/Shared (App)/Resources/Style",
  },
];
