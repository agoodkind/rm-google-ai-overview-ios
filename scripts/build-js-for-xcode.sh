#!/bin/bash
#
#  build-js-for-xcode.sh
#  Skip AI
#
#  Copyright © 2025 Alexander Goodkind. All rights reserved.
#  https://goodkind.io/
#

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

# Map LOG_VERBOSITY (from xcconfig) to LOGGING_VERBOSITY (for JavaScript build)
if [ -n "$LOG_VERBOSITY" ]; then
    export LOGGING_VERBOSITY="$LOG_VERBOSITY"
    echo "Using LOG_VERBOSITY from xcconfig: $LOG_VERBOSITY"
fi

# Set default LOGGING_VERBOSITY based on configuration if not set
if [ -z "$LOGGING_VERBOSITY" ]; then
    case "$CONFIGURATION" in
        "Release")
            export LOGGING_VERBOSITY=2
            ;;
        "Preview")
            export LOGGING_VERBOSITY=3
            ;;
        *)
            export LOGGING_VERBOSITY=5
            ;;
    esac
fi

echo "LOGGING_VERBOSITY: $LOGGING_VERBOSITY"

# Navigate to project root
cd "$SRCROOT" || exit 1

# Build using make based on configuration
case "$CONFIGURATION" in
    "Release")
        echo "Building JS (Release)..."
        LOGGING_VERBOSITY=$LOGGING_VERBOSITY make build-js-release
        ;;
    "Preview")
        echo "Building JS (Preview)..."
        LOGGING_VERBOSITY=$LOGGING_VERBOSITY make build-js-preview
        ;;
    *)
        echo "Building JS (Debug)..."
        LOGGING_VERBOSITY=$LOGGING_VERBOSITY make build-js-debug
        ;;
esac

echo "JS build complete"

