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

/// Debug event entry for event log
struct DebugEvent: Identifiable {
    let id = UUID()
    let timestamp: Date
    let message: String
    let type: EventType
    
    enum EventType {
        case activation
        case deactivation
        case extensionState
        case displayMode
        case launch
    }
}

final class AppViewModel: ObservableObject {
    private let logCategory = "AppViewModel"
    private let maxDebugEvents = 20 // Keep last 20 events
    
    enum DisplayMode: String {
        case hide       // Completely remove AI content
        case highlight  // Show with orange border
    }
    
    // @Published automatically triggers UI updates when these values change
    @Published var displayMode: DisplayMode {
        didSet {
            if displayMode != oldValue {
                logDebug("Display mode changed to \(displayMode.rawValue), saving...", category: logCategory)
                Self.saveDisplayMode(displayMode)
                addDebugEvent("Display mode → \(displayMode.rawValue)", type: .displayMode)
            }
        }
    }
    @Published var extensionEnabled: ExtensionState = .unchecked
    @Published var showEnableExtensionModal: Bool = false  // Controls modal visibility on iOS
    
    // Launch tracking
    @Published var isFirstLaunchEver: Bool = false          // True only on very first app launch
    @Published var launchCount: Int = 0                     // Total number of times app has launched
    @Published var lastLaunchDate: Date?                    // When app was previously launched
    @Published var currentSessionStartDate: Date = Date()   // When current app instance started
    
    // Session tracking
    @Published var lastActiveDate: Date = Date()            // Last time app became active
    @Published var lastInactiveDate: Date?                  // Last time app became inactive
    @Published var isColdLaunch: Bool = true                // True if fresh launch, false if resumed from background
    @Published var activationCount: Int = 0                 // Number of times app became active this session
    
    // Debug event log
    @Published var debugEventLog: [DebugEvent] = []         // Recent events for debug panel
    
    // Extension logs and stats
    var extensionLogReader = ExtensionLogReader()      // Reads logs from extension
    var extensionStatsReader = ExtensionStatsReader()  // Reads stats from extension
    var extensionPingTracker = ExtensionPingTracker()  // Tracks extension pings
    
    // Handler debug logs
    @Published var handlerDebugLogs: [String] = []
    
    // User preferences
    @Published var hasSeenEnableExtensionModal: Bool = false // Track if user dismissed modal
    
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
        
        // Track first launch and launch count
        let defaults = Self.userDefaults()
        let hasLaunchedBefore = defaults?.bool(forKey: "has_launched_before") ?? false
        self.isFirstLaunchEver = !hasLaunchedBefore
        self.launchCount = defaults?.integer(forKey: "launch_count") ?? 0
        self.lastLaunchDate = defaults?.object(forKey: "last_launch_date") as? Date
        self.hasSeenEnableExtensionModal = defaults?.bool(forKey: "has_seen_enable_extension_modal") ?? false
        
        if !hasLaunchedBefore {
            defaults?.set(true, forKey: "has_launched_before")
        }
        defaults?.set(launchCount + 1, forKey: "launch_count")
        defaults?.set(Date(), forKey: "last_launch_date")
        defaults?.synchronize()
        
        logInfo("Launch #\(launchCount + 1), First launch: \(isFirstLaunchEver)", category: logCategory)
        addDebugEvent("Launch #\(launchCount + 1)", type: .launch)
        
        refreshExtensionState()
    }
    
    /// Called when the view appears or app becomes active
    ///
    /// Handles:
    /// - Reloading display mode from storage
    /// - Refreshing extension state
    /// - Refreshing extension logs
    /// - Tracking app activation
    func onAppear() {
        logVerbose("onAppear called", category: logCategory)
        displayMode = Self.loadDisplayMode()
        refreshExtensionState()
        extensionLogReader.refreshLogs()
        extensionStatsReader.refreshStats()
        extensionPingTracker.refreshPings()
        refreshHandlerDebugLogs()
    }
    
    func refreshHandlerDebugLogs() {
        guard let defaults = Self.userDefaults() else { return }
        handlerDebugLogs = defaults.array(forKey: "handler-debug") as? [String] ?? []
    }
    
    /// Track when app becomes active
    /// - Parameter isInitialLaunch: True if this is the first activation after launch
    func trackActivation(isInitialLaunch: Bool = false) {
        let now = Date()
        lastActiveDate = now
        
        if !isInitialLaunch {
            isColdLaunch = false
            activationCount += 1
            logInfo("App became active (activation #\(activationCount)) at \(now)", category: logCategory)
            addDebugEvent("Became active (#\(activationCount))", type: .activation)
        } else {
            logInfo("Initial app activation at \(now)", category: logCategory)
            addDebugEvent("Initial activation", type: .activation)
        }
    }
    
    /// Track when app becomes inactive
    func trackDeactivation() {
        let now = Date()
        lastInactiveDate = now
        logInfo("App became inactive at \(now)", category: logCategory)
        addDebugEvent("Became inactive", type: .deactivation)
    }
    
    /// Add event to debug log
    /// - Parameters:
    ///   - message: Event description
    ///   - type: Event type for categorization
    private func addDebugEvent(_ message: String, type: DebugEvent.EventType) {
        let event = DebugEvent(timestamp: Date(), message: message, type: type)
        debugEventLog.insert(event, at: 0) // Most recent first
        if debugEventLog.count > maxDebugEvents {
            debugEventLog = Array(debugEventLog.prefix(maxDebugEvents))
        }
    }
    
    /// Generate feedback report text
    /// - Returns: Formatted feedback report with app state and diagnostics
    func generateFeedbackReport() -> String {
        FeedbackReporter(viewModel: self).generateReport()
    }
    
    /// Mark that user has seen and dismissed the enable extension modal
    func dismissEnableExtensionModal() {
        showEnableExtensionModal = false
        hasSeenEnableExtensionModal = true
        let defaults = Self.userDefaults()
        defaults?.set(true, forKey: "has_seen_enable_extension_modal")
        defaults?.synchronize()
        logInfo("User dismissed enable extension modal", category: logCategory)
    }
    
    #if DEBUG
    /// Reset modal dismissal flag (DEBUG only)
    func resetModalDismissal() {
        hasSeenEnableExtensionModal = false
        let defaults = Self.userDefaults()
        defaults?.set(false, forKey: "has_seen_enable_extension_modal")
        defaults?.synchronize()
        logInfo("Reset modal dismissal flag", category: logCategory)
    }
    #endif
    
    func selectDisplayMode(_ mode: DisplayMode) {
        displayMode = mode
    }
    
    // Computes appropriate status message based on platform and extension state
    var stateMessage: String {
        switch platform.kind {
        case .ios:
            switch extensionEnabled {
            case .unchecked:
                return LocalizedString.extensionStateiOSUnknown()
            case .enabled:
                return LocalizedString.extensionStateiOSOn()
            case .disabled:
                return LocalizedString.extensionStateiOSOff()
            case .error:
                return LocalizedString.extensionStateiOSError()
            }
        case .mac:
            // macOS 13+ uses "Settings", older versions use "System Preferences"
            let location = LocalizedString.extensionStateMacOSLocation(useSettings: platform.useSettings)
            switch extensionEnabled {
            case .unchecked:
                return LocalizedString.extensionStateMacOSEnable(location: location)
            case .enabled:
                return LocalizedString.extensionStateMacOSOn(location: location)
            case .disabled:
                return LocalizedString.extensionStateMacOSOff(location: location)
            case .error:
                return LocalizedString.extensionStateMacOSError(location: location)
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
        platform.checkExtensionState { [weak self] state in
            guard let self = self else { return }
            // [weak self] prevents memory leaks by allowing self to be deallocated
            DispatchQueue.main.async {
                if self.extensionEnabled != state {
                    self.addDebugEvent("Extension state → \(state)", type: .extensionState)
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
    static func userDefaults() -> UserDefaults? {
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

