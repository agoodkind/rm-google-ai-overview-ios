// esbuild entry points using in/out format for custom output paths
// See: https://esbuild.github.io/api/#entry-points

/** @type {Array<{in: string, out: string}>} */
export const entryPoints = [
  {
    in: "src/Content.ts",
    out: "xcode/Shared (Extension)/Resources/content",
  },
  {
    in: "src/SharedAppView.tsx",
    out: "xcode/Shared (App)/Resources/Script",
  },
  {
    in: "src/styles/App.css",
    out: "xcode/Shared (App)/Resources/Style",
  },
];
