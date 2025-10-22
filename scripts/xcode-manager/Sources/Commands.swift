//
//  Commands.swift
//  Skip AI
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  CLI command implementations using ArgumentParser

import Foundation
import XcodeProj
import PathKit
import ArgumentParser

extension XcodeManager {
    struct SyncGroups: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Sync file groups to Xcode targets"
        )
        
        @Flag(name: .shortAndLong, help: "Skip backup creation")
        var noBackup = false
        
        func run() throws {
            Utils.printHeader("Sync Groups")
            
            let manager = try XcodeProjectManager(projectPath: Config.projectPath)
            
            if !noBackup {
                try manager.backup()
                print()
            }
            
            for groupConfig in Groups.all {
                manager.cleanupGroup(groupConfig)
                manager.populateGroup(groupConfig)
            }
            
            print()
            try manager.save()
            
            Utils.printSuccess("Groups synced successfully!")
        }
    }
    
    struct BumpVersion: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Bump version numbers in project"
        )
        
        @Flag(help: "Bump major version (X.0.0)")
        var major = false
        
        @Flag(help: "Bump minor version (x.X.0)")
        var minor = false
        
        @Flag(help: "Bump patch version (x.x.X)")
        var patch = false
        
        @Flag(help: "Bump build number only")
        var build = false
        
        @Option(help: "Set specific version (e.g., 1.2.3)")
        var setVersion: String?
        
        @Option(help: "Set specific build number (e.g., 215)")
        var setBuild: Int?
        
        @Flag(name: .shortAndLong, help: "Skip backup creation")
        var noBackup = false
        
        func validate() throws {
            let flags = [major, minor, patch, build].filter { $0 }
            let hasSetVersion = setVersion != nil
            let hasSetBuild = setBuild != nil
            
            if flags.count > 1 {
                throw ValidationError("Specify only one of: --major, --minor, --patch, or --build")
            }
            
            if !flags.isEmpty && (hasSetVersion || hasSetBuild) {
                throw ValidationError("Cannot use flags (--major, --minor, etc.) with --set-version or --set-build")
            }
            
            if flags.isEmpty && !hasSetVersion && !hasSetBuild {
                throw ValidationError("Specify at least one option: --major, --minor, --patch, --build, --set-version, or --set-build")
            }
        }
        
        func run() throws {
            Utils.printHeader("Bump Version")
            
            let manager = try XcodeProjectManager(projectPath: Config.projectPath)
            
            if !noBackup {
                try manager.backup()
                print()
            }
            
            let currentVersion = try manager.getMarketingVersion()
            let currentBuild = try manager.getCurrentProjectVersion()
            
            print("Current version: \(currentVersion) (build \(currentBuild))")
            print()
            
            var newVersion = currentVersion
            var newBuild = currentBuild
            
            if let version = setVersion {
                newVersion = version
            } else if let buildNum = setBuild {
                newBuild = buildNum
            } else if build {
                newBuild = currentBuild + 1
            } else {
                let components = currentVersion.split(separator: ".").compactMap { Int($0) }
                guard components.count == 3 else {
                    throw XcodeManagerError.invalidVersion("Current version format invalid: \(currentVersion)")
                }
                
                var (majorVer, minorVer, patchVer) = (components[0], components[1], components[2])
                
                if major {
                    majorVer += 1
                    minorVer = 0
                    patchVer = 0
                } else if minor {
                    minorVer += 1
                    patchVer = 0
                } else if patch {
                    patchVer += 1
                }
                
                newVersion = "\(majorVer).\(minorVer).\(patchVer)"
                newBuild = currentBuild + 1
            }
            
            if setVersion == nil && setBuild == nil {
                try manager.setBothVersions(marketing: newVersion, build: newBuild)
                print("New version: \(newVersion) (build \(newBuild))")
            } else if setVersion != nil {
                try manager.setMarketingVersion(newVersion)
                print("New version: \(newVersion)")
            } else if setBuild != nil {
                try manager.setCurrentProjectVersion(newBuild)
                print("New build: \(newBuild)")
            }
            
            print()
            try manager.save()
            
            Utils.printSuccess("Version updated successfully!")
        }
    }
    
    struct FixInfoPlist: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Fix Info.plist files with required keys"
        )
        
        @Flag(name: .shortAndLong, help: "Show what would be changed without making changes")
        var dryRun = false
        
        func run() throws {
            Utils.printHeader("Fix Info.plist")
            
            print("Checking Info.plist files...\n")
            
            for plistPath in Config.infoPlistPaths {
                let fullPath = Config.workspaceRoot + plistPath
                let fileName = fullPath.lastComponent
                let target = plistPath.contains("Extension") ? "Extension" : "App"
                let platform = plistPath.contains("iOS") ? "iOS" : "macOS"
                
                print("📄 \(platform) \(target): \(fileName)")
                
                guard fullPath.exists else {
                    print("  ⚠️  File not found, skipping\n")
                    continue
                }
                
                let plist = try PropertyListSerialization.propertyList(
                    from: try Data(contentsOf: fullPath.url),
                    options: [],
                    format: nil
                ) as! [String: Any]
                
                var modified = plist
                var changes: [String] = []
                
                let requiredKeys: [(key: String, value: String, description: String)] = [
                    ("CFBundleExecutable", "$(EXECUTABLE_NAME)", "Bundle executable"),
                    ("CFBundleIdentifier", "$(PRODUCT_BUNDLE_IDENTIFIER)", "Bundle identifier"),
                    ("CFBundleName", "$(PRODUCT_NAME)", "Bundle name"),
                    ("CFBundleShortVersionString", "$(MARKETING_VERSION)", "Version string"),
                    ("CFBundleVersion", "$(CURRENT_PROJECT_VERSION)", "Build number")
                ]
                
                for (key, value, desc) in requiredKeys {
                    if modified[key] == nil {
                        modified[key] = value
                        changes.append("  + Add \(desc): \(key)")
                    }
                }
                
                let displayName = target == "Extension" ? "Skip AI Extension" : "Skip AI"
                if modified["CFBundleDisplayName"] == nil {
                    modified["CFBundleDisplayName"] = displayName
                    changes.append("  + Add CFBundleDisplayName: \(displayName)")
                }
                
                if changes.isEmpty {
                    print("  ✓ Already complete\n")
                } else {
                    for change in changes {
                        print(change)
                    }
                    
                    if !dryRun {
                        let data = try PropertyListSerialization.data(
                            fromPropertyList: modified,
                            format: .xml,
                            options: 0
                        )
                        try data.write(to: fullPath.url)
                        print("  ✓ Updated\n")
                    } else {
                        print("  ℹ️  Dry run - no changes made\n")
                    }
                }
            }
            
            if dryRun {
                print("Dry run complete - no files were modified")
            } else {
                Utils.printSuccess("Info.plist files fixed!")
            }
        }
    }
    
    struct ShowVersion: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Show current version numbers"
        )
        
        func run() throws {
            let manager = try XcodeProjectManager(projectPath: Config.projectPath)
            
            let version = try manager.getMarketingVersion()
            let build = try manager.getCurrentProjectVersion()
            
            print("Skip AI")
            print("Version: \(version)")
            print("Build: \(build)")
        }
    }
    
    struct AddBuildScript: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Add JS build script to extension targets"
        )
        
        @Flag(name: .shortAndLong, help: "Skip backup creation")
        var noBackup = false
        
        @Flag(help: "Remove build script instead of adding it")
        var remove = false
        
        func run() throws {
            Utils.printHeader(remove ? "Remove Build Script" : "Add Build Script")
            
            let manager = try XcodeProjectManager(projectPath: Config.projectPath)
            
            if !noBackup {
                try manager.backup()
                print()
            }
            
            let targetNames = ["Skip AI Extension (iOS)", "Skip AI Extension (macOS)"]
            
            for targetName in targetNames {
                guard let target = manager.findTarget(name: targetName) else {
                    print("⚠️  Target not found: \(targetName)")
                    continue
                }
                
                if remove {
                    let removed = try manager.removeBuildScript(from: target, named: "Build JavaScript")
                    if removed {
                        print("✓ Removed build script from: \(targetName)")
                    } else {
                        print("ℹ️  No build script found in: \(targetName)")
                    }
                } else {
                    let added = try manager.addBuildScript(to: target)
                    if added {
                        print("✓ Added build script to: \(targetName)")
                    } else {
                        print("ℹ️  Build script already exists in: \(targetName)")
                    }
                }
            }
            
            print()
            try manager.save()
            
            if remove {
                Utils.printSuccess("Build scripts removed!")
            } else {
                Utils.printSuccess("Build scripts added! JS will now build automatically in Xcode.")
            }
        }
    }
    
    struct AddFiles: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Add source files to Xcode targets"
        )
        
        @Argument(help: "Directory containing files to add")
        var directory: String
        
        @Option(name: .shortAndLong, help: "Target names (comma-separated)")
        var targets: String
        
        @Option(name: .shortAndLong, help: "Group path in Xcode (e.g., 'Sources/iOS/App')")
        var group: String
        
        @Flag(name: .shortAndLong, help: "Skip backup creation")
        var noBackup = false
        
        @Flag(name: .long, help: "Dry run - show what would be added without making changes")
        var dryRun = false
        
        func run() throws {
            Utils.printHeader(dryRun ? "Add Files (Dry Run)" : "Add Files")
            
            let manager = try XcodeProjectManager(projectPath: Config.projectPath)
            
            if !noBackup && !dryRun {
                try manager.backup()
                print()
            }
            
            let targetNames = targets.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
            let targetObjects = targetNames.compactMap { manager.findTarget(name: $0) }
            
            guard !targetObjects.isEmpty else {
                print("❌ No targets found: \(targetNames.joined(separator: ", "))")
                return
            }
            
            let dirPath = Path(directory)
            guard dirPath.exists else {
                print("❌ Directory not found: \(directory)")
                return
            }
            
            let files = manager.findFiles(in: directory, patterns: ["swift"])
            
            guard !files.isEmpty else {
                print("ℹ️  No .swift files found in \(directory)")
                return
            }
            
            print("Found \(files.count) file(s) in \(directory)")
            print("Targets: \(targetNames.joined(separator: ", "))")
            print("Group: \(group)")
            print()
            
            var addedCount = 0
            var skippedCount = 0
            
            for file in files {
                let fileName = file.lastComponent
                
                if dryRun {
                    print("  Would add: \(fileName)")
                    addedCount += 1
                } else {
                    let added = manager.addSourceFile(filePath: file, to: targetObjects, in: group)
                    if added {
                        print("  ✓ Added: \(fileName)")
                        addedCount += 1
                    } else {
                        print("  ⊘ Skipped (already exists): \(fileName)")
                        skippedCount += 1
                    }
                }
            }
            
            print()
            
            if dryRun {
                print("Dry run complete - no changes made")
                print("Would add \(addedCount) file(s)")
            } else {
                try manager.save()
                Utils.printSuccess("Added \(addedCount) file(s), skipped \(skippedCount) file(s)")
            }
        }
    }
    
    struct CleanMissing: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Remove missing file references from Xcode project"
        )
        
        @Option(name: .shortAndLong, help: "Group path in Xcode (e.g., 'Sources/iOS/App')")
        var group: String
        
        @Flag(name: .shortAndLong, help: "Skip backup creation")
        var noBackup = false
        
        func run() throws {
            Utils.printHeader("Clean Missing References")
            
            let manager = try XcodeProjectManager(projectPath: Config.projectPath)
            
            if !noBackup {
                try manager.backup()
                print()
            }
            
            print("Scanning group: \(group)")
            print()
            
            let removed = manager.cleanMissingReferences(in: group)
            
            if removed.isEmpty {
                print("✓ No missing references found")
            } else {
                for file in removed {
                    print("  ✓ Removed: \(file)")
                }
                print()
                try manager.save()
                Utils.printSuccess("Removed \(removed.count) missing reference(s)")
            }
        }
    }
    
    struct FixContentBlocker: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Fix ContentBlocker Info.plist conflict"
        )
        
        @Flag(name: .shortAndLong, help: "Skip backup creation")
        var noBackup = false
        
        func run() throws {
            Utils.printHeader("Fix ContentBlocker Settings")
            
            let manager = try XcodeProjectManager(projectPath: Config.projectPath)
            
            if !noBackup {
                try manager.backup()
                print()
            }
            
            let changed = manager.fixContentBlockerSettings()
            
            if changed {
                print("✓ Set GENERATE_INFOPLIST_FILE = NO for ContentBlocker target")
                print()
                try manager.save()
                Utils.printSuccess("ContentBlocker settings fixed!")
            } else {
                print("✓ ContentBlocker settings already correct")
            }
        }
    }
    
    struct RemoveDuplicates: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Remove duplicate file references from build phases"
        )
        
        @Flag(name: .shortAndLong, help: "Skip backup creation")
        var noBackup = false
        
        func run() throws {
            Utils.printHeader("Remove Duplicate Files")
            
            let manager = try XcodeProjectManager(projectPath: Config.projectPath)
            
            if !noBackup {
                try manager.backup()
                print()
            }
            
            let removedCount = manager.removeDuplicateFiles()
            
            if removedCount > 0 {
                print("✓ Removed \(removedCount) duplicate file reference(s)")
                print()
                try manager.save()
                Utils.printSuccess("Duplicates removed!")
            } else {
                print("✓ No duplicates found")
            }
        }
    }
    
    struct ListTargets: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "List all targets in the project"
        )
        
        func run() throws {
            let manager = try XcodeProjectManager(projectPath: Config.projectPath)
            
            print("Targets in Skip AI.xcodeproj:\n")
            
            for target in manager.project.pbxproj.nativeTargets {
                let name = target.name
                let productType = target.productType?.rawValue ?? "unknown"
                print("  • \(name)")
                print("    Type: \(productType)")
                print()
            }
        }
    }
    
    struct ListGroups: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "List all groups in the project"
        )
        
        @Flag(help: "Show full paths")
        var fullPaths = false
        
        func run() throws {
            let manager = try XcodeProjectManager(projectPath: Config.projectPath)
            
            print("Groups in Skip AI.xcodeproj:\n")
            
            func printGroup(_ group: PBXGroup, indent: String = "") {
                let name = group.name ?? group.path ?? "(unnamed)"
                let path = group.path ?? ""
                
                if fullPaths && !path.isEmpty {
                    print("\(indent)• \(name) → \(path)")
                } else {
                    print("\(indent)• \(name)")
                }
                
                for child in group.children {
                    if let childGroup = child as? PBXGroup {
                        printGroup(childGroup, indent: indent + "  ")
                    }
                }
            }
            
            if let mainGroup = manager.project.pbxproj.rootObject?.mainGroup {
                printGroup(mainGroup)
            }
        }
    }
}
