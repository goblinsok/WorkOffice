#!/bin/sh
# Headless checks: the import (script/resource errors) and the smoke test.
# Usage: Tools/verify.sh [import|smoke]   (no argument: both)
# A fixed entry point, so .claude/settings.json can allowlist it. Exit code: the smoke test's
# failure count (124 if Godot hung, e.g. on a parse error in the test script).

GODOT="${GODOT:-D:/MyGame/Godot_v4.5.1/Godot_v4.5.1-stable_win64_console.exe}"
cd "$(dirname "$0")/.." || exit 1
mode="${1:-all}"
status=0

if [ "$mode" = "import" ] || [ "$mode" = "all" ]; then
	problems=$(timeout 300 "$GODOT" --headless --path . --import 2>&1 | grep -iE "error|warning")
	if [ -n "$problems" ]; then
		echo "$problems"
		status=1
	else
		echo "import: no errors"
	fi
fi

if [ "$mode" = "smoke" ] || [ "$mode" = "all" ]; then
	log=$(mktemp)
	timeout 300 "$GODOT" --headless --path . res://Tests/smoke_test.tscn > "$log" 2>&1
	status=$?
	# Section headers, failures, errors and the RESULT line; passing checks are left out.
	grep -vE "^\s+ok |^Godot Engine|^\s*$" "$log"
	[ "$status" -eq 124 ] && echo "smoke test timed out (parse error in the test script?)"
	rm -f "$log"
fi

exit $status
