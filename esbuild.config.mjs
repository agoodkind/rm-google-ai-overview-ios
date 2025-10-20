// esbuild entry points using in/out format for custom output paths
// See: https://esbuild.github.io/api/#entry-points

/** @type {Array<{in: string, out: string}>} */
export const entryPoints = [
  {
    in: "Sources/js/contexts/page/ContentScript.ts",
    out: "dist/webext/content",
  },
  {
    in: "Sources/js/contexts/background/Background.ts",
    out: "dist/webext/background",
  },
];
