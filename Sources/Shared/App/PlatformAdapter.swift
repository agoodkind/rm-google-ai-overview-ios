// PlatformAdapter.swift
// Skip AI - Safari Extension App
//
// Strategy pattern to handle iOS vs macOS differences
// Platform-specific implementations are in:
// - Sources/iOS/App/PlatformConfiguration.swift (IOSPlatformAdapter)
// - Sources/macOS/App/PlatformConfiguration.swift (MacOSPlatformAdapter)

import Foundation

protocol PlatformAdapter {
    var kind: PlatformKind { get }
    var useSettings: Bool { get }
    var horizontalPadding: CGFloat { get }
    
    func shouldShowPreferencesButton() -> Bool
    func openExtensionPreferences(completion: @escaping () -> Void)
    func checkExtensionState(completion: @escaping (Bool?) -> Void)
}

enum PlatformKind {
    case ios
    case mac
}

