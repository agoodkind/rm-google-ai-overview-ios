//
//  SkipAIApp.swift
//  Skip AI
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  ENTRY POINT - This is where your app starts!
//
// This file contains the main application structure using SwiftUI's modern App protocol.
// The @main attribute tells the operating system "start the app here."
//
// What this file does:
// - Creates the main window for the app
// - Initializes the AppRootView with a view model
// - Configures window appearance (title bar, size) differently for macOS vs iOS
//
// When you launch the app, the OS calls this struct and displays the window defined here.
// Think of it like the "main()" function in other programming languages.

import SwiftUI

@main
struct SkipAIApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView(viewModel: AppViewModel())
        }
        .withPlatformWindowConfiguration()
    }
}
