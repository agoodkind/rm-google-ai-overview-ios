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
            AddBuildScript.self
        ],
        defaultSubcommand: ShowVersion.self
    )
}
