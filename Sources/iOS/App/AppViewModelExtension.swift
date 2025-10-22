//
//  AppViewModelExtension.swift
//  Skip AI (iOS)
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  APP VIEW MODEL EXTENSION - iOS-specific modal handling
//

import SwiftUI

extension AppViewModel {
    // Called from refreshExtensionState
    // Shows modal when extension is disabled (only if user hasn't dismissed it before)
    func handleExtensionStateChanged(state: ExtensionState) {
        if state == .disabled && !hasSeenEnableExtensionModal {
            showEnableExtensionModal = true
            logInfo("Showing enable extension modal (state: disabled, not seen before)", category: "AppViewModel")
        } else if state == .disabled {
            logInfo("Not showing modal: user already dismissed it", category: "AppViewModel")
        }
    }
    
    #if DEBUG
    // Reset modal visibility flag for testing
    func resetModalDismissal() {
        hasSeenEnableExtensionModal = false
        let defaults = Self.userDefaults()
        defaults?.removeObject(forKey: "has_seen_enable_extension_modal")
        defaults?.synchronize()
        logInfo("Reset modal dismissal flag", category: "AppViewModel")
    }
    #endif
    
    // iOS doesn't terminate app when opening Settings
    func terminateAppIfNeeded() {
        // No-op on iOS
    }
}

