import { Command } from "@commander-js/extra-typings";
import tailwindcss from "@tailwindcss/postcss";
import autoprefixer from "autoprefixer";
import { config } from "dotenv";
import { build, context } from "esbuild";
import console from "node:console";
import fs from "node:fs/promises";
import { dirname, isAbsolute, resolve } from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";
import postcss from "postcss";
import { entries as configEntries } from "./build.config.mjs";

// Load environment variables from .env file
config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

/**
 * Resolve path relative to project root
 * @param {...string} args - Path segments to resolve
 * @returns {string} Resolved absolute path
 */
const r = (...args) => resolve(__dirname, ...args);

/** @type {boolean} */
const isDev = process.env.BUILD_ENV === "development";

/**
 * Get the current Git commit SHA.
 * @returns {Promise<string>} The current Git commit SHA.
 */
const getGitCommitSha = async () => {
  const { exec } = await import("node:child_process");
  return new Promise((resolve) => {
    exec("git rev-parse HEAD", (err, stdout) => {
      if (err) {
        resolve("");
      } else {
        resolve(stdout.trim());
      }
    });
  });
};

/**
 * Build entry configuration.
 * @typedef {object} EntryConfig
 * @property {string} name Unique identifier for filtering and logging.
 * @property {string} input Input file path (absolute or relative to project root).
 * @property {string} output Output file path (absolute or relative to project root).
 * @property {'script'|'css'} type Processing pipeline to use.
 * @property {import('esbuild').Format=} [format='iife'] Script output format (scripts only).
 * @property {string=} [target='es2022'] JS target (scripts only).
 * @property {'automatic'|'transform'|'preserve'=} [jsx='automatic'] JSX transform mode.
 */

/**
 * Options accepted by execute().
 * @typedef {object} ExecuteOptions
 * @property {string[]} [only] Only build these named entries.
 * @property {string[]} [exclude] Exclude these named entries.
 * @property {boolean} [list] List entries instead of building.
 * @property {boolean} [watch] Enable watch mode.
 */

/**
 * Result returned by execute().
 * @typedef {object} ExecuteResult
 * @property {'none'|'list'|'watch'|'build'} mode The operation mode performed.
 * @property {EntryConfig[]} entries Entries affected.
 * @property {import('esbuild').BuildContext[]=} contexts Present only in watch mode.
 */

/** Resolve configured entries (convert relative paths). */
/**
 * Resolve configured entries (convert relative paths & apply defaults).
 * @returns {EntryConfig[]}
 */
function getEntries() {
  return configEntries.map((e) => ({
    format: "iife",
    target: "es2022",
    jsx: "automatic",
    ...e,
    input: isAbsolute(e.input) ? e.input : r(e.input),
    output: isAbsolute(e.output) ? e.output : r(e.output),
  }));
}

/** Simple pretty table output for entries. */
/**
 * Pretty-print a collection of entries.
 * @param {EntryConfig[]} entries
 * @returns {void}
 */
function listEntries(entries) {
  if (!entries.length) {
    console.log("No entries");
    return;
  }
  const rows = entries.map((e) => ({
    name: e.name,
    type: e.type,
    input: e.input.replace(__dirname + "/", ""),
    output: e.output.replace(__dirname + "/", ""),
  }));
  console.table(rows);
}

/**
 * PostCSS plugin for esbuild to process CSS with Tailwind and Autoprefixer.
 * @type {import('esbuild').Plugin}
 */
const postCssPlugin = {
  name: "postcss-tailwind",
  setup(build) {
    build.onLoad({ filter: /\.css$/ }, async (args) => {
      const source = await fs.readFile(args.path, "utf8");
      const result = await postcss([
        // Tailwind first so autoprefixer can act on the final utilities
        tailwindcss(),
        autoprefixer(),
      ]).process(source, { from: args.path });
      return { contents: result.css, loader: "css" };
    });
  },
};

/**
 * Create esbuild BuildOptions for an entry.
 * @param {EntryConfig} entry
 * @returns {Promise<import('esbuild').BuildOptions>}
 */
const createBuildOptions = async (entry) => {
  const isCss = entry.type === "css";

  /** @type {import('esbuild').BuildOptions} */
  const base = {
    entryPoints: [entry.input],
    bundle: true,
    outfile: entry.output,
    minify: !isDev,
    sourcemap: isDev ? "inline" : false,
    logLevel: isDev ? "debug" : "info",
    alias: {
      "@": r("src"),
      "@lib": r("src/lib"),
      "@components": r("src/components"),
      "@styles": r("src/styles"),
    },
    define: {
      "process.env.BUILD_ENV": JSON.stringify(
        process.env.BUILD_ENV || "production",
      ),
      "process.env.BUILD_TS": JSON.stringify(new Date().toString()),
      "process.env.COMMIT_SHA": JSON.stringify(await getGitCommitSha()),
    },
  };

  if (isCss) {
    return { ...base, loader: { ".css": "css" }, plugins: [postCssPlugin] };
  }

  return {
    ...base,
    format: entry.format,
    platform: "browser",
    target: entry.target,
    jsx: entry.jsx || "automatic",
    loader: {
      ".png": "dataurl",
    },
  };
};

/**
 * Build a single entry (non-watch).
 * @param {EntryConfig} entry
 * @returns {Promise<import('esbuild').BuildResult>}
 */
async function buildEntry(entry) {
  return build(await createBuildOptions(entry));
}

/**
 * Create a watch context for an entry and start watching.
 * @param {EntryConfig} entry
 * @returns {Promise<import('esbuild').BuildContext>}
 */
async function watchEntry(entry) {
  const ctx = await context(await createBuildOptions(entry));
  await ctx.watch();
  return ctx;
}

/**
 * Filter entries given include/exclude lists.
 * @param {EntryConfig[]} all
 * @param {{only?: string[], exclude?: string[]}} params
 * @returns {EntryConfig[]}
 */
function filterEntries(all, { only, exclude }) {
  let out = all;

  if (only && only.length) {
    const set = new Set(only);
    out = out.filter((e) => set.has(e.name));
  }

  if (exclude && exclude.length) {
    const set = new Set(exclude);
    out = out.filter((e) => !set.has(e.name));
  }

  return out;
}

/**
 * Execute build pipeline according to options.
 * @param {ExecuteOptions} opts
 * @returns {Promise<ExecuteResult>}
 */
async function execute({ only, exclude, list, watch }) {
  let selected = filterEntries(getEntries(), { only, exclude });
  if (!selected.length) {
    console.warn("No entries selected");
    return { mode: "none", entries: [] };
  }

  if (list) {
    listEntries(selected);
    return { mode: "list", entries: selected };
  }

  if (watch) {
    const contexts = await Promise.all(selected.map((e) => watchEntry(e)));
    console.log(
      `Watching (${selected.length}) entries: ${selected
        .map((e) => e.name)
        .join(", ")}`,
    );
    return { mode: "watch", entries: selected, contexts };
  }

  await Promise.all(selected.map((e) => buildEntry(e)));
  console.log(
    `Built (${selected.length}) entries: ${selected
      .map((e) => e.name)
      .join(", ")}`,
  );
  return { mode: "build", entries: selected };
}

/**
 * @param {string[]} argv
 * @return {Promise<void>}
 */
async function main(argv = process.argv) {
  const program = new Command();
  program
    .name("bundle")
    .version("1.0.0")
    .option("--only <names...>", "Comma-separated entry names to include")
    .option("--exclude <names...>", "Comma-separated entry names to exclude")
    .option("--watch", "Watch mode")
    .option("--list", "List matching entries (no build)")
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
