# Swift + XcodeProj Implementation

This is a **type-safe, clean** implementation using the XcodeProj library - no string matching or regex!

## Benefits

✅ **Type-safe** - Swift's strong typing catches errors at compile time  
✅ **Clean API** - Use proper Xcode objects, not string manipulation  
✅ **No regex** - Direct access to project structure  
✅ **Maintained** - XcodeProj is actively maintained by Tuist team  
✅ **Fast** - Compiled Swift binary

## Installation

```bash
cd scripts
swift build
```

This will download XcodeProj dependency and compile the tool.

## Usage

### Quick Run (from scripts directory)
```bash
cd scripts
swift run add-xcode-targets
```

### Build Release Binary (faster)
```bash
cd scripts
swift build -c release
.build/release/add-xcode-targets
```

### Run from Project Root
```bash
cd scripts && swift run add-xcode-targets && cd ..
```

## Configuration

Edit `Sources/main.swift`:

```swift
let GROUPS: [GroupConfig] = [
    GroupConfig(
        id: "app",
        name: "app",
        path: "../dist/app",
        filePatterns: ["js", "css"],  // File extensions (no dots)
        targets: ["Skip AI (iOS)", "Skip AI (macOS)"]
    ),
    // Add more groups...
]
```

## How It Works

### Without XcodeProj (messy)
```swift
// ❌ String matching nightmare
let pattern = "([A-F0-9]{24}).*?/\\*\\s*\(escapedName)\\s*\\*/"
let regex = try? NSRegularExpression(pattern: pattern)
// ... lots of fragile string manipulation
```

### With XcodeProj (clean)
```swift
// ✅ Type-safe API
let target = pbxproj.nativeTargets.first { $0.name == "MyTarget" }
let group = PBXGroup(name: "MyGroup", path: "dist/app")
pbxproj.add(object: group)
mainGroup.children.append(group)
```

## XcodeProj API Highlights

```swift
// Find targets (type-safe)
let target: PBXNativeTarget? = pbxproj.nativeTargets.first { 
    $0.name == "Skip AI (iOS)" 
}

// Create groups (no IDs to manage)
let group = PBXGroup(
    children: [],
    sourceTree: .group,
    name: "app",
    path: "dist/app"
)
pbxproj.add(object: group)

// Create file references
let fileRef = PBXFileReference(
    sourceTree: .group,
    name: "Script.js",
    path: "Script.js"
)
pbxproj.add(object: fileRef)
group.children.append(fileRef)

// Add to build phase
let buildFile = PBXBuildFile(file: fileRef)
pbxproj.add(object: buildFile)
resourcesPhase.files?.append(buildFile)

// Save (atomic write)
try project.write(path: projectPath)
```

## Comparison

| Feature | String Matching | XcodeProj |
|---------|----------------|-----------|
| Type Safety | ❌ None | ✅ Full |
| API Quality | ❌ DIY regex | ✅ Clean methods |
| Error Handling | ⚠️ Runtime crashes | ✅ Compile-time checks |
| Maintainability | ❌ Fragile | ✅ Robust |
| Speed | ⚠️ Slow (parsing) | ✅ Fast (structured) |
| Learning Curve | 😰 High | 😊 Low |

## Troubleshooting

### Build fails with "cannot find package 'XcodeProj'"
```bash
cd scripts
swift package resolve
swift build
```

### "No such file or directory" errors
Make sure you're running from the scripts directory, or adjust paths in config.

### Want to see what changed?
```bash
git diff "Skip AI.xcodeproj/project.pbxproj"
```

## Adding to Build Scripts

### Add to package.json
```json
{
  "scripts": {
    "xcode:update": "cd scripts && swift run add-xcode-targets"
  }
}
```

### Add to Xcode Run Script Phase
```bash
cd scripts
swift run -c release add-xcode-targets
```

## Why XcodeProj?

1. **Active Development** - Used by Tuist and maintained by the community
2. **Production Ready** - Powers tools like Tuist, XcodeGen
3. **Full Coverage** - Supports all Xcode project features
4. **Type Safe** - Catch errors at compile time
5. **Well Documented** - https://tuist.github.io/XcodeProj/

## Performance

```
Ruby xcodeproj:    ~0.5-1s (JIT compilation + Ruby overhead)
Swift interpreted: ~1-2s (swift run without build)
Swift compiled:    ~0.1s (.build/release/add-xcode-targets)
```

**Recommendation**: Build release binary for production use!

