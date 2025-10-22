//
//  logging.ts
//  Skip AI
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  Extension logging that relays to native app

type LogLevel = "debug" | "info" | "warn" | "error";

interface LogEntry {
  timestamp: string;
  level: LogLevel;
  message: string;
  context?: string;
  stack?: string;
  file?: string;
  line?: number;
}

/**
 * Extract call location from stack trace
 * Note: Shows bundled file locations (background.js, content.js)
 * Not TypeScript source due to bundling.
 * Use context parameter for source identification.
 */
function getCallLocation(): {
  file?: string;
  line?: number;
  stack?: string;
} {
  const stack = new Error().stack;
  if (!stack) {
    return {};
  }

  // Parse stack trace to find caller
  // (skip Error, getCallLocation, and the log function)
  const lines = stack.split("\n");
  const callerLine = lines[3] || lines[2]; // Line that called logger

  // Extract file:line from bundled code
  const match = callerLine?.match(/([^/]+\.js):(\d+):\d+/);
  if (match) {
    return {
      file: match[1],
      line: parseInt(match[2], 10),
      stack: stack,
    };
  }

  return { stack };
}

/**
 * Send log to native app for storage
 */
async function sendLogToNative(entry: LogEntry) {
  try {
    await browser.runtime.sendNativeMessage("application.id", {
      type: "extensionLog",
      log: entry,
    });
  } catch (error) {
    // Silently fail - don't create infinite loop
    console.error("Failed to send log to native:", error);
  }
}

/**
 * File-bound logger for a specific source file
 */
interface FileLogger {
  debug: (message: string, fn?: string) => void;
  info: (message: string, fn?: string) => void;
  warn: (message: string, fn?: string) => void;
  error: (message: string, fn?: string) => void;
}

/**
 * Extension logger that relays logs to native app
 *
 * Usage:
 * ```ts
 * const log = ExtensionLogger.for("Background.ts")
 * log.info("Service worker started", "init")
 * ```
 *
 * The file parameter identifies the source file
 * The fn parameter identifies the function/context
 * Combined they create a traceable log entry despite bundling
 */
export const ExtensionLogger = {
  for: (file: string): FileLogger => ({
    debug: (message: string, fn?: string) => {
      const context = fn ? `${file}:${fn}` : file;
      const location = getCallLocation();

      VERBOSE5: console.debug(`[${context}] ${message}`);
      sendLogToNative({
        timestamp: new Date().toISOString(),
        level: "debug",
        message,
        context,
        ...location,
      });
    },

    info: (message: string, fn?: string) => {
      const context = fn ? `${file}:${fn}` : file;
      const location = getCallLocation();

      VERBOSE4: console.info(`[${context}] ${message}`);
      sendLogToNative({
        timestamp: new Date().toISOString(),
        level: "info",
        message,
        context,
        ...location,
      });
    },

    warn: (message: string, fn?: string) => {
      const context = fn ? `${file}:${fn}` : file;
      const location = getCallLocation();

      console.warn(`[${context}] ${message}`);
      sendLogToNative({
        timestamp: new Date().toISOString(),
        level: "warn",
        message,
        context,
        ...location,
      });
    },

    error: (message: string, fn?: string) => {
      const context = fn ? `${file}:${fn}` : file;
      const location = getCallLocation();

      console.error(`[${context}] ${message}`);
      sendLogToNative({
        timestamp: new Date().toISOString(),
        level: "error",
        message,
        context,
        ...location,
      });
    },
  }),
};
