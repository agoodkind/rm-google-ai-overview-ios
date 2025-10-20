// esbuild entry points using in/out format for custom output paths
// See: https://esbuild.github.io/api/#entry-points

/** @type {Array<{in: string, out: string}>} */
export const entryPoints = [
  {
    in: "src/contexts/page/ContentScript.ts",
    out: "dist/webext/content",
  },
  {
    in: "src/contexts/background/Background.ts",
    out: "dist/webext/background",
  },
  {
    in: "src/contexts/app/AppSharedScript.ts",
    out: "dist/app/Script",
  },
  {
    in: "src/styles/App.css",
    out: "dist/app/Style",
  },
];
