//
//  AppDelegate.swift
//  macOS (App)
//
//  Created by Alex Goodkind on 10/7/25.
//

import Cocoa
import WebKit

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Preload WKWebView to eliminate first-launch delay
        workaroundInitialWebViewDelay()
    }
    
    func workaroundInitialWebViewDelay() {
        let webView = WKWebView()
        webView.loadHTMLString("", baseURL: nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

}
