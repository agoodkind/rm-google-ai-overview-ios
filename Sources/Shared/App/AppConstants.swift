//
//  AppConstants.swift
//  Skip AI
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  CONFIGURATION VALUES - Settings that are used everywhere in the app
//
// This file contains global constants that don't change during runtime.
// Think of these as the app's configuration settings.
//
// What's defined here:
// - extensionBundleIdentifier: Unique ID that identifies our Safari extension to the OS
// - APP_GROUP_ID: Shared storage identifier so the app and extension can share data
// - DISPLAY_MODE_KEY: Key used to save/load user's display preference from storage
// - DEFAULT_DISPLAY_MODE: What mode to use when the app first launches
//   (shows "highlight" in development builds so you can see what's being detected,
//    uses "hide" in production builds for end users)
//
// Why have a separate file for constants?
// - Easy to find and update configuration in one place
// - Prevents typos (if you use the constant name wrong, you get a compile error)
// - Makes it clear these values are used throughout the app

import Foundation

let extensionBundleIdentifier = "io.goodkind.SkipAI.Extension"
let APP_GROUP_ID = "group.io.goodkind.skip-ai"  // Shared between app and extension
let DISPLAY_MODE_KEY = "skip-ai-display-mode"

#if DEBUG
let DEFAULT_DISPLAY_MODE = "highlight"  // Show orange borders in development
#else
let DEFAULT_DISPLAY_MODE = "hide"       // Hide AI content in production
#endif
