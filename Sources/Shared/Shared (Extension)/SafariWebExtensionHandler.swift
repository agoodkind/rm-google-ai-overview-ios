//
//  SafariWebExtensionHandler.swift
//  Shared (Extension)
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
    func beginRequest(with context: NSExtensionContext) {
        let request = context.inputItems.first as? NSExtensionItem

        let profile: UUID?
        if #available(iOS 17.0, macOS 14.0, *) {
            profile = request?.userInfo?[SFExtensionProfileKey] as? UUID
        } else {
            profile = request?.userInfo?["profile"] as? UUID
        }

        let message: Any?
        if #available(iOS 15.0, macOS 11.0, *) {
            message = request?.userInfo?[SFExtensionMessageKey]
        } else {
            message = request?.userInfo?["message"]
        }

        os_log(.default, "Received message from browser.runtime.sendNativeMessage: %{public}@ (profile: %{public}@)", String(describing: message), profile?.uuidString ?? "none")

        let response = NSExtensionItem()

        if let messageDict = message as? [String: Any],
           let type = messageDict["type"] as? String
        {
            switch type {
            case "serviceWorkerStarted":
                os_log(.default, "Service worker started")
                if #available(iOS 15.0, macOS 11.0, *) {
                    response.userInfo = [SFExtensionMessageKey: ["status": "acknowledged"]]
                } else {
                    response.userInfo = ["message": ["status": "acknowledged"]]
                }
            case "getDisplayMode":
                let displayMode = getDisplayMode()
                if #available(iOS 15.0, macOS 11.0, *) {
                    response.userInfo = [SFExtensionMessageKey: ["displayMode": displayMode]]
                } else {
                    response.userInfo = ["message": ["displayMode": displayMode]]
                }
            default:
                os_log(.default, "Unknown type: %{public}@", type)
            }
        } else {
            // Fallback echo
            if #available(iOS 15.0, macOS 11.0, *) {
                response.userInfo = [SFExtensionMessageKey: ["echo": message]]
            } else {
                response.userInfo = ["message": ["echo": message]]
            }
        }

        context.completeRequest(returningItems: [response], completionHandler: nil)
    }

    private func getDisplayMode() -> String {
        let defaults = UserDefaults(suiteName: APP_GROUP_ID)
        let mode = defaults?.string(forKey: DISPLAY_MODE_KEY)
        os_log(.default, "Display Mode: (stored) %{public}@, (default) %{public}@", mode ?? "none", DEFAULT_DISPLAY_MODE)
        return mode ?? DEFAULT_DISPLAY_MODE
    }
}
