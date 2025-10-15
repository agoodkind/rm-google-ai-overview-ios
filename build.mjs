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
import { entryPoints } from "./build.config.mjs";

config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

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
    } catch (_err) {
      // keep trying next candidate
    }
  }
  return {};
}

const isDev = process.env.BUILD_ENV === "development";

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
      "process.env.BUILD_ENV": JSON.stringify(
        process.env.BUILD_ENV || "production",
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
