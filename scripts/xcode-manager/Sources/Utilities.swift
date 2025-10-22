//
//  Utilities.swift
//  Skip AI
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  Helper functions and error types

import Foundation

enum Utils {
    static func printHeader(_ title: String) {
        print(String(repeating: "=", count: 80))
        print(title)
        print(String(repeating: "=", count: 80))
        print()
    }

    static func printSuccess(_ message: String) {
        print()
        print(String(repeating: "=", count: 80))
        print("✅ \(message)")
        print(String(repeating: "=", count: 80))
    }
}

enum XcodeManagerError: LocalizedError {
    case versionNotFound(String)
    case invalidVersion(String)
    
    var errorDescription: String? {
        switch self {
        case .versionNotFound(let key):
            return "Could not find \(key) in project settings"
        case .invalidVersion(let message):
            return message
        }
    }
}
