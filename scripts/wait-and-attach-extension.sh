#!/bin/bash
#
# wait-and-attach-extension.sh
# Waits for Safari extension to start, then returns PID for LLDB
#

BUNDLE_ID="io.goodkind.SkipAI.Extension"
PLATFORM="${1:-macos}"
MAX_WAIT=30  # seconds

echo "Waiting for Safari extension to start..." >&2
echo "Platform: $PLATFORM" >&2
echo "Bundle ID: $BUNDLE_ID" >&2
echo "" >&2

for i in $(seq 1 $MAX_WAIT); do
    PID=$(ps aux | grep "$BUNDLE_ID" | grep -v grep | grep -v "$0" | awk '{print $2}' | head -1)
    
    if [ -n "$PID" ]; then
        echo "Found extension process: PID $PID" >&2
        echo "$PID"
        exit 0
    fi
    
    if [ $i -eq 1 ]; then
        echo "Extension not running yet. Make sure:" >&2
        case "$PLATFORM" in
            "ios")
                echo "1. iOS app is running in simulator" >&2
                echo "2. Safari is open in simulator" >&2
                echo "3. You visit a webpage" >&2
                ;;
            "macos")
                echo "1. macOS app is running" >&2
                echo "2. Safari is open" >&2
                echo "3. Extension is enabled in Safari Settings" >&2
                echo "4. You visit a webpage" >&2
                ;;
        esac
        echo "" >&2
        echo "Waiting up to $MAX_WAIT seconds..." >&2
    fi
    
    sleep 1
done

echo "" >&2
echo "Error: Extension did not start within $MAX_WAIT seconds" >&2
exit 1

