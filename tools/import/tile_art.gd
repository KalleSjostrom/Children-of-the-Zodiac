extends RefCounted
## The art of DoubleBackground backgrounds for the converters
## (tools/import/vil_to_scene.gd, world_to_scene.gd; docs/ARCHITECTURE.md
## sections 9 and 13): the 256 px tiles stitched into one image, and the top
## layer of top/top.info. Preload it:
##
##   const TileArt := preload("res://tools/import/tile_art.gd")

const TILE := 256
## The import of a stitched background, as the tiles are imported: lossless,
## no mipmaps; the alpha border was already fixed when the tiles were
## imported.
const IMPORT_PARAMS: Array[String] = ["compress/mode=0", "compress/high_quality=false",
	"mipmaps/generate=false", "mipmaps/limit=-1", "process/fix_alpha_border=false",
	"process/premult_alpha=false", "process/size_limit=0", "detect_3d/compress_to=0"]


## Stitches the tiles DoubleBackground.generateNames draws (<tiles>/x<i>y<j><ext>
## for i < ceil(actual_size.x / 256), j < ceil(actual_size.y / 256)) into one
## image, pixel for pixel as imported, and saves it as a PNG at path with an
## .import file (IMPORT_PARAMS; an .import file that already has them is kept,
## with its uid). label names the background in the report of a missing tile.
## Returns false when no tile exists (nothing is written).
static func stitch(tiles: String, ext: String, actual_size: Vector2i, path: String, label: String) -> bool:
	var columns := ceili(actual_size.x / float(TILE))
	var rows := ceili(actual_size.y / float(TILE))
	var images := {}
	var image_size := Vector2i.ZERO
	var format := -1
	for i in columns:
		for j in rows:
			var tile := GameResourceLoader.resolve("%s/x%dy%d%s" % [tiles, i, j, ext])
			if tile == "":
				print("  %s: tile x%dy%d missing" % [label, i, j])
				continue
			var img := (load(tile) as Texture2D).get_image()
			if img.is_compressed():
				img.decompress()
			if format == -1:
				format = img.get_format()
			images[Vector2i(i, j)] = img
			image_size = image_size.max(Vector2i(i, j) * TILE + img.get_size())
	if images.is_empty():
		return false
	var out := Image.create_empty(image_size.x, image_size.y, false, format)
	for k: Vector2i in images:
		var img: Image = images[k]
		if img.get_format() != format:
			img.convert(format)
		out.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), k * TILE)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	out.save_png(path)
	var current := FileAccess.get_file_as_string(path + ".import")
	if IMPORT_PARAMS.all(func(line: String) -> bool: return current.contains(line + "\n")):
		return true
	var f := FileAccess.open(path + ".import", FileAccess.WRITE)
	f.store_string("[remap]\n\nimporter=\"texture\"\ntype=\"CompressedTexture2D\"\n\n[params]\n\n"
		+ "\n".join(IMPORT_PARAMS) + "\n")
	f.close()
	return true


## DoubleBackground.doTopLayer(images, folder): [position, image path] per line
## of <images><folder>/top/top.info, in order ("i/<name>" lines name an image
## of <images>/top/, as the legacy path is built).
static func top_layer(images: String, folder: String) -> Array:
	var out: Array = []
	var path := images + folder + "/top/top.info"
	if not GameResourceLoader.fileExists(path):
		return out
	for line in GameResourceLoader.readText(path).replace("\r", "").split("\n"):
		if line == "":
			continue
		var args: Array = J.split(line, ":")
		var n: String = args[0]
		var p := Vector2i(J.parseInt(args[1]), J.parseInt(args[2]))
		if n.begins_with("i"):
			out.append([p, images + "/top/" + n.replace("i/", "")])
		else:
			out.append([p, images + folder + "/top/" + n])
	return out
