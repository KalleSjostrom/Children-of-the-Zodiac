"""Report GDScript consts whose sign differs from the Java constant of the same name.

usage: python -I constcheck.py <gd_src_root> <java_src_root> [skel|ported|all]
"""
import os
import re
import sys

gd_root, java_root = sys.argv[1], sys.argv[2]
mode = sys.argv[3] if len(sys.argv) > 3 else "ported"
bad = []
for dp, dn, fn in os.walk(gd_root):
    for f in fn:
        if not f.endswith(".gd"):
            continue
        gp = os.path.join(dp, f)
        rel = os.path.relpath(gp, gd_root)
        jp = os.path.join(java_root, rel[:-3] + ".java")
        if not os.path.exists(jp):
            continue
        g = open(gp, encoding="utf-8").read()
        is_skel = "## SKELETON" in g[:400]
        if (mode == "skel" and not is_skel) or (mode == "ported" and is_skel):
            continue
        j = open(jp, encoding="utf-8", errors="replace").read()
        for m in re.finditer(r"^\s*(?:static\s+)?(?:const|var)\s+(\w+)\s*(?::\s*\w+\s*)?=\s*([^\n#]+)", g, re.M):
            name, gv = m.group(1), m.group(2).strip()
            jm = re.search(r"\b" + re.escape(name) + r"\s*=\s*([^;,]+)[;,]", j)
            if not jm:
                continue
            jv = jm.group(1).strip()
            if not re.match(r"^-?\s*\.?[0-9]", jv):
                continue
            jneg = jv.replace(" ", "").startswith("-")
            gneg = gv.replace(" ", "").startswith("-")
            if jneg != gneg:
                bad.append(f"{rel}: {name} gd={gv} java={jv}")
print("\n".join(bad) if bad else "no sign mismatches")
