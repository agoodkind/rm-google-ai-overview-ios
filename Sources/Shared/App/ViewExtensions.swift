//
//  ViewExtensions.swift
//  Skip AI
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  VIEW MODIFIERS - Custom SwiftUI view behaviors
//
// This file adds new capabilities to SwiftUI views using Swift's extension system.
// Extensions let you add methods to existing types (like adding a new button to your calculator).
//
// What this provides:
// - applyPlatformFrame(): Applies appropriate width constraints based on platform
//   * iOS: Maximum width of 520 points (optimized for phone/tablet screens)
//   * macOS: Minimum width of 560, ideal width of 620 points (desktop window sizing)
//
// How to use it:
// Instead of writing:
//   #if os(iOS)
//     myView.frame(maxWidth: 520)
//   #else
//     myView.frame(minWidth: 560, idealWidth: 620)
//   #endif
//
// You can simply write:
//   myView.applyPlatformFrame(for: platform.kind)
//
// This is SwiftUI's "modifier" pattern - you chain behaviors onto views.

import SwiftUI

extension View {
    // Applies platform-specific width constraints
    func applyPlatformFrame(for platform: PlatformKind) -> some View {
        Group {
            switch platform {
            case .mac:
                self.frame(minWidth: 560, idealWidth: 620)
            case .ios:
                self.frame(maxWidth: 520)
            }
        }
    }
}

