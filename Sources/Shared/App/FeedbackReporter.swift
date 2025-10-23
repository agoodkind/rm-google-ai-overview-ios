//
//  FeedbackReporter.swift
//  Skip AI
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  FEEDBACK REPORTER - Collects app state for bug reports and feedback

import Foundation
import SwiftUI

/// Generates formatted feedback report with app state and diagnostics
struct FeedbackReporter {
    let viewModel: AppViewModel
    
    /// Generate exported storage as JSON file URL
    /// - Returns: URL to temporary JSON file with app storage data
    func generateStorageExport() -> URL? {
        guard let defaults = UserDefaults(suiteName: APP_GROUP_ID) else {
            return nil
        }
        
        // Define app-specific keys to export
        let keysToExport = [
            "extension-logs",
            "extension-stats",
            "extension-ping-background",
            "extension-ping-content",
            "extension-last-active",
            "handler-debug",
            DISPLAY_MODE_KEY
        ]
        
        // Create export data structure
        var exportData: [String: Any] = [:]
        exportData["exportDate"] = ISO8601DateFormatter().string(from: Date())
        exportData["appGroupId"] = APP_GROUP_ID
        
        // Add app-specific storage data, converting non-JSON-serializable types
        for key in keysToExport {
            if let value = defaults.object(forKey: key) {
                exportData[key] = convertToJSONSerializable(value)
            }
        }
        
        // Convert to JSON
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: [.prettyPrinted, .sortedKeys])
            
            // Create filename with timestamp
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let timestamp = formatter.string(from: Date())
            let filename = "skip-ai-storage_\(timestamp).json"
            
            // Save to temporary directory
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent(filename)
            try jsonData.write(to: fileURL)
            
            return fileURL
        } catch {
            print("❌ Failed to generate storage export: \(error)")
            return nil
        }
    }
    
    /// Convert non-JSON-serializable types to serializable equivalents
    private func convertToJSONSerializable(_ value: Any) -> Any {
        if let data = value as? Data {
            return ["__type": "Data", "__base64": data.base64EncodedString()]
        } else if let date = value as? Date {
            return ["__type": "Date", "__iso8601": ISO8601DateFormatter().string(from: date)]
        } else if let array = value as? [Any] {
            return array.map { convertToJSONSerializable($0) }
        } else if let dict = value as? [String: Any] {
            return dict.mapValues { convertToJSONSerializable($0) }
        } else {
            return value
        }
    }
    
    /// Generate complete feedback report
    /// - Returns: Formatted report text
    func generateReport() -> String {
        var report = """
        Skip AI - Feedback Report
        Generated: \(formatDateTime(Date()))
        
        """
        
        report += section("SYSTEM INFO", content: systemInfo())
        report += section("APP STATE", content: appState())
        report += section("EXTENSION", content: extensionInfo())
        report += section("SESSION", content: sessionInfo())
        report += section("EVENT LOG", content: eventLog())
        report += section("EXTENSION LOGS", content: extensionLogs())
        
        return report
    }
    
    private func systemInfo() -> String {
        """
        Platform: \(viewModel.platform.kind)
        iOS/macOS Version: \(getOSVersion())
        App Version: \(getAppVersion())
        Build: \(getBuildNumber())
        """
    }
    
    private func appState() -> String {
        """
        Display Mode: \(viewModel.displayMode.rawValue)
        Scene Phase: \(getScenePhase())
        Show Modal: \(viewModel.showEnableExtensionModal)
        """
    }
    
    private func extensionInfo() -> String {
        """
        State: \(viewModel.extensionEnabled)
        Message: \(viewModel.stateMessage)
        """
    }
    
    private func sessionInfo() -> String {
        var info = """
        Cold Launch: \(viewModel.isColdLaunch)
        First Launch Ever: \(viewModel.isFirstLaunchEver)
        Launch Count: \(viewModel.launchCount + 1)
        Session Start: \(formatDateTime(viewModel.currentSessionStartDate))
        Activations: \(viewModel.activationCount)
        Last Active: \(formatDateTime(viewModel.lastActiveDate))
        """
        
        if let lastInactive = viewModel.lastInactiveDate {
            info += "\nLast Inactive: \(formatDateTime(lastInactive))"
        }
        
        if let lastLaunch = viewModel.lastLaunchDate {
            info += "\nLast Launch: \(formatDateTime(lastLaunch))"
        }
        
        return info
    }
    
    private func eventLog() -> String {
        guard !viewModel.debugEventLog.isEmpty else {
            return "No events recorded"
        }
        
        var log = ""
        for event in viewModel.debugEventLog.prefix(20) {
            let typeIcon = eventTypeIcon(event.type)
            log += "\(formatDateTime(event.timestamp)) \(typeIcon) \(event.message)\n"
        }
        return log
    }
    
    private func extensionLogs() -> String {
        viewModel.extensionLogReader.formatLogsForReport()
    }
    
    private func eventTypeIcon(_ type: DebugEvent.EventType) -> String {
        switch type {
        case .activation:
            return "▲"
        case .deactivation:
            return "▼"
        case .extensionState:
            return "◆"
        case .displayMode:
            return "●"
        case .launch:
            return "★"
        }
    }
    
    private func section(_ title: String, content: String) -> String {
        """
        
        ═══════════════════════════════════════
        \(title)
        ═══════════════════════════════════════
        \(content)
        
        """
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    private func getOSVersion() -> String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }
    
    private func getAppVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    private func getBuildNumber() -> String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    private func getScenePhase() -> String {
        // This would need to be passed in or accessed differently
        "N/A"
    }
}

