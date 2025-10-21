//
//  ContentBlockerStateChecker.swift
//  Skip AI (iOS)
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  EXTENSION STATE DETECTION - Hybrid approach for iOS
//
//  Primary: Content Blocker API (instant, reliable)
//  Secondary: Timestamp tracking (validates runtime state)
//
//  Why hybrid approach:
//  - Content blocker state = official API, instant detection
//  - Timestamp validation = confirms extension actively running
//  - Combined approach = reliable + comprehensive
//

import Foundation
import SafariServices

class ContentBlockerStateChecker {
    static let shared = ContentBlockerStateChecker()
    
    private let contentBlockerIdentifier = "io.goodkind.SkipAI.ContentBlocker"
    private let logCategory = "ContentBlockerStateChecker"
    
    private init() {}
    
    /// Check content blocker state using hybrid approach
    /// - Content blocker enabled → ✅ Enabled (trust API)
    /// - Content blocker disabled → ❌ Disabled (instant detection)
    /// - Content blocker error → 🔄 Fallback to timestamp
    func checkContentBlockerState(completion: @escaping (Bool?) -> Void) {
        logDebug("Starting content blocker state check", category: logCategory)
        
        SFContentBlockerManager.getStateOfContentBlocker(
            withIdentifier: contentBlockerIdentifier
        ) { [weak self] state, error in
            guard let self = self else {
                completion(nil)
                return
            }
            
            if let error = error {
                logWarning("Content blocker check failed: \(error.localizedDescription), falling back to timestamp", category: self.logCategory)
                self.fallbackToTimestampCheck(completion: completion)
                return
            }
            
            if let state = state {
                let isEnabled = state.isEnabled
                logInfo("Content blocker state: \(isEnabled ? "enabled" : "disabled")", category: self.logCategory)
                completion(isEnabled)
            } else {
                logWarning("Content blocker state unknown, falling back to timestamp", category: self.logCategory)
                self.fallbackToTimestampCheck(completion: completion)
            }
        }
    }
    
    private func fallbackToTimestampCheck(completion: @escaping (Bool?) -> Void) {
        logDebug("Checking extension state via timestamp", category: logCategory)
        let isActive = ExtensionCommunicator.shared.isExtensionActive()
        logInfo("Timestamp check result: \(isActive ? "active" : "inactive")", category: logCategory)
        completion(isActive)
    }
}

