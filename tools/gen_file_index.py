"""Generates res://file_index.txt: every asset/data path in the project.

The original Java game loaded files by path on a case-insensitive file system.
Godot's exported packs are case-sensitive and imported files are remapped, so
the game resolves paths through this index (see GameResourceLoader.resolve).
Run from the project root whenever files are added or renamed:
    python tools/gen_file_index.py
"""
import os

SKIP_EXT = {'.import', '.uid', '.gd', '.tscn', '.tres', '.godot'}
paths = []
for top in ('res', 'maps'):
    for root, dirs, files in os.walk(top):
        dirs.sort()
        for f in sorted(files):
            if os.path.splitext(f)[1].lower() in SKIP_EXT:
                continue
            paths.append(os.path.join(root, f).replace(os.sep, '/'))
with open('file_index.txt', 'w', encoding='utf-8', newline='\n') as fo:
    fo.write('\n'.join(paths) + '\n')
print(len(paths), 'paths written to file_index.txt')
