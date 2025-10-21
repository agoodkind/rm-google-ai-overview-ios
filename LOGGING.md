# Logging Configuration

## Overview

Skip AI uses a centralized logging system with configurable verbosity levels controlled via Xcode build configurations.

## Log Levels

| Level | Value | Description | Use Case |
|-------|-------|-------------|----------|
| None | 0 | No logging | Production (if needed) |
| Error | 1 | Only errors | Critical issues only |
| Warning | 2 | Errors + warnings | Production default |
| Info | 3 | Errors + warnings + info | Preview/staging |
| Debug | 4 | All logs including debug | Development default |
| Verbose | 5 | Maximum verbosity | Troubleshooting |

## Configuration

### Build Configurations

Log verbosity is set in `.xcconfig` files and automatically passed to the app via Info.plist:

- **Debug.xcconfig**: `LOG_VERBOSITY = 5` (Verbose level)
- **Preview.xcconfig**: `LOG_VERBOSITY = 3` (Info level)  
- **Release.xcconfig**: `LOG_VERBOSITY = 2` (Warning level)

The build system automatically injects this value into all Info.plist files at build time via the `$(LOG_VERBOSITY)` variable.

### Priority Order

The Logger checks for verbosity in this order:

1. **Runtime Environment Variable** (highest priority)
   - Override at runtime in Xcode scheme
   - Product → Scheme → Edit Scheme... → Run → Arguments → Environment Variables
   - Add: `LOG_VERBOSITY` = `0-5`

2. **Info.plist Build Setting** (set from xcconfig at build time)
   - Automatically injected from xcconfig files
   - Different per build configuration (Debug/Preview/Release)

3. **Build Configuration Default** (lowest priority - fallback)
   - DEBUG: Level 4 (Debug)
   - PREVIEW: Level 3 (Info)
   - RELEASE: Level 2 (Warning)

## Usage

### In App Code

```swift
import Foundation

// Use global convenience functions
logError("Critical error occurred", category: "CategoryName")
logWarning("Something unexpected", category: "CategoryName")
logInfo("User action completed", category: "CategoryName")
logDebug("Variable value: \(value)", category: "CategoryName")
logVerbose("Detailed trace information", category: "CategoryName")

// Or use the logger directly
AppLogger.shared.error("Error message", category: "CategoryName")
```

### In Extension Code

Extension uses the same Logger system:

```swift
logError("Error message", category: "SafariExtension")
logWarning("Warning message", category: "SafariExtension")
logInfo("Info message", category: "SafariExtension")
logDebug("Debug message", category: "SafariExtension")
logVerbose("Verbose trace", category: "SafariExtension")
```

## Log Categories

| Category | Description |
|----------|-------------|
| AppViewModel | App state and UI logic |
| IOSPlatform | iOS-specific platform code |
| macOSPlatform | macOS-specific platform code |
| ExtensionComm | Extension communication via shared storage |
| SafariExtension | Extension handler native messaging |

## Viewing Logs

### Xcode Console
- Run app in Xcode
- View logs in console output

### Console.app
1. Open Console.app
2. Filter by process: "Skip AI"
3. Filter by subsystem: "io.goodkind.SkipAI"
4. Filter by category (optional)

### Command Line
```bash
# Live tail
log stream --predicate 'subsystem == "io.goodkind.SkipAI"' --level debug

# Show recent logs
log show --predicate 'subsystem == "io.goodkind.SkipAI"' --last 1h --info
```

## Best Practices

1. **Use appropriate levels**:
   - Error: Actual errors that need attention
   - Warning: Unexpected but handled situations
   - Info: Important state changes and user actions
   - Debug: Detailed flow information
   - Verbose: Trace-level details for debugging

2. **Include context**:
   ```swift
   logDebug("Loading display mode: \(mode)", category: "AppViewModel")
   ```

3. **Use categories consistently**:
   - Add `private let logCategory = "CategoryName"` to classes
   - Use same category for related operations

4. **File and line numbers**:
   - Automatically captured via `#file` and `#line`
   - Shows in logs as `[FileName.swift:123]`

5. **Privacy**:
   - App logs use `%{public}@` (safe for review)
   - Avoid logging sensitive user data

## Troubleshooting

### Logs not appearing?
1. Check LOG_VERBOSITY setting in xcconfig (Debug.xcconfig, etc.)
2. Clean build folder and rebuild (Xcode → Product → Clean Build Folder)
3. Verify Info.plist contains `$(LOG_VERBOSITY)` placeholder
4. Check Console.app filters
5. Ensure category name is correct
6. Try setting runtime environment variable override

### Too many logs?
1. Lower LOG_VERBOSITY in xcconfig file for your build configuration
2. Clean and rebuild to pick up new value
3. Filter by specific category in Console.app
4. Use `--level` flag with `log` command

### Need more detail?
1. Set LOG_VERBOSITY to 5 (Verbose) in Debug.xcconfig
2. Clean and rebuild
3. Check verbose logs in specific categories
4. Review extension logs separately in Console.app

### Verify current log level
The Logger prints its configuration on first use. Check console output for:
```
[Logger] Initialized with log level: verbose (5)
```

