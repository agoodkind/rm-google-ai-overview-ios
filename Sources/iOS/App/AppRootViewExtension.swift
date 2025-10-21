//
//  AppRootViewExtension.swift
//  Skip AI (iOS)
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  APP ROOT VIEW EXTENSION - Adds iOS-specific modifiers
//

import SwiftUI

extension AppRootView {
    // Add enable extension modal sheet to root view
    func withIOSModifiers() -> some View {
        self.sheet(isPresented: $viewModel.showEnableExtensionModal) {
            EnableExtensionModal(isPresented: $viewModel.showEnableExtensionModal)
        }
    }
}

