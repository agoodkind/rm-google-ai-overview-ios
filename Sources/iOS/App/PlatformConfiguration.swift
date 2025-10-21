//
//  PlatformConfiguration.swift
//  Skip AI
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  iOS-SPECIFIC IMPLEMENTATIONS - How iOS handles platform differences
//
// This file implements the PlatformAdapter protocol for iOS devices (iPhone, iPad).
// It defines behaviors that are unique to iOS or impossible on iOS.
//
// What this file provides:
//
// 1. IOSPlatformAdapter - Implements platform-specific behaviors for iOS
//    - kind: Identifies this as iOS platform
//    - useSettings: Always false (iOS doesn't have the same settings structure as macOS)
//    - horizontalPadding: 32 points (optimized for mobile screens)
//    - shouldShowPreferencesButton: Returns false (iOS can't programmatically open extension settings)
//    - openExtensionPreferences: Does nothing (iOS limitation - user must open Settings manually)
//    - checkExtensionState: Communicates with extension via NSExtensionContext
//
// 2. ExtensionCommunicator - iOS app-to-extension communication via shared storage
//    - Reads extension "last active" timestamp from App Group UserDefaults
//    - Checks if extension is enabled based on presence of timestamp key
//    - Cross-platform: iOS uses shared storage, macOS uses SFSafariApplication.dispatchMessage
//
// 3. PlatformColor extensions - iOS-specific colors
//    - iosWindowBackground: Uses systemBackground (adapts to light/dark mode automatically)
//    - iosPanelBackground: Uses secondarySystemBackground (subtle contrast from window)
//
// Why are some features limited on iOS?
// - Apple restricts what apps can do programmatically for privacy and security
// - Users must manually enable extensions in iOS Settings app
// - Extension communication via NSExtensionContext (similar to macOS but different API)

import SwiftUI
import Foundation
import SafariServices

struct IOSPlatformAdapter: PlatformAdapter {
    let kind: PlatformKind = .ios
    let useSettings: Bool = false
    let horizontalPadding: CGFloat = 32
    
    func shouldShowPreferencesButton() -> Bool { false }
    
    // iOS can't programmatically open extension preferences
    func openExtensionPreferences(completion: @escaping () -> Void) {}
    
    // Check extension state by reading shared App Group storage
    func checkExtensionState(completion: @escaping (Bool?) -> Void) {
        let isEnabled = ExtensionCommunicator.shared.checkExtensionEnabled()
        completion(isEnabled)
    }
}

// MARK: - Extension Communication

// Helper class to communicate with Safari extension via shared App Group storage
// Extension writes timestamp when enabled/started via onInstalled handler
// App checks for presence of timestamp key to determine if extension is enabled
class ExtensionCommunicator {
    static let shared = ExtensionCommunicator()
    
    private let extensionLastActiveKey = "extension-last-active"
    private let appGroupID = "group.io.goodkind.skip-ai"
    private let displayModeKey = "skip-ai-display-mode"
    
    private init() {}
    
    // Check if extension is enabled by checking if timestamp exists
    func checkExtensionEnabled() -> Bool? {
        logVerbose("Accessing shared defaults for extension check", category: "ExtensionComm")
        guard let sharedDefaults = UserDefaults(suiteName: appGroupID) else {
            logError("Failed to access shared UserDefaults with app group: \(appGroupID)", category: "ExtensionComm")
            return nil
        }
        
        // If key exists, extension has been enabled at some point
        // Absence of key means extension never enabled or was removed
        let exists = sharedDefaults.object(forKey: extensionLastActiveKey) != nil
        logDebug("Extension last active key exists: \(exists)", category: "ExtensionComm")
        return exists
    }
    
    // Get display mode from shared storage
    func getDisplayMode() -> String? {
        logVerbose("Retrieving display mode from shared storage", category: "ExtensionComm")
        guard let sharedDefaults = UserDefaults(suiteName: appGroupID) else {
            logError("Failed to access shared UserDefaults with app group: \(appGroupID)", category: "ExtensionComm")
            return nil
        }
        let mode = sharedDefaults.string(forKey: displayModeKey)
        logDebug("Display mode from storage: \(mode ?? "nil")", category: "ExtensionComm")
        return mode
    }
}

// MARK: - Platform Colors

// iOS-specific color implementations
extension PlatformColor {
    static var iosWindowBackground: Color {
        Color(.systemBackground)
    }
    
    static var iosPanelBackground: Color {
        Color(.secondarySystemBackground)
    }
}

