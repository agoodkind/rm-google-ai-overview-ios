//
//  XcodeManager.swift
//  Skip AI
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//

import Foundation
import ArgumentParser

@main
struct XcodeManager: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "xcode-manager",
        abstract: "Xcode project management tool for Skip AI",
        version: "2.0.0",
        subcommands: [
            SyncGroups.self,
            BumpVersion.self,
            FixInfoPlist.self,
            ShowVersion.self,
            AddBuildScript.self,
            AddFiles.self,
            CleanMissing.self,
            FixContentBlocker.self,
            RemoveDuplicates.self,
            ListTargets.self,
            ListGroups.self,
        ],
        defaultSubcommand: ShowVersion.self
    )
}
