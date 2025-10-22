//
//  constants.ts
//  Skip AI
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//

/**
 * Message types sent to native app (Swift handler)
 */
export const MessagesToNativeApp = {
  GetDisplayMode: "get_display_mode",
  ExtensionLog: "extension_log",
  ExtensionStats: "extension_stats",
  ExtensionPing: "extension_ping",
  ServiceWorkerStarted: "service_worker_started",
  Ping: "ping",
} as const;

/**
 * Message types sent to background page
 */
export const MessagesToBackgroundPage = {
  ForwardToNativeApp: "forward_to_native_app",
  Ping: "ping",
} as const;

/**
 * Message types sent to content scripts
 */
export const MessagesToContentScript = {
  RefreshDisplayMode: "refresh_display_mode",
} as const;

/**
 * Display modes for AI content
 */
export const DisplayMode = {
  Hide: "hide",
  Highlight: "highlight",
} as const;

export const DEFAULT_DISPLAY_MODE = DisplayMode.Hide;
