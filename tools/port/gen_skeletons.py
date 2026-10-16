"""Generates GDScript skeletons for every Java class that has not been ported.

Each skeleton declares the class (class_name per docs/class_map.tsv), its
constants, fields, inner classes and method signatures. Java overloads are
merged into one GDScript method; the merge is done over the whole inheritance
family so overrides always have compatible signatures.

usage: python -I gen_skeletons.py <pylib> <project dir> [--write]
"""
import os, re, sys, json, collections
sys.path.insert(0, sys.argv[1])
import javalang
from javalang import tree as T

PROJ = sys.argv[2]
WRITE = '--write' in sys.argv
JSRC = os.path.join(PROJ, '_java_reference', 'src')

# --------------------------------------------------------------------------
# Configuration
# --------------------------------------------------------------------------
# Java classes already ported by hand (framework) -> their .gd files.
FRAMEWORK = {
 'organizer.AbstractMapLoader', 'organizer.ResourceLoader', 'organizer.GameCore', 'organizer.Organizer',
 'organizer.GameMode', 'organizer.GameModeQueue', 'organizer.SubGameMode', 'organizer.MenuStarter',
 'organizer.GameEventListener', 'graphics.GameTexture', 'graphics.ImageHandler', 'graphics.Graphics',
 'graphics.GraphicHelp', 'graphics.Utils3D', 'graphics.Object2D', 'graphics.TimeHideable',
 'input.GameAction', 'input.InputManager', 'input.InputKeyBoardManager', 'input.InputGamePadManager',
 'input.GamePadController', 'input.FakeInputManager', 'sound.OggStreamer', 'sound.SoundPlayer',
 'sound.SoundValues', 'info.Values', 'info.BattleValues', 'info.SoundMap', 'story.Fadeable',
 'battle.Hideable', 'villages.villageStory.Parser',
}
# Java classes that are not ported at all (replaced by Godot / the framework).
SKIP = {
 'organizer.Game', 'organizer.GraphicUI', 'organizer.Screen', 'organizer.FPSAnimator',
 'graphics.ImageLoader', 'graphics.TextManager', 'sound.ALWrapper', 'sound.CachedUrlStream',
 'sound.OggDecoder', 'sound.VorbisInputStream', 'sound.Sound', 'input.DefaultControllerEnvironment',
 'MapChecker', 's',
}
OBJECT_METHODS = {'get', 'set', 'call', 'callv', 'connect', 'disconnect', 'notification', 'free',
                  'is_connected', 'emit_signal', 'get_class', 'is_class', 'has_method', 'set_meta',
                  'get_meta', 'tr', 'get_script', 'set_script'}
GD_RESERVED = {'if', 'elif', 'else', 'for', 'while', 'match', 'when', 'break', 'continue', 'pass',
  'return', 'class', 'class_name', 'extends', 'is', 'in', 'as', 'self', 'super', 'signal', 'func',
  'static', 'const', 'enum', 'var', 'breakpoint', 'preload', 'await', 'yield', 'assert', 'void',
  'PI', 'TAU', 'INF', 'NAN', 'and', 'or', 'not', 'true', 'false', 'null', 'trait', 'namespace',
  'float', 'int', 'bool', 'String', 'Array', 'Dictionary', 'Color', 'Vector2', 'Vector3', 'Rect2',
  'Transform2D', 'Basis', 'Plane', 'Object', 'Callable', 'Signal', 'RID', 'NodePath', 'StringName',
  'script'}

godot_classes = set(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'godot_classes', 'classes.txt')).read().split())
class_map = {}
for line in open(os.path.join(PROJ, 'docs', 'class_map.tsv'), encoding='utf-8').read().splitlines()[1:]:
    fqn, gd, path = line.split('\t')
    class_map[fqn] = (gd, path)
global_gd_names = {v[0] for v in class_map.values()}

report = collections.defaultdict(list)

# --------------------------------------------------------------------------
# Parse Java
# --------------------------------------------------------------------------
class CInfo:
    def __init__(s):
        s.fqn = s.name = s.pkg = s.kind = None
        s.outer = None
        s.extends = None  # unresolved simple/qualified name
        s.parent = None   # resolved fqn
        s.fields = []     # (name, static, final, type, init)
        s.methods = []    # (name, params[(name,type)], static, abstract)
        s.ctors = []
        s.inner = []
        s.enum_consts = []
        s.cu = None
        s.file = None
        s.gdname = None   # global name or Outer.Inner

classes = {}

def type_str(t):
    if t is None:
        return 'void'
    n = t.name
    if isinstance(t, T.ReferenceType) and t.sub_type is not None:
        st = t.sub_type
        while st is not None:
            n += '.' + st.name
            st = st.sub_type
    return n + '[]' * len(t.dimensions or [])

def collect(decl, pkg, outer, cu, path):
    c = CInfo()
    c.name = decl.name
    c.pkg = pkg
    c.outer = outer
    c.fqn = (outer.fqn + '.' + decl.name) if outer else ((pkg + '.' if pkg else '') + decl.name)
    c.kind = {'ClassDeclaration': 'class', 'InterfaceDeclaration': 'interface', 'EnumDeclaration': 'enum'}[type(decl).__name__]
    c.cu = cu
    c.file = path
    if c.kind == 'class' and decl.extends is not None:
        c.extends = type_str(decl.extends)
    body = decl.body
    if c.kind == 'enum':
        c.enum_consts = [k.name for k in body.constants]
        body = body.declarations
    for m in body:
        mods = getattr(m, 'modifiers', set()) or set()
        if isinstance(m, T.FieldDeclaration) or isinstance(m, T.ConstantDeclaration):
            st = 'static' in mods or c.kind == 'interface'
            fin = 'final' in mods or c.kind == 'interface'
            for d in m.declarators:
                c.fields.append((d.name, st, fin, type_str(m.type), d.initializer))
        elif isinstance(m, T.MethodDeclaration):
            ps = [(p.name, type_str(p.type) + ('...' if p.varargs else '')) for p in m.parameters]
            c.methods.append((m.name, ps, 'static' in mods, 'abstract' in mods or c.kind == 'interface'))
        elif isinstance(m, T.ConstructorDeclaration):
            ps = [(p.name, type_str(p.type)) for p in m.parameters]
            c.ctors.append(ps)
        elif isinstance(m, (T.ClassDeclaration, T.InterfaceDeclaration, T.EnumDeclaration)):
            c.inner.append(collect(m, pkg, c, cu, path))
    classes[c.fqn] = c
    return c

top = []
for root, dirs, files in os.walk(JSRC):
    for f in sorted(files):
        if not f.endswith('.java'):
            continue
        p = os.path.join(root, f)
        cu = javalang.parse.parse(open(p, encoding='utf-8').read())
        pkg = cu.package.name if cu.package else ''
        for t in cu.types:
            top.append(collect(t, pkg, None, cu, os.path.relpath(p, JSRC).replace(os.sep, '/')))

# --------------------------------------------------------------------------
# Resolve names
# --------------------------------------------------------------------------
by_pkg_simple = {}
for fqn, c in classes.items():
    if c.outer is None:
        by_pkg_simple[(c.pkg, c.name)] = fqn

def resolve(name, ctx):
    """Resolve a Java type name used in class ctx to a project fqn, or None."""
    if name is None:
        return None
    name = name.replace('[]', '')
    parts = name.split('.')
    first = parts[0]
    # nested types visible from ctx (walk outward)
    c = ctx
    while c is not None:
        for i in c.inner:
            if i.name == first:
                f = i.fqn
                for p in parts[1:]:
                    f += '.' + p
                return f if f in classes else None
        if c.name == first and c.outer is None:
            break
        c = c.outer
    cu = ctx.cu
    for imp in cu.imports:
        if not imp.wildcard and not imp.static and imp.path.split('.')[-1] == first:
            f = imp.path + ''.join('.' + p for p in parts[1:])
            return f if f in classes else None
    if (ctx.pkg, first) in by_pkg_simple:
        f = by_pkg_simple[(ctx.pkg, first)] + ''.join('.' + p for p in parts[1:])
        return f if f in classes else None
    for imp in cu.imports:
        if imp.wildcard and not imp.static:
            if (imp.path, first) in by_pkg_simple:
                f = by_pkg_simple[(imp.path, first)] + ''.join('.' + p for p in parts[1:])
                return f if f in classes else None
    if name in classes:
        return name
    return None

for c in classes.values():
    if c.extends:
        c.parent = resolve(c.extends, c)
        if c.parent is None:
            report['external_superclass'].append('%s extends %s' % (c.fqn, c.extends))

def inner_name(c):
    if c.name in godot_classes or c.name in global_gd_names:
        return c.outer.name + c.name
    return c.name

def gd_ref(fqn):
    c = classes[fqn]
    if c.outer is None:
        return class_map[fqn][0]
    return gd_ref(c.outer.fqn) + '.' + inner_name(c)

# --------------------------------------------------------------------------
# Framework signatures (parse the hand written .gd files)
# --------------------------------------------------------------------------
fw_sigs = {}   # fqn -> {method: (total, required, raw_params, static)}
fw_fields = {}
for fqn in FRAMEWORK:
    path = os.path.join(PROJ, class_map[fqn][1].replace('res://', ''))
    sigs = {}
    flds = set()
    if os.path.exists(path):
        for line in open(path, encoding='utf-8'):
            m = re.match(r'^(static )?func (\w+)\((.*)\)\s*(?:->\s*([\w.]+))?', line)
            if m:
                raw = m.group(3)
                params = [p.strip() for p in re.split(r',(?![^\[\(]*[\]\)])', raw) if p.strip()]
                req = sum(1 for p in params if '=' not in p)
                sigs[m.group(2)] = (len(params), req, raw, bool(m.group(1)), m.group(4))
            m = re.match(r'^(static )?var (\w+)', line)
            if m:
                flds.add(m.group(2))
            m = re.match(r'^const (\w+)', line)
            if m:
                flds.add(m.group(1))
    fw_sigs[fqn] = sigs
    fw_fields[fqn] = flds

def ancestors(fqn):
    out = []
    p = classes[fqn].parent
    while p is not None:
        out.append(p)
        p = classes[p].parent
    return out

def family_root(fqn):
    a = [fqn] + ancestors(fqn)
    return a[-1]

families = collections.defaultdict(list)
for fqn in classes:
    families[family_root(fqn)].append(fqn)

RET_DEFAULT = {'int': '0', 'float': '0.0', 'bool': 'false', 'String': '""', 'Array': '[]',
               'Dictionary': '{}'}


def gd_method_name(n, static=False):
    if static and n == 'toString':
        return n
    if n in OBJECT_METHODS:
        return n + '_'
    if n == 'toString':
        return '_to_string'
    return n

# Merge signatures per family and method name (instance methods only).
merged = {}  # (root, method) -> (total, required, names)
for root, members in families.items():
    groups = collections.defaultdict(list)
    for fqn in members:
        for (n, ps, st, ab) in classes[fqn].methods:
            if not st:
                groups[n].append(ps)
    for n, lists in groups.items():
        total = max(len(l) for l in lists)
        req = min(len(l) for l in lists)
        names = None
        for l in lists:
            if len(l) == total:
                names = [p[0] for p in l]
                break
        fw = None
        for fqn in members + ancestors(root) + [root]:
            if fqn in FRAMEWORK and gd_method_name(n) in fw_sigs[fqn]:
                fw = fw_sigs[fqn][gd_method_name(n)]
                break
        if fw:
            total = max(total, fw[0])
            req = min(req, fw[1])
            if fw[0] >= total:
                names = None  # use framework parameter list
        merged[(root, n)] = (total, req, names, fw)

def sanitize(n):
    if n in GD_RESERVED:
        return n + '_'
    return n

def param_list(names, total, req, fw_raw=None, framework_total=0):
    out = []
    if fw_raw is not None and framework_total >= total:
        return fw_raw
    for i in range(total):
        n = sanitize(names[i]) if names and i < len(names) else 'arg%d' % i
        out.append(n if i < req else n + ' = null')
    # make names unique
    seen = set()
    res = []
    for p in out:
        base = p.split(' = ')[0]
        nb = base
        k = 2
        while nb in seen:
            nb = base + str(k); k += 1
        seen.add(nb)
        res.append(p.replace(base, nb, 1))
    return ', '.join(res)

# --------------------------------------------------------------------------
# Constants
# --------------------------------------------------------------------------
NUM = re.compile(r'^(0[xX][0-9a-fA-F]+|[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)[fFdDlL]?$')

def conv_expr(e, consts):
    """Converts a constant Java expression; returns (code, kind) or None."""
    if isinstance(e, T.Literal):
        v = e.value
        if v in ('true', 'false'):
            return v, 'bool'
        if v == 'null':
            return None
        if v.startswith('"'):
            return v, 'str'
        if v.startswith("'"):
            return '"' + v[1:-1] + '"', 'str'
        if NUM.match(v):
            isfloat = ('.' in v or v[-1] in 'fFdD' or 'e' in v.lower()) and not v.lower().startswith('0x')
            v = re.sub(r'[fFdDlL]$', '', v)
            if v.startswith('.'):
                v = '0' + v
            if v.endswith('.'):
                v += '0'
            if isfloat and '.' not in v and 'e' not in v.lower():
                v += '.0'
            return v, 'float' if isfloat else 'int'
        return None
    if isinstance(e, T.MemberReference):
        if e.qualifier in ('', None) and e.member in consts:
            return e.member, consts[e.member]
        return None
    if isinstance(e, T.BinaryOperation):
        l = conv_expr(e.operandl, consts)
        r = conv_expr(e.operandr, consts)
        if not l or not r:
            return None
        if e.operator not in ('+', '-', '*', '/', '%', '<<', '>>', '|', '&', '^'):
            return None
        if (l[1] == 'str') != (r[1] == 'str'):
            return None
        kind = 'str' if l[1] == 'str' else ('float' if 'float' in (l[1], r[1]) else 'int')
        lc, rc = l[0], r[0]
        if e.operator == '/' and kind == 'int':
            pass
        return '(%s %s %s)' % (lc, e.operator, rc), kind
    if isinstance(e, T.Cast):
        inner = conv_expr(e.expression, consts)
        if not inner:
            return None
        tn = e.type.name
        if tn in ('float', 'double'):
            return 'float(%s)' % inner[0], 'float'
        if tn in ('int', 'long', 'short', 'byte'):
            return 'int(%s)' % inner[0], 'int'
        return inner
    if isinstance(e, T.Literal) is False and hasattr(e, 'prefix_operators') and e.prefix_operators:
        pass
    return None

def strip_paren(code):
    if code.startswith('(') and code.endswith(')'):
        return code[1:-1]
    return code

PRIM_DEFAULT = {'int': '0', 'long': '0', 'short': '0', 'byte': '0', 'char': '0', 'float': '0.0',
                'double': '0.0', 'boolean': 'false', 'String': '""'}

# --------------------------------------------------------------------------
# Emit
# --------------------------------------------------------------------------
def emit_class(c, indent, is_top):
    ind = '\t' * indent
    lines = []
    if is_top:
        lines.append('class_name %s' % class_map[c.fqn][0])
    parent = 'RefCounted'
    if c.parent:
        parent = gd_ref(c.parent)
    if is_top:
        lines.append('extends %s' % parent)
        lines.append('## SKELETON: generated from _java_reference/src/%s - replace with the full port.' % c.file)
        if c.kind == 'interface':
            lines.append('## (Java interface: implementing classes do not extend this; use duck typing.)')
        lines.append('')
    else:
        iname = inner_name(c)
        if iname != c.name:
            report['inner_class_renamed'].append('%s -> %s.%s (shadowed a global/native class)' % (c.fqn, gd_ref(c.outer.fqn), iname))
        lines.append('%sclass %s extends %s:' % (ind[:-1] if indent else '', iname, parent))
    root = family_root(c.fqn)
    inherited_fields = set()
    for a in ancestors(c.fqn):
        if a in FRAMEWORK:
            inherited_fields |= fw_fields[a]
        else:
            inherited_fields |= {f[0] for f in classes[a].fields}
    method_names = {gd_method_name(m[0]) for m in c.methods}
    fam_methods = set()
    for f in families[root]:
        fam_methods |= {gd_method_name(m[0]) for m in classes[f].methods}
    for a in ancestors(c.fqn):
        if a in FRAMEWORK:
            fam_methods |= set(fw_sigs[a].keys())
    fam_instance_methods = set()
    for f in families[root]:
        fam_instance_methods |= {gd_method_name(m[0]) for m in classes[f].methods if not m[2]}
    for a in ancestors(c.fqn):
        if a in FRAMEWORK:
            fam_instance_methods |= {k for k, v in fw_sigs[a].items() if not v[3]}
    consts = {}
    body = []
    # enum constants
    if c.kind == 'enum':
        for k in c.enum_consts:
            body.append('%sstatic var %s = null' % (ind, k))
    for (n, st, fin, ty, init) in c.fields:
        name = n
        if name in fam_methods or name in method_names:
            report['field_renamed_method_clash'].append('%s.%s -> %s_' % (c.fqn, n, n))
            name = n + '_'
        if n == 'logger':
            continue
        while name in inherited_fields:
            report['field_renamed_hides_parent_field'].append('%s.%s -> %s_ (a parent class declares %s too)' % (c.fqn, n, name, n))
            name = name + '_'
        if name in GD_RESERVED:
            report['field_reserved_word'].append('%s.%s -> %s_' % (c.fqn, n, n))
            name = n + '_'
        if st and fin and init is not None and '[' not in ty:
            cv = conv_expr(init, consts)
            if cv:
                body.append('%sconst %s = %s' % (ind, name, strip_paren(cv[0])))
                consts[name] = cv[1]
                continue
        default = PRIM_DEFAULT.get(ty, 'null')
        body.append('%s%svar %s = %s' % (ind, 'static ' if st else '', name, default))
    # constructor
    if c.ctors:
        total = max(len(p) for p in c.ctors)
        names = [p[0] for p in max(c.ctors, key=len)]
        pl = param_list(names, total, 0)
        body.append('')
        body.append('%sfunc _init(%s) -> void:' % (ind, pl))
        body.append('%s\tpass' % ind)
    # methods
    done = set()
    for (n, ps, st, ab) in c.methods:
        gn = gd_method_name(n, st)
        if (gn, st) in done:
            continue
        done.add((gn, st))
        if gn != n:
            report['method_renamed'].append('%s.%s -> %s' % (c.fqn, n, gn))
        if st:
            over = [m[1] for m in c.methods if m[0] == n and m[2]]
            total = max(len(o) for o in over)
            req = min(len(o) for o in over)
            names = [p[0] for p in max(over, key=len)]
            pl = param_list(names, total, req)
            if any(m[0] == n and not m[2] for m in c.methods) or gn in fam_instance_methods:
                report['static_method_renamed'].append('%s.%s (static) -> %sStatic (an instance method has the same name)' % (c.fqn, n, gn))
                gn = gn + 'Static'
            if len(over) > 1:
                report['merged_overloads'].append('%s.%s (static) -> (%s)' % (c.fqn, gn, pl))
            body.append('')
            body.append('%sstatic func %s(%s):' % (ind, gn, pl))
            body.append('%s\tpass' % ind)
        else:
            total, req, names, fw = merged[(root, n)]
            fw_raw = None
            if fw and names is None:
                fw_raw = fw[2]
                if fw[3]:
                    report['framework_static_vs_instance'].append('%s.%s' % (c.fqn, n))
            pl = param_list(names, total, req, fw_raw, fw[0] if fw else 0)
            own = [m[1] for m in c.methods if m[0] == n and not m[2]]
            if len(own) > 1 or total != len(own[0]) or req != len(own[0]):
                report['merged_overloads'].append('%s.%s -> (%s)' % (c.fqn, gn, pl))
            body.append('')
            body.append('%sfunc %s(%s):' % (ind, gn, pl))
            ret = 'pass'
            if gn == '_to_string':
                ret = 'return ""'
            elif fw and fw[4] and fw[4] != 'void':
                ret = 'return %s' % RET_DEFAULT.get(fw[4], 'null')
            body.append('%s\t%s' % (ind, ret))
    for i in c.inner:
        body.append('')
        body.append('')
        body.extend(emit_class(i, indent + 1, False))
    if not body:
        body.append('%spass' % ind)
    lines.extend(body)
    return lines

count = 0
for c in top:
    if c.fqn in FRAMEWORK or c.fqn in SKIP:
        continue
    gd, path = class_map[c.fqn]
    out = os.path.join(PROJ, path.replace('res://', ''))
    text = '\n'.join(emit_class(c, 0, True)) + '\n'
    count += 1
    if WRITE:
        if os.path.exists(out) and 'SKELETON' not in open(out, encoding='utf-8').read(400):
            report['kept_existing_port'].append(path)
            continue
        os.makedirs(os.path.dirname(out), exist_ok=True)
        open(out, 'w', encoding='utf-8', newline='\n').write(text)

with open(os.path.join(PROJ, 'docs', 'skeleton_report.md'), 'w', encoding='utf-8', newline='\n') as f:
    f.write('# Skeleton generation report\n\nGenerated by the port tooling; lists places where the GDScript\n'
            'API differs from the Java one. Use it when porting call sites.\n')
    for k in sorted(report):
        f.write('\n## %s (%d)\n\n' % (k, len(report[k])))
        for v in report[k]:
            f.write('- %s\n' % v)
print(count, 'skeletons', 'written' if WRITE else '(dry run)')
for k in sorted(report):
    print(k, len(report[k]))
