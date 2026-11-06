class_name DungeonLook
extends RefCounted
## A prototype look of the labyrinths (docs/LOOK_PROTOTYPES_PLAN.md): another
## way to draw a few dungeon floors, chosen with --look=<name> or the
## console's "look". The default look ("legacy") is the floor scenes as
## converted, and nothing here runs for it.
##
## The looks live in res://proto/, which the shipping export leaves out
## (export_presets.cfg), so game code reaches them only through this class,
## by path with load(): a class_name of proto/ named in game code would
## compile from source but break the exported build.
##
## A look has two parts, both in its script (extends DungeonLook):
## * global: apply_global, for what the look changes in the whole game (the
##   pixel look's filter over the whole frame), called when the look is
##   switched on or off;
## * per floor: for_floor makes an instance for one of FLOORS, and
##   DungeonScene calls it while it sets up and draws that floor (set_up,
##   floor_built, show_object, and view_shown when the look moves the
##   camera).

const DEFAULT := &"legacy"
## The looks and their scripts.
const SCRIPTS := {
	&"hd-painted": "res://proto/hd/HDLook.gd",
	&"hd-photo": "res://proto/hd/HDLook.gd",
	&"pixel": "res://proto/pixel/PixelLook.gd",
}
## The floors with prototype content (DungeonScene.map_name); every other
## floor keeps the default look.
const FLOORS: PackedStringArray = ["Forest of Reil--Forest Path.map", "The Great Mine--Tunnel.map"]

## The look's name (a key of SCRIPTS).
var look_name: StringName


## The names the console offers.
static func names() -> PackedStringArray:
	var out := PackedStringArray([String(DEFAULT)])
	for k: StringName in SCRIPTS:
		out.append(String(k))
	return out


## Switches to the look name (Main.look) with its settings changed by
## settings (configure): its global part at once, the floors from their next
## entry. Returns "" or what went wrong (an unknown look, one whose script is
## missing as in an export without proto/, a bad setting).
static func set_current(look: StringName, settings := {}) -> String:
	var now := _create(look)
	if look != DEFAULT and now == null:
		return "No look '%s' here (%s)" % [look, ", ".join(names())]
	if now != null and not settings.is_empty():
		var bad := now.configure(settings)
		if bad != "":
			return bad
	elif now == null and not settings.is_empty():
		return "The default look has no settings"
	var old := _create(Main.look)
	if old != null:
		old.apply_global(Main.instance, false)
	Main.look = look
	if now != null:
		now.apply_global(Main.instance, true)
	return ""


## The settings of the current look, for the console ("" for the default).
static func current_settings() -> String:
	var now := _create(Main.look)
	return "" if now == null else now.describe()


## "key=value key=value" (or with commas) as a Dictionary: the settings of
## the console's look and of --look-settings.
static func parse_settings(text: String) -> Dictionary:
	var out := {}
	for word in text.replace(",", " ").split(" ", false):
		var kv := word.split("=", true, 1)
		out[kv[0]] = kv[1] if kv.size() > 1 else ""
	return out


## The look of the floor map_name (a .map file name, as main.bank names it):
## null in the default look and on a floor without prototype content.
static func for_floor(map_name: String) -> DungeonLook:
	if Main.look == DEFAULT or not FLOORS.has(map_name):
		return null
	return _create(Main.look)


static func _create(look: StringName) -> DungeonLook:
	var path: String = SCRIPTS.get(look, "")
	if path == "" or not ResourceLoader.exists(path):
		return null
	var instance: DungeonLook = load(path).new()
	instance.look_name = look
	return instance


## Changes the look's settings (key: value, as the console gives them; kept
## for the session in the look's script); returns "" or what is wrong.
func configure(settings: Dictionary) -> String:
	return "%s has no settings (%s)" % [look_name, ", ".join(PackedStringArray(settings.keys()))]


## The look's settings as "key=value ...", for the console.
func describe() -> String:
	return ""


## The look's changes to the whole game, made (on) or undone (not on) when
## it is switched on or off, and made again when its settings change; main
## is the Main node.
func apply_global(_main: Node, _on: bool) -> void:
	pass


## The floor's run-time scene is set up (DungeonScene._set_up, before its
## first frame, possibly before it enters the tree).
func set_up(_scene: DungeonScene) -> void:
	pass


## The floor's walls, floors and roofs were built (DungeonScene.show_floor).
func floor_built(_scene: DungeonScene) -> void:
	pass


## True when the camera moves through the floor (the legacy view's inverse)
## instead of the floor moving past a camera at the origin.
func moves_camera() -> bool:
	return false


## Every frame of a look that moves the camera, after the camera was placed
## (camera: its transform, the legacy view's inverse).
func view_shown(_scene: DungeonScene, _camera: Transform3D) -> void:
	pass


## Every frame, for each of the floor's objects (DungeonScene.show_object):
## true when the look draws object (its node, or null) itself, and the scene
## leaves out the quad its legacy draw would draw (view, Inventory.place_view,
## also when that is not visible).
func show_object(_scene: DungeonScene, _object: DungeonObject, _view: Dictionary) -> bool:
	return false
