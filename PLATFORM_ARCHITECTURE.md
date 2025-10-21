# Platform Architecture

## Overview

Skip AI uses a clean separation between shared and platform-specific code. All `#if os()` conditional compilation logic is isolated in platform-specific folders or dedicated infrastructure files.

## Folder Structure

```
Sources/
├── Shared/           # Platform-agnostic shared code
│   ├── App/          # Core app logic (no platform-specific behavior)
│   └── Extension/    # Extension handler (works on both platforms)
├── iOS/              # iOS-only code
│   ├── App/          # iOS-specific implementations
│   └── ContentBlocker/  # iOS content blocker for state detection
└── macOS/            # macOS-only code
    ├── App/          # macOS-specific implementations
    └── Extension/    # macOS extension info
```

## Architecture Patterns

### 1. Platform Adapter Pattern

**Location:** `Sources/Shared/App/PlatformAdapter.swift`

Defines a protocol that each platform implements differently:

```swift
// Shared protocol definition
protocol PlatformAdapter {
    var kind: PlatformKind { get }
    func checkExtensionState(completion: @escaping (Bool?) -> Void)
    // ... other methods
}

// iOS implementation in Sources/iOS/App/PlatformConfiguration.swift
struct IOSPlatformAdapter: PlatformAdapter { ... }

// macOS implementation in Sources/macOS/App/PlatformConfiguration.swift
struct MacOSPlatformAdapter: PlatformAdapter { ... }
```

### 2. Extension Method Pattern

Platform-specific extensions add functionality without polluting shared code:

#### View Model Extensions

**iOS:** `Sources/iOS/App/AppViewModelExtension.swift`
```swift
extension AppViewModel {
    func handleExtensionStateChanged(enabled: Bool?) {
        // Show modal when extension disabled
    }
}
```

**macOS:** `Sources/macOS/App/AppViewModelExtension.swift`
```swift
extension AppViewModel {
    func handleExtensionStateChanged(enabled: Bool?) {
        // No-op - uses button instead
    }
}
```

#### View Extensions

**iOS:** `Sources/iOS/App/AppRootViewExtension.swift`
```swift
extension AppRootView {
    func withIOSModifiers() -> some View {
        self.sheet(isPresented: $viewModel.showEnableExtensionModal) {
            EnableExtensionModal(...)
        }
    }
}
```

**macOS:** `Sources/macOS/App/AppRootViewExtension.swift`
```swift
extension AppRootView {
    func withIOSModifiers() -> some View {
        self  // No additional modifiers
    }
}
```

### 3. Platform-Specific Views

iOS-only views live in iOS folder:

- `Sources/iOS/App/EnableExtensionViews.swift` - Modal for enabling extension
- Contains `EnableExtensionModal` and `InstructionStep` views

macOS doesn't need these views (uses button to open Settings directly).

### 4. Color Extension Pattern

**Shared:** `Sources/Shared/App/PlatformColor.swift`
```swift
struct PlatformColor {
    static var windowBackground: Color {
        #if os(iOS)
        return iosWindowBackground
        #else
        return macOSWindowBackground
        #endif
    }
}
```

**Platform-specific implementations:**
- iOS: `Sources/iOS/App/PlatformConfiguration.swift`
- macOS: `Sources/macOS/App/PlatformConfiguration.swift`

Each defines the actual colors:
```swift
extension PlatformColor {
    static var iosWindowBackground: Color {
        Color(.systemBackground)
    }
}
```

## Remaining `#if os()` in Shared Code

Only infrastructure code has conditional compilation:

### 1. Factory Method (AppViewModel.swift)
```swift
private static func createPlatformAdapter() -> PlatformAdapter {
    #if os(iOS)
    return IOSPlatformAdapter()
    #else
    return MacOSPlatformAdapter()
    #endif
}
```
**Why:** Necessary to instantiate the correct platform adapter.

### 2. Window Configuration (WindowConfiguration.swift)
```swift
static func configure<S: Scene>(_ scene: S) -> some Scene {
    #if os(macOS)
    return scene
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 620, height: 700)
    #else
    return scene
    #endif
}
```
**Why:** Window styling is structural configuration, isolated in dedicated file.

### 3. Color Pattern Routing (PlatformColor.swift)
```swift
static var windowBackground: Color {
    #if os(iOS)
    return iosWindowBackground
    #else
    return macOSWindowBackground
    #endif
}
```
**Why:** Routes to platform-specific implementations defined in respective folders.

## Benefits

### Clean Separation
- Shared code contains no platform-specific behavior
- Easy to see what's platform-specific (it's in the platform folder!)
- No scattered `#if os()` checks throughout codebase

### Testability
- Can mock platform adapters for testing
- Platform-specific code can be unit tested independently
- Shared code tests work on both platforms

### Maintainability
- Adding platform-specific features: create extension in platform folder
- Modifying platform behavior: edit only platform-specific file
- Shared logic changes affect both platforms automatically

### Scalability
- Easy to add new platforms (tvOS, watchOS, visionOS)
- Each platform maintains its own implementations
- No risk of breaking one platform when modifying another

## File Inventory

### Platform-Specific Files Created

**iOS:**
- `Sources/iOS/App/AppViewModelExtension.swift` - Modal logic
- `Sources/iOS/App/AppRootViewExtension.swift` - Sheet modifier
- `Sources/iOS/App/EnableExtensionViews.swift` - Modal views
- `Sources/iOS/App/PlatformConfiguration.swift` - Adapter, state checker, colors
- `Sources/iOS/ContentBlocker/*` - Content blocker for state detection

**macOS:**
- `Sources/macOS/App/AppViewModelExtension.swift` - Stubs for iOS-only methods
- `Sources/macOS/App/AppRootViewExtension.swift` - No-op modifier
- `Sources/macOS/App/PlatformConfiguration.swift` - Adapter, state checker, colors

**Shared Infrastructure:**
- `Sources/Shared/App/WindowConfiguration.swift` - Window styling encapsulation
- `Sources/Shared/App/PlatformAdapter.swift` - Protocol definition
- `Sources/Shared/App/PlatformColor.swift` - Color routing

### Modified Shared Files

- `Sources/Shared/App/AppViewModel.swift` - Removed `#if os()` from behavior
- `Sources/Shared/App/AppViews.swift` - Removed platform-specific modal code
- `Sources/Shared/App/SkipAIApp.swift` - Uses window configuration extension

## Extension State Detection

### iOS Approach (Hybrid)
Uses content blocker + timestamp tracking:

**Primary: Content Blocker API**
1. Minimal content blocker with dummy rule
2. `SFContentBlockerManager` checks if content blocker enabled
3. Content blocker and web extension share same Settings toggle
4. **Benefits:** Instant detection, official API

**Secondary: Timestamp Tracking**
1. Extension updates timestamp via `SafariWebExtensionHandler`
2. App checks timestamp freshness (5-minute window)
3. Validates extension is actively running
4. **Benefits:** Runtime validation, display mode sync

**Decision Logic:**
- Content blocker enabled → ✅ Enabled (instant, trust API)
- Content blocker disabled → ❌ Disabled (instant detection)
- Content blocker error → 🔄 Fallback to timestamp
- First launch → ✅ Works (trusts content blocker API)

**Implementation:**
- `ContentBlockerStateChecker` - Hybrid detection logic
- `ExtensionCommunicator` - Timestamp and settings sync

### macOS Approach
Uses `SFSafariExtensionManager` API directly:
1. Official API for web extension state
2. Can directly query web extension status
3. No content blocker needed
4. **Benefits:** Direct, straightforward

Both implementations live in their respective `PlatformConfiguration.swift` files.

## Adding New Platform-Specific Features

### iOS-Only Feature

1. Add implementation to `Sources/iOS/App/AppViewModelExtension.swift`
2. Add stub to `Sources/macOS/App/AppViewModelExtension.swift`
3. Call from shared code (method exists on both platforms)

### macOS-Only Feature

1. Add implementation to `Sources/macOS/App/AppViewModelExtension.swift`
2. Add stub to `Sources/iOS/App/AppViewModelExtension.swift`
3. Call from shared code (method exists on both platforms)

### UI Feature

1. Create view in platform-specific folder
2. Add extension method to show it (e.g., `withPlatformSheet()`)
3. Call extension from shared view

## Best Practices

### ✅ Do
- Put platform-specific behavior in platform folders
- Use protocol-based adapters for platform differences
- Use extension methods to add platform features
- Encapsulate `#if os()` in dedicated infrastructure files

### ❌ Don't
- Scatter `#if os()` throughout shared business logic
- Duplicate shared code in platform folders
- Use `#if os()` for behavioral differences (use protocol instead)
- Put iOS code in Shared folder (even with `#if os()`)

## References

- Platform Adapter Pattern: `Sources/Shared/App/PlatformAdapter.swift`
- Extension Method Pattern: `Sources/iOS/App/*Extension.swift`
- Content Blocker Approach: `CONTENT_BLOCKER_SETUP.md`


