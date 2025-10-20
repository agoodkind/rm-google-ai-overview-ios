import { Command } from "@commander-js/extra-typings";
import tailwindcss from "@tailwindcss/postcss";
import autoprefixer from "autoprefixer";
import { config } from "dotenv";
import { build, context } from "esbuild";
import fs, { readFile as fsReadFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";
import postcss from "postcss";
import { entryPoints } from "./esbuild.config.mjs";

config();

const LOGGING_VERBOSITY = Number(process.env.LOGGING_VERBOSITY || 0);
const configuration = process.env.CONFIGURATION || "Release";
const isDev = configuration === "Debug";
// const isPreview = configuration === "Preview";
// const isProd = configuration === "Release";
console.log(`Configuration: ${configuration}`);

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

console.log(`LOGGING_VERBOSITY: ${LOGGING_VERBOSITY}`);
console.log(`Log levels to drop: ${getLogLevelsToDrop()}`);

// is verbosity is 3, drop VERBOSE4 and above
// is verbosity is 2, drop VERBOSE3 and above
// is verbosity is 1, drop VERBOSE2 and above
// is verbosity is 0, log nothing
function getLogLevelsToDrop() {
  return Array.from({ length: LOGGING_VERBOSITY }, (_, i) => i + 1)
    .filter((level) => LOGGING_VERBOSITY < level)
    .map((level) => `VERBOSE${level}`);
}

/**
 * Load path aliases from tsconfig.app.json (or fallback tsconfig.json)
 */
async function loadTsconfigAliases() {
  const candidates = ["tsconfig.app.json", "tsconfig.json"];
  for (const file of candidates) {
    try {
      const raw = await fsReadFile(resolve(__dirname, file), "utf8");
      const stripped = raw
        .replace(/\/\/[^\n]*$/gm, "")
        .replace(/\/\*[\s\S]*?\*\//g, "");
      const json = JSON.parse(stripped);
      const paths = json?.compilerOptions?.paths;
      if (!paths) {
        continue;
      }
      /** @type {Record<string,string>} */
      const alias = {};
      for (const [key, arr] of Object.entries(paths)) {
        if (!Array.isArray(arr) || !arr.length) {
          continue;
        }
        const bareKey = key.endsWith("/*") ? key.slice(0, -2) : key;
        let target = arr[0];
        if (target.endsWith("/*")) {
          target = target.slice(0, -2);
        }
        if (target.startsWith("./")) {
          target = target.slice(2);
        }
        alias[bareKey] = resolve(__dirname, target);
      }
      return alias;
    } catch (err) {
      console.error("Error loading tsconfig aliases:", err);
    }
  }
  return {};
}

/**
 * Get the current Git commit SHA.
 */
export const getGitCommitSha = async () => {
  const { exec } = await import("node:child_process");
  return new Promise((resolve) => {
    exec("git rev-parse HEAD", (err, stdout) => {
      resolve(err ? "" : stdout.trim());
    });
  });
};

/**
 * PostCSS plugin for esbuild to process CSS with Tailwind and Autoprefixer.
 * @type {import('esbuild').Plugin}
 */
const postCssPlugin = {
  name: "postcss-tailwind",
  setup(build) {
    build.onLoad({ filter: /\.css$/ }, async (args) => {
      const source = await fs.readFile(args.path, "utf8");
      const result = await postcss([tailwindcss(), autoprefixer()]).process(
        source,
        { from: args.path },
      );
      return { contents: result.css, loader: "css" };
    });
  },
};

/**
 * Create esbuild BuildOptions for all entries.
 * @returns {Promise<import('esbuild').BuildOptions>}
 */
const createBuildOptions = async () => {
  const dynamicAlias = await loadTsconfigAliases();
  const commitSha = await getGitCommitSha();

  return {
    entryPoints,
    bundle: true,
    outdir: ".",
    outbase: ".",
    minify: !isDev,
    sourcemap: isDev ? "inline" : false,
    logLevel: isDev ? "debug" : "info",
    alias: dynamicAlias,
    define: {
      "process.env.CONFIGURATION": JSON.stringify(
        process.env.CONFIGURATION || "Release",
      ),
      "process.env.BUILD_TS": JSON.stringify(new Date().toString()),
      "process.env.COMMIT_SHA": JSON.stringify(commitSha),
    },
    format: "iife",
    platform: "browser",
    target: ["es2022"],
    jsx: "automatic",
    loader: {
      ".png": "dataurl",
    },
    dropLabels: getLogLevelsToDrop(),
    plugins: [postCssPlugin],
  };
};

/**
 * Execute build pipeline.
 * @param {{ watch?: boolean; serve?: number }} opts
 */
export async function execute({ watch = false, serve }) {
  const options = await createBuildOptions();

  if (serve) {
    const ctx = await context(options);
    const { host, port } = await ctx.serve({
      servedir: ".",
      port: serve,
      host: "localhost",
    });
    console.log(`Serving at http://${host}:${port}`);

    if (watch) {
      await ctx.watch();
      console.log("Watch mode enabled - live reload active");
    }

    return { mode: "serve", contexts: [ctx], host, port };
  }

  if (watch) {
    const ctx = await context(options);
    await ctx.watch();
    console.log("Watching all entries...");
    return { mode: "watch", contexts: [ctx] };
  }

  await build(options);
  console.log("Built all entries");
  return { mode: "build" };
}

/**
 * @param {string[]} argv
 */
async function main(argv = process.argv) {
  const program = new Command();
  program
    .name("bundle")
    .version("1.0.0")
    .option("--watch", "Watch mode")
    .option("--serve <port>", "Serve mode with optional port", parseInt)
    .action(async (options) => {
      await execute(options);
    });

  await program.parseAsync(argv);
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch((err) => {
    console.error(err);
    process.exit(1);
  });
}
