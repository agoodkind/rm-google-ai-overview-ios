//
//  PlatformColor.swift
//  Skip AI
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  COLOR SYSTEM - Provides consistent colors that adapt to iOS vs macOS
//
// iOS and macOS have different native color systems (UIKit vs AppKit).
// This file provides a unified color API that works on both platforms.
//
// What this provides:
// - windowBackground: The main background color of the app window
// - panelBackground: The background color for the settings panel
//
// How it works:
// - Shared code calls PlatformColor.windowBackground
// - Based on the platform, it returns the iOS or macOS specific color
// - Actual color values are defined in the platform-specific files
//
// Why separate colors by platform?
// - iOS uses UIColor (systemBackground, secondarySystemBackground)
// - macOS uses NSColor (windowBackgroundColor, underPageBackgroundColor)
// - Colors automatically adapt to light/dark mode
// - Following platform conventions makes the app feel native
//
// Platform-specific implementations:
// - iOS: Sources/iOS/App/PlatformConfiguration.swift
// - macOS: Sources/macOS/App/PlatformConfiguration.swift

import SwiftUI

enum PlatformColor {
    static var windowBackground: Color {
        #if os(iOS)
        return iosWindowBackground
        #else
        return macOSWindowBackground
        #endif
    }
    
    static var panelBackground: Color {
        #if os(iOS)
        return iosPanelBackground
        #else
        return macOSPanelBackground
        #endif
    }
}
