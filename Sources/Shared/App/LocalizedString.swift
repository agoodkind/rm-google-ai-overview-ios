// LocalizedString.swift
// Skip AI - Safari Extension App
//
// TRANSLATIONS - Handles text in multiple languages
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
    static func extensionStateIOSUnknown() -> String {
        NSLocalizedString("extension.state.ios.unknown", comment: "iOS extension state unknown")
    }
    
    static func extensionStateIOSOn() -> String {
        NSLocalizedString("extension.state.ios.on", comment: "iOS extension is enabled")
    }
    
    static func extensionStateIOSOff() -> String {
        NSLocalizedString("extension.state.ios.off", comment: "iOS extension is disabled")
    }
    
    static func extensionStateMacLocation(useSettings: Bool) -> String {
        let key = useSettings ? "extension.state.mac.location.settings" : "extension.state.mac.location.preferences"
        return NSLocalizedString(key, comment: "Where to find Safari extension settings on macOS")
    }
    
    static func extensionStateMacEnable(location: String) -> String {
        // String(format:) substitutes %@ with the location parameter
        String(format: NSLocalizedString("extension.state.mac.enable", comment: "Message when extension state is unknown"), location)
    }
    
    static func extensionStateMacOn(location: String) -> String {
        String(format: NSLocalizedString("extension.state.mac.on", comment: "Message when extension is currently enabled"), location)
    }
    
    static func extensionStateMacOff(location: String) -> String {
        String(format: NSLocalizedString("extension.state.mac.off", comment: "Message when extension is currently disabled"), location)
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
}

