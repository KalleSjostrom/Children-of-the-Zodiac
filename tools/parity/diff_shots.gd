extends SceneTree
## Compares two folders of screenshots pixel by pixel (tools/parity/parity.sh).
##
##   Godot --headless --path . --script res://tools/parity/diff_shots.gd -- \
##       <dir_a> <dir_b> <out_dir> [--tolerance=<0-255>] [--max-pixels=<n>]
##
## Every PNG under dir_a or dir_b is matched by its relative path. A pixel
## differs when one of its channels differs by more than the tolerance; a shot
## passes when at most max-pixels pixels differ. For each shot that is not
## identical, <out_dir>/<path>.diff.png shows the A image dimmed to gray, pixels
## above the tolerance in red and smaller differences in yellow. The results
## go to stdout and <out_dir>/summary.txt. Exit code 0 = all passed.

var _tolerance := 0
var _max_pixels := 0
var _lines: PackedStringArray = []


func _initialize() -> void:
	var positional: Array[String] = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tolerance="):
			_tolerance = int(arg.get_slice("=", 1))
		elif arg.begins_with("--max-pixels="):
			_max_pixels = int(arg.get_slice("=", 1))
		else:
			positional.append(arg)
	if positional.size() != 3:
		printerr("usage: diff_shots.gd -- <dir_a> <dir_b> <out_dir> [--tolerance=N] [--max-pixels=N]")
		quit(2)
		return
	quit(_run(positional[0], positional[1], positional[2]))


func _run(dir_a: String, dir_b: String, out_dir: String) -> int:
	var shots_a := _list_pngs(dir_a, "")
	var shots_b := _list_pngs(dir_b, "")
	var all: Array[String] = []
	for s in shots_a + shots_b:
		if not all.has(s):
			all.append(s)
	all.sort()
	DirAccess.make_dir_recursive_absolute(out_dir)
	_out("A: %s" % dir_a)
	_out("B: %s" % dir_b)
	_out("tolerance %d, max differing pixels %d" % [_tolerance, _max_pixels])
	var failed := 0
	var identical := 0
	for rel in all:
		if not shots_a.has(rel) or not shots_b.has(rel):
			_out("FAIL %s: only in %s" % [rel, "A" if shots_a.has(rel) else "B"])
			failed += 1
			continue
		var result := _compare(dir_a.path_join(rel), dir_b.path_join(rel), out_dir.path_join(rel))
		if result.identical:
			identical += 1
		if not result.passed:
			failed += 1
		_out("%s %s: %s" % ["PASS" if result.passed else "FAIL", rel, result.text])
	var verdict := "PASS" if failed == 0 and not all.is_empty() else "FAIL"
	_out("RESULT %s: %d shots, %d identical, %d failed" % [verdict, all.size(), identical, failed])
	var f := FileAccess.open(out_dir.path_join("summary.txt"), FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(_lines) + "\n")
	return 0 if verdict == "PASS" else 1


func _out(line: String) -> void:
	print(line)
	_lines.append(line)


## Relative paths of all PNGs under dir (recursive), without .diff.png files.
func _list_pngs(dir: String, rel: String) -> Array[String]:
	var result: Array[String] = []
	var path := dir.path_join(rel)
	for f in DirAccess.get_files_at(path):
		if f.ends_with(".png") and not f.ends_with(".diff.png"):
			result.append(rel.path_join(f) if rel != "" else f)
	for d in DirAccess.get_directories_at(path):
		result.append_array(_list_pngs(dir, rel.path_join(d) if rel != "" else d))
	return result


func _compare(path_a: String, path_b: String, out_path: String) -> Dictionary:
	var a := Image.load_from_file(path_a)
	var b := Image.load_from_file(path_b)
	if a == null or b == null:
		return {"passed": false, "identical": false, "text": "could not load"}
	a.convert(Image.FORMAT_RGB8)
	b.convert(Image.FORMAT_RGB8)
	if a.get_size() != b.get_size():
		return {"passed": false, "identical": false,
			"text": "size %s vs %s" % [a.get_size(), b.get_size()]}
	var da := a.get_data()
	var db := b.get_data()
	if da == db:
		return {"passed": true, "identical": true, "text": "identical"}
	var width := a.get_width()
	var out := PackedByteArray()
	out.resize(da.size())
	var max_diff := 0
	var over := 0
	var nonzero := 0
	var min_p := Vector2i(width, a.get_height())
	var max_p := Vector2i(-1, -1)
	for i in range(0, da.size(), 3):
		var d := maxi(absi(da[i] - db[i]), maxi(absi(da[i + 1] - db[i + 1]), absi(da[i + 2] - db[i + 2])))
		if d == 0:
			var gray := (da[i] + da[i + 1] + da[i + 2]) / 9
			out[i] = gray
			out[i + 1] = gray
			out[i + 2] = gray
			continue
		nonzero += 1
		max_diff = maxi(max_diff, d)
		out[i] = 255
		out[i + 2] = 0
		if d > _tolerance:
			over += 1
			out[i + 1] = 0
			var p := Vector2i((i / 3) % width, (i / 3) / width)
			min_p = min_p.min(p)
			max_p = max_p.max(p)
		else:
			out[i + 1] = 255
	DirAccess.make_dir_recursive_absolute(out_path.get_base_dir())
	var diff_image := Image.create_from_data(width, a.get_height(), false, Image.FORMAT_RGB8, out)
	diff_image.save_png(out_path.get_basename() + ".diff.png")
	var total := width * a.get_height()
	var text := "max channel diff %d, %d pixels differ (%.3f%%), %d over tolerance" % [
		max_diff, nonzero, 100.0 * nonzero / total, over]
	if over > 0:
		text += ", box %d,%d-%d,%d" % [min_p.x, min_p.y, max_p.x, max_p.y]
	return {"passed": over <= _max_pixels, "identical": false, "text": text}
