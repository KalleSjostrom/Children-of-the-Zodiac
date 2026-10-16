extends SceneTree
## Compiles every GDScript under res://src (or the folders given after "--")
## and prints a summary. Run through tools/check.sh, which refreshes the
## global class cache first.
##
##   godot --headless --path . --script res://tools/check_all.gd -- src/battle src/cards


func _init() -> void:
	var roots: Array = []
	for a in OS.get_cmdline_user_args():
		roots.append("res://" + String(a).trim_prefix("res://").trim_suffix("/"))
	if roots.is_empty():
		roots.append("res://src")
	var files: Array = []
	for r in roots:
		if r.ends_with(".gd"):
			files.append(r)
		else:
			_collect(r, files)
	files.sort()
	var failed := 0
	for f in files:
		var s = ResourceLoader.load(f, "", ResourceLoader.CACHE_MODE_IGNORE)
		if s == null or not (s is GDScript) or not s.can_instantiate():
			failed += 1
			print("FAILED: " + f)
	print("CHECKED %d scripts, %d failed" % [files.size(), failed])
	quit(1 if failed > 0 else 0)


func _collect(dir: String, out: Array) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	d.list_dir_begin()
	var n := d.get_next()
	while n != "":
		if d.current_is_dir():
			if not n.begins_with("."):
				_collect(dir + "/" + n, out)
		elif n.ends_with(".gd"):
			out.append(dir + "/" + n)
		n = d.get_next()
