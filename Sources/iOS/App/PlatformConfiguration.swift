// IOSPlatform.swift
// iOS (App)
//
// iOS-specific platform adapter implementation

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

