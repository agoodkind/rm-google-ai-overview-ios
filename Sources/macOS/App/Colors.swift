//
//  PlatformColors.swift
//  Skip AI (macOS)
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  PLATFORM COLORS - macOS-specific color implementations
//

import SwiftUI
import AppKit

extension PlatformColor {
    static var macOSWindowBackground: Color {
        Color(NSColor.windowBackgroundColor)
    }
    
    static var macOSPanelBackground: Color {
        Color(NSColor.underPageBackgroundColor)
    }
}

