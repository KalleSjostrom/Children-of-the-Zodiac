"""Static cross-file call lint for the GDScript port.

usage: python -I calllint.py <project_root> <extension_api.json> [subdir ...]

Reports, for non-skeleton files (or only those under the given subdirs):
  * Known class receiver (ClassName.m(...), ClassName.Inner.m(...), self.m, super.m):
    method missing in the class chain, or argument count not accepted.
  * ClassName.new(...): argument count not accepted by _init in the chain.
  * x.m(...) on unknown receivers: m defined nowhere (user code or Godot API),
    or (when m is defined only in user code) no definition accepts the count.
"""
import json
import os
import re
import sys

root, api_path = sys.argv[1], sys.argv[2]
only = [os.path.normpath(os.path.join(root, s)) for s in sys.argv[3:]]

api = json.load(open(api_path, encoding="utf-8"))
godot_methods = set()
godot_classes = {}
for c in api["classes"]:
    godot_classes[c["name"]] = c
    for m in c.get("methods", []):
        godot_methods.add(m["name"])
    for s in c.get("signals", []):
        pass
for c in api["builtin_classes"]:
    for m in c.get("methods", []):
        godot_methods.add(m["name"])
utility = {f["name"] for f in api["utility_functions"]}
gd_builtins = {
    "print", "str", "range", "len", "preload", "load", "typeof", "is_instance_valid",
    "assert", "Color8", "char", "convert", "type_exists", "instance_from_id",
    "print_debug", "push_error", "push_warning", "get_stack", "inst_to_dict",
    "dict_to_inst", "print_stack", "is_instance_of", "ord", "await", "super",
    "func", "if", "elif", "while", "for", "match", "return", "not", "and", "or",
    "in", "else", "yield", "emit_signal", "breakpoint",
}
builtin_types = {c["name"] for c in api["builtin_classes"]} | {"int", "float", "bool"}

def strip_code(text):
    """Blank out strings and comments, keep length/newlines."""
    out = []
    i, n = 0, len(text)
    while i < n:
        ch = text[i]
        if ch == "#":
            while i < n and text[i] != "\n":
                out.append(" ")
                i += 1
            continue
        if ch in "\"'":
            q = ch
            triple = text[i:i + 3] == q * 3
            end = q * 3 if triple else q
            out.append('"')
            i += len(end)
            while i < n and text[i:i + len(end)] != end:
                if text[i] == "\\":
                    out.append("  ")
                    i += 2
                    continue
                out.append("\n" if text[i] == "\n" else " ")
                i += 1
            out.append('"')
            i += len(end)
            continue
        out.append(ch)
        i += 1
    return "".join(out)

def parse_params(s):
    s = s.strip()
    if not s:
        return 0, 0
    parts = split_top(s)
    mn = sum(1 for p in parts if "=" not in p)
    return mn, len(parts)

def split_top(s):
    parts, depth, cur = [], 0, []
    for ch in s:
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        if ch == "," and depth == 0:
            parts.append("".join(cur))
            cur = []
        else:
            cur.append(ch)
    if "".join(cur).strip():
        parts.append("".join(cur))
    return [p for p in parts if p.strip()]

# --- collect classes -------------------------------------------------------
classes = {}   # qualified name -> {"extends": str|None, "funcs": {name: [(mn,mx,static)]}, "file": path, "outer": qn|None, "inner": {}}
files = []
for dp, dn, fn in os.walk(os.path.join(root, "src")):
    for f in fn:
        if f.endswith(".gd"):
            files.append(os.path.join(dp, f))
# also tools? no.

file_class = {}
for path in files:
    raw = open(path, encoding="utf-8").read()
    code = strip_code(raw)
    m = re.search(r"^class_name\s+(\w+)", code, re.M)
    cname = m.group(1) if m else "file:" + os.path.relpath(path, root)
    m = re.search(r"^extends\s+([\w.]+)", code, re.M)
    ext = m.group(1) if m else "RefCounted"
    top = {"extends": ext, "funcs": {}, "file": path, "outer": None, "inner": {}, "name": cname,
           "skeleton": "## SKELETON" in raw[:400]}
    classes[cname] = top
    file_class[path] = cname
    stack = [(-1, top)]
    lines = code.split("\n")
    i = 0
    while i < len(lines):
        line = lines[i]
        if not line.strip():
            i += 1
            continue
        indent = len(line) - len(line.lstrip("\t"))
        while len(stack) > 1 and indent <= stack[-1][0]:
            stack.pop()
        cm = re.match(r"^\t*class\s+(\w+)(?:\s+extends\s+([\w.]+))?\s*:", line)
        if cm:
            outer = stack[-1][1]
            qn = outer["name"] + "." + cm.group(1)
            ic = {"extends": cm.group(2) or "RefCounted", "funcs": {}, "file": path, "outer": outer["name"],
                  "inner": {}, "name": qn, "skeleton": top["skeleton"]}
            outer["inner"][cm.group(1)] = qn
            classes[qn] = ic
            stack.append((indent, ic))
            i += 1
            continue
        fm = re.match(r"^\t*(static\s+)?func\s+(\w+)\s*\(", line)
        if fm:
            # gather until matching paren
            buf = line[fm.end():]
            j = i
            depth = 1
            params = []
            k = 0
            text = buf
            while True:
                for ch in text:
                    if ch == "(":
                        depth += 1
                    elif ch == ")":
                        depth -= 1
                        if depth == 0:
                            break
                    params.append(ch)
                if depth == 0:
                    break
                j += 1
                if j >= len(lines):
                    break
                text = lines[j]
            mn, mx = parse_params("".join(params))
            owner = stack[-1][1]
            if indent > stack[-1][0] + (1 if stack[-1][0] >= 0 else 0):
                pass  # nested lambda-ish; still record
            owner["funcs"].setdefault(fm.group(2), []).append((mn, mx, bool(fm.group(1))))
            i = j + 1
            continue
        i += 1

all_user_funcs = {}
for qn, c in classes.items():
    for name, sigs in c["funcs"].items():
        all_user_funcs.setdefault(name, []).extend(sigs)

def resolve_class(name, context_qn=None):
    """Resolve an identifier (possibly dotted) to a qualified user class name."""
    parts = name.split(".")
    first = parts[0]
    qn = None
    # inner class visible from context (own or outer)
    ctx = context_qn
    while ctx:
        c = classes.get(ctx)
        if c and first in c["inner"]:
            qn = c["inner"][first]
            break
        ctx = c["outer"] if c else None
    if qn is None and first in classes:
        qn = first
    if qn is None:
        return None
    for p in parts[1:]:
        c = classes.get(qn)
        if not c or p not in c["inner"]:
            return None
        qn = c["inner"][p]
    return qn

def chain(qn):
    seen = []
    cur = qn
    while cur and cur in classes and cur not in seen:
        seen.append(cur)
        c = classes[cur]
        nxt = resolve_class(c["extends"], c["outer"] or cur) if c["extends"] else None
        if nxt is None:
            seen.append("native:" + c["extends"])
            break
        cur = nxt
    return seen

def native_has(native, method):
    n = native
    while n and n in godot_classes:
        if any(m["name"] == method for m in godot_classes[n].get("methods", [])):
            return True
        n = godot_classes[n].get("inherits")
    return False

def lookup(qn, method):
    """Return (found, sigs) for method in chain of qn."""
    sigs = []
    for c in chain(qn):
        if c.startswith("native:"):
            if native_has(c[7:], method):
                return True, None
            break
        if method in classes[c]["funcs"]:
            sigs.extend(classes[c]["funcs"][method])
            return True, sigs  # nearest definition wins (override)
    return False, None

def accepts(sigs, n):
    return any(mn <= n <= mx for mn, mx, _ in sigs)

def count_args(code, start):
    """start: index just after '('. Returns (nargs, end_index)."""
    depth = 1
    i = start
    buf = []
    while i < len(code) and depth > 0:
        ch = code[i]
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
            if depth == 0:
                break
        buf.append(ch)
        i += 1
    s = "".join(buf)
    return len(split_top(s)) if s.strip() else 0, i

issues = []
call_re = re.compile(r"((?:[A-Za-z_]\w*\.)*)([A-Za-z_]\w*)\s*\(")
for path in files:
    if only and not any(os.path.normpath(path).startswith(o) for o in only):
        continue
    qn_file = file_class[path]
    if classes[qn_file]["skeleton"]:
        continue
    raw = open(path, encoding="utf-8").read()
    code = strip_code(raw)
    # map line -> enclosing class qn (for inner-class context)
    lines = code.split("\n")
    line_ctx = []
    stack = [(-1, qn_file)]
    for line in lines:
        if line.strip():
            indent = len(line) - len(line.lstrip("\t"))
            while len(stack) > 1 and indent <= stack[-1][0]:
                stack.pop()
            cm = re.match(r"^\t*class\s+(\w+)", line)
            if cm:
                stack.append((indent, classes[stack[-1][1]]["inner"].get(cm.group(1), stack[-1][1])))
        line_ctx.append(stack[-1][1])
    offs = []
    o = 0
    for line in lines:
        offs.append(o)
        o += len(line) + 1
    import bisect
    for m in call_re.finditer(code):
        prefix, name = m.group(1), m.group(2)
        s = m.start()
        if s > 0 and (code[s - 1].isalnum() or code[s - 1] in "_$@"):
            continue
        chained = s > 0 and code[s - 1] == "."
        ln = bisect.bisect_right(offs, s) - 1
        ctx = line_ctx[ln]
        before = code[max(0, s - 6):s]
        if re.search(r"func\s*$", code[max(0, s - 12):s]) or re.search(r"\bclass\s+$", code[max(0, s - 12):s]) or re.search(r"signal\s+$", code[max(0, s - 12):s]):
            continue
        nargs, _ = count_args(code, m.end())
        where = f"{os.path.relpath(path, root)}:{ln + 1}"
        recv = prefix[:-1] if prefix else ""
        if chained:
            recv = "<expr>." + recv if recv else "<expr>"
        if recv == "" :
            # unqualified call
            if name in gd_builtins or name in utility or name in builtin_types:
                continue
            if name in classes or resolve_class(name, ctx):
                continue
            found, sigs = lookup(ctx, name)
            if found:
                if sigs is not None and not accepts(sigs, nargs):
                    issues.append(f"{where}: {name}() called with {nargs} args; own chain accepts {sorted(set((a, b) for a, b, _ in sigs))}")
                continue
            # outer class funcs are not visible from inner classes in GDScript (static only)
            if name in godot_methods:
                continue
            issues.append(f"{where}: unqualified {name}() not found in class chain of {ctx}")
            continue
        last = recv.split(".")[-1]
        if recv in ("self",) or recv == "super":
            target = ctx
            if recv == "super":
                ch = chain(ctx)
                target = ch[1] if len(ch) > 1 and not ch[1].startswith("native:") else None
                if target is None:
                    continue
            found, sigs = lookup(target, name)
            if not found:
                issues.append(f"{where}: {recv}.{name}() not found in chain of {target}")
            elif sigs is not None and not accepts(sigs, nargs):
                issues.append(f"{where}: {recv}.{name}() called with {nargs} args; accepts {sorted(set((a, b) for a, b, _ in sigs))}")
            continue
        rq = resolve_class(recv, ctx) if recv[0].isupper() else None
        if rq:
            if name == "new":
                found, sigs = lookup(rq, "_init")
                if found and sigs is not None and not accepts(sigs, nargs):
                    issues.append(f"{where}: {recv}.new() with {nargs} args; _init accepts {sorted(set((a, b) for a, b, _ in sigs))}")
                elif not found and nargs > 0:
                    issues.append(f"{where}: {recv}.new() with {nargs} args but no _init in chain")
                continue
            found, sigs = lookup(rq, name)
            if not found:
                if name in godot_methods and name in ("get", "set", "call", "has_method", "get_script", "new"):
                    continue
                issues.append(f"{where}: {recv}.{name}() not found in class {rq}")
            elif sigs is not None and not accepts(sigs, nargs):
                issues.append(f"{where}: {recv}.{name}() called with {nargs} args; accepts {sorted(set((a, b) for a, b, _ in sigs))}")
            continue
        if recv in godot_classes or recv in builtin_types or recv in ("Engine", "OS", "Time", "Input", "DisplayServer", "ResourceLoader", "FileAccess", "DirAccess", "JSON", "ClassDB", "RenderingServer", "PhysicsServer3D", "AudioServer", "Performance", "ProjectSettings", "TranslationServer", "IP", "Marshalls", "ResourceSaver", "InputMap"):
            continue
        # unknown receiver (variable)
        if name in godot_methods:
            continue
        if name not in all_user_funcs:
            issues.append(f"{where}: .{name}() is defined nowhere (receiver {recv})")
        elif not accepts(all_user_funcs[name], nargs):
            issues.append(f"{where}: {recv}.{name}() with {nargs} args; no definition accepts it {sorted(set((a, b) for a, b, _ in all_user_funcs[name]))}")

for i in issues:
    print(i)
print(f"-- {len(issues)} issues")
