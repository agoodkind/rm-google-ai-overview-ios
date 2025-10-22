//
//  PlatformAdapter.swift
//  Skip AI
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  PLATFORM ABSTRACTION - Defines what platform-specific code must do
//
// iOS and macOS are different! This file defines the contract (protocol) that both
// platforms must implement, without caring about HOW they do it.
//
// What this protocol defines:
// - What information each platform needs to provide (padding, settings location, etc.)
// - What actions each platform can perform (open preferences, check extension state)
//
// Why use this pattern?
// - Keeps shared code clean - no scattered #if os(iOS) checks everywhere
// - Each platform implements features in its own way (iOS can't check extension state, macOS can)
// - Easy to test - you can swap in a mock platform for testing
// - Single Responsibility: Each platform handles its own quirks in its own file
//
// Actual implementations live in:
// - Sources/iOS/App/PlatformConfiguration.swift (IOSPlatformAdapter)
// - Sources/macOS/App/PlatformConfiguration.swift (MacOSPlatformAdapter)
//
// This is the "Strategy Pattern" in object-oriented design.

import Foundation

enum ExtensionState {
    case unchecked  // Haven't checked yet
    case enabled    // Extension is enabled
    case disabled   // Extension is disabled
    case error      // Check failed with error
}

protocol PlatformAdapter {
    var kind: PlatformKind { get }
    var useSettings: Bool { get }
    var horizontalPadding: CGFloat { get }
    
    func shouldShowPreferencesButton() -> Bool
    func openExtensionPreferences(completion: @escaping () -> Void)
    func checkExtensionState(completion: @escaping (ExtensionState) -> Void)
}

enum PlatformKind {
    case ios
    case mac
}
