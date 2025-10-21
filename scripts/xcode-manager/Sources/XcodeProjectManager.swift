// XcodeProjectManager.swift
// Xcode Manager
//
// Handles Xcode project manipulation using XcodeProj library

import Foundation
import XcodeProj
import PathKit

class XcodeProjectManager {
    let project: XcodeProj
    let pbxproj: PBXProj
    let projectPath: Path
    
    init(projectPath: Path) throws {
        self.projectPath = projectPath
        self.project = try XcodeProj(path: projectPath)
        self.pbxproj = project.pbxproj
    }
    
    // Version Management
    
    func getMarketingVersion() throws -> String {
        guard let target = pbxproj.nativeTargets.first,
              let configs = target.buildConfigurationList?.buildConfigurations,
              let config = configs.first,
              let version = config.buildSettings["MARKETING_VERSION"] as? String else {
            throw XcodeManagerError.versionNotFound("MARKETING_VERSION")
        }
        return version
    }
    
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
    
    func setMarketingVersion(_ version: String) throws {
        for target in pbxproj.nativeTargets {
            guard let configs = target.buildConfigurationList?.buildConfigurations else { continue }
            for config in configs {
                config.buildSettings["MARKETING_VERSION"] = version
            }
        }
    }
    
    func setCurrentProjectVersion(_ build: Int) throws {
        for target in pbxproj.nativeTargets {
            guard let configs = target.buildConfigurationList?.buildConfigurations else { continue }
            for config in configs {
                config.buildSettings["CURRENT_PROJECT_VERSION"] = "\(build)"
            }
        }
    }
    
    func setBothVersions(marketing: String, build: Int) throws {
        try setMarketingVersion(marketing)
        try setCurrentProjectVersion(build)
    }
    
    // Group Management
    
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
    
    func findTarget(name: String) -> PBXNativeTarget? {
        return pbxproj.nativeTargets.first { $0.name == name }
    }
    
    func mainGroup() -> PBXGroup? {
        return pbxproj.projects.first?.mainGroup
    }
    
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
    
    func populateGroup(_ config: GroupConfig) {
        print("\nProcessing group: \(config.name) (\(config.path))")
        
        let dirPath = Path(config.path)
        guard dirPath.exists else {
            print("  ⚠️  Directory not found: \(config.path), skipping")
            return
        }
        
        let files = findFiles(in: config.path, patterns: config.filePatterns)
        
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
    
    func save() throws {
        print("\nSaving project...")
        try project.write(path: projectPath)
        print("✅ Project saved successfully")
    }
    
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
    
    // Build Script Management
    
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
        
        // Find the copy files phase (embed extensions)
        guard let copyFilesIndex = target.buildPhases.firstIndex(where: { $0 is PBXCopyFilesBuildPhase }) else {
            print("  ⚠️  No copy files phase found in target")
            return false
        }
        
        // Create shell script build phase
        let scriptPhase = PBXShellScriptBuildPhase(
            name: "Build JavaScript",
            inputFileListPaths: nil,
            outputFileListPaths: ["$(SRCROOT)/scripts/js-outputs.xcfilelist"],
            shellPath: "/bin/bash",
            shellScript: "\"$SRCROOT/scripts/build-js-for-xcode.sh\"\n"
        )
        
        pbxproj.add(object: scriptPhase)
        
        // Insert before copy files phase
        target.buildPhases.insert(scriptPhase, at: copyFilesIndex)
        
        return true
    }
    
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
}

