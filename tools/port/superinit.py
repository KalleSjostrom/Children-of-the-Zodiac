"""Find _init methods that do not chain to a user-defined parent _init.

GDScript 4 does not call the parent's _init implicitly when a class defines
its own _init (Java always runs super()). Reports:
  MISSING  <file>:<line> <class> -> <ancestor with _init>  (min args of ancestor _init)
  BRANCH   <file>:<line> <class>  super( present but not the first statement
usage: python -I superinit.py <project_root> [--fix]
--fix inserts "super()" as the first statement of MISSING _inits whose
nearest ancestor _init accepts 0 arguments.
"""
import os
import re
import sys

root = sys.argv[1]
fix = "--fix" in sys.argv

classes = {}  # qn -> dict(extends, outer, file, init=(line_idx, indent, mn) or None, inner={})

def params_min(s):
    s = s.strip()
    if not s:
        return 0
    depth, parts, cur = 0, [], ""
    for ch in s:
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        if ch == "," and depth == 0:
            parts.append(cur)
            cur = ""
        else:
            cur += ch
    if cur.strip():
        parts.append(cur)
    return sum(1 for p in parts if "=" not in p)

file_lines = {}
for dp, dn, fn in os.walk(os.path.join(root, "src")):
    for f in fn:
        if not f.endswith(".gd"):
            continue
        path = os.path.join(dp, f)
        lines = open(path, encoding="utf-8").read().split("\n")
        file_lines[path] = lines
        cname = None
        ext = "RefCounted"
        for l in lines:
            m = re.match(r"^class_name\s+(\w+)", l)
            if m:
                cname = m.group(1)
            m = re.match(r"^extends\s+([\w.]+)", l)
            if m:
                ext = m.group(1)
        if cname is None:
            cname = "file:" + os.path.relpath(path, root)
        top = {"name": cname, "extends": ext, "outer": None, "file": path, "init": None, "inner": {}}
        classes[cname] = top
        stack = [(-1, top)]
        for i, l in enumerate(lines):
            if not l.strip() or l.lstrip().startswith("#"):
                continue
            indent = len(l) - len(l.lstrip("\t"))
            while len(stack) > 1 and indent <= stack[-1][0]:
                stack.pop()
            m = re.match(r"^\t*class\s+(\w+)(?:\s+extends\s+([\w.]+))?\s*:", l)
            if m:
                outer = stack[-1][1]
                qn = outer["name"] + "." + m.group(1)
                c = {"name": qn, "extends": m.group(2) or "RefCounted", "outer": outer["name"], "file": path,
                     "init": None, "inner": {}}
                outer["inner"][m.group(1)] = qn
                classes[qn] = c
                stack.append((indent, c))
                continue
            m = re.match(r"^(\t*)func\s+_init\s*\((.*)\)", l)
            if m and len(m.group(1)) == stack[-1][0] + 1:
                stack[-1][1]["init"] = (i, len(m.group(1)), params_min(m.group(2)))

def resolve(name, ctx):
    parts = name.split(".")
    qn = None
    c = classes.get(ctx)
    while c:
        if parts[0] in c["inner"]:
            qn = c["inner"][parts[0]]
            break
        c = classes.get(c["outer"]) if c["outer"] else None
    if qn is None and parts[0] in classes:
        qn = parts[0]
    if qn is None:
        return None
    for p in parts[1:]:
        qn = classes.get(qn, {}).get("inner", {}).get(p)
        if qn is None:
            return None
    return qn

def body(c):
    i, ind, _ = c["init"]
    lines = file_lines[c["file"]]
    out = []
    for j in range(i + 1, len(lines)):
        l = lines[j]
        if l.strip() and (len(l) - len(l.lstrip("\t"))) <= ind and not l.lstrip().startswith("#"):
            break
        out.append((j, l))
    return out

fixes = {}
for qn, c in sorted(classes.items()):
    if c["init"] is None:
        continue
    # nearest user ancestor with _init
    anc = resolve(c["extends"], c["outer"] or qn)
    seen = set()
    while anc and anc not in seen and classes[anc]["init"] is None:
        seen.add(anc)
        anc = resolve(classes[anc]["extends"], classes[anc]["outer"] or anc)
    if not anc or classes[anc]["init"] is None:
        continue
    b = body(c)
    code = [(j, l) for j, l in b if l.strip() and not l.strip().startswith("#")]
    has_super = any(re.search(r"\bsuper\s*\(|\bsuper\._init\s*\(", l) for _, l in code)
    rel = os.path.relpath(c["file"], root)
    line_no = c["init"][0] + 1
    if not has_super:
        mn = classes[anc]["init"][2]
        print(f"MISSING {rel}:{line_no} {qn} -> {anc} (ancestor _init min args {mn})")
        if fix and mn == 0:
            fixes.setdefault(c["file"], []).append((c["init"][0], c["init"][1]))
    else:
        first = code[0][1].strip() if code else ""
        if not re.match(r"super\s*\(", first):
            print(f"BRANCH  {rel}:{line_no} {qn} (first statement: {first[:60]})")

if fix:
    for path, items in fixes.items():
        lines = file_lines[path]
        for idx, ind in sorted(items, reverse=True):
            # handle "func _init(...) -> void: pass"-style one-liners: not expected
            lines.insert(idx + 1, "\t" * (ind + 1) + "super()")
        open(path, "w", encoding="utf-8", newline="\n").write("\n".join(lines))
    print(f"fixed {sum(len(v) for v in fixes.values())} _init methods in {len(fixes)} files")
