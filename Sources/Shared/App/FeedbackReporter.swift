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

