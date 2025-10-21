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
    @Binding var isPresented: Bool
    
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
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private var instructionSteps: some View {
        VStack(alignment: .leading, spacing: 24) {
            InstructionStep(
                icon: "gearshape.fill",
                text: LocalizedString.enableExtensionModalStep1(),
                iconColor: .gray
            )
            
            InstructionStep(
                icon: "safari.fill",
                text: LocalizedString.enableExtensionModalStep2(),
                iconColor: .blue
            )
            
            InstructionStep(
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
            
            Button(action: { isPresented = false }) {
                Text(LocalizedString.enableExtensionModalDismiss())
                    .font(.body)
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
        isPresented = false
    }
}

struct InstructionStep: View {
    let icon: String
    let text: String
    let iconColor: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(iconColor)
                .frame(width: 44, height: 44)
                .background(iconColor.opacity(0.1))
                .cornerRadius(12)
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer(minLength: 0)
        }
    }
}

