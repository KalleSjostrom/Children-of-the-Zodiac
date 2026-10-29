#!/usr/bin/env bash
# Coverage probe (docs/CONVERTING_UI.md section 1): runs parity cases headless
# from a copy of the project that has temporary "[cov] f=<frame> <kind> ..."
# prints in the draws you probe and in AutoPlay's shot, and keeps each case's
# log. tools/parity/probe_report.py then tells per shot what it shows.
#
#   tools/parity/probe.sh <project copy> <out dir> [--jobs=<n>] [case...]
#
# Cases are those of the copy's tools/parity/cases.txt (all of them, extra
# ones too, when none are named; a name may be a pattern). Each run gets the
# parity runs' options (--fixed-fps 60, --mute --seed=1 --uncapped) and its
# own user data folder per job. Headless: no screenshots are written (the
# shot lines and their frames are what counts).
set -u
PROJ="$1"; OUTD="$2"; shift 2
GODOT="${GODOT:-/c/Users/c06ks/Work/Godot/Godot_v4.7-stable_win64_console.exe}"
JOBS=4
want=()
for a in "$@"; do
  case "$a" in
    --jobs=*) JOBS="${a#--jobs=}" ;;
    *) want+=("$a") ;;
  esac
done
mkdir -p "$OUTD"
lines=()
while IFS= read -r line; do
  line="${line%$'\r'}"
  [[ -z "${line// }" || "$line" == \#* ]] && continue
  name="${line%% *}"
  if [ ${#want[@]} -eq 0 ]; then lines+=("$line"); continue; fi
  for w in "${want[@]}"; do if [[ "$name" == $w ]]; then lines+=("$line"); break; fi; done
done < "$PROJ/tools/parity/cases.txt"

run_case() {
  local line="$1" appdata="$2"
  line="${line%%# extra*}"
  local -a words; eval "words=($line)"
  local name="${words[0]}" script="${words[1]}"
  local -a game_args=("${words[@]:2}")
  (cd "$PROJ" && export APPDATA="$appdata" && timeout 900 "$GODOT" --headless --path "$PROJ" \
    --fixed-fps 60 -- --mute --seed=1 --uncapped "${game_args[@]}" \
    --autoplay="tools/autoplay/$script.txt") < /dev/null > "$OUTD/$name.log" 2>&1
  echo "$name: exit $?"
}

queue="$OUTD/.queue"; rm -rf "$queue"; mkdir -p "$queue"; echo 0 > "$queue/next"
for ((k = 0; k < JOBS; k++)); do
  (
    appdata="$(cygpath -w "$OUTD/.userdata/job$k" 2>/dev/null || echo "$OUTD/.userdata/job$k")"
    mkdir -p "$OUTD/.userdata/job$k"
    while true; do
      until mkdir "$queue/lock" 2>/dev/null; do sleep 0.1; done
      i=$(cat "$queue/next"); echo $((i + 1)) > "$queue/next"; rmdir "$queue/lock"
      [ "$i" -ge ${#lines[@]} ] && break
      run_case "${lines[$i]}" "$appdata"
    done
  ) &
done
wait
rm -rf "$queue"
