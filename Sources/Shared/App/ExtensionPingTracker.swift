//
//  ExtensionPingTracker.swift
//  Skip AI
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  EXTENSION PING TRACKER - Tracks last ping from background and content scripts

import Foundation
import Combine

struct ExtensionPing {
    var source: String
    var timestamp: Date
    var tabId: Int?
    
    static func from(_ dict: [String: Any]) -> ExtensionPing? {
        guard let source = dict["source"] as? String,
              let timestampString = dict["timestamp"] as? String else {
            return nil
        }
        
        let formatter = ISO8601DateFormatter()
        guard let timestamp = formatter.date(from: timestampString) else {
            return nil
        }
        
        let tabId = dict["tabId"] as? Int
        
        return ExtensionPing(
            source: source,
            timestamp: timestamp,
            tabId: tabId
        )
    }
}

class ExtensionPingTracker: ObservableObject {
    @Published var backgroundPing: ExtensionPing?
    @Published var contentPing: ExtensionPing?
    private let logCategory = "ExtensionPingTracker"
    
    func refreshPings() {
        guard let defaults = UserDefaults(suiteName: APP_GROUP_ID) else {
            return
        }
        
        if let bgData = defaults.dictionary(forKey: "extension-ping-background") {
            backgroundPing = ExtensionPing.from(bgData)
        }
        
        if let contentData = defaults.dictionary(forKey: "extension-ping-content") {
            contentPing = ExtensionPing.from(contentData)
        }
    }
}

