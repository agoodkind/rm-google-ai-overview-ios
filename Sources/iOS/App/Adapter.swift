//
//  PlatformAdapter.swift
//  Skip AI (iOS)
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  PLATFORM ADAPTER - Implements PlatformAdapter protocol for iOS
//

import SwiftUI
import Foundation
import SafariServices

struct iOSPlatformAdapter: PlatformAdapter {
    let kind: PlatformKind = .ios
    let useSettings: Bool = false
    let horizontalPadding: CGFloat = 32
    
    func shouldShowPreferencesButton() -> Bool { false }
    
    // iOS can't programmatically open extension preferences
    func openExtensionPreferences(completion: @escaping () -> Void) {}
    
    // Check extension state using hybrid content blocker + timestamp approach
    func checkExtensionState(completion: @escaping (Bool?) -> Void) {
        ContentBlockerStateChecker.shared.checkContentBlockerState(completion: completion)
    }
}
