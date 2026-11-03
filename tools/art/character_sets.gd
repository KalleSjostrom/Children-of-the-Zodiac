extends RefCounted
## The character image sets of the villages and cutscenes, for the tools in
## tools/art/ (docs/VILLAGER_SPRITES_PLAN.md): every folder
## res/Village/<place>/villagers/<Name>/ and res/Village/Characters/<Name>/
## whose frames are <Name>1.png, <Name>2.png ... (the name is the folder's:
## Man1's frames are Man11..Man116).
##
## In scope (find):
## * a walking character: the 16 frames <Name>1..16;
## * a single frame <Name>1 alone that fits a 36x56 cell (the four 36x56
##   villagers, the five sitting ones).
## Not in scope, and not returned: the zodiac images of Home of the Gods
## (28x113), ball (3 frames), KinSmall (its files are named Kin1..16),
## Characters/Animation (cutscene poses), and every file whose base name
## ends in "_pixel" or "_pixel<digits>" (pixel-art tests, never touched).

const VILLAGE_DIR := "res://res/Village/"
const CHARACTERS := "Characters"
const WALK_FRAMES := 16

static var _pixel_test := RegEx.create_from_string("_pixel\\d*$")


## A set: its folder (res://...), its name and the paths of its frames 1..n.
class CharacterSet:
	var folder := ""
	var name := ""
	var frames: PackedStringArray = []

	func is_walking() -> bool:
		return frames.size() == WALK_FRAMES


## True for a pixel-art test file (base name ending in _pixel[digits]).
static func is_pixel_test(path: String) -> bool:
	return _pixel_test.search(path.get_file().get_basename()) != null


## Every set in scope, sorted by folder; sets without frame files (all packed
## into a sheet) are left out. Problems (a set of another frame count, sizes
## that do not fit the cell) go to errors.
static func find(errors: Array[String]) -> Array[CharacterSet]:
	var out: Array[CharacterSet] = []
	for folder in set_folders():
		var s := _read_set(folder, errors)
		if s != null:
			out.append(s)
	return out


## Every character set folder (res://...), sorted.
static func set_folders() -> PackedStringArray:
	var folders: PackedStringArray = []
	for place in DirAccess.get_directories_at(VILLAGE_DIR):
		var parent := VILLAGE_DIR + place + ("" if place == CHARACTERS else "/villagers")
		if not DirAccess.dir_exists_absolute(parent):
			continue
		for d in DirAccess.get_directories_at(parent):
			folders.append(parent + "/" + d)
	folders.sort()
	return folders


static func _read_set(folder: String, errors: Array[String]) -> CharacterSet:
	var name := folder.get_file()
	var numbered := {}
	for f in DirAccess.get_files_at(folder):
		if f.get_extension().to_lower() != "png" or is_pixel_test(f):
			continue
		var n := CharacterSheet.frame_number(folder + "/" + f)
		if n > 0:
			numbered[n] = folder + "/" + f
	if numbered.is_empty():
		return null
	var count := numbered.size()
	for n in range(1, count + 1):
		if not numbered.has(n):
			errors.append("%s: frames are not numbered 1..%d" % [folder, count])
			return null
	if count != WALK_FRAMES and count != 1:
		return null # ball (3 frames)
	var s := CharacterSet.new()
	s.folder = folder
	s.name = name
	for n in range(1, count + 1):
		s.frames.append(numbered[n])
	if count == 1:
		var size := image_size(s.frames[0])
		if size.x > CharacterSheet.CELL.x or size.y > CharacterSheet.CELL.y:
			return null # the zodiac images
	return s


## The size of a PNG from its header (no decoding).
static func image_size(path: String) -> Vector2i:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return Vector2i.ZERO
	f.big_endian = true
	f.seek(16)
	var w := f.get_32()
	var h := f.get_32()
	return Vector2i(w, h)


## The image of a PNG file as RGBA8 (the source file, not the import).
static func load_rgba(path: String) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image != null and image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	return image


## True when both images have the same size and the same RGBA8 bytes.
static func same_pixels(a: Image, b: Image) -> bool:
	return a != null and b != null and a.get_size() == b.get_size() \
			and a.get_format() == b.get_format() and a.get_data() == b.get_data()


## The folder of a res:// path without res:// (as the legacy paths are).
static func legacy_path(path: String) -> String:
	return path.trim_prefix("res://")
