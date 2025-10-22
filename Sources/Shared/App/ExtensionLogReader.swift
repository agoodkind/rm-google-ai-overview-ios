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
    let context: String
    let file: String?
    let line: Int?
    
    /// Parse log entry from storage format
    /// - Parameter dict: Dictionary from UserDefaults
    /// - Returns: Parsed log entry, or nil if invalid
    static func from(_ dict: [String: Any]) -> ExtensionLogEntry? {
        guard let timestampString = dict["timestamp"] as? String,
              let level = dict["level"] as? String,
              let message = dict["message"] as? String else {
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
    
    /// Read logs from shared UserDefaults
    func refreshLogs() {
        guard let defaults = UserDefaults(suiteName: APP_GROUP_ID) else {
            logWarning("Failed to access app group", category: logCategory)
            return
        }
        
        guard let logData = defaults.array(forKey: "extension-logs") as? [[String: Any]] else {
            logs = []
            return
        }
        
        logs = logData.compactMap { ExtensionLogEntry.from($0) }
        logDebug("Loaded \(logs.count) extension logs", category: logCategory)
    }
    
    /// Format logs for feedback report
    /// - Returns: Formatted log text
    func formatLogsForReport() -> String {
        guard !logs.isEmpty else {
            return "No extension logs available"
        }
        
        var report = ""
        for log in logs.prefix(30) {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .medium
            let timeStr = formatter.string(from: log.timestamp)
            
            let contextStr = log.context.isEmpty ? "" : " [\(log.context)]"
            let locationStr = log.file != nil ? " (\(log.file!):\(log.line ?? 0))" : ""
            report += "\(timeStr) [\(log.level.uppercased())]\(contextStr)\(locationStr) \(log.message)\n"
        }
        return report
    }
}

