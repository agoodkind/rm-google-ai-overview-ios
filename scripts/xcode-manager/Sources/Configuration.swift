//
//  Configuration.swift
//  Skip AI
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  Project paths and group configurations

import Foundation
import PathKit

/// Global configuration for xcode-manager tool
enum Config {
    /// Path to Skip AI.xcodeproj (relative to tool location)
    static let projectPath = Path("../../Skip AI.xcodeproj")
    
    /// Absolute path to workspace root directory
    static var workspaceRoot: Path {
        projectPath.parent().absolute()
    }
    
    /// Info.plist file paths to validate/fix
    static let infoPlistPaths = [
        "Sources/iOS/App/Info.plist",
        "Sources/iOS/Extension/Info.plist",
        "Sources/macOS/App/Info.plist",
        "Sources/macOS/Extension/Info.plist"
    ]
}

/// Configuration for a file group in Xcode project
struct GroupConfig {
    /// Unique identifier for the group
    let id: String
    /// Display name in Xcode
    let name: String
    /// Filesystem path to directory
    let path: String
    /// File extensions to include (e.g. ["swift", "js"])
    let filePatterns: [String]
    /// Target names to add files to
    let targets: [String]
}

/// Predefined file groups for sync operation
enum Groups {
    /// All configured file groups
    static var all: [GroupConfig] {
        [
            GroupConfig(
                id: "webext",
                name: "webext",
                path: "dist/webext",
                filePatterns: ["js", "json"],
                targets: ["Skip AI Extension (iOS)", "Skip AI Extension (macOS)"]
            )
        ]
    }
}
