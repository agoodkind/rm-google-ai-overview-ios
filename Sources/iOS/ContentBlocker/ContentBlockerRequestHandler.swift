//
//  ContentBlockerRequestHandler.swift
//  Skip AI Content Blocker
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  CONTENT BLOCKER - Minimal content blocker for extension state detection
//
//  This is a minimal content blocker extension that exists primarily to enable
//  reliable extension state detection on iOS using SFContentBlockerManager.
//
//  Why this exists:
//  - iOS provides no official API to check if a Safari Web Extension is enabled
//  - iOS DOES provide SFContentBlockerManager.getStateOfContentBlocker API
//  - By adding a minimal content blocker, we can reliably detect if extension is enabled
//  - The actual content filtering happens in the web extension (not this blocker)
//
//  How it works:
//  - Contains a dummy blocking rule that will never match real content
//  - iOS checks this blocker's state to determine if user enabled extensions
//  - No actual content is blocked by this extension
//

import SafariServices

class ContentBlockerRequestHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        // Load the blocking rules from the JSON file
        let attachment = NSItemProvider(contentsOf: Bundle.main.url(forResource: "blockerList", withExtension: "json"))!
        
        let item = NSExtensionItem()
        item.attachments = [attachment]
        
        context.completeRequest(returningItems: [item], completionHandler: nil)
    }
}

