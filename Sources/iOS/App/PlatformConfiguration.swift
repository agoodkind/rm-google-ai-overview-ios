// PlatformConfiguration.swift
// iOS (App)
//
// iOS-SPECIFIC IMPLEMENTATIONS - How iOS handles platform differences
//
// This file implements the PlatformAdapter protocol for iOS devices (iPhone, iPad).
// It defines behaviors that are unique to iOS or impossible on iOS.
//
// What this file provides:
//
// 1. IOSPlatformAdapter - Implements platform-specific behaviors for iOS
//    - kind: Identifies this as iOS platform
//    - useSettings: Always false (iOS doesn't have the same settings structure as macOS)
//    - horizontalPadding: 32 points (optimized for mobile screens)
//    - shouldShowPreferencesButton: Returns false (iOS can't programmatically open extension settings)
//    - openExtensionPreferences: Does nothing (iOS limitation - user must open Settings manually)
//    - checkExtensionState: Returns nil (iOS doesn't allow apps to query extension status)
//
// 2. PlatformColor extensions - iOS-specific colors
//    - iosWindowBackground: Uses systemBackground (adapts to light/dark mode automatically)
//    - iosPanelBackground: Uses secondarySystemBackground (subtle contrast from window)
//
// Why are some features limited on iOS?
// - Apple restricts what apps can do programmatically for privacy and security
// - Users must manually enable extensions in iOS Settings app
// - Apps can't query extension state to prevent tracking/fingerprinting

import SwiftUI

struct IOSPlatformAdapter: PlatformAdapter {
    let kind: PlatformKind = .ios
    let useSettings: Bool = false
    let horizontalPadding: CGFloat = 32
    
    func shouldShowPreferencesButton() -> Bool { false }
    
    // iOS can't programmatically open extension preferences
    func openExtensionPreferences(completion: @escaping () -> Void) {}
    
    // iOS can't check extension state programmatically - returns nil (unknown)
    func checkExtensionState(completion: @escaping (Bool?) -> Void) {
        completion(nil)
    }
}

// iOS-specific color implementations
extension PlatformColor {
    static var iosWindowBackground: Color {
        Color(.systemBackground)
    }
    
    static var iosPanelBackground: Color {
        Color(.secondarySystemBackground)
    }
}

