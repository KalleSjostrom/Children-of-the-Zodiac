"""Coverage probe report (docs/CONVERTING_UI.md section 1).

usage: python -I probe_report.py <probe out dir> [kind ...]

Reads the logs of tools/parity/probe.sh: the temporary "[cov] f=<frame> shot
<name>" lines of AutoPlay's shot and the "[cov] f=<frame> <kind> <state>"
lines of the probed draws. A shot taken in frame F shows what frame F - 1
drew, so for each kind it prints the shots that show it, with that frame's
state lines, and the cases that drew it in no shot.
"""
import os
import re
import sys
from collections import defaultdict


def main():
    out_dir = sys.argv[1]
    kinds = set(sys.argv[2:])
    line_re = re.compile(r"^\[cov\] f=(\d+) (\S+)(.*)$")
    shown = defaultdict(list)  # kind -> [(case, shot, state)]
    drawn = defaultdict(set)  # kind -> cases that drew it at all
    for name in sorted(os.listdir(out_dir)):
        if not name.endswith(".log"):
            continue
        case = name[:-4]
        by_frame = defaultdict(list)
        shots = []
        with open(os.path.join(out_dir, name), encoding="utf-8", errors="replace") as f:
            for raw in f:
                m = line_re.match(raw.rstrip("\n"))
                if not m:
                    continue
                frame, kind, state = int(m.group(1)), m.group(2), m.group(3).strip()
                if kind == "shot":
                    shots.append((frame, state))
                else:
                    by_frame[frame].append((kind, state))
                    drawn[kind].add(case)
        for frame, shot in shots:
            for kind, state in by_frame.get(frame - 1, []):
                shown[kind].append((case, shot, state))
    for kind in sorted(drawn):
        if kinds and kind not in kinds:
            continue
        entries = shown.get(kind, [])
        cases = {c for c, _, _ in entries}
        print("== %s: %d shots in %d cases (drawn in %d cases)" % (
            kind, len({(c, s) for c, s, _ in entries}), len(cases), len(drawn[kind])))
        for case, shot, state in entries:
            print("   %s/%s %s" % (case, shot, state))
        for case in sorted(drawn[kind] - cases):
            print("   %s: drawn, in no shot" % case)


if __name__ == "__main__":
    main()
