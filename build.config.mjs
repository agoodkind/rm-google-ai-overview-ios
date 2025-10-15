// Central declarative build configuration for JS/CSS bundle entries.
// Each entry is resolved relative to the project root by build.mjs.
// Fields:
// name   : unique identifier used for filtering (CLI: --only, --exclude)
// type   : 'script' | 'css'
// input  : source file (relative or absolute)
// output : target file path (relative or absolute). Parent folders must exist.
// format : optional esbuild output format for scripts (defaults to 'iife')
// target : optional JS target (defaults to 'es2022')
// jsx    : optional jsx mode (defaults to 'automatic')
//
// CLI Usage examples:
//   pnpm run build                # normal build (all entries)
//   node build.mjs --list         # list entries
//   node build.mjs --only appView # build single entry
//   node build.mjs --exclude appStyles
//   node build.mjs --watch --only extensionContent,appStyles

/** @typedef {import('./build.mjs').EntryConfig} EntryConfig */

/** @type {EntryConfig[]} */
export const entries = [
  {
    name: "contentScript",
    type: "script",
    input: "src/Content.ts",
    output: "xcode/Shared (Extension)/Resources/content.js",
  },
  {
    name: "appWebView",
    type: "script",
    input: "src/SharedAppView.tsx",
    output: "xcode/Shared (App)/Resources/Script.js",
  },
  {
    name: "appStyles",
    type: "css",
    input: "src/styles/App.css",
    output: "xcode/Shared (App)/Resources/Style.css",
  },
];
