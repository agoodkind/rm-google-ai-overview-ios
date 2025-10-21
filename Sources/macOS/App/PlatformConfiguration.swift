//
//  PlatformConfiguration.swift
//  Skip AI
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  macOS-SPECIFIC IMPLEMENTATIONS - How macOS handles platform differences
//
// This file implements the PlatformAdapter protocol for macOS (Mac computers).
// Unlike iOS, macOS allows more programmatic control over extensions.
//
// What this file provides:
//
// 1. MacOSPlatformAdapter - Implements platform-specific behaviors for macOS
//    - kind: Identifies this as macOS platform
//    - useSettings: True for macOS 13+, false for older versions
//      (macOS 13 introduced new Settings app, older versions use System Preferences)
//    - horizontalPadding: 56 points (wider spacing for desktop displays)
//    - shouldShowPreferencesButton: Returns true (macOS can open extension preferences)
//    - openExtensionPreferences: Opens Safari extension settings, then quits app
//    - checkExtensionState: Queries Safari to see if extension is enabled
//
// 2. PlatformColor extensions - macOS-specific colors
//    - macOSWindowBackground: Uses windowBackgroundColor (standard Mac window color)
//    - macOSPanelBackground: Uses underPageBackgroundColor (recessed panel appearance)
//
// 3. AppViewModel extension - macOS-specific behaviors
//    - terminateApp(): Quits the app (using NSApp.terminate)
//      Called after opening Safari preferences so the app doesn't stay running
//
// Why does macOS have more capabilities?
// - Desktop OS has different privacy model than mobile
// - Safari Extension APIs are more open on macOS
// - Users expect desktop apps to have more control

import SwiftUI
import SafariServices
import AppKit

struct MacOSPlatformAdapter: PlatformAdapter {
    let kind: PlatformKind = .mac
    let horizontalPadding: CGFloat = 56
    
    // macOS 13+ uses modern Settings app, older versions use System Preferences
    var useSettings: Bool {
        if #available(macOS 13, *) {
            return true
        } else {
            return false
        }
    }
    
    func shouldShowPreferencesButton() -> Bool { true }
    
    func openExtensionPreferences(completion: @escaping () -> Void) {
        logInfo("Opening Safari extension preferences", category: "macOSPlatform")
        SFSafariApplication.showPreferencesForExtension(withIdentifier: extensionBundleIdentifier) { error in
            if let error = error {
                logError("Failed to open extension preferences: \(error.localizedDescription)", category: "macOSPlatform")
                return
            }
            logInfo("Extension preferences opened successfully", category: "macOSPlatform")
            completion()
        }
    }
    
    // Queries Safari to check if our extension is currently enabled
    func checkExtensionState(completion: @escaping (Bool?) -> Void) {
        logDebug("Querying Safari for extension state", category: "macOSPlatform")
        SFSafariExtensionManager.getStateOfSafariExtension(withIdentifier: extensionBundleIdentifier) { state, error in
            if let error = error {
                logError("Failed to query extension state: \(error.localizedDescription)", category: "macOSPlatform")
                completion(nil)
                return
            }
            
            if let state = state {
                logInfo("Extension state from Safari: \(state.isEnabled ? "enabled" : "disabled")", category: "macOSPlatform")
                completion(state.isEnabled)
            } else {
                logWarning("Extension state is nil", category: "macOSPlatform")
                completion(nil)
            }
        }
    }
}

// macOS-specific color implementations
extension PlatformColor {
    static var macOSWindowBackground: Color {
        Color(NSColor.windowBackgroundColor)
    }
    
    static var macOSPanelBackground: Color {
        Color(NSColor.underPageBackgroundColor)
    }
}

// macOS-specific app termination helper
extension AppViewModel {
    func terminateApp() {
        NSApp.terminate(nil)
    }
}

