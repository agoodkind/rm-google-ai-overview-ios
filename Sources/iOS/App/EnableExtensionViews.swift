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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                instructionSteps
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                
                Spacer()
                
                actionButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
            .navigationTitle(LocalizedString.enableExtensionModalTitle())
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.dismissEnableExtensionModal() }) {
                        Image(systemName: "xmark")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private var instructionSteps: some View {
        VStack(alignment: .leading, spacing: 28) {
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
        VStack(spacing: 12) {
            Button(action: openSettings) {
                Text(LocalizedString.enableExtensionModalOpenSettings())
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            
            Button(action: { viewModel.dismissEnableExtensionModal() }) {
                Text(LocalizedString.enableExtensionModalDismiss())
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        viewModel.dismissEnableExtensionModal()
    }
}

struct InstructionStep: View {
    let number: Int
    let icon: String
    let text: String
    let iconColor: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                VStack(spacing: 2) {
                    Text("\(number)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(iconColor.opacity(0.6))
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(iconColor)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(text)
                    .font(.body)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
    }
}
