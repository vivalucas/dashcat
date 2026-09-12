#!/bin/bash
set -euo pipefail
TASK_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TASK_BUILD="$(mktemp -d /tmp/dashcat-tests.XXXXXX)"
trap 'rm -rf "$TASK_BUILD"' EXIT
xcrun swiftc "$TASK_ROOT/DashCat/ClipboardManager.swift" "$TASK_ROOT/DashCat/ClipboardPanel.swift" "$TASK_ROOT/DashCat/AppDelegate.swift" "$TASK_ROOT/DashCat/SystemMonitor.swift" "$TASK_ROOT/DashCat/ScrollManager.swift" "$TASK_ROOT/Tests/ClipboardRegression.swift" -o "$TASK_BUILD/clipboard-regression"
"$TASK_BUILD/clipboard-regression"
