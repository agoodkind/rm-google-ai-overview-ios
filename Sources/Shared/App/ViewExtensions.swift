// ViewExtensions.swift
// Skip AI - Safari Extension App
//
// SwiftUI View extensions for platform-specific behaviors

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

