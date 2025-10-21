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

# Build using make based on configuration
case "$CONFIGURATION" in
    "Release")
        echo "Building JS (Release)..."
        make build-js-release
        ;;
    "Preview")
        echo "Building JS (Preview)..."
        make build-js-preview
        ;;
    *)
        echo "Building JS (Debug)..."
        make build-js-debug
        ;;
esac

echo "JS build complete"

