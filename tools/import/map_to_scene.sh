#!/usr/bin/env bash
# Converts dungeon floors to scenes (tools/import/map_to_scene.gd), then runs
# Godot's import (the new resources and the textures' changed .import
# settings). Run from bash in the project root:
#
#   tools/import/map_to_scene.sh "Forest of Reil--Forest Path" "The Great Mine--Tunnel"
#
# Extra options (--data-only, --out=<dir>, --all) are passed on; with
# --data-only the import is skipped.
set -u
PROJ="$(cd "$(dirname "$0")/../.." && pwd)"
GODOT="${GODOT:-/c/Users/c06ks/Work/Godot/Godot_v4.7-stable_win64_console.exe}"
# J.parseInt's own error reports (with their backtraces) are left out: the
# converter names such tokens in a warning with the file and line.
"$GODOT" --headless --path "$PROJ" --script res://tools/import/map_to_scene.gd -- "$@" < /dev/null 2>&1 \
  | grep -v "^Godot Engine\|^$" \
  | grep -Ev "^ERROR: J\.parse(Int|Float): not an? |^   at: push_error|^   GDScript backtrace|^       \[[0-9]+\] "
code=${PIPESTATUS[0]}
if [[ " $* " != *" --data-only "* ]]; then
  "$GODOT" --headless --path "$PROJ" --import < /dev/null > /dev/null 2>&1
fi
exit $code
