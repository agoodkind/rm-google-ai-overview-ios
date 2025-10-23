//
//  EnableExtensionViews.swift
//  Skip AI (iOS)
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  ENABLE EXTENSION MODAL - AdGuard-style onboarding popup
//

import SwiftUI

struct EnableExtensionModal: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var showWelcome: Bool
    
    init(viewModel: AppViewModel) {
        self.viewModel = viewModel
        #if DEBUG
        _showWelcome = State(initialValue: viewModel.forceShowWelcome || viewModel.isFirstLaunchEver)
        #else
        _showWelcome = State(initialValue: viewModel.isFirstLaunchEver)
        #endif
    }
    
    var body: some View {
        NavigationView {
            if showWelcome {
                welcomeView
            } else {
                instructionsView
            }
        }
    }
    
    private var welcomeView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(.bottom, 8)
                
                Text("Welcome to Skip AI")
                    .font(.system(size: 34, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text("Remove AI overviews from Search results and browse the web your way.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            Button(action: { withAnimation { showWelcome = false } }) {
                Text("Get Started")
                    .font(.body)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .cornerRadius(14)
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { viewModel.dismissEnableExtensionModal() }) {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var instructionsView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    instructionSteps
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    Spacer(minLength: 60)
                }
            }
            
            actionButtons
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(uiColor: .systemBackground))
        }
        .navigationTitle(LocalizedString.enableExtensionModalTitle())
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { viewModel.dismissEnableExtensionModal() }) {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var instructionSteps: some View {
        VStack(alignment: .leading, spacing: 28) {
            InstructionStep(
                icon: "gearshape.fill",
                title: LocalizedString.enableExtensionModalStep1Title(),
                description: LocalizedString.enableExtensionModalStep1Description(),
                iconColor: .gray
            )
            
            InstructionStep(
                icon: "safari.fill",
                title: LocalizedString.enableExtensionModalStep2Title(),
                description: LocalizedString.enableExtensionModalStep2Description(),
                iconColor: .blue
            )
            
            InstructionStep(
                icon: "switch.2",
                title: LocalizedString.enableExtensionModalStep3Title(),
                description: LocalizedString.enableExtensionModalStep3Description(),
                iconColor: .orange
            )
            
            InstructionStep(
                icon: "globe",
                title: LocalizedString.enableExtensionModalStep4Title(),
                description: LocalizedString.enableExtensionModalStep4Description(),
                iconColor: .purple
            )
            
            InstructionStep(
                icon: "checkmark.seal.fill",
                title: LocalizedString.enableExtensionModalStep5Title(),
                description: LocalizedString.enableExtensionModalStep5Description(),
                iconColor: .green
            )
        }
    }
    
    private func safariReaderIconName() -> String {
        let systemVersion = ProcessInfo.processInfo.operatingSystemVersion
        let majorVersion = systemVersion.majorVersion
        
        if majorVersion >= 26 {
            return "safariReaderiOS26"
        } else if majorVersion >= 17 {
            return "safariReaderiOS18"
        } else {
            return "safariReaderiOS16"
        }
    }
    
    private var actionButtons: some View {
        Button(action: { viewModel.dismissEnableExtensionModal() }) {
            Text(LocalizedString.enableExtensionModalDismiss())
                .font(.body)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .backport.glassEffect(.interactive(isEnabled: true))
        .cornerRadius(14)
    }
}

struct InstructionStep: View {
    let icon: String
    let title: String
    let description: String
    let iconColor: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(iconColor)
                .frame(width: 48, height: 48)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
    }
}

struct InstructionStepWithAsset: View {
    let assetName: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(assetName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
    }
}

#Preview("Enable Extension Modal") {
    EnableExtensionModal(viewModel: AppViewModel())
}

#Preview("Welcome Screen") {
    struct WelcomePreview: View {
        @StateObject var viewModel: AppViewModel
        
        init() {
            let vm = AppViewModel()
            vm.isFirstLaunchEver = true
            _viewModel = StateObject(wrappedValue: vm)
        }
        
        var body: some View {
            EnableExtensionModal(viewModel: viewModel)
        }
    }
    
    return WelcomePreview()
}

#Preview("Instruction Step") {
    VStack(spacing: 28) {
        InstructionStep(
            icon: "gearshape.fill",
            title: "Open Settings",
            description: "Launch the Settings app on your device.",
            iconColor: .gray
        )
        InstructionStep(
            icon: "safari.fill",
            title: "Navigate to Extensions",
            description: "Go to Apps > Safari > Extensions. Tap into both Skip AI and Skip AI Content Blocker.",
            iconColor: .blue
        )
        InstructionStep(
            icon: "switch.2",
            title: "Configure Skip AI Extension",
            description: "In Skip AI, turn on Allow Extension and Allow in Private Browsing.",
            iconColor: .orange
        )
        InstructionStep(
            icon: "globe",
            title: "Allow All Websites",
            description: "In Skip AI, tap All Websites and select Allow.",
            iconColor: .purple
        )
        InstructionStep(
            icon: "checkmark.seal.fill",
            title: "Configure Content Blocker",
            description: "In Skip AI Content Blocker, turn on Allow Extension and Allow in Private Browsing.",
            iconColor: .green
        )
    }
    .padding()
}
