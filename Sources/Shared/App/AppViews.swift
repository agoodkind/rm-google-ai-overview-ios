//
//  AppViews.swift
//  Skip AI
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  USER INTERFACE - All the visual components you see on screen
//
//  This file contains the SwiftUI views that make up the app's interface.
//  Views describe WHAT the UI should look like, not HOW to build it (declarative programming).
//
//  Views in this file:
//
//  1. AppRootView - The main container for the entire app
//     - Shows the app icon, status message, and settings panel
//     - Automatically updates when the view model's state changes
//     - Adapts layout based on platform (iOS vs macOS)
//
//  2. SettingsPanelView - The settings card with display mode options
//     - Shows title and description
//     - Contains the Hide/Highlight mode selector buttons
//     - Displays explanation text for each mode
//
//
//  How SwiftUI views work:
//  - Views are structs (lightweight, value types)
//  - The body property returns the view hierarchy
//  - Views automatically re-render when @Published data changes
//  - You compose complex UIs by nesting simple views
//
//  SF Symbols:
//  systemImage parameters use SF Symbols (Apple's icon system)
//  Browse available symbols:
//  - macOS: Download SF Symbols app from https://developer.apple.com/sf-symbols
//  - Xcode: Window → SF Symbols
//  - Online: https://developer.apple.com/sf-symbols

import SwiftUI
import SwiftUIBackports

/// Feedback button with share sheet
struct FeedbackButton: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var showShareSheet = false
    @State private var screenshot: UIImage?
    
    var body: some View {
        Button(action: captureAndShare) {
            Label(LocalizedString.reportFeedback(), systemImage: "envelope.fill")
                .font(.body)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        }
        .backport.glassProminentButtonStyle()
        .controlSize(.large)
        .sheet(isPresented: $showShareSheet) {
            #if os(iOS)
            if let screenshot = screenshot {
                ShareSheet(activityItems: [viewModel.generateFeedbackReport(), screenshot])
            } else {
                ShareSheet(activityItems: [viewModel.generateFeedbackReport()])
            }
            #else
            ShareSheet(activityItems: [viewModel.generateFeedbackReport()])
            #endif
        }
    }
    
    private func captureAndShare() {
        #if os(iOS)
        screenshot = captureScreen()
        #endif
        showShareSheet = true
    }
    
    #if os(iOS)
    private func captureScreen() -> UIImage? {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else {
            return nil
        }
        
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        return renderer.image { context in
            window.layer.render(in: context.cgContext)
        }
    }
    #endif
}

/// Main application view container
///
/// Root view that displays:
/// - App icon and status message
/// - Settings panel with display mode options
/// - Debug panel (DEBUG builds only)
///
/// Handles scene phase changes to refresh extension state
struct AppRootView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var showFeedback = false
    
    var body: some View {
        if #available(macOS 14.0, iOS 17.0, *) {
            content
                .onAppear {
                    viewModel.onAppear()
                    viewModel.trackActivation(isInitialLaunch: true)
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    handleScenePhaseChange(from: oldPhase, to: newPhase)
                }
            #if os(iOS)
            .sheet(isPresented: $viewModel.showEnableExtensionModal) {
                EnableExtensionModal(viewModel: viewModel)
            }
            .sheet(isPresented: $showFeedback) {
                ShareSheet(activityItems: [viewModel.generateFeedbackReport()])
            }
            .onAppear {
                ShakeDetector.shared.onShake {
                    showFeedback = true
                }
            }
            #endif
        } else {
            content
                .onAppear {
                    viewModel.onAppear()
                    viewModel.trackActivation(isInitialLaunch: true)
                }
                .onChange(of: scenePhase, perform: { newPhase in
                    handleScenePhaseChangeLegacy(to: newPhase)
                })
            #if os(iOS)
            .sheet(isPresented: $viewModel.showEnableExtensionModal) {
                EnableExtensionModal(viewModel: viewModel)
            }
            .sheet(isPresented: $showFeedback) {
                ShareSheet(activityItems: [viewModel.generateFeedbackReport()])
            }
            .onAppear {
                ShakeDetector.shared.onShake {
                    showFeedback = true
                }
            }
            #endif
        }
    }
    
    /// Handle scene phase changes (iOS 17+, macOS 14+)
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch (oldPhase, newPhase) {
        case (_, .active):
            // App came to foreground
            viewModel.onAppear()
            viewModel.trackActivation()
        case (.active, .inactive), (.active, .background):
            // App left foreground
            viewModel.trackDeactivation()
        default:
            break
        }
    }
    
    /// Handle scene phase changes (legacy iOS/macOS)
    private func handleScenePhaseChangeLegacy(to newPhase: ScenePhase) {
        if newPhase == .active {
            viewModel.onAppear()
            viewModel.trackActivation()
        } else if scenePhase == .active {
            // Was active, now becoming inactive or background
            viewModel.trackDeactivation()
        }
    }
    
    private var content: some View {
        ZStack {
            PlatformColor.windowBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    headerSection
                    
                    SettingsPanelView(viewModel: viewModel)
                    
                    FeedbackButton(viewModel: viewModel)
                    
                    #if DEBUG
                    DebugPanelView(viewModel: viewModel)
                    #endif
                }
                .applyPlatformFrame(for: viewModel.platform.kind)
                .padding(.top, 48)
                .padding(.bottom, 32)
                .padding(.horizontal, viewModel.platform.horizontalPadding)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // Header with app icon, status message, and preferences button (macOS only)
    private var headerSection: some View {
        VStack(spacing: 20) {
            Image("LargeIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 128, height: 128)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            Text(viewModel.stateMessage)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
            
            VStack(spacing: 12) {
                // Preferences button (macOS only)
                if let buttonTitle = viewModel.preferencesButtonTitle {
                    Button(action: viewModel.openPreferences) {
                        Text(buttonTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
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
}

/// Settings panel for display mode configuration
///
/// Allows user to choose between:
/// - Hide: Completely remove AI content
/// - Highlight: Show with orange border
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
        .backport.glassEffect(in: .rect(cornerRadius: 20))
    }
    
    private var headerText: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString.displayModeTitle())
                .font(.headline)
                .fontWeight(.semibold)
            Text(LocalizedString.displayModeDescription())
                .font(.subheadline)
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
                systemImage: "text.line.magnify",
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
                .fixedSize(horizontal: false, vertical: true)
            Text(LocalizedString.displayModeHighlightDescription())
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.subheadline)
        .foregroundColor(.secondary)
    }
    
    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(PlatformColor.panelBackground)
    }
}

/// Display mode button with glass effect
struct DisplayModeButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let selectedColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Group {
                    if isSelected {
                        selectedColor
                    } else {
                        Color.clear
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .backport.glassButtonStyle()
    }
}

#Preview("App Root View") {
    AppRootView(viewModel: AppViewModel())
}

#Preview("Settings Panel") {
    SettingsPanelView(viewModel: AppViewModel())
        .padding()
}
