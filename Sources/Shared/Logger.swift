//
//  Logger.swift
//  Skip AI
//
//  Copyright © 2025 Alexander Goodkind. All rights reserved.
//  https://goodkind.io/
//
//  LOGGING UTILITY - Centralized logging with verbosity levels
//
//  Provides consistent logging across the app and extension with configurable verbosity.
//  Verbosity level set via LOG_VERBOSITY in xcconfig files and passed through Info.plist.
//
//  Levels:
//  - 0 (None): No logging
//  - 1 (Error): Only errors
//  - 2 (Warning): Errors and warnings
//  - 3 (Info): Errors, warnings, and info
//  - 4 (Debug): All logs including debug
//  - 5 (Verbose): Maximum verbosity with detailed tracing

import Foundation
import os.log

enum LogLevel: Int, Comparable {
    case none = 0
    case error = 1
    case warning = 2
    case info = 3
    case debug = 4
    case verbose = 5
    
    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

class AppLogger {
    static let shared = AppLogger()
    
    private let subsystem = "io.goodkind.SkipAI"
    private let logLevel: LogLevel
    
    private init() {
        // Read LOG_VERBOSITY from environment, Info.plist, or use default based on build config
        
        var source = ""
        
        // 1. Try runtime environment variable (for debugging/overrides)
        if let verbosityString = ProcessInfo.processInfo.environment["LOG_VERBOSITY"],
           let verbosityInt = Int(verbosityString),
           let level = LogLevel(rawValue: verbosityInt) {
            self.logLevel = level
            source = "environment variable"
        }
        // 2. Try reading from Info.plist (set at build time from xcconfig)
        else if let verbosityString = Bundle.main.object(forInfoDictionaryKey: "LOG_VERBOSITY") as? String,
           let verbosityInt = Int(verbosityString),
           let level = LogLevel(rawValue: verbosityInt) {
            self.logLevel = level
            source = "Info.plist (xcconfig)"
        }
        // 3. Fall back to build configuration defaults
        else {
            #if DEBUG
            self.logLevel = .debug
            source = "DEBUG default"
            #elseif PREVIEW
            self.logLevel = .info
            source = "PREVIEW default"
            #else
            self.logLevel = .warning
            source = "RELEASE default"
            #endif
        }
        
        // Log initialization (only if level allows info)
        if self.logLevel >= .info {
            let logger = OSLog(subsystem: subsystem, category: "Logger")
            os_log(.info, log: logger, "[Logger] Initialized with level: %{public}@ (%d) from %{public}@", 
                   String(describing: self.logLevel), self.logLevel.rawValue, source)
        }
    }
    
    func error(_ message: String, category: String = "General", file: String = #file, line: Int = #line) {
        log(message, level: .error, category: category, file: file, line: line)
    }
    
    func warning(_ message: String, category: String = "General", file: String = #file, line: Int = #line) {
        log(message, level: .warning, category: category, file: file, line: line)
    }
    
    func info(_ message: String, category: String = "General", file: String = #file, line: Int = #line) {
        log(message, level: .info, category: category, file: file, line: line)
    }
    
    func debug(_ message: String, category: String = "General", file: String = #file, line: Int = #line) {
        log(message, level: .debug, category: category, file: file, line: line)
    }
    
    func verbose(_ message: String, category: String = "General", file: String = #file, line: Int = #line) {
        log(message, level: .verbose, category: category, file: file, line: line)
    }
    
    private func log(_ message: String, level: LogLevel, category: String, file: String, line: Int) {
        guard level <= logLevel else { return }
        
        let logger = OSLog(subsystem: subsystem, category: category)
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(fileName):\(line)] \(message)"
        
        switch level {
        case .none:
            break
        case .error:
            os_log(.error, log: logger, "%{public}@", logMessage)
        case .warning:
            os_log(.default, log: logger, "⚠️ %{public}@", logMessage)
        case .info:
            os_log(.info, log: logger, "%{public}@", logMessage)
        case .debug:
            os_log(.debug, log: logger, "🔍 %{public}@", logMessage)
        case .verbose:
            os_log(.debug, log: logger, "📝 %{public}@", logMessage)
        }
    }
}

// Convenience global functions
func logError(_ message: String, category: String = "General", file: String = #file, line: Int = #line) {
    AppLogger.shared.error(message, category: category, file: file, line: line)
}

func logWarning(_ message: String, category: String = "General", file: String = #file, line: Int = #line) {
    AppLogger.shared.warning(message, category: category, file: file, line: line)
}

func logInfo(_ message: String, category: String = "General", file: String = #file, line: Int = #line) {
    AppLogger.shared.info(message, category: category, file: file, line: line)
}

func logDebug(_ message: String, category: String = "General", file: String = #file, line: Int = #line) {
    AppLogger.shared.debug(message, category: category, file: file, line: line)
}

func logVerbose(_ message: String, category: String = "General", file: String = #file, line: Int = #line) {
    AppLogger.shared.verbose(message, category: category, file: file, line: line)
}
