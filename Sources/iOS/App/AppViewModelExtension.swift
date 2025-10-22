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
        }
    }
    
    // iOS doesn't terminate app when opening Settings
    func terminateAppIfNeeded() {
        // No-op on iOS
    }
}
