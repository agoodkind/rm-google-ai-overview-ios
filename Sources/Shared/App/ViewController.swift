// ViewController.swift
// Skip AI - Safari Extension App
//
// This file contains the main UI for the Skip AI companion app.
// The app allows users to configure how the Safari extension handles AI content on web pages.
//
// ARCHITECTURE OVERVIEW:
// ┌─────────────────────────────────────────────────────────────────┐
// │                      ViewController (Entry Point)                │
// │  - Creates and hosts SwiftUI views in UIKit/AppKit container    │
// │  - Called by iOS/macOS when app launches                        │
// └──────────────────────┬──────────────────────────────────────────┘
//                        │
//                        ▼
// ┌─────────────────────────────────────────────────────────────────┐
// │                     AppViewModel (State Manager)                 │
// │  - Stores display mode, extension status, platform info          │
// │  - Uses PlatformAdapter to handle iOS vs macOS differences       │
// └──────────────────────┬──────────────────────────────────────────┘
//                        │
//                        ▼
// ┌─────────────────────────────────────────────────────────────────┐
// │                    AppRootView (UI Layout)                       │
// │  - Header with icon, status message, preferences button          │
// │  - SettingsPanel with display mode selector                      │
// └─────────────────────────────────────────────────────────────────┘

import SwiftUI
import Combine

#if os(iOS)
import UIKit
#elseif os(macOS)
import Cocoa
import SafariServices
#endif

// MARK: - Constants

let extensionBundleIdentifier = "io.goodkind.Skip-AI.Extension"
let APP_GROUP_ID = "group.com.goodkind.skip-ai"  // Shared between app and extension
let DISPLAY_MODE_KEY = "skip-ai-display-mode"
#if DEBUG
let DEFAULT_DISPLAY_MODE = "highlight"  // Show orange borders in development
#else
let DEFAULT_DISPLAY_MODE = "hide"       // Hide AI content in production
#endif

// MARK: - Localization

// Centralized localization helper - provides type-safe access to translated strings
// NSLocalizedString looks up translations from Localizable.strings based on user's language
enum LocalizedString {
    static func extensionStateIOS() -> String {
        NSLocalizedString("extension.state.ios", comment: "iOS extension activation message")
    }
    
    static func extensionStateMacLocation(useSettings: Bool) -> String {
        let key = useSettings ? "extension.state.mac.location.settings" : "extension.state.mac.location.preferences"
        return NSLocalizedString(key, comment: "Where to find Safari extension settings on macOS")
    }
    
    static func extensionStateMacEnable(location: String) -> String {
        // String(format:) substitutes %@ with the location parameter
        String(format: NSLocalizedString("extension.state.mac.enable", comment: "Message when extension state is unknown"), location)
    }
    
    static func extensionStateMacOn(location: String) -> String {
        String(format: NSLocalizedString("extension.state.mac.on", comment: "Message when extension is currently enabled"), location)
    }
    
    static func extensionStateMacOff(location: String) -> String {
        String(format: NSLocalizedString("extension.state.mac.off", comment: "Message when extension is currently disabled"), location)
    }
    
    static func preferencesButton(useSettings: Bool) -> String {
        let key = useSettings ? "preferences.button.settings" : "preferences.button.preferences"
        return NSLocalizedString(key, comment: "Button text to open Safari extension preferences")
    }
    
    static func displayModeTitle() -> String {
        NSLocalizedString("display_mode.title", comment: "Settings panel title")
    }
    
    static func displayModeDescription() -> String {
        NSLocalizedString("display_mode.description", comment: "Explanation of display mode options")
    }
    
    static func displayModeHideTitle() -> String {
        NSLocalizedString("display_mode.hide.title", comment: "Hide mode button label")
    }
    
    static func displayModeHideDescription() -> String {
        NSLocalizedString("display_mode.hide.description", comment: "What hide mode does")
    }
    
    static func displayModeHighlightTitle() -> String {
        NSLocalizedString("display_mode.highlight.title", comment: "Highlight mode button label")
    }
    
    static func displayModeHighlightDescription() -> String {
        NSLocalizedString("display_mode.highlight.description", comment: "What highlight mode does")
    }
}

// MARK: - Platform Abstraction

// Strategy pattern to handle iOS vs macOS differences without scattering #if checks everywhere
protocol PlatformAdapter {
    var kind: PlatformKind { get }
    var useSettings: Bool { get }
    var horizontalPadding: CGFloat { get }
    
    func shouldShowPreferencesButton() -> Bool
    func openExtensionPreferences(completion: @escaping () -> Void)
    func checkExtensionState(completion: @escaping (Bool?) -> Void)
}

enum PlatformKind {
    case ios
    case mac
}

// MARK: - View Model

// The "brain" of the UI - manages state and business logic
// ObservableObject + @Published properties make SwiftUI views reactive
final class AppViewModel: ObservableObject {
    enum DisplayMode: String {
        case hide       // Completely remove AI content
        case highlight  // Show with orange border
    }
    
    // @Published automatically triggers UI updates when these values change
    @Published var displayMode: DisplayMode
    @Published var extensionEnabled: Bool?  // nil = unknown, true/false = known state
    
    let platform: PlatformAdapter
    
    init(platform: PlatformAdapter = Self.createPlatformAdapter()) {
        self.platform = platform
        self.displayMode = Self.loadDisplayMode()
        refreshExtensionState()
    }
    
    func onAppear() {
        displayMode = Self.loadDisplayMode()
        refreshExtensionState()
    }
    
    func selectDisplayMode(_ mode: DisplayMode) {
        guard displayMode != mode else { return }
        displayMode = mode
        Self.saveDisplayMode(mode)
    }
    
    // Computes appropriate status message based on platform and extension state
    var stateMessage: String {
        switch platform.kind {
        case .ios:
            return LocalizedString.extensionStateIOS()
        case .mac:
            let location = LocalizedString.extensionStateMacLocation(useSettings: platform.useSettings)
            guard let enabled = extensionEnabled else {
                return LocalizedString.extensionStateMacEnable(location: location)
            }
            return enabled
                ? LocalizedString.extensionStateMacOn(location: location)
                : LocalizedString.extensionStateMacOff(location: location)
        }
    }
    
    // Returns button title for macOS, nil for iOS (no button shown)
    var preferencesButtonTitle: String? {
        guard platform.shouldShowPreferencesButton() else { return nil }
        return LocalizedString.preferencesButton(useSettings: platform.useSettings)
    }
    
    // Opens Safari preferences and quits the app (macOS only)
    func openPreferences() {
        platform.openExtensionPreferences {
            DispatchQueue.main.async {
                #if os(macOS)
                NSApp.terminate(nil)
                #endif
            }
        }
    }
    
    // Checks with Safari whether extension is currently enabled
    private func refreshExtensionState() {
        platform.checkExtensionState { [weak self] enabled in
            // [weak self] prevents memory leaks by allowing self to be deallocated
            DispatchQueue.main.async {
                self?.extensionEnabled = enabled
            }
        }
    }
    
    private static func createPlatformAdapter() -> PlatformAdapter {
        #if os(iOS)
        return IOSPlatformAdapter()
        #else
        return MacOSPlatformAdapter()
        #endif
    }
    
    // UserDefaults with suiteName allows sharing preferences between app and extension
    private static func userDefaults() -> UserDefaults? {
        UserDefaults(suiteName: APP_GROUP_ID)
    }
    
    private static func loadDisplayMode() -> DisplayMode {
        let stored = userDefaults()?.string(forKey: DISPLAY_MODE_KEY)
        if let raw = stored, let mode = DisplayMode(rawValue: raw) {
            return mode
        }
        return DisplayMode(rawValue: DEFAULT_DISPLAY_MODE) ?? .hide
    }
    
    private static func saveDisplayMode(_ mode: DisplayMode) {
        let defaults = userDefaults()
        defaults?.set(mode.rawValue, forKey: DISPLAY_MODE_KEY)
        defaults?.synchronize()
    }
}

// MARK: - SwiftUI Views

struct AppRootView: View {
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        ZStack {
            PlatformColor.windowBackground.ignoresSafeArea()
            
            VStack(spacing: 32) {
                headerSection
                SettingsPanelView(viewModel: viewModel)
            }
            .applyPlatformFrame(for: viewModel.platform.kind)
            .padding(.vertical, 48)
            .padding(.horizontal, viewModel.platform.horizontalPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
    
    // Header with app icon, status message, and preferences button (macOS only)
    private var headerSection: some View {
        VStack(spacing: 20) {
            Image("LargeIcon")
                .resizable()
                .frame(width: 128, height: 128)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            Text(viewModel.stateMessage)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
            
            // Optional unwrapping - only shows button if title is not nil
            if let buttonTitle = viewModel.preferencesButtonTitle {
                Button(action: viewModel.openPreferences) {
                    Text(buttonTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 18)
                        .background(
                            Capsule()
                                .fill(Color.accentColor.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct SettingsPanelView: View {
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            headerText
            modeButtons
            Divider()
            descriptionText
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(panelBackground)
    }
    
    private var headerText: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString.displayModeTitle())
                .font(.callout)
                .fontWeight(.semibold)
            Text(LocalizedString.displayModeDescription())
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }
    
    // Two-button selector for Hide vs Highlight mode
    private var modeButtons: some View {
        HStack(spacing: 16) {
            DisplayModeButton(
                title: LocalizedString.displayModeHideTitle(),
                systemImage: "eye.slash",
                isSelected: viewModel.displayMode == .hide,
                selectedColor: .blue
            ) {
                viewModel.selectDisplayMode(.hide)
            }
            
            DisplayModeButton(
                title: LocalizedString.displayModeHighlightTitle(),
                systemImage: "checkmark.seal",
                isSelected: viewModel.displayMode == .highlight,
                selectedColor: .orange
            ) {
                viewModel.selectDisplayMode(.highlight)
            }
        }
    }
    
    private var descriptionText: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedString.displayModeHideDescription())
            Text(LocalizedString.displayModeHighlightDescription())
        }
        .font(.footnote)
        .foregroundColor(.secondary)
    }
    
    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(PlatformColor.panelBackground)
    }
}

struct DisplayModeButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let selectedColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)  // SF Symbol icon
                    .font(.title3)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundColor(isSelected ? .white : .primary)
            .background(buttonBackground)
        }
        .buttonStyle(.plain)
    }
    
    private var buttonBackground: some View {
        Group {
            if isSelected {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(selectedColor)
            } else {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(PlatformColor.windowBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    )
            }
        }
    }
}

// MARK: - Platform Colors

// Centralized platform-specific colors with macOS availability checks
enum PlatformColor {
    static var windowBackground: Color {
        #if os(iOS)
        return Color(.systemBackground)
        #else
        return macOSWindowBackground
        #endif
    }
    
    static var panelBackground: Color {
        #if os(iOS)
        return Color(.secondarySystemBackground)
        #else
        return macOSPanelBackground
        #endif
    }
    
    #if os(macOS)
    // macOS 12+ uses Color(nsColor:), older versions use Color(NSColor)
    private static var macOSWindowBackground: Color {
        if #available(macOS 12.0, *) {
            return Color(nsColor: .windowBackgroundColor)
        } else {
            return Color(NSColor.windowBackgroundColor)
        }
    }
    
    private static var macOSPanelBackground: Color {
        if #available(macOS 12.0, *) {
            return Color(nsColor: .underPageBackgroundColor)
        } else {
            return Color(NSColor.windowBackgroundColor)
        }
    }
    #endif
}

// MARK: - View Extensions

extension View {
    // Applies platform-specific width constraints
    func applyPlatformFrame(for platform: PlatformKind) -> some View {
        Group {
            switch platform {
            case .mac:
                self.frame(minWidth: 560, idealWidth: 620)
            case .ios:
                self.frame(maxWidth: 520)
            }
        }
    }
}

// MARK: - View Controller (Entry Point)

#if os(iOS)
typealias PlatformViewController = UIViewController
#elseif os(macOS)
typealias PlatformViewController = NSViewController
#endif

// The OS creates this class and calls viewDidLoad() when the app launches
// This bridges SwiftUI views into UIKit/AppKit
final class ViewController: PlatformViewController {
    private let viewModel = AppViewModel()
    
    #if os(iOS)
    private var hostingController: UIHostingController<AppRootView>?
    
    // ENTRY POINT: iOS calls this after view is loaded into memory
    override func viewDidLoad() {
        super.viewDidLoad()
        setupHostingController()
    }
    
    // UIHostingController bridges SwiftUI views into UIKit
    private func setupHostingController() {
        view.backgroundColor = .systemBackground
        
        let hosting = UIHostingController(rootView: AppRootView(viewModel: viewModel))
        addChild(hosting)
        view.addSubview(hosting.view)
        
        // Auto Layout constraints to fill the entire view
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        hosting.didMove(toParent: self)
        hostingController = hosting
    }
    
    #elseif os(macOS)
    private var hostingView: NSHostingView<AppRootView>?
    
    override func loadView() {
        self.view = NSView()
    }
    
    // ENTRY POINT: macOS calls this after view is loaded into memory
    override func viewDidLoad() {
        super.viewDidLoad()
        setupHostingView()
    }
    
    // NSHostingView bridges SwiftUI views into AppKit
    private func setupHostingView() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        let hosting = NSHostingView(rootView: AppRootView(viewModel: viewModel))
        view.addSubview(hosting)
        
        // Auto Layout constraints with minimum width for macOS window
        hosting.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hosting.widthAnchor.constraint(greaterThanOrEqualToConstant: 560),
        ])
        
        hostingView = hosting
    }
    #endif
}
