//
//  AppHelpers.swift
//  Skip AI (macOS)
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  APP HELPERS - macOS-specific helper functions
//

import SwiftUI
import AppKit

extension AppViewModel {
    // macOS-specific app termination helper
    // Called after opening Safari preferences so the app doesn't stay running
    func terminateApp() {
        logInfo("Terminating app", category: "AppViewModel")
        NSApp.terminate(nil)
    }
}
