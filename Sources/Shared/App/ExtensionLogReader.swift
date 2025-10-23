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

/// Log entry from Safari extension
struct ExtensionLogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let level: String
    let message: String
    let source: String
    let context: String
    let file: String?
    let line: Int?
    
    /// Parse log entry from storage format
    /// - Parameter dict: Dictionary from UserDefaults
    /// - Returns: Parsed log entry, or nil if invalid
    static func from(_ dict: [String: Any]) -> ExtensionLogEntry? {
        let timestampString = dict["timestamp"] as? String ?? ""
        let level = dict["level"] as? String ?? "unknown"
        let message = dict["message"] as? String ?? "no message"
        let source = dict["source"] as? String ?? "unknown"
        
        // Configure ISO8601 formatter with fractional seconds support
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var timestamp = formatter.date(from: timestampString)
        
        // Only use current time if timestamp string was empty
        if timestamp == nil {
            timestamp = timestampString.isEmpty ? Date() : Date(timeIntervalSince1970: 0)
        }
        
        let context = dict["context"] as? String ?? ""
        let file = dict["file"] as? String
        let line = dict["line"] as? Int
        
        return ExtensionLogEntry(
            timestamp: timestamp!,
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
                lastLogCount = 0
            }
            return
        }
        
        logs = logData.compactMap { ExtensionLogEntry.from($0) }
        
        // Only log when count changes
        if logs.count != lastLogCount {
            let message = "Loaded \(logs.count) extension logs"
            logInfo(message, category: logCategory)
            
            // Print to console for visibility
            if !logs.isEmpty {
                print("📊 Extension Logs: \(logs.count) total")
                
                // Print most recent log
                if let recent = logs.first {
                    print("  └─ Most recent: [\(recent.source):\(recent.level)] \(recent.message)")
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
        
        var report = "=== EXTENSION LOGS ===\n"
        for log in logs.prefix(50) {
            report += formatLogEntry(log)
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
