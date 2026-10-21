extends SceneTree
## Puts screenshots side by side into one image, for looking at a parity set
## (or its .diff.png files) at a glance. Run headless from the project root:
##
##   godot --headless --path . --script res://tools/parity/contact_sheet.gd -- \
##       <out.png> [--columns=<n>] [--scale=<s>] <image or directory>...
##
## A directory adds its *.png files in name order. Each tile is the image
## scaled by --scale (default 0.25), with its file name printed below it on
## the command line output (the sheet has no text), row by row.

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		print("usage: contact_sheet.gd -- <out.png> [--columns=<n>] [--scale=<s>] <image or directory>...")
		quit(2)
		return
	var out: String = args[0]
	var columns := 4
	var scale := 0.25
	var files: PackedStringArray = []
	for a: String in args.slice(1):
		if a.begins_with("--columns="):
			columns = int(a.trim_prefix("--columns="))
		elif a.begins_with("--scale="):
			scale = float(a.trim_prefix("--scale="))
		elif DirAccess.dir_exists_absolute(a):
			var names := DirAccess.get_files_at(a)
			names.sort()
			for n in names:
				if n.ends_with(".png"):
					files.append(a.path_join(n))
		else:
			files.append(a)
	if files.is_empty():
		print("contact_sheet: no images")
		quit(1)
		return
	var tiles: Array[Image] = []
	var tile_size := Vector2i.ZERO
	for f in files:
		var img := Image.load_from_file(f)
		if img == null:
			push_error("contact_sheet: cannot read " + f)
			continue
		img.convert(Image.FORMAT_RGBA8)
		img.resize(maxi(1, roundi(img.get_width() * scale)), maxi(1, roundi(img.get_height() * scale)),
				Image.INTERPOLATE_BILINEAR)
		tile_size = tile_size.max(img.get_size())
		tiles.append(img)
	var rows := ceili(float(tiles.size()) / columns)
	var gap := 4
	var sheet := Image.create(columns * (tile_size.x + gap), rows * (tile_size.y + gap), false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.5, 0.0, 0.5))
	for i in tiles.size():
		var at := Vector2i((i % columns) * (tile_size.x + gap), (i / columns) * (tile_size.y + gap))
		sheet.blit_rect(tiles[i], Rect2i(Vector2i.ZERO, tiles[i].get_size()), at)
		if i % columns == 0:
			print("row %d:" % (i / columns))
		print("  " + files[i].get_file())
	sheet.save_png(out)
	print("wrote %s (%d images)" % [out, tiles.size()])
	quit()
