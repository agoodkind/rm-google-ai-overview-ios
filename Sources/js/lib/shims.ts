//
//  shims.ts
//  Skip AI
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//

export const isDev = process.env.CONFIGURATION === "Debug";
export const isPreview = process.env.CONFIGURATION === "Preview";
export const isProd = process.env.CONFIGURATION === "Release";

export const verbose = isDev || isPreview;

export const buildTime = process.env.BUILD_TS;
export const commitSHA = process.env.COMMIT_SHA || "unknown";

// Only bind console methods once
interface BoundConsole {
  __skipAiBound?: boolean;
}

export function bindConsole(context?: string) {
  if (!(console.log as typeof console.log & BoundConsole).__skipAiBound) {
    const logLabel = `[skip-ai]${context ? ` [${context}]` : ""}`;

    const originalLog = console.log;
    const originalWarn = console.warn;
    const originalError = console.error;
    const originalDebug = console.debug;

    console.log = originalLog.bind(console, logLabel);
    console.warn = originalWarn.bind(console, logLabel);
    console.error = originalError.bind(console, logLabel);
    console.debug = originalDebug.bind(console, logLabel);

    (console.log as typeof console.log & BoundConsole).__skipAiBound = true;
  }
}

bindConsole();
