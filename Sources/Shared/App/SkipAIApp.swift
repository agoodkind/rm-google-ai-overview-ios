// SkipAIApp.swift
// Skip AI - Safari Extension App
//
// Main SwiftUI app entry point for both iOS and macOS
// This is the ENTRY POINT with @main - iOS/macOS starts here

import SwiftUI

@main
struct SkipAIApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView(viewModel: AppViewModel())
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 620, height: 700)
        #endif
    }
}

