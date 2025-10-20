#!/usr/bin/env swift

/*
 Xcode Group Manager - Swift Implementation with XcodeProj
 
 This script uses the XcodeProj library for clean, type-safe project manipulation.
 No string matching or regex - just proper Swift APIs.
 
 Installation:
   cd scripts
   swift build
   
 Usage:
   cd scripts
   swift run add-xcode-targets
   
 Or build and run the binary:
   swift build -c release
   .build/release/add-xcode-targets
*/

import Foundation
import XcodeProj
import PathKit

// ============================================================================
// CONFIGURATION - All customizable IDs and paths
// ============================================================================

let PROJECT_PATH = Path("../Skip AI.xcodeproj")
let WORKSPACE_ROOT = PROJECT_PATH.parent().absolute()

/// Configuration for a group to be added to the project
struct GroupConfig {
    let id: String
    let name: String
    let path: String
    let filePatterns: [String]
    let targets: [String]
}

let GROUPS: [GroupConfig] = [
    GroupConfig(
        id: "webext",
        name: "webext",
        path: (WORKSPACE_ROOT + "dist/webext").string,
        filePatterns: ["js", "json"],
        targets: ["Skip AI Extension (iOS)", "Skip AI Extension (macOS)"]
    )
]

// ============================================================================
// XCODE PROJECT MANAGER
// ============================================================================

class XcodeProjectManager {
    let project: XcodeProj
    let pbxproj: PBXProj
    let projectPath: Path
    
    init(projectPath: Path) throws {
        self.projectPath = projectPath
        self.project = try XcodeProj(path: projectPath)
        self.pbxproj = project.pbxproj
    }
    
    /// Find files in directory matching patterns
    func findFiles(in directory: String, patterns: [String]) -> [Path] {
        let dirPath = Path(directory)
        
        guard dirPath.exists else {
            return []
        }
        
        var files: [Path] = []
        
        do {
            let children = try dirPath.children()
            
            for child in children {
                if child.isFile {
                    let ext = child.extension ?? ""
                    if patterns.contains(ext) {
                        files.append(child)
                    }
                }
            }
        } catch {
            print("  ⚠️  Error reading directory \(directory): \(error.localizedDescription)")
        }
        
        return files.sorted { $0.lastComponent < $1.lastComponent }
    }
    
    /// Find target by name
    func findTarget(name: String) -> PBXNativeTarget? {
        return pbxproj.nativeTargets.first { $0.name == name }
    }
    
    /// Find main group
    func mainGroup() -> PBXGroup? {
        return pbxproj.projects.first?.mainGroup
    }
    
    /// Clean up existing group
    func cleanupGroup(_ config: GroupConfig) {
        print("Cleaning up group: \(config.name)")
        
        guard let mainGroup = mainGroup() else {
            print("  ⚠️  Main group not found")
            return
        }
        
        // Find and remove existing group
        if let existingGroup = mainGroup.children.compactMap({ $0 as? PBXGroup }).first(where: { $0.name == config.name }) {
            // Get all file references from the group
            let fileRefs = existingGroup.children.compactMap { $0 as? PBXFileReference }
            
            // Remove from build phases
            for target in pbxproj.nativeTargets {
                if let resourcesPhase = target.buildPhases.first(where: { $0 is PBXResourcesBuildPhase }) as? PBXResourcesBuildPhase {
                    let filesToRemove = resourcesPhase.files?.filter { buildFile in
                        fileRefs.contains { $0 == buildFile.file as? PBXFileReference }
                    } ?? []
                    
                    for file in filesToRemove {
                        resourcesPhase.files?.removeAll { $0 == file }
                        pbxproj.delete(object: file)
                    }
                }
            }
            
            // Remove file references
            for fileRef in fileRefs {
                pbxproj.delete(object: fileRef)
            }
            
            // Remove group
            mainGroup.children.removeAll { $0 == existingGroup }
            pbxproj.delete(object: existingGroup)
            
            print("  ✓ Removed existing group")
        }
    }
    
    /// Populate group with files
    func populateGroup(_ config: GroupConfig) {
        print("\nProcessing group: \(config.name) (\(config.path))")
        
        let dirPath = Path(config.path)
        guard dirPath.exists else {
            print("  ⚠️  Directory not found: \(config.path), skipping")
            return
        }
        
        // Find files
        let files = findFiles(in: config.path, patterns: config.filePatterns)
        
        guard !files.isEmpty else {
            print("  ℹ️  No files found in \(config.path)")
            return
        }
        
        print("  Found \(files.count) file(s)")
        
        // Get main group
        guard let mainGroup = mainGroup() else {
            print("  ⚠️  Main group not found")
            return
        }
        
        // Create new group
        let group = PBXGroup(
            children: [],
            sourceTree: .group,
            name: config.name,
            path: config.path
        )
        pbxproj.add(object: group)
        mainGroup.children.insert(group, at: 0)
        
        // Find targets
        let targets = config.targets.compactMap { findTarget(name: $0) }
        
        if targets.isEmpty {
            print("  ⚠️  No targets found for: \(config.targets.joined(separator: ", "))")
            return
        }
        
        // Add each file
        for filePath in files {
            let fileName = filePath.lastComponent
            
            // Create file reference
            let fileRef = PBXFileReference(
                sourceTree: .group,
                name: fileName,
                path: fileName
            )
            pbxproj.add(object: fileRef)
            group.children.append(fileRef)
            
            // Add to each target's resources phase
            var addedToTargets: [String] = []
            
            for target in targets {
                // Get or create resources build phase
                guard let resourcesPhase = target.buildPhases.first(where: { $0 is PBXResourcesBuildPhase }) as? PBXResourcesBuildPhase else {
                    continue
                }
                
                // Create build file
                let buildFile = PBXBuildFile(file: fileRef)
                pbxproj.add(object: buildFile)
                
                // Add to resources phase
                if resourcesPhase.files == nil {
                    resourcesPhase.files = []
                }
                resourcesPhase.files?.append(buildFile)
                
                addedToTargets.append(target.name)
            }
            
            if !addedToTargets.isEmpty {
                print("    ✓ \(fileName) → \(addedToTargets.joined(separator: ", "))")
            }
        }
    }
    
    /// Save the project
    func save() throws {
        print("\nSaving project...")
        try project.write(path: projectPath)
        print("✅ Project saved successfully")
    }
    
    /// Create backup
    func backup() throws {
        let pbxprojPath = projectPath + "project.pbxproj"
        let backupPath = pbxprojPath.parent() + "project.pbxproj.backup"
        
        // Remove old backup if exists
        if FileManager.default.fileExists(atPath: backupPath.string) {
            try FileManager.default.removeItem(at: backupPath.url)
        }
        
        try FileManager.default.copyItem(
            at: pbxprojPath.url,
            to: backupPath.url
        )
        
        print("📦 Backup created: \(backupPath)")
    }
}

// ============================================================================
// MAIN EXECUTION
// ============================================================================

func main() {
    print(String(repeating: "=", count: 80))
    print("Xcode Group Manager (Swift + XcodeProj)")
    print(String(repeating: "=", count: 80))
    print()
    
    do {
        // Check if project exists
        guard PROJECT_PATH.exists else {
            print("❌ Project not found: \(PROJECT_PATH)")
            exit(1)
        }
        
        // Create manager
        let manager = try XcodeProjectManager(projectPath: PROJECT_PATH)
        
        // Create backup
        try manager.backup()
        print()
        
        // Process each group
        for groupConfig in GROUPS {
            manager.cleanupGroup(groupConfig)
            manager.populateGroup(groupConfig)
        }
        
        // Save project
        print()
        try manager.save()
        
        print()
        print(String(repeating: "=", count: 80))
        print("✅ Complete!")
        print(String(repeating: "=", count: 80))
        
    } catch {
        print()
        print("❌ Error: \(error.localizedDescription)")
        print(error)
        exit(1)
    }
}

// Run main
main()
