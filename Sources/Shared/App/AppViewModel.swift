// AppViewModel.swift
// Skip AI - Safari Extension App
//
// STATE MANAGEMENT - The "brain" of the app's UI
//
// This is the single source of truth for the app's current state.
// When data in this file changes, the UI automatically updates.
//
// What this file manages:
// - Current display mode (hide or highlight AI content)
// - Extension enabled status (is the Safari extension turned on?)
// - Platform-specific behaviors (iOS vs macOS differences)
// - Loading/saving user preferences to persistent storage
// - Communication with Safari to check extension state
//
// How SwiftUI reactivity works:
// 1. This class conforms to ObservableObject
// 2. Properties marked with @Published automatically notify views when they change
// 3. Views marked with @ObservedObject automatically redraw when notified
// 4. Result: Change data here → UI updates instantly
//
// This follows the MVVM (Model-View-ViewModel) architectural pattern.
// The ViewModel sits between your data (Model) and your UI (View).

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
            guard let enabled = extensionEnabled else {
                return LocalizedString.extensionStateIOSUnknown()
            }
            return enabled
                ? LocalizedString.extensionStateIOSOn()
                : LocalizedString.extensionStateIOSOff()
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

