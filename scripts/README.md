# Xcode Project Management Scripts

## 🏆 Best Options

Choose based on your preferences:

### 1. **Swift + XcodeProj** (Most Type-Safe) ⭐️

**Recommended if you want compile-time safety and native Swift**

- ✅ Full type safety with Swift
- ✅ Clean API - no string matching
- ✅ Compiles to fast binary
- ✅ Native to Xcode ecosystem

[See Swift README](./README-swift.md)

```bash
cd scripts
swift build
swift run add-xcode-targets
```

### 2. **Ruby + xcodeproj** (Most Mature)

**Recommended if you prefer Ruby or need maximum stability**

- ✅ Battle-tested library
- ✅ Used by CocoaPods
- ✅ Excellent documentation
- ✅ Quick to run

```bash
ruby scripts/add-xcode-targets.rb
```

---

## Ruby Script (add-xcode-targets.rb)

Clean, maintainable approach using the `xcodeproj` gem.

### Prerequisites
```bash
gem install xcodeproj
```

### Usage
```bash
ruby scripts/add-xcode-targets.rb
```

### Configuration

All settings are at the top of the file:

```ruby
PROJECT_PATH = 'Skip AI.xcodeproj'

GROUPS = [
  {
    id: 'app',                    # Internal identifier
    name: 'app',                  # Group name in Xcode
    path: 'dist/app',             # Directory path
    file_patterns: ['*.js', '*.css'],  # Files to include
    targets: ['Skip AI (iOS)', 'Skip AI (macOS)']  # Target names
  },
  {
    id: 'webext',
    name: 'webext',
    path: 'dist/webext',
    file_patterns: ['*.js'],
    targets: ['Skip AI Extension (iOS)', 'Skip AI Extension (macOS)']
  }
]
```

### Adding New Groups

Simply add a new hash to the `GROUPS` array:

```ruby
{
  id: 'my_new_group',
  name: 'MyGroup',
  path: 'path/to/files',
  file_patterns: ['*.swift', '*.h'],
  targets: ['Target1', 'Target2']
}
```

### Features

- ✅ **Idempotent**: Run multiple times without issues
- ✅ **Generic**: Works with any folder and file patterns
- ✅ **Type-safe**: Uses proper Xcode API via xcodeproj gem
- ✅ **Automatic cleanup**: Removes old references before adding new ones
- ✅ **Backup creation**: Creates backup before modifications
- ✅ **Handles missing dirs**: Gracefully skips non-existent directories
- ✅ **Clear output**: Shows exactly what's happening

### How It Works

1. **Cleanup**: Removes existing group references from project
2. **Create Groups**: Creates PBXGroup entries for each configured group
3. **Find Files**: Scans directories for files matching patterns
4. **Add References**: Creates PBXFileReference for each file
5. **Link to Targets**: Adds files to Resources build phase of specified targets
6. **Save**: Writes updated project file

### Why Ruby over Bash?

| Feature | Ruby (xcodeproj) | Bash (manual) |
|---------|------------------|---------------|
| Maintainability | ✅ High | ❌ Low |
| Type Safety | ✅ Yes | ❌ No |
| Error Handling | ✅ Excellent | ⚠️ Limited |
| Xcode API | ✅ Native | ❌ Manual parsing |
| Complexity | ✅ Low | ❌ High |
| Edge Cases | ✅ Handled | ⚠️ Manual |

---

## Legacy: Bash Script (add-xcode-targets.sh)

**Deprecated.** Kept for reference only.

Manual pbxproj manipulation using sed/awk/perl. Works but harder to maintain.

### Issues with Bash Approach

- Complex regex patterns for pbxproj structure
- Platform-specific sed syntax (macOS vs Linux)
- Fragile when Xcode format changes
- Hard to debug
- Manual UUID generation
- No validation

### When to Use Bash Version

- Cannot install Ruby gems
- Need to understand exact pbxproj structure
- Educational purposes

---

## Troubleshooting

### xcodeproj gem not found
```bash
gem install xcodeproj
# Or with rbenv:
rbenv exec gem install xcodeproj
```

### Target not found
Check target names in Xcode match exactly:
- Product → Scheme → Manage Schemes
- Or check project.pbxproj for target names

### Files not appearing
Ensure:
1. Directory exists
2. File patterns match
3. Files aren't in .gitignore
4. Run `ls -la dist/app` to verify files exist

### Permission errors
```bash
chmod +x scripts/add-xcode-targets.rb
```

---

## Development

### Testing Changes

```bash
# Test with current project
ruby scripts/add-xcode-targets.rb

# Test with missing directories
mv dist dist.bak
ruby scripts/add-xcode-targets.rb
mv dist.bak dist

# Test idempotency
ruby scripts/add-xcode-targets.rb
ruby scripts/add-xcode-targets.rb
```

### Adding Debug Output

Add to script:
```ruby
puts "DEBUG: #{variable.inspect}"
```

### Understanding xcodeproj

Documentation: https://www.rubydoc.info/gems/xcodeproj

Key classes:
- `Xcodeproj::Project` - Main project interface
- `PBXGroup` - Folder groups
- `PBXFileReference` - File references
- `PBXNativeTarget` - Build targets
- `PBXResourcesBuildPhase` - Resources phase

---

## Quick Comparison

| Feature | Swift + XcodeProj | Ruby + xcodeproj | Bash (deprecated) |
|---------|-------------------|------------------|-------------------|
| **Type Safety** | ✅ Full (compile-time) | ⚠️ Partial (runtime) | ❌ None |
| **API Quality** | ✅ Clean objects | ✅ Clean objects | ❌ String parsing |
| **Speed** | ✅ Fast (<0.1s compiled) | ✅ Fast (~0.5s) | ⚠️ Medium |
| **Setup** | Swift Package Manager | gem install | None |
| **Maintainability** | ✅ Excellent | ✅ Excellent | ❌ Fragile |
| **Platform** | macOS only | Any platform | Any platform |
| **Ecosystem** | Native Apple | CocoaPods/Ruby | Unix tools |

**Recommendation**: 
- **Swift** if you want type safety and are building on macOS
- **Ruby** if you need cross-platform or prefer Ruby
- **Bash** only for reference (deprecated)

