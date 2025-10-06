// @ts-check
import { build, context } from 'esbuild';
import console from 'node:console';
import { dirname, resolve } from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

/**
 * Resolve path relative to project root
 * @param {...string} args - Path segments to resolve
 * @returns {string} Resolved absolute path
 */
const r = (...args) => resolve(__dirname, ...args);

/** @type {boolean} */
const isDev = process.env.NODE_ENV === 'development';

/** @type {boolean} */
const watch = process.argv.includes('--watch');

/** @type {import('esbuild').BuildOptions} */
const buildOptions = {
  entryPoints: [r('src/content.ts')],
  bundle: true,
  outfile: r('Shared (Extension)', 'Resources', 'content.js'),
  format: 'iife',
  platform: 'browser',
  target: 'es2022',
  minify: !isDev,
  sourcemap: isDev ? 'inline' : false,
  logLevel: isDev ? 'debug' : 'info',
};

if (watch) {
  const ctx = await context(buildOptions);
  await ctx.watch();
  console.log('Watching for changes...');
} else {
  await build(buildOptions).catch(() => process.exit(1));
}
