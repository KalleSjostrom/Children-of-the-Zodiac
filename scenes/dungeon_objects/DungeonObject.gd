@tool
class_name DungeonObject
extends Node3D
## An object of a dungeon floor: an "inv" line of a .map file (a legacy
## labyrinth Inventory: chest, door, hinder door, lever, save point, ...).
## One scene per kind in scenes/dungeon_objects/, each with its script; the
## floor scene lists them under Objects in file order, which is the order
## the legacy loader created them in (door indices, links to earlier
## objects and the Database reads depend on it).
##
## The node stands at its cell's centre (DungeonCell.center); a View child
## (AnimatedSprite3D with the object's frames) shows it in the editor as the
## legacy drawing does: a quad, a wall or a floor tile.
##
## Step A (docs/MODERNIZATION_PLAN.md 7.4): create_inventory builds the
## legacy object as Inventory.createInventory does for the line: the same
## constructor with the same arguments, the same database name and status
## reads. The exports are those constructor arguments, typed; the text of
## names ("_" for spaces) is kept as the .map file writes it, since the
## legacy constructors convert it.
##
## Step B (7.5): the legacy object stays in charge; Labyrinth hands the scene
## its state every frame (DungeonScene.show_object): whether it is drawn, the
## frame it binds and the quad its draw would draw. The scene draws that
## quad, with the legacy vertices to the bit and batched as the legacy
## drawing batches it: a hinder door lies in the plane of its wall, and which
## of the two shows is decided by their depth's rounding, which a Sprite3D's
## own vertices would decide differently (a door that vanishes while
## turning). The View mirrors the frame, hidden at run time.

## The .map command of the line ("chest", "door--up", "hinderDoor", ...): its
## part before "--" names the object in the Database, "--up" / "--down" make
## a door lead up or down a floor.
@export var kind := ""
## The cell (DungeonCell.address) the object is in.
@export var cell := 0
## The direction the object faces (Values.UP .. LEFT): the wall it is on, for
## doors; the side its quad faces, for the others. This is the legacy
## Inventory.dir, the opposite of the direction the .map line gives.
@export var facing := 0
## The image the legacy object draws, as the .map file names it (under
## res/Labyrinth/; a series without its number and extension: "Images/chest"
## for chest0.png and chest1.png).
@export var image := ""
## The object's name in the Database (Inventory.dataBaseName): map name,
## kind and cell ("the great mine--tunnel.maphinderdoor51"). Its status
## there is the object's state; buttons name the doors they open by it, also
## on other floors. Written by the converter, derived again at load.
@export var database_name := ""

const _MARK_COLOR := Color(0.3, 0.6, 1.0)

## What the legacy object draws: a quad standing in the cell
## (Inventory._drawQuad), one of the cell's walls (HinderDoor:
## LabyrinthNode.drawOneWall) or its floor tile (FloorButton: drawOneFloor).
enum ViewShape { QUAD, WALL, FLOOR }


func _ready() -> void:
	if Engine.is_editor_hint():
		_add_editor_marker()


## Step A: the legacy inventory of this line, as Inventory.createInventory
## builds it for map (a LabyrinthMap with its nodes) on the floor lab_name
## (MapLoader.labyrinthName). Puts it on its node; the caller adds it to the
## map's inventory list.
func create_inventory(map, lab_name: String) -> Inventory:
	var command_name := kind.get_slice("--", 0)
	var db_name: String = Organizer.convert(lab_name + command_name + str(cell))
	var status: int = Database.getStatusFor(db_name)
	var n = map.getNode(cell)
	var inv: Inventory = _new_inventory(n, map, status)
	if inv == null:
		push_error("DungeonObject: no inventory for %s (%s)" % [name, kind])
		return null
	inv.setDatabaseName(_database_name_for(db_name))
	inv.checkHaveBeen()
	n.setInventory(inv)
	return inv


## The legacy constructor call of this kind (override). status is the
## Database status read for the object.
func _new_inventory(node, map, status: int) -> Inventory:
	return null


## The database name the legacy object gets (a boss uses its name instead).
func _database_name_for(db_name: String) -> String:
	return db_name


## Is a direction down or up a floor ("door--up")? Calls setGoingUp as the
## legacy loader does for a command with "--".
func _set_going(door) -> void:
	if kind.contains("--"):
		door.setGoingUp(kind.get_slice("--", 1) == "up")


## Inventory.getHinders: the objects that the names (database names as the
## .map file writes them) stand for, a DummyDoor for a name that is not on
## this floor (yet): buttons open doors on other floors through them.
static func hinders_for(map, names: PackedStringArray) -> Array:
	var hinders: Array = []
	for n in names:
		var db_name: String = Organizer.convert(n)
		var inv = map.getInventory(db_name)
		hinders.append(inv if inv != null else DummyDoor.new(db_name))
	return hinders


## The rest of a line as a legacy tokenizer, for constructors that read
## their extra tokens themselves (doors read their further destinations).
static func tokens(words: PackedStringArray) -> StringTokenizer:
	return StringTokenizer.new(" ".join(words))


## Dialogs as the legacy objects keep them: [speaker, line 1, line 2].
static func legacy_dialogs(dialogs: Array[PackedStringArray]) -> Array:
	var out: Array = []
	for d in dialogs:
		out.append(Array(d))
	return out


## Step B: mirrors what the legacy object inv draws this frame (view, its
## place_view; the scene draws its quad): the View's frame.
func show_view(inv, view: Dictionary) -> void:
	var v := get_node_or_null(^"View") as AnimatedSprite3D
	if v != null and v.sprite_frames != null and view.has("frame"):
		v.frame = clampi(view.frame, 0, v.sprite_frames.get_frame_count(&"default") - 1)


## Step B: hides the views (the legacy drawing shows what it draws).
func hide_view() -> void:
	for n in ["View", "Particles"]:
		var v := get_node_or_null(NodePath(n)) as Node3D
		if v != null:
			v.visible = false


## The shape the legacy object inv draws.
static func view_shape(inv) -> ViewShape:
	if inv is HinderDoor:
		return ViewShape.WALL
	if inv is FloorButton:
		return ViewShape.FLOOR
	return ViewShape.QUAD


## The transform (in the floor's space) that makes a View (a Sprite3D,
## centred, pixel_size 1) showing a frame of frame_size pixels cover the
## quad the legacy object inv draws: its node's position, its direction and,
## for a quad, its size, height and offset from the cell's centre as
## Inventory.setSettings and initDraw left them. The quad's normal is the
## View's +z axis.
static func view_transform(inv, frame_size: Vector2) -> Transform3D:
	var p = inv.getNode().getPos()
	var px: float = p.getX()
	var pz: float = p.getZ()
	var fw := maxf(frame_size.x, 1.0)
	var fh := maxf(frame_size.y, 1.0)
	match view_shape(inv):
		ViewShape.FLOOR:
			return Transform3D(Basis(Vector3.RIGHT, -PI / 2) * Basis.from_scale(Vector3(4.0 / fw, 4.0 / fh, 1)),
					Vector3(px, LabyrinthNode.FLOOR_HEIGHT, pz))
		ViewShape.WALL:
			var wall_centre: Array[Vector3] = [Vector3(px, 0, pz + 2), Vector3(px - 2, 0, pz),
				Vector3(px, 0, pz - 2), Vector3(px + 2, 0, pz)]
			return Transform3D(_facing_basis(inv.dir) * Basis.from_scale(Vector3(4.0 / fw, 4.0 / fh, 1)),
					wall_centre[inv.dir])
	var w: float = inv.width * inv.scale2
	var h: float = inv.height * inv.scale2
	var y: float = LabyrinthNode.FLOOR_HEIGHT + inv.heightOffset + h / 2
	var z_off: float = inv.zOff
	var centre: Array[Vector3] = [Vector3(px, y, pz + z_off), Vector3(px - z_off, y, pz),
		Vector3(px, y, pz - z_off), Vector3(px + z_off, y, pz)]
	return Transform3D(_facing_basis(inv.dir) * Basis.from_scale(Vector3(w / fw, h / fh, 1)), centre[inv.dir])


## A wall view of the backward-facing sides (UP and LEFT) has its texture
## mirrored (drawOneWall's flip).
static func view_flipped(inv) -> bool:
	return view_shape(inv) == ViewShape.WALL and (inv.dir == 0 or inv.dir == 3)


## The rotation that turns the View's +z to the legacy quad's normal for a
## direction: UP (0) -z, RIGHT (1) +x, DOWN (2) +z, LEFT (3) -x.
static func _facing_basis(dir: int) -> Basis:
	return Basis(Vector3.UP, [PI, PI / 2, 0.0, -PI / 2][dir])


## The editor marker: the object's kind and cell above it.
func _add_editor_marker() -> void:
	var label := Label3D.new()
	label.text = _marker_text()
	label.position = Vector3(0, 1.6, 0)
	label.pixel_size = 0.004
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = _MARK_COLOR
	label.no_depth_test = true
	add_child(label, false, Node.INTERNAL_MODE_FRONT)


func _marker_text() -> String:
	return "%s %d" % [kind, cell]
