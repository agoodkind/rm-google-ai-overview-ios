// @ts-check
import { config } from 'dotenv';
import { build, context } from 'esbuild';
import console from 'node:console';
import { dirname, resolve } from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

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
const isDev = process.env.DEV_MODE === 'true';

/** @type {boolean} */
const watch = process.argv.includes('--watch');

/**
 * @typedef {Object} EntryConfig
 * @property {string} input - Input file path
 * @property {string} output - Output file path
 */

/** @type {EntryConfig[]} */
const entries = [
  {
    input: r('src/content.ts'),
    output: r('xcode', 'Shared (Extension)', 'Resources', 'content.js'),
  },
  // {
  //   input: r('src/shared-script.ts'),
  //   output: r('xcode', 'Shared (App)', 'Resources', 'Script.js'),
  // },
];

/**
 * Create build options for an entry
 * @param {EntryConfig} entry
 * @returns {import('esbuild').BuildOptions}
 */
const createBuildOptions = (entry) => ({
  entryPoints: [entry.input],
  bundle: true,
  outfile: entry.output,
  format: 'iife',
  platform: 'browser',
  target: 'es2022',
  minify: !isDev,
  sourcemap: isDev ? 'inline' : false,
  logLevel: isDev ? 'debug' : 'info',
  define: {
    // Inject environment variables as compile-time constants
    'process.env.DEV_MODE': JSON.stringify(Boolean(process.env.DEV_MODE === 'true' || false)),
    'process.env.BUILD_TS': JSON.stringify(new Date().toString()),
    // Add any additional environment variables you want to inject
    // Format: 'process.env.VAR_NAME': JSON.stringify(process.env.VAR_NAME || 'default_value'),
  },
});

if (watch) {
  const contexts = await Promise.all(entries.map((entry) => context(createBuildOptions(entry))));
  await Promise.all(contexts.map((ctx) => ctx.watch()));
  console.log('Watching for changes...');
} else {
  await Promise.all(entries.map((entry) => build(createBuildOptions(entry)))).catch(() =>
    process.exit(1),
  );
}
