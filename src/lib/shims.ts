export const isDev = process.env.CONFIGURATION === "Debug";
export const isPreview = process.env.CONFIGURATION === "Preview";
export const isProd = process.env.CONFIGURATION === "Release";

export const verbose = isDev || isPreview;

export const buildTime = process.env.BUILD_TS;
export const commitSHA = process.env.COMMIT_SHA || "unknown";

if (verbose) {
  const logLabel = `[skip-ai-ios]`;

  // Bind the timestamp object - toString() gets called at log-time
  console.log = console.log.bind(console, logLabel);
  console.warn = console.warn.bind(console, logLabel);
  console.error = console.error.bind(console, logLabel);
  console.debug = console.debug.bind(console, logLabel);
}

export function log(
  level: "log" | "warn" | "error" | "debug",
  logFn: () => unknown,
) {
  if (verbose || level !== "debug") {
    logFn();
  }
}
