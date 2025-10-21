// AppConstants.swift
// Skip AI - Safari Extension App
//
// Global constants used throughout the app

import Foundation

let extensionBundleIdentifier = "goodkind-io.Skip-AI.Extension"
let APP_GROUP_ID = "group.com.goodkind.skip-ai"  // Shared between app and extension
let DISPLAY_MODE_KEY = "skip-ai-display-mode"

#if DEBUG
let DEFAULT_DISPLAY_MODE = "highlight"  // Show orange borders in development
#else
let DEFAULT_DISPLAY_MODE = "hide"       // Hide AI content in production
#endif

