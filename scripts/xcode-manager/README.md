# Xcode Manager CLI

Command-line tool for managing the Skip AI Xcode project.

## Installation

```bash
cd scripts/xcode-manager
swift build
```

## Configuration

The tool automatically finds your Xcode project using the following order:

1. Environment variable: `XCODE_PROJECT_PATH`
2. Configuration file: `.env` in project root
3. Configuration file: `.env.local` in project root
4. Configuration file: `.xcodemanager` in project root
5. Configuration file: `~/.xcodemanager` in home directory
6. Git repository root: searches for .xcodeproj in `git rev-parse --show-toplevel`
7. Upward search: searches current directory and parent directories for .xcodeproj
8. Default: `Skip AI.xcodeproj`

This means you can run the tool from anywhere within your git repository and it will find the project automatically.

### Automatic Detection

The tool will automatically find your project if you run it from anywhere within the git repository:

```bash
cd /Users/you/Projects/skip-ai
swift run --package-path scripts/xcode-manager xcode-manager show-version

cd /Users/you/Projects/skip-ai/Sources/Shared/App
swift run --package-path ../../scripts/xcode-manager xcode-manager show-version
```

Both commands will find the project automatically.

### Using Environment Variable

```bash
export XCODE_PROJECT_PATH="Skip AI.xcodeproj"
swift run xcode-manager show-version

# Or specify project name for git detection
export XCODE_PROJECT_NAME="Skip AI.xcodeproj"
swift run xcode-manager show-version
```

### Using .env File

Add to your `.env` or `.env.local` file:

```bash
# Path to the Xcode project file
XCODE_PROJECT_PATH=Skip AI.xcodeproj
```

The tool supports quoted and unquoted values:

```bash
XCODE_PROJECT_PATH="Skip AI.xcodeproj"
XCODE_PROJECT_PATH='Skip AI.xcodeproj'
XCODE_PROJECT_PATH=Skip AI.xcodeproj
```

### Using .xcodemanager File

Create `.xcodemanager` in your project root:

```bash
# Path to the Xcode project file
XCODE_PROJECT_PATH=Skip AI.xcodeproj
```

Or create `~/.xcodemanager` for global configuration:

```bash
cp scripts/xcode-manager/.xcodemanager.example ~/.xcodemanager
# Edit ~/.xcodemanager with your project path
```

## Commands

### Show Version

Display current version and build numbers:

```bash
swift run xcode-manager
# or
swift run xcode-manager show-version
```

### Sync Groups

Sync file groups (like dist/webext) to Xcode targets:

```bash
swift run xcode-manager sync-groups
swift run xcode-manager sync-groups --no-backup  # Skip backup
```

### Bump Version

Increment version numbers across all targets:

```bash
# Bump major version (2.0.0 → 3.0.0)
swift run xcode-manager bump-version --major

# Bump minor version (2.0.0 → 2.1.0)
swift run xcode-manager bump-version --minor

# Bump patch version (2.0.0 → 2.0.1)
swift run xcode-manager bump-version --patch

# Bump build number only
swift run xcode-manager bump-version --build

# Set specific version
swift run xcode-manager bump-version --set-version 3.1.0

# Set specific build number
swift run xcode-manager bump-version --set-build 250

# Skip backup
swift run xcode-manager bump-version --patch --no-backup
```

### Fix Info.plist

Add required keys to Info.plist files (CFBundleExecutable, CFBundleIdentifier, etc.):

```bash
# Preview changes without modifying files
swift run xcode-manager fix-infoplist --dry-run

# Apply fixes
swift run xcode-manager fix-infoplist
```

### Add Build Script

Add a build phase to extension targets that automatically compiles JavaScript:

```bash
# Add JS build phase to both extension targets
swift run xcode-manager add-build-script

# Remove the build phase
swift run xcode-manager add-build-script --remove
```

**How it works:**
- Adds a build phase before "Embed Foundation Extensions"
- Runs `scripts/build-js-for-xcode.sh` which builds JS based on configuration
- Skips when `SKIP_JS_BUILD=1` env var is set (automatic when using Makefile)
- Allows building from Xcode UI without running Makefile commands

## Building Release Binary

For faster execution, build a release binary:

```bash
swift build -c release
.build/release/xcode-manager --help
```

## Common Workflows

### Initial Project Setup

```bash
# Add JS build phase to enable Xcode-only builds
swift run xcode-manager add-build-script

# Fix Info.plist files
swift run xcode-manager fix-infoplist
```

### Before Release

```bash
# Bump version and fix plists
swift run xcode-manager bump-version --minor
swift run xcode-manager fix-infoplist
```

### After Updating dist/webext

```bash
# Sync new JavaScript files to extension targets
swift run xcode-manager sync-groups
```

### Building from Xcode UI

After running `make add-build-script`, you can build directly from Xcode:
- JS will be compiled automatically based on the selected configuration
- No need to run Makefile commands first
- Makefile builds skip the JS build phase (already built via `make build-js-*`)

## Help

All commands support `--help`:

```bash
swift run xcode-manager --help
swift run xcode-manager bump-version --help
```

