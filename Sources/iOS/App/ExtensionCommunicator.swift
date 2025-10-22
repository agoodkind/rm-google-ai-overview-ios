//
//  ExtensionCommunicator.swift
//  Skip AI (iOS)
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  TIMESTAMP TRACKING - Secondary extension state detection for iOS
//
//  How it works:
//  - Extension updates timestamp via SafariWebExtensionHandler
//  - App checks timestamp freshness (5-minute window)
//  - Validates extension is actively running
//
//  Why needed:
//  - Complements content blocker state checking
//  - Validates extension runtime state
//  - Enables display mode synchronization
//

import Foundation

class ExtensionCommunicator {
    static let shared = ExtensionCommunicator()
    
    private let timestampKey = "extension-last-active"
    private let freshnessWindow: TimeInterval = 5 * 60  // 5 minutes
    private let logCategory = "ExtensionCommunicator"
    
    private init() {}
    
    /// Check if extension is actively running based on timestamp
    /// Returns true if timestamp exists and is within 5-minute window
    func isExtensionActive() -> Bool {
        logDebug("Checking extension active state via timestamp", category: logCategory)
        
        guard let defaults = UserDefaults(suiteName: APP_GROUP_ID) else {
            logError("Failed to access shared UserDefaults", category: logCategory)
            return false
        }
        
        guard let lastActive = defaults.object(forKey: timestampKey) as? Date else {
            logInfo("No timestamp found, extension not active", category: logCategory)
            return false
        }
        
        let timeSinceActive = Date().timeIntervalSince(lastActive)
        let isActive = timeSinceActive < freshnessWindow
        
        logInfo("Timestamp check: \(Int(timeSinceActive))s since last active, threshold: \(Int(freshnessWindow))s, active: \(isActive)", category: logCategory)
        
        return isActive
    }
}
