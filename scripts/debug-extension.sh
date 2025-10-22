#!/bin/bash
#
# debug-extension.sh
# One-click Safari extension debugging with lldb
#

set -e

PLATFORM="${1:-macos}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🔍 Finding Safari extension process..."
PID=$("$SCRIPT_DIR/wait-and-attach-extension.sh" "$PLATFORM" 2>&1 | tail -1)

if ! [[ "$PID" =~ ^[0-9]+$ ]]; then
    echo "❌ Failed to find extension process"
    exit 1
fi

echo "✅ Found extension at PID: $PID"
echo ""
echo "🐛 Launching lldb..."
echo "   Set breakpoints, then type 'c' to continue"
echo "   Type 'help' for lldb commands"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Launch lldb and attach
lldb -p "$PID"

