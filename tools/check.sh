#!/usr/bin/env bash
# Compiles the port's GDScript files and prints only the errors.
#
#   tools/check.sh                 # everything under src/, scenes/ and tools/
#   tools/check.sh src/battle      # only some folders/files
#
# Refreshes Godot's global class cache (an editor --import pass) first so new
# class_name scripts are known. A lock directory serializes concurrent runs.
set -u
PROJ="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-/c/Users/c06ks/Work/Godot/Godot_v4.7-stable_win64_console.exe}"
LOCK="$PROJ/.godot/check.lock"
mkdir -p "$PROJ/.godot"
for i in $(seq 1 600); do
  if mkdir "$LOCK" 2>/dev/null; then break; fi
  sleep 1
done
trap 'rmdir "$LOCK" 2>/dev/null' EXIT

"$GODOT" --headless --path "$PROJ" --import > /dev/null 2>&1
"$GODOT" --headless --path "$PROJ" --script res://tools/check_all.gd -- "$@" 2>&1 \
  | grep -v "^Godot Engine\|^$\|resource_format_text\|resource_loader.cpp" \
  | sed -E 's/\x1b\[[0-9;]*m//g' \
  | grep -E "ERROR|SCRIPT ERROR|Parse Error|FAILED|CHECKED|at: |WARNING: .*\.gd" \
  | grep -v "^   at: (load|_load|load_resource|_reload_from_file|reload|GDScript::reload)" \
  | head -${MAXLINES:-200}
