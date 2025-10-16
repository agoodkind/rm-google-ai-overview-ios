//
//  SafariWebExtensionHandler.swift
//  Shared (Extension)
//
//  Created by Alex Goodkind on 10/7/25.
//

import SafariServices
import os.log

let APP_GROUP_ID = "group.com.goodkind.rm-google-ai-overview"
let DISPLAY_MODE_KEY = "rm-ai-display-mode"

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {

    func beginRequest(with context: NSExtensionContext) {
        print("Received message from browser.runtime.sendNativeMessage", context.inputItems)
        
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
        
        os_log(.default, "Received message from browser.runtime.sendNativeMessage: %@ (profile: %@)", String(describing: message), profile?.uuidString ?? "none")

        let response = NSExtensionItem()
        
        if let messageDict = message as? [String: Any],
           let action = messageDict["action"] as? String {
            
            switch(action) {
            case "serviceWorkerStarted":
                print("Service worker started notification received")
                os_log(.default, "Service worker started")
                if #available(iOS 15.0, macOS 11.0, *) {
                    response.userInfo = [ SFExtensionMessageKey: [ "status": "acknowledged" ] ]
                } else {
                    response.userInfo = [ "message": [ "status": "acknowledged" ] ]
                }
            case "getDisplayMode":
                let displayMode = getDisplayMode()
                if #available(iOS 15.0, macOS 11.0, *) {
                    response.userInfo = [ SFExtensionMessageKey: [ "displayMode": displayMode ] ]
                } else {
                    response.userInfo = [ "message": [ "displayMode": displayMode ] ]
                }
            default:
                print("Unknown action received:", action)
                os_log(.default, "Unknown type: %@", action)
                break;
            }
        } else {
            // Fallback echo
            if #available(iOS 15.0, macOS 11.0, *) {
                response.userInfo = [ SFExtensionMessageKey: [ "echo": message ] ]
            } else {
                response.userInfo = [ "message": [ "echo": message ] ]
            }
        }

        context.completeRequest(returningItems: [ response ], completionHandler: nil)
    }
    
    private func getDisplayMode() -> String? {
        return "test mode change me"
    }
    
    private func setDisplayMode(_ mode: String) {
        let defaults = UserDefaults(suiteName: APP_GROUP_ID)
        defaults?.set(mode, forKey: DISPLAY_MODE_KEY)
    }

}
