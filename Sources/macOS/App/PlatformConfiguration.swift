// MacOSPlatform.swift
// macOS (App)
//
// macOS-specific platform adapter implementation

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
        SFSafariApplication.showPreferencesForExtension(withIdentifier: extensionBundleIdentifier) { error in
            guard error == nil else { return }
            completion()
        }
    }
    
    // Queries Safari to check if our extension is currently enabled
    func checkExtensionState(completion: @escaping (Bool?) -> Void) {
        SFSafariExtensionManager.getStateOfSafariExtension(withIdentifier: extensionBundleIdentifier) { state, error in
            if let state = state, error == nil {
                completion(state.isEnabled)
            } else {
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

