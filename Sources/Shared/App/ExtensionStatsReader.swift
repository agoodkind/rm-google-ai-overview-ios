//
//  ExtensionStatsReader.swift
//  Skip AI
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  EXTENSION STATS READER - Reads stats from Safari extension

import Foundation
import Combine

/// Stats from content script
struct ExtensionStats {
    var totalHidden: Int
    var totalDupes: Int
    var lastUpdated: Date
    
    static func from(_ dict: [String: Any]) -> ExtensionStats? {
        guard let totalHidden = dict["totalHidden"] as? Int,
              let totalDupes = dict["totalDupes"] as? Int,
              let timestamp = dict["timestamp"] as? String else {
            return nil
        }
        
        let formatter = ISO8601DateFormatter()
        guard let lastUpdated = formatter.date(from: timestamp) else {
            return nil
        }
        
        return ExtensionStats(
            totalHidden: totalHidden,
            totalDupes: totalDupes,
            lastUpdated: lastUpdated
        )
    }
}

/// Reads extension stats from shared storage
class ExtensionStatsReader: ObservableObject {
    @Published var stats: ExtensionStats?
    private let logCategory = "ExtensionStatsReader"
    
    /// Read stats from shared UserDefaults
    func refreshStats() {
        guard let defaults = UserDefaults(suiteName: APP_GROUP_ID) else {
            logWarning("Failed to access app group", category: logCategory)
            return
        }
        
        guard let statsData = defaults.dictionary(forKey: "extension-stats") else {
            stats = nil
            return
        }
        
        stats = ExtensionStats.from(statsData)
    }
}
