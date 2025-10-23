//
//  LocalizedString.swift
//  Skip AI
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  TRANSLATIONS - Handles text in multiple languages
//
// This file provides all user-facing text strings that appear in the app's interface.
// It automatically shows text in the user's preferred language (English, Spanish, Japanese, etc.)
//
// How it works:
// 1. Each function returns a translated string for a specific piece of UI text
// 2. NSLocalizedString() looks up the translation in Localizable.strings files
// 3. The system picks the right language file based on user's device settings
//
// Why use this instead of hardcoded strings?
// - Supports multiple languages automatically
// - Easy to add new languages (just add a new .strings file)
// - Type-safe: If you mistype a function name, you get a compile error
// - Centralized: All text in one place makes it easy to review copy
//
// Translation files are located at:
// Sources/Shared/App/Resources/[language].lproj/Localizable.strings
// (where [language] is en, es, fr, de, ja, zh-Hans, pt, it, ar, etc.)

import Foundation

enum LocalizedString {
    static func extensionStateiOSUnknown() -> String {
        NSLocalizedString("extension.state.ios.unknown", comment: "iOS extension state unknown")
    }
    
    static func extensionStateiOSOn() -> String {
        NSLocalizedString("extension.state.ios.on", comment: "iOS extension is enabled")
    }
    
    static func extensionStateiOSOff() -> String {
        NSLocalizedString("extension.state.ios.off", comment: "iOS extension is disabled")
    }
    
    static func extensionStateiOSError() -> String {
        NSLocalizedString("extension.state.ios.error", comment: "iOS extension state check failed")
    }
    
    static func extensionStateMacOSLocation(useSettings: Bool) -> String {
        let key = useSettings ? "extension.state.mac.location.settings" : "extension.state.mac.location.preferences"
        return NSLocalizedString(key, comment: "Where to find Safari extension settings on macOS")
    }
    
    static func extensionStateMacOSEnable(location: String) -> String {
        // String(format:) substitutes %@ with the location parameter
        String(format: NSLocalizedString("extension.state.mac.enable", comment: "Message when extension state is unknown"), location)
    }
    
    static func extensionStateMacOSOn(location: String) -> String {
        String(format: NSLocalizedString("extension.state.mac.on", comment: "Message when extension is currently enabled"), location)
    }
    
    static func extensionStateMacOSOff(location: String) -> String {
        String(format: NSLocalizedString("extension.state.mac.off", comment: "Message when extension is currently disabled"), location)
    }
    
    static func extensionStateMacOSError(location: String) -> String {
        String(format: NSLocalizedString("extension.state.mac.error", comment: "Message when extension state check failed"), location)
    }
    
    static func preferencesButton(useSettings: Bool) -> String {
        let key = useSettings ? "preferences.button.settings" : "preferences.button.preferences"
        return NSLocalizedString(key, comment: "Button text to open Safari extension preferences")
    }
    
    static func displayModeTitle() -> String {
        NSLocalizedString("display_mode.title", comment: "Settings panel title")
    }
    
    static func displayModeDescription() -> String {
        NSLocalizedString("display_mode.description", comment: "Explanation of display mode options")
    }
    
    static func displayModeHideTitle() -> String {
        NSLocalizedString("display_mode.hide.title", comment: "Hide mode button label")
    }
    
    static func displayModeHideDescription() -> String {
        NSLocalizedString("display_mode.hide.description", comment: "What hide mode does")
    }
    
    static func displayModeHighlightTitle() -> String {
        NSLocalizedString("display_mode.highlight.title", comment: "Highlight mode button label")
    }
    
    static func displayModeHighlightDescription() -> String {
        NSLocalizedString("display_mode.highlight.description", comment: "What highlight mode does")
    }
    
    // MARK: - Enable Extension Modal
    
    static func enableExtensionModalTitle() -> String {
        NSLocalizedString("enable_extension.modal.title", comment: "Modal title for enabling extension")
    }
    
    static func enableExtensionModalStep1Title() -> String {
        NSLocalizedString("enable_extension.modal.step1.title", comment: "First step title")
    }
    
    static func enableExtensionModalStep1Description() -> String {
        NSLocalizedString("enable_extension.modal.step1.description", comment: "First step description")
    }
    
    static func enableExtensionModalStep2Title() -> String {
        NSLocalizedString("enable_extension.modal.step2.title", comment: "Second step title")
    }
    
    static func enableExtensionModalStep2Description() -> String {
        NSLocalizedString("enable_extension.modal.step2.description", comment: "Second step description")
    }
    
    static func enableExtensionModalStep3Title() -> String {
        NSLocalizedString("enable_extension.modal.step3.title", comment: "Third step title")
    }
    
    static func enableExtensionModalStep3Description() -> String {
        NSLocalizedString("enable_extension.modal.step3.description", comment: "Third step description")
    }
    
    static func enableExtensionModalStep4Title() -> String {
        NSLocalizedString("enable_extension.modal.step4.title", comment: "Fourth step title")
    }
    
    static func enableExtensionModalStep4Description() -> String {
        NSLocalizedString("enable_extension.modal.step4.description", comment: "Fourth step description")
    }
    
    static func enableExtensionModalStep5Title() -> String {
        NSLocalizedString("enable_extension.modal.step5.title", comment: "Fifth step title")
    }
    
    static func enableExtensionModalStep5Description() -> String {
        NSLocalizedString("enable_extension.modal.step5.description", comment: "Fifth step description")
    }
    
    static func enableExtensionModalDismiss() -> String {
        NSLocalizedString("enable_extension.modal.dismiss", comment: "Button to dismiss modal")
    }
    
    static func enableExtensionModalOpenSettings() -> String {
        NSLocalizedString("enable_extension.modal.open_settings", comment: "Button to open Settings app")
    }
    
    // MARK: - Feedback
    
    static func reportFeedback() -> String {
        NSLocalizedString("feedback.report", comment: "Report feedback button")
    }
}
