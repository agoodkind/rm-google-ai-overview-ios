// AppViews.swift
// Skip AI - Safari Extension App
//
// SwiftUI view components for the app

import SwiftUI

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
