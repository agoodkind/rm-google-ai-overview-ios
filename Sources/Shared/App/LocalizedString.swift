// LocalizedString.swift
// Skip AI - Safari Extension App
//
// Centralized localization helper - provides type-safe access to translated strings
// NSLocalizedString looks up translations from Localizable.strings based on user's language

import Foundation

enum LocalizedString {
    static func extensionStateIOS() -> String {
        NSLocalizedString("extension.state.ios", comment: "iOS extension activation message")
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

