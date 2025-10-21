#!/bin/bash

# Build JS for Xcode
# This script runs during Xcode builds to ensure JS is compiled
# It's skipped when building via Makefile (which handles JS separately)

# Check if we should skip (when building from Makefile)
if [ "$SKIP_JS_BUILD" = "1" ]; then
    echo "Skipping JS build (SKIP_JS_BUILD=1)"
    exit 0
fi

# Determine configuration
CONFIGURATION="${CONFIGURATION:-Debug}"
echo "Building JS for configuration: $CONFIGURATION"

# Navigate to project root
cd "$SRCROOT" || exit 1

# Check if pnpm is available
if ! command -v pnpm &> /dev/null; then
    echo "Error: pnpm not found. Install with: npm install -g pnpm"
    exit 1
fi

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "Installing JS dependencies..."
    pnpm install
fi

# Build based on configuration
case "$CONFIGURATION" in
    "Release")
        echo "Building JS (Release)..."
        pnpm run build:release
        ;;
    "Preview")
        echo "Building JS (Preview)..."
        pnpm run build:preview
        ;;
    *)
        echo "Building JS (Debug)..."
        pnpm run build:debug
        ;;
esac

echo "JS build complete"

