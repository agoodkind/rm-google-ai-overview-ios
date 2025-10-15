//
//  ViewController.swift
//  Shared (App)
//
//  Created by Alex Goodkind on 10/7/25.
//

import WebKit

#if os(iOS)
import UIKit
typealias PlatformViewController = UIViewController
#elseif os(macOS)
import Cocoa
import SafariServices
typealias PlatformViewController = NSViewController
#endif

let extensionBundleIdentifier = "goodkind-io.Remove-Google-AI-Overview.Extension"

class ViewController: PlatformViewController, WKNavigationDelegate, WKScriptMessageHandler {

    @IBOutlet var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.webView.navigationDelegate = self

#if os(iOS)
        self.webView.scrollView.isScrollEnabled = false
#endif

        self.webView.configuration.userContentController.add(self, name: "controller")
#if DEBUG
        if #available(macOS 13.3, *) {
            self.webView.isInspectable = true
        }
#endif
#if DEBUG
        // Attempt to load local dev server for rapid React iteration
        if let devURL = URL(string: "http://localhost:5173/") {
            let request = URLRequest(url: devURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 1.0)
            let task = URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
                guard let self = self else { return }
                if let http = response as? HTTPURLResponse, http.statusCode == 200, error == nil {
                    print("[Dev] Loading dev server at \(devURL)")
                    DispatchQueue.main.async { self.webView.load(URLRequest(url: devURL)) }
                } else {
                    if let error = error { print("[Dev] Dev server unreachable: \(error.localizedDescription). Falling back to bundled HTML.") }
                    else { print("[Dev] Dev server probe failed (status code mismatch). Falling back to bundled HTML.") }
                    DispatchQueue.main.async {
                        self.webView.loadFileURL(Bundle.main.url(forResource: "Main", withExtension: "html")!, allowingReadAccessTo: Bundle.main.resourceURL!)
                    }
                }
            }
            task.resume()
        } else {
            self.webView.loadFileURL(Bundle.main.url(forResource: "Main", withExtension: "html")!, allowingReadAccessTo: Bundle.main.resourceURL!)
        }
#else
        self.webView.loadFileURL(Bundle.main.url(forResource: "Main", withExtension: "html")!, allowingReadAccessTo: Bundle.main.resourceURL!)
#endif
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
 #if os(iOS)
        webView.evaluateJavaScript("window.platform = 'ios';")
 #elseif os(macOS)
        webView.evaluateJavaScript("window.platform = 'mac';")

        #if DEBUG
        if let currentURL = webView.url?.absoluteString, currentURL.contains("localhost:5173") {
            // Automatically open inspector in debug when using dev server
            webView.forceInspector()
        }
        #endif

        SFSafariExtensionManager.getStateOfSafariExtension(withIdentifier: extensionBundleIdentifier) { (state, error) in
            guard let state = state, error == nil else {
                // Insert code to inform the user that something went wrong.
                return
            }

            DispatchQueue.main.async {
                if #available(macOS 13, *) {
                    webView.evaluateJavaScript("window.platform = 'mac'; window.extensionState = \(state.isEnabled); window.useSettings = true;")
                } else {
                    webView.evaluateJavaScript("window.platform = 'mac'; window.extensionState = \(state.isEnabled); window.useSettings = false;")
                }
            }
        }
#endif
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
#if os(macOS)
        if (message.body as! String != "open-preferences") {
            return
        }

        SFSafariApplication.showPreferencesForExtension(withIdentifier: extensionBundleIdentifier) { error in
            guard error == nil else {
                // Insert code to inform the user that something went wrong.
                return
            }

            DispatchQueue.main.async {
                NSApp.terminate(self)
            }
        }
#endif
    }

}

#if DEBUG
import WebKit
extension WKWebView {
    func forceInspector() {
        evaluateJavaScript("void 0") { _, _ in
            // Private API call (avoid for App Store) – use only locally:
            self.perform(Selector(("_inspectElementAtPoint:")));
        }
    }
}
#endif
