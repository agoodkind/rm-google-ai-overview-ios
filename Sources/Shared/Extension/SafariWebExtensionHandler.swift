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
            switch type {
            case "ping":
                logInfo("Ping received from app", category: logCategory)
                setResponseData(on: response, data: ["type": "pong"])
                logDebug("Responded with pong", category: logCategory)
            case "serviceWorkerStarted":
                logInfo("Service worker started notification", category: logCategory)
                setResponseData(on: response, data: ["status": "acknowledged"])
                logDebug("Acknowledged service worker start", category: logCategory)
            case "getDisplayMode":
                logDebug("Display mode requested", category: logCategory)
                let displayMode = getDisplayMode()
                setResponseData(on: response, data: ["displayMode": displayMode])
                logInfo("Returned display mode: \(displayMode)", category: logCategory)
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
