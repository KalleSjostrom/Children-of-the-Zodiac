import os, re, sys, json, collections
src = sys.argv[1]
godot = set(open(sys.argv[2]).read().split())
variant = set("bool int float String Vector2 Vector2i Rect2 Rect2i Vector3 Vector3i Transform2D Vector4 Vector4i Plane Quaternion AABB Basis Transform3D Projection Color StringName NodePath RID Object Callable Signal Dictionary Array PackedByteArray PackedInt32Array PackedInt64Array PackedFloat32Array PackedFloat64Array PackedStringArray PackedVector2Array PackedVector3Array PackedColorArray PackedVector4Array GDScript".split())
reserved = godot | variant
classes = []
for root, dirs, files in os.walk(src):
    for f in files:
        if f.endswith('.java'):
            rel = os.path.relpath(os.path.join(root, f), src).replace(os.sep,'/')
            pkg = os.path.dirname(rel).replace('/', '.')
            name = f[:-5]
            classes.append((pkg, name, rel))
count = collections.Counter(n for _, n, _ in classes)
def pascal(pkg):
    last = pkg.split('.')[-1] if pkg else ''
    return last[:1].upper() + last[1:]
out = []
for pkg, name, rel in sorted(classes):
    gd = name
    reason = ''
    if count[name] > 1 or name in reserved:
        gd = pascal(pkg) + name
        reason = 'dup' if count[name] > 1 else 'godot'
        if count[name] > 1 and name in reserved: reason = 'dup+godot'
    if gd in reserved:
        gd = 'Coz' + gd; reason += '+again'
    fqn = (pkg + '.' if pkg else '') + name
    out.append((fqn, gd, 'res://src/' + rel[:-5] + '.gd', reason))
# check uniqueness
c2 = collections.Counter(g for _, g, _, _ in out)
for fqn, gd, p, r in out:
    if c2[gd] > 1: print("STILL DUP", fqn, gd)
with open(sys.argv[3], 'w', encoding='utf-8') as fo:
    fo.write("java_fqn\tgd_class_name\tgd_path\tnote\n")
    for row in out: fo.write('\t'.join(row) + '\n')
for row in out:
    if row[3]: print(row)
print(len(out))
