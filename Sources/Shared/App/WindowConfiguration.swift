//
//  WindowConfiguration.swift
//  Skip AI
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  WINDOW CONFIGURATION - Platform-specific window styling
//
//  Provides extension methods to apply platform-specific window modifiers
//  Keeps the main app definition clean
//

import SwiftUI

extension Scene {
    // Apply platform-specific window configuration
    func withPlatformWindowConfiguration() -> some Scene {
        PlatformWindowConfiguration.configure(self)
    }
}

// Platform-specific window configuration
enum PlatformWindowConfiguration {
    static func configure<S: Scene>(_ scene: S) -> some Scene {
        #if os(macOS)
        return scene
            .windowStyle(.hiddenTitleBar)
            .windowResizability(.contentSize)
            .defaultSize(width: 620, height: 700)
        #else
        return scene
        #endif
    }
}
