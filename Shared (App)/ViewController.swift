//
//  ViewController.swift
//  Shared (App)
//
//  Created by Alex Goodkind on 10/7/25.
//

import os.log
import WebKit

#if os(iOS)
    import UIKit

    typealias PlatformViewController = UIViewController
#elseif os(macOS)
    import Cocoa
    import SafariServices

    typealias PlatformViewController = NSViewController
#endif

let extensionBundleIdentifier =
    "goodkind-io.Skip-AI.Extension"
let APP_GROUP_ID = "group.com.goodkind.skip-ai"
let DISPLAY_MODE_KEY = "skip-ai-display-mode"
#if DEBUG
    let DEFAULT_DISPLAY_MODE = "highlight"
#else
    let DEFAULT_DISPLAY_MODE = "hide"
#endif

#if DEBUG
    let devServerDefaultHost = "http://localhost:8080"
    let devServerHTMLPath = "xcode/Shared (App)/Resources/Base.lproj/Main.html"

    // Read from UserDefaults if available, otherwise use default
    var devServerBaseURL: String {
        UserDefaults.standard.string(forKey: "devServerHost")
            ?? devServerDefaultHost
    }
#endif

class ViewController: PlatformViewController, WKNavigationDelegate,
    WKScriptMessageHandler
{
    // Helper to dispatch the 'safari-extension-state' event with optional fields
    private func dispatchSafariExtensionState(
        platform: String? = nil,
        enabled: Bool? = nil,
        useSettings: Bool? = nil
    ) {
        var details: [String] = []
        if let platform = platform {
            details.append("platform: '\(platform)'")
        }
        if let enabled = enabled {
            details.append("enabled: \(enabled)")
        }
        if let useSettings = useSettings {
            details.append("useSettings: \(useSettings)")
        }
        let detailBody = details.joined(separator: ", ")
        let js = """
        window.dispatchEvent(new CustomEvent('safari-extension-state', {
          detail: { \(detailBody) }
        }));
        """
        self.webView.evaluateJavaScript(js)
    }

    @IBOutlet var webView: WKWebView!

    private func loadInitialContent() {
        #if DEBUG
            if #available(macOS 13.3, *) {
                if #available(iOS 16.4, *) {
                    self.webView.isInspectable = true
                }
            }
            // Attempt to load local dev server for rapid React iteration
            if let devURL = URL(
                string: "\(devServerBaseURL)/\(devServerHTMLPath)"
            ) {
                let request = URLRequest(
                    url: devURL,
                    cachePolicy: .reloadIgnoringLocalCacheData,
                    timeoutInterval: 1.0
                )
                let task = URLSession.shared.dataTask(with: request) {
                    [weak self] _, response, error in
                    guard let self = self else { return }
                    if let http = response as? HTTPURLResponse,
                       http.statusCode == 200, error == nil
                    {
                        print("[Dev] Loading dev server at \(devURL)")
                        DispatchQueue.main.async {
                            self.webView.load(URLRequest(url: devURL))
                        }
                    } else {
                        // fallback to bundled
                        if let error = error {
                            print(
                                "[Dev] Dev server unreachable: \(error.localizedDescription). Falling back to bundled HTML."
                            )
                        } else {
                            print(
                                "[Dev] Dev server probe failed (status code mismatch). Falling back to bundled HTML."
                            )
                        }
                        DispatchQueue.main.async {
                            self.webView.loadFileURL(
                                Bundle.main.url(
                                    forResource: "Main",
                                    withExtension: "html"
                                )!,
                                allowingReadAccessTo: Bundle.main.resourceURL!
                            )
                        }
                    }
                }
                task.resume()
            } else {
                self.webView.loadFileURL(
                    Bundle.main.url(
                        forResource: "Main",
                        withExtension: "html"
                    )!,
                    allowingReadAccessTo: Bundle.main.resourceURL!
                )
            }
        #else
            self.webView.loadFileURL(
                Bundle.main.url(forResource: "Main", withExtension: "html")!,
                allowingReadAccessTo: Bundle.main.resourceURL!
            )
        #endif
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.webView.navigationDelegate = self

        #if os(iOS)
            self.webView.scrollView.isScrollEnabled = false
        #endif

        self.webView.configuration.userContentController.add(
            self,
            name: "controller"
        )
        self.loadInitialContent()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        #if os(iOS)
            self.dispatchSafariExtensionState(platform: "ios")
        #elseif os(macOS)
            self.dispatchSafariExtensionState(platform: "mac")

            SFSafariExtensionManager.getStateOfSafariExtension(
                withIdentifier: extensionBundleIdentifier
            ) { state, error in
                guard let state = state, error == nil else { return }

                DispatchQueue.main.async {
                    let useSettingsFlag: Bool = {
                        if #available(macOS 13, *) {
                            return true
                        } else {
                            return false
                        }
                    }()
                    self.dispatchSafariExtensionState(
                        platform: "mac",
                        enabled: state.isEnabled,
                        useSettings: useSettingsFlag
                    )
                }
            }
        #endif
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard let body = message.body as? [String: Any] else { return }
        guard let type = body["type"] as? String else { return }

        #if DEBUG
            os_log(
                .debug,
                "[userContentController] got message name=%{public}@ body=%{public}@",
                message.name
            )

            // Handle dev server URL updates from web content
            if type == "setDevServerUrl",
            let url = body["url"] as? String
            {
                UserDefaults.standard.set(url, forKey: "devServerHost")
                os_log(.debug, "[Dev] Updated dev server URL to: %@", url)
                // reload
                DispatchQueue.main.async {
                    self.loadInitialContent()
                }
                return
            }
        #endif

        switch type {
        // Handle display mode changes from AppWebView
        case "setDisplayMode":
            if let mode = body["mode"] as? String {
                let defaults = UserDefaults(suiteName: APP_GROUP_ID)
                defaults?.set(mode, forKey: DISPLAY_MODE_KEY)
                defaults?.synchronize()
                os_log(
                    .debug,
                    "[userContentController] [setDisplayMode] Updated display mode to: %@",
                    mode
                )
            } else {
                os_log(
                    .debug,
                    "[userContentController] [setDisplayMode] ERROR: mode is nil"
                )
            }
            return
        case "getDisplayMode":
            let mode = self.getDisplayMode()
            let js = """
            window.dispatchEvent(new CustomEvent('displayModeResponse', {
              detail: { mode: '\(mode)' }
            }));
            """
            self.webView.evaluateJavaScript(js)
            return
        default:
            break
        }

        #if os(macOS)
            // mac specific extension settings
            // since macs can programmatically open safari settings (iOS & catalyst can't)

            switch type {
            case "openPreferences":
                SFSafariApplication.showPreferencesForExtension(
                    withIdentifier: extensionBundleIdentifier
                ) { error in
                    guard error == nil else { return }
                    DispatchQueue.main.async { NSApp.terminate(self) }
                }
            case "requestState":
                // Re-query current state and dispatch event
                SFSafariExtensionManager.getStateOfSafariExtension(
                    withIdentifier: extensionBundleIdentifier
                ) { state, error in
                    guard let state = state, error == nil else { return }
                    DispatchQueue.main.async {
                        let useSettingsFlag: Bool = {
                            if #available(macOS 13, *) {
                                return true
                            } else {
                                return false
                            }
                        }()
                        self.dispatchSafariExtensionState(
                            enabled: state.isEnabled,
                            useSettings: useSettingsFlag
                        )
                    }
                }
            default:
                break
            }
        #endif
    }

    private func getDisplayMode() -> String {
        let defaults = UserDefaults(suiteName: APP_GROUP_ID)
        let mode =
            defaults?.string(forKey: DISPLAY_MODE_KEY) ?? DEFAULT_DISPLAY_MODE
        return mode
    }
}
