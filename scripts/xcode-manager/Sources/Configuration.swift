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
    /// Path to Skip AI.xcodeproj
    static var projectPath: Path {
        if let envPath = ProcessInfo.processInfo.environment["XCODE_PROJECT_PATH"] {
            return Path(envPath)
        }
        
        if let configPath = loadFromConfigFile() {
            return Path(configPath)
        }
        
        if let gitPath = findProjectInGitRoot() {
            return gitPath
        }
        
        if let searchPath = searchUpwardsForProject() {
            return searchPath
        }
        
        return Path("Skip AI.xcodeproj")
    }
    
    /// Absolute path to workspace root directory
    static var workspaceRoot: Path {
        projectPath.parent().absolute()
    }
    
    /// Load project path from config files
    private static func loadFromConfigFile() -> String? {
        var possiblePaths: [Path] = [
            Path(".env"),
            Path(".env.local"),
            Path(".xcodemanager"),
            Path.home + ".xcodemanager",
            Path.current + ".xcodemanager"
        ]
        
        if let gitRoot = getGitRoot() {
            possiblePaths.insert(gitRoot + ".env", at: 0)
            possiblePaths.insert(gitRoot + ".env.local", at: 1)
            possiblePaths.insert(gitRoot + ".xcodemanager", at: 2)
        }
        
        for configPath in possiblePaths {
            guard configPath.exists else { continue }
            
            if let value = parseConfigFile(at: configPath) {
                return value
            }
        }
        
        return nil
    }
    
    /// Parse config file and extract XCODE_PROJECT_PATH value
    private static func parseConfigFile(at path: Path) -> String? {
        do {
            let contents = try String(contentsOf: path.url, encoding: .utf8)
            let lines = contents.split(separator: "\n")
            
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                
                if trimmed.isEmpty || trimmed.hasPrefix("#") {
                    continue
                }
                
                if trimmed.hasPrefix("XCODE_PROJECT_PATH=") {
                    var value = String(trimmed.dropFirst("XCODE_PROJECT_PATH=".count))
                    value = value.trimmingCharacters(in: .whitespaces)
                    
                    if value.hasPrefix("\"") && value.hasSuffix("\"") {
                        value = String(value.dropFirst().dropLast())
                    }
                    if value.hasPrefix("'") && value.hasSuffix("'") {
                        value = String(value.dropFirst().dropLast())
                    }
                    
                    return value
                }
            }
        } catch {
            return nil
        }
        
        return nil
    }
    
    /// Get git repository root
    private static func getGitRoot() -> Path? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["git", "rev-parse", "--show-toplevel"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            
            guard process.terminationStatus == 0 else {
                return nil
            }
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else {
                return nil
            }
            
            return Path(output.trimmingCharacters(in: .whitespacesAndNewlines))
        } catch {
            return nil
        }
    }
    
    /// Find project file in git repository root
    private static func findProjectInGitRoot() -> Path? {
        guard let gitRoot = getGitRoot() else {
            return nil
        }
        
        if let projectName = ProcessInfo.processInfo.environment["XCODE_PROJECT_NAME"] {
            let projectPath = gitRoot + projectName
            if projectPath.exists {
                return projectPath
            }
        }
        
        do {
            let children = try gitRoot.children()
            for child in children {
                if child.extension == "xcodeproj" {
                    return child
                }
            }
        } catch {
            return nil
        }
        
        return nil
    }
    
    /// Search upwards from current directory for .xcodeproj file
    private static func searchUpwardsForProject() -> Path? {
        var currentPath = Path.current
        
        for _ in 0..<10 {
            do {
                let children = try currentPath.children()
                for child in children {
                    if child.extension == "xcodeproj" {
                        return child
                    }
                }
            } catch {
                return nil
            }
            
            let parent = currentPath.parent()
            if parent == currentPath {
                break
            }
            currentPath = parent
        }
        
        return nil
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
