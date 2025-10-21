// PlatformColor.swift
// Skip AI - Safari Extension App
//
// Platform-specific color implementations are in:
// - Sources/iOS/App/PlatformConfiguration.swift (iosWindowBackground, iosPanelBackground)
// - Sources/macOS/App/PlatformConfiguration.swift (macOSWindowBackground, macOSPanelBackground)

import SwiftUI

enum PlatformColor {
    static var windowBackground: Color {
        #if os(iOS)
        return iosWindowBackground
        #else
        return macOSWindowBackground
        #endif
    }
    
    static var panelBackground: Color {
        #if os(iOS)
        return iosPanelBackground
        #else
        return macOSPanelBackground
        #endif
    }
}

