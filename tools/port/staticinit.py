"""List static initializers that read other classes' non-const state.

Godot runs static var initializers and _static_init when a script loads (in
dependency order, through cycles), not on first use like Java. Reading another
class's static var / calling its static func there can see uninitialized
values (0 / null / empty).

usage: python -I staticinit.py <project_root>
"""
import os
import re
import sys

root = sys.argv[1]
consts = {}   # class_name -> set(const names + inner class names + enum names)
files = {}
for dp, dn, fn in os.walk(os.path.join(root, "src")):
    for f in fn:
        if f.endswith(".gd"):
            p = os.path.join(dp, f)
            t = open(p, encoding="utf-8").read()
            m = re.search(r"^class_name\s+(\w+)", t, re.M)
            if not m:
                continue
            cn = m.group(1)
            files[cn] = (p, t)
            cs = set(re.findall(r"^\s*const\s+(\w+)", t, re.M))
            cs |= set(re.findall(r"^\s*class\s+(\w+)", t, re.M))
            cs |= set(re.findall(r"^\s*enum\s+(\w+)", t, re.M))
            consts[cn] = cs

ref_re = re.compile(r"\b([A-Z]\w*)\.(\w+)")
for cn, (p, t) in sorted(files.items()):
    lines = t.split("\n")
    rel = os.path.relpath(p, root)
    hits = []
    # static var initializers (top level only)
    for i, l in enumerate(lines):
        m = re.match(r"^static var\s+(\w+)[^=]*=\s*(.+)$", l)
        if m:
            for c, mem in ref_re.findall(m.group(2)):
                if c in files and c != cn and mem not in consts.get(c, set()) and mem != "new":
                    hits.append(f"{rel}:{i + 1}: static var {m.group(1)} reads {c}.{mem}")
                elif c in files and c != cn and mem == "new":
                    hits.append(f"{rel}:{i + 1}: static var {m.group(1)} constructs {c} (runs its _init at load)")
    # _static_init body
    for i, l in enumerate(lines):
        if re.match(r"^static func _static_init\s*\(", l):
            j = i + 1
            while j < len(lines) and (not lines[j].strip() or lines[j].startswith("\t") or lines[j].lstrip().startswith("#")):
                for c, mem in ref_re.findall(lines[j]):
                    if c in files and c != cn and mem not in consts.get(c, set()):
                        hits.append(f"{rel}:{j + 1}: _static_init reads {c}.{mem}")
                j += 1
    for h in hits:
        print(h)
