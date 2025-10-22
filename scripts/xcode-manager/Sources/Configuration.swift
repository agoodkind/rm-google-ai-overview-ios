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

enum Config {
    static let projectPath = Path("../../Skip AI.xcodeproj")
    static var workspaceRoot: Path {
        projectPath.parent().absolute()
    }
    
    static let infoPlistPaths = [
        "Sources/iOS/App/Info.plist",
        "Sources/iOS/Extension/Info.plist",
        "Sources/macOS/App/Info.plist",
        "Sources/macOS/Extension/Info.plist"
    ]
}

struct GroupConfig {
    let id: String
    let name: String
    let path: String
    let filePatterns: [String]
    let targets: [String]
}

enum Groups {
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
