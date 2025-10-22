//
//  PlatformAdapter.swift
//  Skip AI (macOS)
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  PLATFORM ADAPTER - Implements PlatformAdapter protocol for macOS
//

import SwiftUI
import SafariServices
import AppKit

struct macOSPlatformAdapter: PlatformAdapter {
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
    func checkExtensionState(completion: @escaping (ExtensionState) -> Void) {
        logDebug("Querying Safari for extension state", category: "macOSPlatform")
        SFSafariExtensionManager.getStateOfSafariExtension(withIdentifier: extensionBundleIdentifier) { state, error in
            if let error = error {
                logError("Failed to query extension state: \(error.localizedDescription)", category: "macOSPlatform")
                completion(.error)
                return
            }
            
            if let state = state {
                let extensionState: ExtensionState = state.isEnabled ? .enabled : .disabled
                logInfo("Extension state from Safari: \(state.isEnabled ? "enabled" : "disabled")", category: "macOSPlatform")
                completion(extensionState)
            } else {
                logWarning("Extension state is nil", category: "macOSPlatform")
                completion(.unchecked)
            }
        }
    }
}
