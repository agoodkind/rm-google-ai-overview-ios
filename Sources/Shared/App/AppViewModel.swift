// AppViewModel.swift
// Skip AI - Safari Extension App
//
// The "brain" of the UI - manages state and business logic
// ObservableObject + @Published properties make SwiftUI views reactive

import SwiftUI
import Combine

final class AppViewModel: ObservableObject {
    enum DisplayMode: String {
        case hide       // Completely remove AI content
        case highlight  // Show with orange border
    }
    
    // @Published automatically triggers UI updates when these values change
    @Published var displayMode: DisplayMode
    @Published var extensionEnabled: Bool?  // nil = unknown, true/false = known state
    
    let platform: PlatformAdapter
    
    // Default initializer - creates platform adapter automatically
    convenience init() {
        self.init(platform: Self.createPlatformAdapter())
    }
    
    // Primary initializer - allows injecting custom platform adapter (useful for testing)
    init(platform: PlatformAdapter) {
        self.platform = platform
        self.displayMode = Self.loadDisplayMode()
        refreshExtensionState()
    }
    
    func onAppear() {
        displayMode = Self.loadDisplayMode()
        refreshExtensionState()
    }
    
    func selectDisplayMode(_ mode: DisplayMode) {
        guard displayMode != mode else { return }
        displayMode = mode
        Self.saveDisplayMode(mode)
    }
    
    // Computes appropriate status message based on platform and extension state
    var stateMessage: String {
        switch platform.kind {
        case .ios:
            return LocalizedString.extensionStateIOS()
        case .mac:
            let location = LocalizedString.extensionStateMacLocation(useSettings: platform.useSettings)
            guard let enabled = extensionEnabled else {
                return LocalizedString.extensionStateMacEnable(location: location)
            }
            return enabled
                ? LocalizedString.extensionStateMacOn(location: location)
                : LocalizedString.extensionStateMacOff(location: location)
        }
    }
    
    // Returns button title for macOS, nil for iOS (no button shown)
    var preferencesButtonTitle: String? {
        guard platform.shouldShowPreferencesButton() else { return nil }
        return LocalizedString.preferencesButton(useSettings: platform.useSettings)
    }
    
    // Opens Safari preferences and quits the app (macOS only)
    func openPreferences() {
        platform.openExtensionPreferences {
            DispatchQueue.main.async {
                #if os(macOS)
                self.terminateApp()
                #endif
            }
        }
    }
    
    // Checks with Safari whether extension is currently enabled
    private func refreshExtensionState() {
        platform.checkExtensionState { [weak self] enabled in
            // [weak self] prevents memory leaks by allowing self to be deallocated
            DispatchQueue.main.async {
                self?.extensionEnabled = enabled
            }
        }
    }
    
    private static func createPlatformAdapter() -> PlatformAdapter {
        #if os(iOS)
        return IOSPlatformAdapter()
        #else
        return MacOSPlatformAdapter()
        #endif
    }
    
    // UserDefaults with suiteName allows sharing preferences between app and extension
    private static func userDefaults() -> UserDefaults? {
        UserDefaults(suiteName: APP_GROUP_ID)
    }
    
    private static func loadDisplayMode() -> DisplayMode {
        let stored = userDefaults()?.string(forKey: DISPLAY_MODE_KEY)
        if let raw = stored, let mode = DisplayMode(rawValue: raw) {
            return mode
        }
        return DisplayMode(rawValue: DEFAULT_DISPLAY_MODE) ?? .hide
    }
    
    private static func saveDisplayMode(_ mode: DisplayMode) {
        let defaults = userDefaults()
        defaults?.set(mode.rawValue, forKey: DISPLAY_MODE_KEY)
        defaults?.synchronize()
    }
}

