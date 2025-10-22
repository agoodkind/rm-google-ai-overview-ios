//
//  logging.ts
//  Skip AI
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  Extension logging that relays to native app

import { MessagesToNativeApp } from "./messaging/constants";
import type { INativeMessenger } from "./messaging/native";

type LogSource = "background" | "content";

export const LogLevel = {
  DEBUG: "debug",
  INFO: "info",
  WARN: "warn",
  ERROR: "error",
} as const;

type LogLevel = (typeof LogLevel)[keyof typeof LogLevel];

export interface LogEntry {
  timestamp: string;
  level: LogLevel;
  source: LogSource;
  context?: string;
  message: string;
  extra?: unknown;
  file?: string;
  line?: number;
  stack?: string;
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
export class ExtensionLogger {
  #source: LogSource;
  private static instance: ExtensionLogger | null = null;

  #messenger: INativeMessenger;

  private constructor(source: LogSource, messenger: INativeMessenger) {
    this.#source = source;
    this.#messenger = messenger;
  }

  async #sendLogToNative(entry: LogEntry) {
    switch (entry.source) {
      case "background":
        await this.#messenger.sendNativeMessage(
          MessagesToNativeApp.ExtensionLog,
          entry,
        );
        break;
      case "content":
        await this.#messenger.sendNativeMessage(
          MessagesToNativeApp.ExtensionLog,
          entry,
        );
        break;
      default:
        throw new Error(`Invalid log source: ${entry.source}`);
    }
  }

  static for(source: LogSource, messenger: INativeMessenger): ExtensionLogger {
    if (!ExtensionLogger.instance) {
      ExtensionLogger.instance = new ExtensionLogger(source, messenger);
    }
    return ExtensionLogger.instance;
  }

  /**
   * Extract call location from stack trace
   * Note: Shows bundled file locations (background.js, content.js)
   * Not TypeScript source due to bundling.
   * Use context parameter for source identification.
   */
  static #getCallLocation(): {
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

  async #doLog({
    level,
    context,
    message,
    extra,
  }: {
    level: LogLevel;
    context?: string;
    message: string;
    extra?: unknown;
  }): Promise<void> {
    const location = ExtensionLogger.#getCallLocation();
    await this.#sendLogToNative({
      ...location,
      level,
      timestamp: new Date().toISOString(),
      source: this.#source,
      message,
      context,
      extra,
    });
  }

  async debug(context: string, message: string, ...extra: unknown[]) {
    await this.#doLog({ level: LogLevel.DEBUG, context, message, extra });
  }

  async info(context: string, message: string, ...extra: unknown[]) {
    await this.#doLog({ level: LogLevel.INFO, context, message, extra });
  }

  async warn(context: string, message: string, ...extra: unknown[]) {
    await this.#doLog({ level: LogLevel.WARN, context, message, extra });
  }

  async error(context: string, message: string, ...extra: unknown[]) {
    await this.#doLog({ level: LogLevel.ERROR, context, message, extra });
  }
}
