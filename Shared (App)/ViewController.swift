import SwiftUI
import Combine

#if os(iOS)
import UIKit
typealias PlatformViewController = UIViewController
#elseif os(macOS)
import Cocoa
import SafariServices
typealias PlatformViewController = NSViewController
#endif

let extensionBundleIdentifier = "goodkind-io.Skip-AI.Extension"
let APP_GROUP_ID = "group.com.goodkind.skip-ai"
let DISPLAY_MODE_KEY = "skip-ai-display-mode"
#if DEBUG
let DEFAULT_DISPLAY_MODE = "highlight"
#else
let DEFAULT_DISPLAY_MODE = "hide"
#endif

final class AppViewModel: ObservableObject {
    enum PlatformKind {
        case ios
        case mac
    }

    enum DisplayMode: String {
        case hide
        case highlight
    }

    @Published var displayMode: DisplayMode
    @Published var extensionEnabled: Bool?
    @Published var useSettings: Bool
    let platform: PlatformKind

    init() {
        #if os(iOS)
        platform = .ios
        useSettings = false
        #else
        platform = .mac
        useSettings = AppViewModel.shouldUseSettings()
        #endif

        displayMode = AppViewModel.loadDisplayMode()

        #if os(macOS)
        refreshExtensionState()
        #endif
    }

    func onAppear() {
        displayMode = AppViewModel.loadDisplayMode()
        #if os(macOS)
        refreshExtensionState()
        #endif
    }

    func selectDisplayMode(_ mode: DisplayMode) {
        guard displayMode != mode else { return }
        displayMode = mode
        AppViewModel.saveDisplayMode(mode)
    }

    var stateMessage: String {
        switch platform {
        case .ios:
            return "You can turn on Skip AI's Safari extension in Settings."
        case .mac:
            let location = useSettings
                ? "the Extensions section of Safari Settings"
                : "Safari Extensions preferences"
            guard let enabled = extensionEnabled else {
                return "You can turn on Skip AI's extension in \(location)."
            }

            if enabled {
                return "Skip AI's extension is currently on. You can turn it off in \(location)."
            } else {
                return "Skip AI's extension is currently off. You can turn it on in \(location)."
            }
        }
    }

    var preferencesButtonTitle: String? {
        guard platform == .mac else { return nil }
        if useSettings {
            return "Quit and Open Safari Settings…"
        } else {
            return "Quit and Open Safari Extensions Preferences…"
        }
    }

    func openPreferences() {
        guard platform == .mac else { return }
        #if os(macOS)
        SFSafariApplication.showPreferencesForExtension(withIdentifier: extensionBundleIdentifier) { error in
            guard error == nil else { return }
            DispatchQueue.main.async {
                NSApp.terminate(nil)
            }
        }
        #endif
    }

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

    #if os(macOS)
    private func refreshExtensionState() {
        SFSafariExtensionManager.getStateOfSafariExtension(withIdentifier: extensionBundleIdentifier) { [weak self] state, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let state = state, error == nil {
                    self.extensionEnabled = state.isEnabled
                } else {
                    self.extensionEnabled = nil
                }
                self.useSettings = AppViewModel.shouldUseSettings()
            }
        }
    }

    private static func shouldUseSettings() -> Bool {
        if #available(macOS 13, *) {
            return true
        } else {
            return false
        }
    }
    #else
    private func refreshExtensionState() {}
    #endif
}

struct AppRootView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        ZStack {
            #if os(iOS)
            Color(.systemBackground).ignoresSafeArea()
            #else
            Color.platformWindowBackground.ignoresSafeArea()
            #endif

            VStack(spacing: 32) {
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

                SettingsPanelView(viewModel: viewModel)
            }
#if os(macOS)
            .frame(minWidth: 560, idealWidth: 620)
#else
            .frame(maxWidth: 520)
#endif
            .padding(.vertical, 48)
            .padding(.horizontal, rootHorizontalPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
}

struct SettingsPanelView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Display Mode")
                    .font(.callout)
                    .fontWeight(.semibold)
                Text("Choose whether to hide AI overview elements completely or highlight them with an orange border.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 16) {
                DisplayModeButton(
                    title: "Hide",
                    systemImage: "eye.slash",
                    isSelected: viewModel.displayMode == .hide,
                    selectedColor: Color.blue
                ) {
                    viewModel.selectDisplayMode(.hide)
                }

                DisplayModeButton(
                    title: "Highlight",
                    systemImage: "checkmark.seal",
                    isSelected: viewModel.displayMode == .highlight,
                    selectedColor: Color.orange
                ) {
                    viewModel.selectDisplayMode(.highlight)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Hide: Completely removes AI overview sections from view.")
                Text("Highlight: Shows AI overview sections with an orange border so you can see what is being detected.")
            }
            .font(.footnote)
            .foregroundColor(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            Group {
                #if os(iOS)
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
                #else
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.platformUnderPageBackground)
                #endif
            }
        )
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
                Image(systemName: systemImage)
                    .font(.title3)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundColor(isSelected ? Color.white : Color.primary)
            .background(background)
        }
        .buttonStyle(.plain)
    }

    private var background: some View {
        Group {
            if isSelected {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(selectedColor)
            } else {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(unselectedFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(borderColor, lineWidth: 2)
                    )
            }
        }
    }

    private var unselectedFill: Color {
        #if os(iOS)
        return Color(.systemBackground)
        #else
        return Color.platformWindowBackground
        #endif
    }

    private var borderColor: Color {
        Color.gray.opacity(0.3)
    }
}

private extension Color {
    #if os(iOS)
    static var platformWindowBackground: Color { Color(.systemBackground) }
    static var platformUnderPageBackground: Color { Color(.secondarySystemBackground) }
    #elseif os(macOS)
    static var platformWindowBackground: Color {
        if #available(macOS 12.0, *) {
            return Color(nsColor: .windowBackgroundColor)
        } else {
            return Color(NSColor.windowBackgroundColor)
        }
    }

    static var platformUnderPageBackground: Color {
        if #available(macOS 12.0, *) {
            return Color(nsColor: .underPageBackgroundColor)
        } else {
            return Color(NSColor.windowBackgroundColor)
        }
    }
    #endif
}

final class ViewController: PlatformViewController {
    private let viewModel = AppViewModel()

    #if os(iOS)
    private var hostingController: UIHostingController<AppRootView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let hosting = UIHostingController(rootView: AppRootView(viewModel: viewModel))
        addChild(hosting)
        view.addSubview(hosting.view)
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

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        let hosting = NSHostingView(rootView: AppRootView(viewModel: viewModel))
        hosting.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hostingView = hosting
    }
    #endif
}
