#!/bin/bash
#
# attach-safari-extension.sh
# Finds Safari extension process and returns PID for LLDB attach
#

BUNDLE_ID="io.goodkind.SkipAI.Extension"
PLATFORM="${1:-macos}"  # macos or ios

echo "Searching for Safari extension process..." >&2
echo "Platform: $PLATFORM" >&2
echo "Bundle ID: $BUNDLE_ID" >&2
echo "" >&2

# Find the extension process PID
# Safari extensions run as separate processes with the bundle ID in their command line
PID=$(ps aux | grep "$BUNDLE_ID" | grep -v grep | grep -v "$0" | awk '{print $2}' | head -1)

if [ -z "$PID" ]; then
    echo "Error: Safari extension not running." >&2
    echo "" >&2
    echo "To start the extension:" >&2
    case "$PLATFORM" in
        "ios")
            echo "1. Run iOS app in simulator" >&2
            echo "2. Open Safari in simulator" >&2
            echo "3. Visit any webpage" >&2
            echo "4. Extension will load automatically" >&2
            ;;
        "macos")
            echo "1. Run macOS app" >&2
            echo "2. Open Safari" >&2
            echo "3. Enable extension in Safari → Settings → Extensions" >&2
            echo "4. Visit any webpage" >&2
            echo "5. Extension will load automatically" >&2
            ;;
    esac
    exit 1
fi

echo "Found extension process: PID $PID" >&2
echo "" >&2
echo "Use this PID to attach debugger in VS Code or Xcode" >&2
echo "$PID"

