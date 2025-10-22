//
//  AppViewModel.swift
//  Skip AI
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  STATE MANAGEMENT - The "brain" of the app's UI
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
    private let logCategory = "AppViewModel"
    enum DisplayMode: String {
        case hide       // Completely remove AI content
        case highlight  // Show with orange border
    }
    
    enum ExtensionState {
        case unchecked  // Haven't checked yet or check failed
        case enabled    // Extension is enabled
        case disabled   // Extension is disabled
    }
    
    // @Published automatically triggers UI updates when these values change
    @Published var displayMode: DisplayMode
    @Published var extensionEnabled: ExtensionState = .unchecked
    @Published var showEnableExtensionModal: Bool = false  // Controls modal visibility on iOS
    
    let platform: PlatformAdapter
    
    // Default initializer - creates platform adapter automatically
    convenience init() {
        self.init(platform: Self.createPlatformAdapter())
    }
    
    // Primary initializer - allows injecting custom platform adapter (useful for testing)
    init(platform: PlatformAdapter) {
        logInfo("Initializing AppViewModel with platform: \(platform.kind)", category: logCategory)
        self.platform = platform
        self.displayMode = Self.loadDisplayMode()
        logDebug("Initial display mode: \(displayMode.rawValue)", category: logCategory)
        refreshExtensionState()
    }
    
    // Called when the view appears
    func onAppear() {
        logVerbose("onAppear called", category: logCategory)
        displayMode = Self.loadDisplayMode()
        refreshExtensionState()
    }
    
    func selectDisplayMode(_ mode: DisplayMode) {
        guard displayMode != mode else {
            logVerbose("Display mode already set to \(mode.rawValue), skipping", category: logCategory)
            return
        }
        logInfo("Changing display mode from \(displayMode.rawValue) to \(mode.rawValue)", category: logCategory)
        displayMode = mode
        Self.saveDisplayMode(mode)
    }
    
    // Computes appropriate status message based on platform and extension state
    var stateMessage: String {
        switch platform.kind {
        case .ios:
            switch extensionEnabled {
            case .unchecked:
                return LocalizedString.extensionStateIOSUnknown()
            case .enabled:
                return LocalizedString.extensionStateIOSOn()
            case .disabled:
                return LocalizedString.extensionStateIOSOff()
            }
        case .mac:
            let location = LocalizedString.extensionStateMacLocation(useSettings: platform.useSettings)
            switch extensionEnabled {
            case .unchecked:
                return LocalizedString.extensionStateMacEnable(location: location)
            case .enabled:
                return LocalizedString.extensionStateMacOn(location: location)
            case .disabled:
                return LocalizedString.extensionStateMacOff(location: location)
            }
        }
    }
    
    // Returns button title for macOS, nil for iOS (no button shown)
    var preferencesButtonTitle: String? {
        guard platform.shouldShowPreferencesButton() else { return nil }
        return LocalizedString.preferencesButton(useSettings: platform.useSettings)
    }
    
    // Opens Safari preferences and quits the app (macOS only)
    func openPreferences() {
        logInfo("Opening extension preferences", category: logCategory)
        platform.openExtensionPreferences {
            DispatchQueue.main.async {
                // Platform-specific termination (implemented in platform extensions)
                self.terminateAppIfNeeded()
            }
        }
    }
    
    // Checks with Safari whether extension is currently enabled
    private func refreshExtensionState() {
        logDebug("Checking extension state", category: logCategory)
        platform.checkExtensionState { [weak self] enabled in
            guard let self = self else { return }
            // [weak self] prevents memory leaks by allowing self to be deallocated
            DispatchQueue.main.async {
                let state: ExtensionState
                if let enabled = enabled {
                    state = enabled ? .enabled : .disabled
                    logInfo("Extension state: \(enabled ? "enabled" : "disabled")", category: self.logCategory)
                } else {
                    state = .unchecked
                    logWarning("Extension state unknown", category: self.logCategory)
                }
                self.extensionEnabled = state
                
                // Platform-specific handling (iOS shows modal, macOS does nothing)
                self.handleExtensionStateChanged(state: state)
            }
        }
    }
    
    private static func createPlatformAdapter() -> PlatformAdapter {
        #if os(iOS)
        return iOSPlatformAdapter()
        #else
        return macOSPlatformAdapter()
        #endif
    }
    
    // UserDefaults with suiteName allows sharing preferences between app and extension
    private static func userDefaults() -> UserDefaults? {
        UserDefaults(suiteName: APP_GROUP_ID)
    }
    
    private static func loadDisplayMode() -> DisplayMode {
        let stored = userDefaults()?.string(forKey: DISPLAY_MODE_KEY)
        if let raw = stored, let mode = DisplayMode(rawValue: raw) {
            logDebug("Loaded display mode from storage: \(raw)", category: "AppViewModel")
            return mode
        }
        logDebug("No stored display mode, using default: \(DEFAULT_DISPLAY_MODE)", category: "AppViewModel")
        return DisplayMode(rawValue: DEFAULT_DISPLAY_MODE) ?? .hide
    }
    
    private static func saveDisplayMode(_ mode: DisplayMode) {
        logDebug("Saving display mode: \(mode.rawValue)", category: "AppViewModel")
        let defaults = userDefaults()
        defaults?.set(mode.rawValue, forKey: DISPLAY_MODE_KEY)
        defaults?.synchronize()
        logVerbose("Display mode saved successfully", category: "AppViewModel")
    }
}
