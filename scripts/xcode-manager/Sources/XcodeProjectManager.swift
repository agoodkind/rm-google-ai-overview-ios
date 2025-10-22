//
//  XcodeProjectManager.swift
//  Skip AI
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  Handles Xcode project manipulation using XcodeProj library

import Foundation
import XcodeProj
import PathKit

/// Manages Xcode project file manipulation
///
/// Provides methods for:
/// - Version management (MARKETING_VERSION, CURRENT_PROJECT_VERSION)
/// - Group and file management
/// - Build script configuration
/// - Project file cleanup and validation
class XcodeProjectManager {
    /// The loaded Xcode project
    let project: XcodeProj
    /// The project's PBX representation
    let pbxproj: PBXProj
    /// Path to the .xcodeproj directory
    let projectPath: Path
    
    /// Initialize with project path
    /// - Parameter projectPath: Path to .xcodeproj directory
    /// - Throws: Error if project cannot be loaded
    init(projectPath: Path) throws {
        self.projectPath = projectPath
        self.project = try XcodeProj(path: projectPath)
        self.pbxproj = project.pbxproj
    }
    
    // MARK: - Version Management
    
    /// Get the marketing version (user-facing version string)
    /// - Returns: Marketing version string (e.g. "1.0.0")
    /// - Throws: `XcodeManagerError.versionNotFound` if not set
    func getMarketingVersion() throws -> String {
        guard let target = pbxproj.nativeTargets.first,
              let configs = target.buildConfigurationList?.buildConfigurations,
              let config = configs.first,
              let version = config.buildSettings["MARKETING_VERSION"] as? String else {
            throw XcodeManagerError.versionNotFound("MARKETING_VERSION")
        }
        return version
    }
    
    /// Get the current project version (build number)
    /// - Returns: Build number as integer
    /// - Throws: `XcodeManagerError.versionNotFound` if not set
    func getCurrentProjectVersion() throws -> Int {
        guard let target = pbxproj.nativeTargets.first,
              let configs = target.buildConfigurationList?.buildConfigurations,
              let config = configs.first,
              let versionString = config.buildSettings["CURRENT_PROJECT_VERSION"] as? String,
              let version = Int(versionString) else {
            throw XcodeManagerError.versionNotFound("CURRENT_PROJECT_VERSION")
        }
        return version
    }
    
    /// Set the marketing version for all targets
    /// - Parameter version: Marketing version string (e.g. "1.0.0")
    /// - Throws: Error if update fails
    func setMarketingVersion(_ version: String) throws {
        for target in pbxproj.nativeTargets {
            guard let configs = target.buildConfigurationList?.buildConfigurations else { continue }
            for config in configs {
                config.buildSettings["MARKETING_VERSION"] = version
            }
        }
    }
    
    /// Set the current project version (build number) for all targets
    /// - Parameter build: Build number as integer
    /// - Throws: Error if update fails
    func setCurrentProjectVersion(_ build: Int) throws {
        for target in pbxproj.nativeTargets {
            guard let configs = target.buildConfigurationList?.buildConfigurations else { continue }
            for config in configs {
                config.buildSettings["CURRENT_PROJECT_VERSION"] = "\(build)"
            }
        }
    }
    
    /// Set both marketing version and build number
    /// - Parameters:
    ///   - marketing: Marketing version string
    ///   - build: Build number
    /// - Throws: Error if update fails
    func setBothVersions(marketing: String, build: Int) throws {
        try setMarketingVersion(marketing)
        try setCurrentProjectVersion(build)
    }
    
    // MARK: - Group Management
    
    /// Find files in directory matching extension patterns
    /// - Parameters:
    ///   - directory: Directory path to search
    ///   - patterns: File extensions to match (e.g. ["swift", "js"])
    /// - Returns: Array of file paths, sorted by name
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
    /// - Parameter name: Target name (e.g. "Skip AI (iOS)")
    /// - Returns: Target if found, nil otherwise
    func findTarget(name: String) -> PBXNativeTarget? {
        return pbxproj.nativeTargets.first { $0.name == name }
    }
    
    /// Get the project's main group
    /// - Returns: Main group if found
    func mainGroup() -> PBXGroup? {
        return pbxproj.projects.first?.mainGroup
    }
    
    /// Remove existing group and all its file references
    /// - Parameter config: Group configuration
    func cleanupGroup(_ config: GroupConfig) {
        print("Cleaning up group: \(config.name)")
        
        guard let mainGroup = mainGroup() else {
            print("  ⚠️  Main group not found")
            return
        }
        
        if let existingGroup = mainGroup.children.compactMap({ $0 as? PBXGroup }).first(where: { $0.name == config.name }) {
            let fileRefs = existingGroup.children.compactMap { $0 as? PBXFileReference }
            
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
            
            for fileRef in fileRefs {
                pbxproj.delete(object: fileRef)
            }
            
            mainGroup.children.removeAll { $0 == existingGroup }
            pbxproj.delete(object: existingGroup)
            
            print("  ✓ Removed existing group")
        }
    }
    
    /// Create group and add files to specified targets
    /// - Parameter config: Group configuration with files and targets
    func populateGroup(_ config: GroupConfig) {
        print("\nProcessing group: \(config.name) (\(config.path))")
        
        // Resolve path relative to project root
        let projectRoot = projectPath.parent()
        let absolutePath = Path(config.path).isAbsolute ? Path(config.path) : projectRoot + config.path
        
        guard absolutePath.exists else {
            print("  ⚠️  Directory not found: \(config.path), skipping")
            return
        }
        
        let files = findFiles(in: absolutePath.string, patterns: config.filePatterns)
        
        guard !files.isEmpty else {
            print("  ℹ️  No files found in \(config.path)")
            return
        }
        
        print("  Found \(files.count) file(s)")
        
        guard let mainGroup = mainGroup() else {
            print("  ⚠️  Main group not found")
            return
        }
        
        let group = PBXGroup(
            children: [],
            sourceTree: .group,
            name: config.name,
            path: config.path
        )
        pbxproj.add(object: group)
        mainGroup.children.insert(group, at: 0)
        
        let targets = config.targets.compactMap { findTarget(name: $0) }
        
        if targets.isEmpty {
            print("  ⚠️  No targets found for: \(config.targets.joined(separator: ", "))")
            return
        }
        
        for filePath in files {
            let fileName = filePath.lastComponent
            
            let fileRef = PBXFileReference(
                sourceTree: .group,
                name: fileName,
                path: fileName
            )
            pbxproj.add(object: fileRef)
            group.children.append(fileRef)
            
            var addedToTargets: [String] = []
            
            for target in targets {
                guard let resourcesPhase = target.buildPhases.first(where: { $0 is PBXResourcesBuildPhase }) as? PBXResourcesBuildPhase else {
                    continue
                }
                
                let buildFile = PBXBuildFile(file: fileRef)
                pbxproj.add(object: buildFile)
                
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
    
    /// Save project changes to disk
    /// - Throws: Error if write fails
    func save() throws {
        print("\nSaving project...")
        try project.write(path: projectPath)
        print("✅ Project saved successfully")
    }
    
    /// Create backup of project.pbxproj file
    /// - Throws: Error if backup fails
    func backup() throws {
        let pbxprojPath = projectPath + "project.pbxproj"
        let backupPath = pbxprojPath.parent() + "project.pbxproj.backup"
        
        if FileManager.default.fileExists(atPath: backupPath.string) {
            try FileManager.default.removeItem(at: backupPath.url)
        }
        
        try FileManager.default.copyItem(
            at: pbxprojPath.url,
            to: backupPath.url
        )
        
        print("📦 Backup created: \(backupPath)")
    }
    
    // MARK: - Build Script Management
    
    /// Add JavaScript build script to target
    /// - Parameter target: Target to add script to
    /// - Returns: True if added, false if already exists
    /// - Throws: Error if addition fails
    func addBuildScript(to target: PBXNativeTarget) throws -> Bool {
        // Check if script already exists
        if target.buildPhases.contains(where: { phase in
            if let scriptPhase = phase as? PBXShellScriptBuildPhase {
                return scriptPhase.name == "Build JavaScript"
            }
            return false
        }) {
            return false
        }
        
        // Create shell script build phase
        let scriptPhase = PBXShellScriptBuildPhase(
            name: "Build JavaScript",
            inputPaths: ["$(SRCROOT)/scripts/build-js-for-xcode.sh"],
            inputFileListPaths: nil,
            outputFileListPaths: ["$(SRCROOT)/scripts/js-outputs.xcfilelist"],
            shellPath: "/bin/bash",
            shellScript: "\"$SRCROOT/scripts/build-js-for-xcode.sh\"\n"
        )
        
        pbxproj.add(object: scriptPhase)
        
        // Insert before resources phase (or at the end if not found)
        if let resourcesIndex = target.buildPhases.firstIndex(where: { $0 is PBXResourcesBuildPhase }) {
            target.buildPhases.insert(scriptPhase, at: resourcesIndex)
        } else {
            target.buildPhases.append(scriptPhase)
        }
        
        return true
    }
    
    /// Remove build script from target
    /// - Parameters:
    ///   - target: Target to remove script from
    ///   - named: Name of script phase
    /// - Returns: True if removed, false if not found
    /// - Throws: Error if removal fails
    func removeBuildScript(from target: PBXNativeTarget, named: String) throws -> Bool {
        guard let scriptPhase = target.buildPhases.first(where: { phase in
            if let script = phase as? PBXShellScriptBuildPhase {
                return script.name == named
            }
            return false
        }) else {
            return false
        }
        
        target.buildPhases.removeAll { $0 == scriptPhase }
        pbxproj.delete(object: scriptPhase)
        
        return true
    }
    
    // MARK: - File Management
    
    /// Find or create group at path
    /// - Parameters:
    ///   - path: Group path (e.g. "Sources/Shared/App")
    ///   - parentGroup: Parent group, defaults to main group
    /// - Returns: Found or created group
    func findOrCreateGroup(at path: String, in parentGroup: PBXGroup? = nil) -> PBXGroup {
        let parent = parentGroup ?? mainGroup()!
        let components = path.split(separator: "/")
        
        var currentGroup = parent
        for component in components {
            let name = String(component)
            if let existing = currentGroup.children.compactMap({ $0 as? PBXGroup }).first(where: { $0.name == name || $0.path == name }) {
                currentGroup = existing
            } else {
                let newGroup = PBXGroup(children: [], sourceTree: .group, name: name, path: name)
                pbxproj.add(object: newGroup)
                currentGroup.children.append(newGroup)
                currentGroup = newGroup
            }
        }
        
        return currentGroup
    }
    
    /// Add source file to targets
    /// - Parameters:
    ///   - filePath: Path to source file
    ///   - targets: Targets to add file to
    ///   - groupPath: Group path in project
    /// - Returns: True if added, false if already exists
    func addSourceFile(filePath: Path, to targets: [PBXNativeTarget], in groupPath: String) -> Bool {
        let group = findOrCreateGroup(at: groupPath)
        let fileName = filePath.lastComponent
        
        // Check if file already exists in group, if so use existing reference
        let fileRef: PBXFileReference
        if let existing = group.children.compactMap({ $0 as? PBXFileReference }).first(where: { $0.name == fileName || $0.path == fileName }) {
            fileRef = existing
        } else {
            // Create new file reference
            let relativePath = fileName
            fileRef = PBXFileReference(
                sourceTree: .group,
                name: fileName,
                path: relativePath
            )
            pbxproj.add(object: fileRef)
            group.children.append(fileRef)
        }
        
        var added = false
        for target in targets {
            guard let sourcesPhase = target.buildPhases.first(where: { $0 is PBXSourcesBuildPhase }) as? PBXSourcesBuildPhase else {
                continue
            }
            
            // Check if file is already in build phase
            let alreadyInPhase = sourcesPhase.files?.contains(where: { buildFile in
                buildFile.file?.uuid == fileRef.uuid
            }) ?? false
            
            if alreadyInPhase {
                continue // Skip - already in this target's build phase
            }
            
            let buildFile = PBXBuildFile(file: fileRef)
            pbxproj.add(object: buildFile)
            
            if sourcesPhase.files == nil {
                sourcesPhase.files = []
            }
            sourcesPhase.files?.append(buildFile)
            added = true
        }
        
        return added
    }
    
    /// Remove file reference from group and all build phases
    /// - Parameters:
    ///   - fileName: Name of file to remove
    ///   - group: Group containing the file
    /// - Returns: True if removed, false if not found
    func removeFileReference(named fileName: String, from group: PBXGroup) -> Bool {
        guard let fileRef = group.children.compactMap({ $0 as? PBXFileReference }).first(where: { $0.name == fileName || $0.path == fileName }) else {
            return false
        }
        
        // Remove from all build phases
        for target in pbxproj.nativeTargets {
            for phase in target.buildPhases {
                if let sourcesPhase = phase as? PBXSourcesBuildPhase {
                    let filesToRemove = sourcesPhase.files?.filter { $0.file?.uuid == fileRef.uuid } ?? []
                    for file in filesToRemove {
                        sourcesPhase.files?.removeAll { $0 == file }
                        pbxproj.delete(object: file)
                    }
                }
                if let resourcesPhase = phase as? PBXResourcesBuildPhase {
                    let filesToRemove = resourcesPhase.files?.filter { $0.file?.uuid == fileRef.uuid } ?? []
                    for file in filesToRemove {
                        resourcesPhase.files?.removeAll { $0 == file }
                        pbxproj.delete(object: file)
                    }
                }
            }
        }
        
        // Remove from group
        group.children.removeAll { $0 == fileRef }
        pbxproj.delete(object: fileRef)
        
        return true
    }
    
    /// Remove file references that no longer exist on disk
    /// - Parameter groupPath: Group path to clean
    /// - Returns: Array of removed file names
    func cleanMissingReferences(in groupPath: String) -> [String] {
        let group = findOrCreateGroup(at: groupPath)
        var removedFiles: [String] = []
        
        let fileRefs = group.children.compactMap { $0 as? PBXFileReference }
        let projectRoot = projectPath.parent()
        
        for fileRef in fileRefs {
            let fileName = fileRef.name ?? fileRef.path ?? ""
            let filePath = projectRoot + groupPath + fileName
            
            if !filePath.exists {
                if removeFileReference(named: fileName, from: group) {
                    removedFiles.append(fileName)
                }
            }
        }
        
        return removedFiles
    }
    
    /// Fix ContentBlocker target Info.plist settings
    /// - Returns: True if changes made, false otherwise
    func fixContentBlockerSettings() -> Bool {
        guard let target = findTarget(name: "ContentBlocker") else {
            return false
        }
        
        var changed = false
        if let configs = target.buildConfigurationList?.buildConfigurations {
            for config in configs {
                // If INFOPLIST_FILE is set, GENERATE_INFOPLIST_FILE should be NO
                if config.buildSettings["INFOPLIST_FILE"] != nil {
                    if config.buildSettings["GENERATE_INFOPLIST_FILE"] as? String != "NO" {
                        config.buildSettings["GENERATE_INFOPLIST_FILE"] = "NO"
                        changed = true
                    }
                }
            }
        }
        
        return changed
    }
    
    /// Remove duplicate file references from build phases
    /// - Returns: Number of duplicates removed
    func removeDuplicateFiles() -> Int {
        var removedCount = 0
        
        for target in pbxproj.nativeTargets {
            print("\nChecking target: \(target.name)")
            for phase in target.buildPhases {
                if let sourcesPhase = phase as? PBXSourcesBuildPhase {
                    let removed = removeDuplicatesFromPhase(sourcesPhase, targetName: target.name)
                    if removed > 0 {
                        print("  Removed \(removed) duplicate(s) from Sources phase")
                    }
                    removedCount += removed
                }
                if let resourcesPhase = phase as? PBXResourcesBuildPhase {
                    let removed = removeDuplicatesFromPhase(resourcesPhase, targetName: target.name)
                    if removed > 0 {
                        print("  Removed \(removed) duplicate(s) from Resources phase")
                    }
                    removedCount += removed
                }
            }
        }
        
        return removedCount
    }
    
    /// Remove duplicates from a build phase
    private func removeDuplicatesFromPhase<T: PBXBuildPhase>(_ phase: T, targetName: String) -> Int {
        guard let files = phase.files else { return 0 }
        
        print("  Phase has \(files.count) file(s)")
        
        var seenFileRefs = Set<String>()
        var keptIndices = Set<Int>()
        var removedCount = 0
        
        // First pass: identify which entries to keep
        for (index, buildFile) in files.enumerated() {
            guard let fileRef = buildFile.file else {
                keptIndices.insert(index)
                continue
            }
            
            // Use file reference UUID as identifier
            let uuid = fileRef.uuid
            
            if seenFileRefs.contains(uuid) {
                // Duplicate found
                let fileName = (fileRef as? PBXFileReference)?.name 
                    ?? (fileRef as? PBXFileReference)?.path 
                    ?? "unknown"
                print("    Removing duplicate: \(fileName)")
                removedCount += 1
            } else {
                seenFileRefs.insert(uuid)
                keptIndices.insert(index)
            }
        }
        
        // Second pass: remove duplicates
        if removedCount > 0 {
            let filesToKeep = files.enumerated()
                .filter { keptIndices.contains($0.offset) }
                .map { $0.element }
            
            let filesToRemove = files.enumerated()
                .filter { !keptIndices.contains($0.offset) }
                .map { $0.element }
            
            // Delete removed build files from project
            for buildFile in filesToRemove {
                pbxproj.delete(object: buildFile)
            }
            
            // Update phase files array
            phase.files = filesToKeep
        }
        
        return removedCount
    }
}
