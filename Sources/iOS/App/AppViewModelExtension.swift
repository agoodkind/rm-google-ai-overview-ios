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
    // Shows modal when extension is disabled or state unknown
    func handleExtensionStateChanged(enabled: Bool?) {
        if enabled == false || enabled == nil {
            // Small delay to ensure view is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showEnableExtensionModal = true
            }
        }
    }
    
    // iOS doesn't terminate app when opening Settings
    func terminateAppIfNeeded() {
        // No-op on iOS
    }
}

