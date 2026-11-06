class_name ActorView
extends AnimatedSprite2D
## An actor in the Actors layer of a village scene. Villagers and animated
## objects are saved in the scene (role VILLAGER or ANIMATED_OBJECT, with the
## data VillageScene.load_into reads); party members and story actors are
## added at run time (role RUNTIME).
##
## Phase 1 step B: the legacy sprite (Villager, PartyMember, AnimatedObjects,
## DefaultSprite) stays in charge. Every frame the village hands the view the
## image the sprite would draw and where (show_frame); the view shows that
## image from its SpriteFrames (animations "up", "right", "down" and "left"
## for a villager, "default" for an animated object) and adds images it does
## not know (party members, story animations) to an "extra" animation. The
## origin is the sprite's top-left corner (centered = false), the legacy
## position.
##
## Frames are looked up by a key, not by object (_frame_key): a frame of a
## character sheet (docs/VILLAGER_SPRITES_PLAN.md) is an AtlasTexture, and
## the SpriteFrames' AtlasTextures and ImageHandler's are different objects
## of the same sheet and cell; they still match after ImageHandler drops a
## game mode's list and makes new ones.

enum Role { RUNTIME, VILLAGER, ANIMATED_OBJECT }

@export var role: Role = Role.RUNTIME
## VILLAGER: the name of the villager line ("_" read as a space): its file is
## maps/Village/<villager_folder>/villagers/<villager_name>.char. The node's
## position is only a preview: the start position is in the .char file
## (unless walk_override).
@export var villager_name := ""
## VILLAGER: the villager is there only when the Database status of its name
## is one of these; empty: always.
@export var statuses: PackedInt32Array = []
## VILLAGER: the folder of the .char file and of the villager's images.
@export var villager_folder := ""
## ANIMATED_OBJECT: the image series res/Village/<folder>/animobj/<name>/;
## the node's position is the object's position.
@export var object_name := ""
## ANIMATED_OBJECT: the number of images (the first four are animated).
@export var image_count := 4
## VILLAGER in a remake's scene (VillageRemake): the villager starts at the
## node's position and walks walk instead of its .char file's start and in
## lines (VillageScene._override_walk).
@export var walk_override := false
## The walk: one .char "in" line each without the "in" ("<direction>
## <distance> <stopped>[ <speed>]", direction 0-3 up, right, down, left;
## stopped: stand still that long). It must end where it starts.
@export var walk: PackedStringArray = []

## Key of the mirrored legacy sprite in its sprite map (get_instance_id());
## 0 when the actor is not loaded (a villager of another status).
var sprite_key := 0
var _frame_of := {} # _frame_key(texture) -> [animation, frame index]
var _owns_frames := false


func _ready() -> void:
	_index_frames()


## Shows texture with its top-left corner at at (village pixels); null hides
## the actor (the legacy sprite has no image).
func show_frame(texture: Texture2D, at: Vector2i) -> void:
	if texture == null:
		visible = false
		return
	visible = true
	position = Vector2(at)
	var found: Array = _frame_of.get(_frame_key(texture), [])
	if found.is_empty():
		found = _add_extra_frame(texture)
	if animation != found[0]:
		animation = found[0]
	if frame != found[1]:
		frame = found[1]


func _index_frames() -> void:
	_frame_of.clear()
	if sprite_frames == null:
		return
	for anim in sprite_frames.get_animation_names():
		for i in sprite_frames.get_frame_count(anim):
			var t := sprite_frames.get_frame_texture(anim, i)
			if t == null:
				continue
			var key: Variant = _frame_key(t)
			if not _frame_of.has(key):
				_frame_of[key] = [anim, i]


func _add_extra_frame(texture: Texture2D) -> Array:
	# The SpriteFrames resource is shared by every view of the image set.
	if not _owns_frames:
		sprite_frames = sprite_frames.duplicate() if sprite_frames != null else SpriteFrames.new()
		_owns_frames = true
	if not sprite_frames.has_animation(&"extra"):
		sprite_frames.add_animation(&"extra")
		sprite_frames.set_animation_loop(&"extra", false)
	var index := sprite_frames.get_frame_count(&"extra")
	sprite_frames.add_frame(&"extra", texture)
	var found := [&"extra", index]
	_frame_of[_frame_key(texture)] = found
	return found


## The key of a frame: an AtlasTexture's atlas and region (the sheet is one
## object, ResourceLoader's), any other texture itself.
static func _frame_key(texture: Texture2D) -> Variant:
	if texture is AtlasTexture:
		var atlas := texture as AtlasTexture
		return [atlas.atlas, atlas.region]
	return texture
