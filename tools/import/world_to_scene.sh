#!/usr/bin/env bash
# Converts the world maps and the airship maps to scenes
# (tools/import/world_to_scene.gd): the art stage (stitched backgrounds),
# Godot's import of the new images, then the scenes and the place index. Run
# from bash in the project root:
#
#   tools/import/world_to_scene.sh --all
#   tools/import/world_to_scene.sh world0.map land1.map
set -u
PROJ="$(cd "$(dirname "$0")/../.." && pwd)"
GODOT="${GODOT:-/c/Users/c06ks/Work/Godot/Godot_v4.7-stable_win64_console.exe}"
# J.parseInt's own error report (with its backtrace) is left out: the
# converter names such tokens in a warning with the file and line.
run() {
  "$GODOT" --headless --path "$PROJ" --script res://tools/import/world_to_scene.gd -- "$@" < /dev/null 2>&1 \
    | grep -v "^Godot Engine\|^$" \
    | grep -Ev "^ERROR: J\.parseInt: not an int|^   at: push_error|^   GDScript backtrace|^       \[[0-9]+\] "
  return "${PIPESTATUS[0]}"
}
run --stage=art "$@" || exit 1
"$GODOT" --headless --path "$PROJ" --import < /dev/null > /dev/null 2>&1
run --stage=scenes "$@"
