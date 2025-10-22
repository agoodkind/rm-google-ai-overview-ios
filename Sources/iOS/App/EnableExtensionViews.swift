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
import SwiftUIBackports

struct EnableExtensionModal: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var showWelcome: Bool
    
    init(viewModel: AppViewModel) {
        self.viewModel = viewModel
        _showWelcome = State(initialValue: viewModel.isFirstLaunchEver)
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
            
            VStack(spacing: 24) {
                Image(systemName: "sparkles")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Welcome to Skip AI")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Remove AI overviews from Search results and browse the web your way.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            
            Button(action: { withAnimation { showWelcome = false } }) {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .backport.glassProminentButtonStyle()
            .controlSize(.large)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
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
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 0) {
                    instructionSteps
                        .padding(.horizontal, 24)
                        .padding(.top, 32)
                    
                    Spacer(minLength: 300)
                    
                    actionButtons
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                }
            }
            
            // Fade at top
            LinearGradient(
                colors: [
                    Color(uiColor: .systemBackground),
                    Color(uiColor: .systemBackground).opacity(0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 20)
            .allowsHitTesting(false)
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
        VStack(alignment: .leading, spacing: 20) {
            InstructionStep(
                number: 1,
                icon: "gearshape.fill",
                text: LocalizedString.enableExtensionModalStep1(),
                iconColor: .gray
            )
            
            InstructionStep(
                number: 2,
                icon: "safari.fill",
                text: LocalizedString.enableExtensionModalStep2(),
                iconColor: .blue
            )
            
            InstructionStep(
                number: 3,
                icon: "checkmark.circle.fill",
                text: LocalizedString.enableExtensionModalStep3(),
                iconColor: .green
            )
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 14) {
            Button(action: openSettings) {
                Text(LocalizedString.enableExtensionModalOpenSettings())
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .backport.glassProminentButtonStyle()
            .controlSize(.large)
            
            Button(action: { viewModel.dismissEnableExtensionModal() }) {
                Text(LocalizedString.enableExtensionModalDismiss())
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .backport.glassButtonStyle()
            .controlSize(.large)
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

struct InstructionStep: View {
    let number: Int
    let icon: String
    let text: String
    let iconColor: Color
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(iconColor)
                .frame(width: 44, height: 44)
            
            HStack(spacing: 8) {
                Text("\(number).")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text(text)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
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
    VStack(spacing: 20) {
        InstructionStep(
            number: 1,
            icon: "gearshape.fill",
            text: "Open Settings.",
            iconColor: .gray
        )
        InstructionStep(
            number: 2,
            icon: "safari.fill",
            text: "Go to Apps > Safari > Extensions.",
            iconColor: .blue
        )
        InstructionStep(
            number: 3,
            icon: "checkmark.circle.fill",
            text: "Enable both Skip AI extensions. You're good to go!",
            iconColor: .green
        )
    }
    .padding()
}
