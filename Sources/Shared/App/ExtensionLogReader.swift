//
//  ExtensionLogReader.swift
//  Skip AI
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  EXTENSION LOG READER - Reads logs from Safari extension

import Foundation
import SwiftUI
import Combine

/// Log source type
enum LogSource: String {
    case background = "background"
    case content = "content"
}

/// Log entry from Safari extension
struct ExtensionLogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let level: String
    let message: String
    let source: LogSource
    let context: String
    let file: String?
    let line: Int?
    
    /// Parse log entry from storage format
    /// - Parameter dict: Dictionary from UserDefaults
    /// - Returns: Parsed log entry, or nil if invalid
    static func from(_ dict: [String: Any]) -> ExtensionLogEntry? {
        guard let timestampString = dict["timestamp"] as? String,
              let level = dict["level"] as? String,
              let message = dict["message"] as? String,
              let sourceString = dict["source"] as? String,
              let source = LogSource(rawValue: sourceString) else {
            return nil
        }
        
        let formatter = ISO8601DateFormatter()
        guard let timestamp = formatter.date(from: timestampString) else {
            return nil
        }
        
        let context = dict["context"] as? String ?? ""
        let file = dict["file"] as? String
        let line = dict["line"] as? Int
        
        return ExtensionLogEntry(
            timestamp: timestamp,
            level: level,
            message: message,
            source: source,
            context: context,
            file: file,
            line: line
        )
    }
}

/// Reads extension logs from shared storage
class ExtensionLogReader: ObservableObject {
    @Published var logs: [ExtensionLogEntry] = []
    @Published var backgroundLogs: [ExtensionLogEntry] = []
    @Published var contentLogs: [ExtensionLogEntry] = []
    private let logCategory = "ExtensionLogReader"
    private var lastLogCount: Int = 0
    
    /// Read logs from shared UserDefaults
    func refreshLogs() {
        guard let defaults = UserDefaults(suiteName: APP_GROUP_ID) else {
            logWarning("Failed to access app group", category: logCategory)
            return
        }
        
        guard let logData = defaults.array(forKey: "extension-logs") as? [[String: Any]] else {
            if lastLogCount != 0 {
                logDebug("No extension logs in storage", category: logCategory)
                logs = []
                backgroundLogs = []
                contentLogs = []
                lastLogCount = 0
            }
            return
        }
        
        let parsedLogs = logData.compactMap { ExtensionLogEntry.from($0) }
        let failedCount = logData.count - parsedLogs.count
        
        logs = parsedLogs
        backgroundLogs = logs.filter { $0.source == .background }
        contentLogs = logs.filter { $0.source == .content }
        
        // Only log when count changes
        if logs.count != lastLogCount {
            let message = "Loaded \(logs.count) extension logs (\(backgroundLogs.count) background, \(contentLogs.count) content), failed to parse: \(failedCount)"
            logInfo(message, category: logCategory)
            
            // Also print to console for visibility
            if backgroundLogs.count > 0 || contentLogs.count > 0 {
                print("📊 Extension Logs: \(backgroundLogs.count) background, \(contentLogs.count) content")
                
                // Print most recent log from each source
                if let recentBackground = backgroundLogs.first {
                    print("  └─ Background: [\(recentBackground.level)] \(recentBackground.message)")
                }
                if let recentContent = contentLogs.first {
                    print("  └─ Content: [\(recentContent.level)] \(recentContent.message)")
                }
            }
            
            lastLogCount = logs.count
        }
    }
    
    /// Format logs for feedback report
    /// - Returns: Formatted log text
    func formatLogsForReport() -> String {
        guard !logs.isEmpty else {
            return "No extension logs available"
        }
        
        var report = ""
        
        // Background logs section
        if !backgroundLogs.isEmpty {
            report += "=== BACKGROUND LOGS ===\n"
            for log in backgroundLogs.prefix(20) {
                report += formatLogEntry(log)
            }
            report += "\n"
        }
        
        // Content script logs section
        if !contentLogs.isEmpty {
            report += "=== CONTENT SCRIPT LOGS ===\n"
            for log in contentLogs.prefix(20) {
                report += formatLogEntry(log)
            }
        }
        
        return report
    }
    
    /// Format a single log entry
    /// - Parameter log: The log entry to format
    /// - Returns: Formatted log string
    private func formatLogEntry(_ log: ExtensionLogEntry) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        let timeStr = formatter.string(from: log.timestamp)
        
        let contextStr = log.context.isEmpty ? "" : " [\(log.context)]"
        let locationStr = log.file != nil ? " (\(log.file!):\(log.line ?? 0))" : ""
        return "\(timeStr) [\(log.level.uppercased())]\(contextStr)\(locationStr) \(log.message)\n"
    }
}

