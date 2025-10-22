//
//  AppViews.swift
//  Skip AI
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  USER INTERFACE - All the visual components you see on screen
//
// This file contains the SwiftUI views that make up the app's interface.
// Views describe WHAT the UI should look like, not HOW to build it (declarative programming).
//
// Views in this file:
//
// 1. AppRootView - The main container for the entire app
//    - Shows the app icon, status message, and settings panel
//    - Automatically updates when the view model's state changes
//    - Adapts layout based on platform (iOS vs macOS)
//
// 2. SettingsPanelView - The settings card with display mode options
//    - Shows title and description
//    - Contains the Hide/Highlight mode selector buttons
//    - Displays explanation text for each mode
//
// 3. DisplayModeButton - Individual button for selecting a display mode
//    - Changes appearance when selected (filled vs outlined)
//    - Shows an icon and title
//    - Calls the view model when tapped
//
// How SwiftUI views work:
// - Views are structs (lightweight, value types)
// - The body property returns the view hierarchy
// - Views automatically re-render when @Published data changes
// - You compose complex UIs by nesting simple views

import SwiftUI

struct AppRootView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        if #available(macOS 14.0, iOS 17.0, *) {
            content
                .onAppear {
                    viewModel.onAppear()
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    if newPhase == .active {
                        viewModel.onAppear()
                    }
                }
                #if os(iOS)
                .sheet(isPresented: $viewModel.showEnableExtensionModal) {
                    EnableExtensionModal(isPresented: $viewModel.showEnableExtensionModal)
                }
                #endif
        } else {
            content
                .onAppear {
                    viewModel.onAppear()
                }
                .onChange(of: scenePhase, perform: { newPhase in
                    if newPhase == .active {
                        viewModel.onAppear()
                    }
                })
                #if os(iOS)
                .sheet(isPresented: $viewModel.showEnableExtensionModal) {
                    EnableExtensionModal(isPresented: $viewModel.showEnableExtensionModal)
                }
                #endif
        }
    }
    
    private var content: some View {
        ZStack {
            PlatformColor.windowBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    headerSection
                    SettingsPanelView(viewModel: viewModel)
                    #if DEBUG
                    DebugPanelView(viewModel: viewModel)
                    #endif
                }
                .applyPlatformFrame(for: viewModel.platform.kind)
                .padding(.vertical, 48)
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
                .fixedSize(horizontal: false, vertical: true)
            Text(LocalizedString.displayModeHighlightDescription())
                .fixedSize(horizontal: false, vertical: true)
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

#if DEBUG
struct DebugPanelView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("DEBUG INFO")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.red)
            
            debugRow(label: "Platform", value: "\(viewModel.platform.kind)")
            debugRow(label: "Scene Phase", value: scenePhaseText)
            debugRow(label: "First Launch Ever", value: "\(viewModel.isFirstLaunchEver)")
            debugRow(label: "Launch Count", value: "\(viewModel.launchCount + 1)")
            debugRow(label: "Session Start", value: formatDate(viewModel.currentSessionStartDate))
            if let lastLaunch = viewModel.lastLaunchDate {
                debugRow(label: "Last Launch", value: formatDate(lastLaunch))
                debugRow(label: "Time Since Last", value: timeSince(lastLaunch))
            }
            debugRow(label: "Display Mode", value: viewModel.displayMode.rawValue)
            debugRow(label: "Extension State", value: extensionStateText)
            debugRow(label: "Use Settings", value: "\(viewModel.platform.useSettings)")
            debugRow(label: "Show Prefs Button", value: "\(viewModel.platform.shouldShowPreferencesButton())")
            debugRow(label: "Horizontal Padding", value: "\(viewModel.platform.horizontalPadding)")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(debugBackground)
        .font(.system(.caption, design: .monospaced))
    }
    
    private var scenePhaseText: String {
        switch scenePhase {
        case .active:
            return "active"
        case .inactive:
            return "inactive"
        case .background:
            return "background"
        @unknown default:
            return "unknown"
        }
    }
    
    private var extensionStateText: String {
        switch viewModel.extensionEnabled {
        case .unchecked:
            return "unchecked"
        case .enabled:
            return "enabled"
        case .disabled:
            return "disabled"
        case .error:
            return "error"
        }
    }
    
    private func debugRow(label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Text("\(label):")
                .foregroundColor(.secondary)
            Text(value)
                .fontWeight(.semibold)
            Spacer()
        }
    }
    
    private var debugBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.red.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
            )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    private func timeSince(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
#endif
