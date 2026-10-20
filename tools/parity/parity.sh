#!/usr/bin/env bash
# Screenshot parity: run AutoPlay scripts deterministically and compare shots.
#
#   tools/parity/parity.sh record <set> [options] [case...]
#       Runs the cases (all non-extra cases of cases.txt when none are named)
#       and keeps their shots in tools/parity/out/<set>/<case>/ and the game
#       output in tools/parity/out/<set>/<case>.log.
#   tools/parity/parity.sh compare <set_a> <set_b> [options] [case...]
#       Compares two recorded sets: the shots (tools/parity/diff_shots.gd) and
#       the AutoPlay log lines (game mode/place at every log/shot, fps removed).
#       Writes tools/parity/out/diff-<set_a>-vs-<set_b>/ (*.diff.png,
#       summary.txt). Exit code 0 = everything passed.
#   tools/parity/parity.sh ab "<args_a>" "<args_b>" [options] [case...]
#       Records set <name>-a with args_a and <name>-b with args_b added to the
#       game arguments, then compares them. Example (once a subsystem has a
#       scene path): tools/parity/parity.sh ab "--legacy=villages" "" village
#
# Options:
#   --args="<game args>"   extra game arguments for record (e.g. --legacy=villages)
#   --seed=<n>             random seed (default 1)
#   --tolerance=<0-255>    per channel difference that is ignored (default 0)
#   --max-pixels=<n>       pixels over the tolerance a shot may have (default 0)
#   --name=<name>          set name prefix for ab (default ab)
#   --timeout=<s>          per run (default 900)
#   --ignore-world         compare the logs without AutoPlay's "world=<scene>"
#                          (legacy vs. scene runs: only a scene run shows one)
#
# Every run gets the engine option --fixed-fps 60 (a fixed delta for nodes,
# timers and tweens) and the game options --mute --seed=<n> --uncapped (see
# src/main/Main.gd and docs/ARCHITECTURE.md). Runs open a window: screenshots
# need a renderer, so do not use --headless.
set -u
PROJ="$(cd "$(dirname "$0")/../.." && pwd)"
GODOT="${GODOT:-/c/Users/c06ks/Work/Godot/Godot_v4.7-stable_win64_console.exe}"
OUT_REL="tools/parity/out"
OUT="$PROJ/$OUT_REL"
CASES="$PROJ/tools/parity/cases.txt"

SEED=1
TOLERANCE=0
MAX_PIXELS=0
NAME=ab
TIMEOUT=900
IGNORE_WORLD=0
EXTRA_ARGS=""
POS=()
for a in "$@"; do
  case "$a" in
    --args=*) EXTRA_ARGS="${a#--args=}" ;;
    --seed=*) SEED="${a#--seed=}" ;;
    --tolerance=*) TOLERANCE="${a#--tolerance=}" ;;
    --max-pixels=*) MAX_PIXELS="${a#--max-pixels=}" ;;
    --name=*) NAME="${a#--name=}" ;;
    --timeout=*) TIMEOUT="${a#--timeout=}" ;;
    --ignore-world) IGNORE_WORLD=1 ;;
    *) POS+=("$a") ;;
  esac
done

mkdir -p "$OUT"
touch "$OUT/.gdignore" # keep Godot from importing the shots

# Prints "<case> <script> <args...>" lines of the selected cases.
select_cases() {
  local want=("$@")
  while IFS= read -r line; do
    line="${line%$'\r'}"
    [[ -z "${line// }" || "$line" == \#* ]] && continue
    local name="${line%% *}"
    if [ ${#want[@]} -eq 0 ]; then
      [[ "$line" == *"# extra"* ]] && continue
      echo "$line"
    else
      for w in "${want[@]}"; do
        [ "$w" == "$name" ] && echo "$line"
      done
    fi
  done < "$CASES"
}

record() {
  local set="$1"; shift
  local lines
  lines="$(select_cases "$@")"
  if [ -z "$lines" ]; then echo "no such case: $*" >&2; return 2; fi
  while IFS= read -r line; do
    line="${line%%# extra*}"
    local -a words
    eval "words=($line)"
    local name="${words[0]}" script="${words[1]}"
    local -a game_args=("${words[@]:2}")
    local -a extra=()
    [ -n "$EXTRA_ARGS" ] && eval "extra=($EXTRA_ARGS)"
    local shots="$OUT_REL/$set/$name"
    rm -rf "$PROJ/$shots"
    mkdir -p "$PROJ/$shots"
    local log="$OUT/$set/$name.log"
    local start=$SECONDS
    echo "== record $set/$name: ${game_args[*]} ${extra[*]}"
    (cd "$PROJ" && timeout "$TIMEOUT" "$GODOT" --path "$PROJ" --fixed-fps 60 -- --mute --seed="$SEED" --uncapped \
      "${game_args[@]}" "${extra[@]}" --autoplay="tools/autoplay/$script.txt" --shots="$shots") \
      < /dev/null > "$log" 2>&1
    local code=$?
    local nshots errors
    nshots=$(ls "$PROJ/$shots" | grep -c '\.png$')
    # Errors during the run (the leak reports at exit are not counted).
    errors=$(grep -E "^(SCRIPT )?ERROR" "$log" | grep -cv "leaked at exit\|still in use at exit")
    echo "   exit $code, $((SECONDS - start)) s, $nshots shots, $errors errors ($OUT_REL/$set/$name.log)"
  done <<< "$lines"
}

# AutoPlay lines of a log without the fps value and the shot directory (and
# without world=<scene> with --ignore-world).
log_states() {
  local world='s/^//'
  [ "$IGNORE_WORLD" -eq 1 ] && world='s/ world=.* place=/ place=/'
  tr -d '\r' < "$1" | grep '^\[autoplay' | sed -E 's/ fps=[0-9]+//; s#screenshot .*/#screenshot #' | sed -E "$world"
}

compare() {
  local a="$1" b="$2"; shift 2
  local diff_rel="$OUT_REL/diff-$a-vs-$b"
  rm -rf "$PROJ/$diff_rel"
  mkdir -p "$PROJ/$diff_rel"
  local dir_a="$OUT_REL/$a" dir_b="$OUT_REL/$b"
  if [ $# -gt 0 ]; then
    # Compare only the named cases: link them into temporary roots.
    dir_a="$diff_rel/.a"; dir_b="$diff_rel/.b"
    mkdir -p "$PROJ/$dir_a" "$PROJ/$dir_b"
    for c in "$@"; do
      [ -d "$OUT/$a/$c" ] && cp -r "$OUT/$a/$c" "$PROJ/$dir_a/"
      [ -d "$OUT/$b/$c" ] && cp -r "$OUT/$b/$c" "$PROJ/$dir_b/"
    done
  fi
  (cd "$PROJ" && "$GODOT" --headless --path "$PROJ" --script res://tools/parity/diff_shots.gd -- \
    "$dir_a" "$dir_b" "$diff_rel" --tolerance="$TOLERANCE" --max-pixels="$MAX_PIXELS") < /dev/null 2>&1 \
    | grep -E "^(A|B|tolerance|PASS|FAIL|RESULT)" | tee "$OUT/.diff_output"
  local shots_ok=1
  grep -q "^RESULT PASS" "$OUT/.diff_output" || shots_ok=0
  rm -rf "$PROJ/$diff_rel/.a" "$PROJ/$diff_rel/.b" "$OUT/.diff_output"
  local logs_ok=1
  local -a names=("$@")
  if [ ${#names[@]} -eq 0 ]; then
    for l in "$OUT/$a"/*.log; do names+=("$(basename "$l" .log)"); done
  fi
  for c in "${names[@]}"; do
    local la="$OUT/$a/$c.log" lb="$OUT/$b/$c.log"
    if [ ! -f "$la" ] || [ ! -f "$lb" ]; then
      echo "LOG FAIL $c: log missing" | tee -a "$PROJ/$diff_rel/summary.txt"; logs_ok=0; continue
    fi
    if diff <(log_states "$la") <(log_states "$lb") > "$PROJ/$diff_rel/$c.log.diff"; then
      echo "LOG PASS $c" | tee -a "$PROJ/$diff_rel/summary.txt"
      rm -f "$PROJ/$diff_rel/$c.log.diff"
    else
      echo "LOG FAIL $c: autoplay states differ ($diff_rel/$c.log.diff)" | tee -a "$PROJ/$diff_rel/summary.txt"
      logs_ok=0
    fi
  done
  if [ $shots_ok -eq 1 ] && [ $logs_ok -eq 1 ]; then
    echo "PARITY PASS ($diff_rel)"; return 0
  fi
  echo "PARITY FAIL ($diff_rel)"; return 1
}

case "${POS[0]:-}" in
  record)
    [ ${#POS[@]} -ge 2 ] || { echo "usage: parity.sh record <set> [case...]" >&2; exit 2; }
    record "${POS[1]}" "${POS[@]:2}"
    ;;
  compare)
    [ ${#POS[@]} -ge 3 ] || { echo "usage: parity.sh compare <set_a> <set_b> [case...]" >&2; exit 2; }
    compare "${POS[1]}" "${POS[2]}" "${POS[@]:3}"
    ;;
  ab)
    [ ${#POS[@]} -ge 3 ] || { echo "usage: parity.sh ab <args_a> <args_b> [case...]" >&2; exit 2; }
    EXTRA_ARGS="${POS[1]}"
    record "$NAME-a" "${POS[@]:3}"
    EXTRA_ARGS="${POS[2]}"
    record "$NAME-b" "${POS[@]:3}"
    compare "$NAME-a" "$NAME-b" "${POS[@]:3}"
    ;;
  *)
    sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
    exit 2
    ;;
esac
