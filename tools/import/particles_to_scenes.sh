#!/usr/bin/env bash
# Generates the GPU particle systems (tools/import/particles_to_scenes.gd):
# the emission point images of the image shapes, Godot's import of them, then
# the scenes. Run from bash in the project root:
#
#   tools/import/particles_to_scenes.sh                 # every system
#   tools/import/particles_to_scenes.sh smokesystem     # some systems
#
# Extra options (--reset-tuning) are passed on. See docs/CONVERTING_PARTICLES.md.
set -u
PROJ="$(cd "$(dirname "$0")/../.." && pwd)"
GODOT="${GODOT:-/c/Users/c06ks/Work/Godot/Godot_v4.7-stable_win64_console.exe}"
run() {
  "$GODOT" --headless --path "$PROJ" --script res://tools/import/particles_to_scenes.gd -- "$@" < /dev/null 2>&1 \
    | grep -v "^Godot Engine\|^$"
}
run --stage=points "$@" | grep -v "^  " || exit 1
"$GODOT" --headless --path "$PROJ" --import < /dev/null > /dev/null 2>&1
run --stage=scenes "$@"
