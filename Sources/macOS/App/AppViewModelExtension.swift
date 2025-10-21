//
//  AppViewModelExtension.swift
//  Skip AI (macOS)
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  APP VIEW MODEL EXTENSION - macOS stubs for iOS-specific functionality
//

import SwiftUI

extension AppViewModel {
    // macOS stub - no modal needed
    func handleExtensionStateChanged(enabled: Bool?) {
        // macOS doesn't use modal - uses preferences button instead
    }
    
    // macOS terminates app after opening Safari preferences
    func terminateAppIfNeeded() {
        logInfo("Extension preferences opened, terminating app", category: "AppViewModel")
        terminateApp()
    }
}

