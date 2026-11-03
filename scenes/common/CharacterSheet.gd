class_name CharacterSheet
extends RefCounted
## The sprite sheet of a walking character (docs/VILLAGER_SPRITES_PLAN.md,
## plan B): <set folder>/<Name>_sheet.png holds the 16 frames that were
## <Name>1.png .. <Name>16.png, 4 columns (the walk frames) by 4 rows (up,
## right, down, left: the file order, Values.UP..LEFT), each 36x56 cell at a
## 40x60 pitch, so the sheet is 160x240.
##
## The 2 px gutter around a cell holds copies of the cell's edge pixels
## (extruded, tools/art/pack_character_sheets.gd): where linear filtering
## (a cutscene zoom, full screen) samples past the cell's edge it gets the
## edge, as clamp-to-edge does for a frame file. The AtlasTextures do not set
## filter_clip: with this renderer it clamps a hair inside the edge texels and
## blends the cell's last row and column with their neighbours by up to 3/255
## even unzoomed, where the extruded gutter keeps a 1:1 frame identical to its
## frame file.
##
## The legacy code keeps its frame paths (Sprite.animImages): ImageHandler
## asks frame_texture for a path whose file is gone, and gets the region of
## the set's sheet. Used by tools/art/ to write the sheets too.

const COLUMNS := 4
const ROWS := 4
const FRAMES := COLUMNS * ROWS
const CELL := Vector2i(36, 56)
const GUTTER := 2
const PITCH := CELL + Vector2i(2 * GUTTER, 2 * GUTTER)
const SIZE := Vector2i(COLUMNS * PITCH.x, ROWS * PITCH.y)
const SUFFIX := "_sheet.png"


## The cell of frame n (1-16, the number of the frame file) in a sheet.
static func region(n: int) -> Rect2i:
	var i := n - 1
	return Rect2i(Vector2i(i % COLUMNS, i / COLUMNS) * PITCH + Vector2i(GUTTER, GUTTER), CELL)


## The sheet of the set in folder (a path without res://, any case):
## <folder>/<folder's name>_sheet.png.
static func sheet_path(folder: String) -> String:
	return folder + "/" + folder.get_file() + SUFFIX


## The frame number of a frame path, <folder>/<folder's name><n>.png with n
## 1-16 (case-insensitive: the legacy paths are), or 0. The name comes from
## the folder, not from a digit pattern: Man1's frames are Man11..Man116.
static func frame_number(path: String) -> int:
	if path.get_extension().to_lower() != "png":
		return 0
	var folder := path.get_base_dir().get_file().to_lower()
	var base := path.get_file().get_basename().to_lower()
	if folder == "" or not base.begins_with(folder):
		return 0
	var digits := base.substr(folder.length())
	if not digits.is_valid_int() or digits.begins_with("+") or digits.begins_with("-"):
		return 0
	var n := digits.to_int()
	return n if n >= 1 and n <= FRAMES and str(n) == digits else 0


## The frame of a legacy frame path from its set's sheet (an AtlasTexture of
## the frame's cell), or null when the path names no frame
## of a set that has a sheet.
static func frame_texture(path: String) -> AtlasTexture:
	var n := frame_number(path)
	if n == 0:
		return null
	var sheet := GameResourceLoader.resolve(sheet_path(path.get_base_dir()))
	if sheet == "":
		return null
	return cell(ResourceLoader.load(sheet), n)


## Frame n (1-16) of a sheet: an AtlasTexture of its cell (filter_clip off,
## see above).
static func cell(sheet: Texture2D, n: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(region(n))
	return atlas
