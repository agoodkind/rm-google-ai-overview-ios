//
//  SafariWebExtensionHandler.swift
//  Skip AI
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  NATIVE MESSAGING HANDLER - Communication between app and extension
//
//  This class handles messages sent from the JavaScript background script to the native app.
//  Called via browser.runtime.sendNativeMessage() from the extension.
//
//  Message types handled:
//  - "ping": Extension state check (responds with "pong")
//  - "getDisplayMode": Returns current display mode preference
//  - "serviceWorkerStarted": Writes timestamp to shared storage (iOS) or responds (macOS)
//
//  Extension-to-app communication:
//  - macOS: App can also initiate via SFSafariApplication.dispatchMessage()
//  - iOS: Only extension→app messaging; app reads shared storage for state
//
//  Created by Alex Goodkind on 10/7/25.
//

import os.log
import SafariServices

let APP_GROUP_ID = "group.io.goodkind.skip-ai"
let DISPLAY_MODE_KEY = "skip-ai-display-mode"
#if DEBUG
    let DEFAULT_DISPLAY_MODE = "highlight"
#else
    let DEFAULT_DISPLAY_MODE = "hide"
#endif

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    private let logCategory = "SafariExtension"
    
    override init() {
        super.init()
        logDebug("SafariWebExtensionHandler initialized", category: logCategory)
    }
    
    func beginRequest(with context: NSExtensionContext) {
        logDebug("beginRequest start", category: logCategory)
        
        let request = context.inputItems.first as? NSExtensionItem
        let message = extractMessage(from: request)
        let profile = extractProfile(from: request)

        logInfo("Received message: \(String(describing: message)) (profile: \(profile?.uuidString ?? "none"))", category: logCategory)

        let response = NSExtensionItem()
        
        // Update the last active timestamp in shared storage
        updateLastActiveTimestamp()
        
        if let messageDict = message as? [String: Any],
           let type = messageDict["type"] as? String {
            storeHandlerDebug("Received message: \(type) with data: \(messageDict)")
            
            // Store messages that have log data structure (timestamp, level, message, source)
            if let logData = messageDict["data"] as? [String: Any],
               logData["timestamp"] != nil,
               logData["level"] != nil,
               logData["message"] != nil,
               logData["source"] != nil {
                storeExtensionLog(logData)
            }

            switch type {
            case "ping":
                logInfo("Ping received from app", category: logCategory)
                setResponseData(on: response, data: ["type": "pong"])
                logDebug("Responded with pong", category: logCategory)
                
            case "service_worker_started":
                logInfo("Service worker started notification", category: logCategory)
                setResponseData(on: response, data: ["status": "acknowledged"])
                logDebug("Acknowledged service worker start", category: logCategory)
                
            case "get_display_mode":
                logDebug("Display mode requested", category: logCategory)
                let displayMode = getDisplayMode()
                setResponseData(on: response, data: ["displayMode": displayMode])
                logDebug("Returned display mode: \(displayMode)", category: logCategory)
                
            case "extension_stats":
                logDebug("Extension stats received", category: logCategory)
                
                if let statsData = messageDict["data"] as? [String: Any] {
                    storeExtensionStats(statsData)
                }
                
                setResponseData(on: response, data: ["status": "recorded"])
                
            case "extension_ping":
                logDebug("Extension ping received", category: logCategory)
                
                if let pingData = messageDict["data"] as? [String: Any] {
                    let source = pingData["source"] as? String ?? "unknown"
                    let tabId = pingData["tabId"] as? Int
                    storeExtensionPing(source: source, tabId: tabId)
                }
                
                setResponseData(on: response, data: ["type": "pong"])
                
            default:
                logError("Unknown message type: \(type)", category: logCategory)
            }
        } else {
            // Fallback echo
            logWarning("No valid message type, echoing message", category: logCategory)
            setResponseData(on: response, data: ["echo": message ?? "no message given"])
        }

        logDebug("Completing request", category: logCategory)
        context.completeRequest(returningItems: [response], completionHandler: nil)
    }

    func getDisplayMode() -> String {
        logDebug("Getting display mode from shared storage", category: logCategory)
        let defaults = UserDefaults(suiteName: APP_GROUP_ID)
        let mode = defaults?.string(forKey: DISPLAY_MODE_KEY)
        logInfo("Display mode - stored: \(mode ?? "none"), default: \(DEFAULT_DISPLAY_MODE)", category: logCategory)
        return mode ?? DEFAULT_DISPLAY_MODE
    }
    
    private func updateLastActiveTimestamp() {
        logDebug("Updating last active timestamp in shared storage", category: logCategory)
        let defaults = UserDefaults(suiteName: APP_GROUP_ID)
        defaults?.set(Date(), forKey: "extension-last-active")
        defaults?.synchronize()
        logInfo("Extension last active timestamp updated", category: logCategory)
    }
    
    private func storeExtensionLog(_ logData: [String: Any]) {
        let defaults = UserDefaults(suiteName: APP_GROUP_ID)
        var logs = defaults?.array(forKey: "extension-logs") as? [[String: Any]] ?? []
        
        // Store complete log data as-is
        logs.insert(logData, at: 0)
        
        // Keep last 100 logs
        if logs.count > 100 {
            logs = Array(logs.prefix(100))
        }
        
        defaults?.set(logs, forKey: "extension-logs")
        defaults?.synchronize()
        
        // Log summary for debugging
        let timestamp = logData["timestamp"] as? String ?? "?"
        let level = logData["level"] as? String ?? "?"
        let message = logData["message"] as? String ?? "?"
        let source = logData["source"] as? String ?? "?"
        
        storeHandlerDebug("Stored log #\(logs.count): [\(source):\(level)] \(message)")
        logVerbose("Stored extension log: [\(source):\(level)] \(message)", category: logCategory)
    }
    
    private func storeHandlerDebug(_ message: String) {
        let defaults = UserDefaults(suiteName: APP_GROUP_ID)
        var debugLogs = defaults?.array(forKey: "handler-debug") as? [String] ?? []
        
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        debugLogs.insert("\(timestamp): \(message)", at: 0)
        
        // Keep last 20 debug messages
        if debugLogs.count > 20 {
            debugLogs = Array(debugLogs.prefix(20))
        }
        
        defaults?.set(debugLogs, forKey: "handler-debug")
        defaults?.synchronize()
    }
    
    private func storeExtensionStats(_ statsData: [String: Any]) {
        guard let sessionHidden = statsData["elementsHidden"] as? Int,
              let sessionDupes = statsData["duplicatesFound"] as? Int else {
            logWarning("Invalid stats data format", category: logCategory)
            return
        }
        
        let defaults = UserDefaults(suiteName: APP_GROUP_ID)
        let currentStats = defaults?.dictionary(forKey: "extension-stats") ?? [:]
        
        // Get previous session stats to calculate delta
        let prevSessionHidden = currentStats["lastSessionHidden"] as? Int ?? 0
        let prevSessionDupes = currentStats["lastSessionDupes"] as? Int ?? 0
        
        // Calculate deltas (handles page reloads where counters reset)
        let deltaHidden = sessionHidden >= prevSessionHidden ? (sessionHidden - prevSessionHidden) : sessionHidden
        let deltaDupes = sessionDupes >= prevSessionDupes ? (sessionDupes - prevSessionDupes) : sessionDupes
        
        // Accumulate into totals
        let totalHidden = (currentStats["totalHidden"] as? Int ?? 0) + deltaHidden
        let totalDupes = (currentStats["totalDupes"] as? Int ?? 0) + deltaDupes
        
        let stats: [String: Any] = [
            "lastSessionHidden": sessionHidden,
            "lastSessionDupes": sessionDupes,
            "totalHidden": totalHidden,
            "totalDupes": totalDupes,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        defaults?.set(stats, forKey: "extension-stats")
        defaults?.synchronize()
        
        logInfo("Stats: session(\(sessionHidden)/\(sessionDupes)) delta(+\(deltaHidden)/+\(deltaDupes)) total(\(totalHidden)/\(totalDupes))", category: logCategory)
    }
    
    private func storeExtensionPing(source: String, tabId: Int?) {
        let defaults = UserDefaults(suiteName: APP_GROUP_ID)
        let timestamp = ISO8601DateFormatter().string(from: Date())
        
        if source == "background" {
            let pingData: [String: Any] = [
                "source": "background",
                "timestamp": timestamp
            ]
            defaults?.set(pingData, forKey: "extension-ping-background")
            logInfo("Background script ping recorded", category: logCategory)
        } else if source == "content" {
            var pingData: [String: Any] = [
                "source": "content",
                "timestamp": timestamp
            ]
            if let tabId = tabId {
                pingData["tabId"] = tabId
            }
            defaults?.set(pingData, forKey: "extension-ping-content")
            let tabInfo = tabId != nil ? " (tab: \(tabId!))" : ""
            logInfo("Content script ping recorded\(tabInfo)", category: logCategory)
        }
        
        defaults?.synchronize()
    }
    
    // MARK: - Helper Methods
    
    private func extractProfile(from request: NSExtensionItem?) -> UUID? {
        logVerbose("Extracting profile from request", category: logCategory)
        if #available(iOS 17.0, macOS 14.0, *) {
            return request?.userInfo?[SFExtensionProfileKey] as? UUID
        } else {
            return request?.userInfo?["profile"] as? UUID
        }
    }
    
    private func extractMessage(from request: NSExtensionItem?) -> Any? {
        logVerbose("Extracting message from request", category: logCategory)
        if #available(iOS 15.0, macOS 11.0, *) {
            return request?.userInfo?[SFExtensionMessageKey]
        } else {
            return request?.userInfo?["message"]
        }
    }
    
    private func setResponseData(on response: NSExtensionItem, data: [String: Any]) {
        logVerbose("Setting response data", category: logCategory)
        if #available(iOS 15.0, macOS 11.0, *) {
            response.userInfo = [SFExtensionMessageKey: data]
        } else {
            response.userInfo = ["message": data]
        }
    }
}
