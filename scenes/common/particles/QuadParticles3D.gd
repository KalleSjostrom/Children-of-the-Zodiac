@tool
class_name QuadParticles3D
extends GPUParticles3D
## A particle system of a dungeon floor on the GPU (the dungeon particles
## phase, docs/MODERNIZATION_PLAN.md 6.11): the base of WeatherParticles3D
## (rain, snow) and SaveParticles3D (a save point). Its process shader runs
## the legacy particle laws as per-second rates at 60 steps a second; its draw
## pass is quad_particle_3d.gdshader: each particle is the axis-aligned quad
## the legacy draw gives it, oriented by the player's facing, additive, in
## the floor's fog.
##
## The particles never die and are emitted once (their process shader
## restarts them as the legacy particles restart), so the lifetime is longer
## than any run. The node's local coordinates are the floor's dungeon units:
## its parent carries the legacy modelview (the camera stays at the origin,
## docs/ARCHITECTURE.md section 10).
##
## Step B: the legacy system stays in charge (WeatherSystem, SaveSystem): it
## is built, updated and asked for its drawing as before, without particles,
## and every frame its owner hands this node what that drawing would draw
## (show_state): whether the legacy system was updated (the particles run for
## the frame's time, or stand still), the player's facing, the GL alpha test
## and fog, and whether it draws at all (set_shown: hidden, a system stands
## still, as the legacy particles do while they are not drawn).
##
## Tuning in the editor: intensity, size_scale.

const DRAW_SHADER := preload("res://scenes/common/particles/quad_particle_3d.gdshader")
## Far beyond any run (s): a slot is never emitted a second time.
const LIFETIME := 1000000.0

## The particle texture (the legacy system's).
@export var texture: Texture2D:
	set(value):
		texture = value
		_set_draw(&"tex", value)
## The legacy quad: its width and height, and its first corner as a share
## of them from the particle's position (along the quad, up, across).
@export var quad_size := Vector2(0.075, 0.075):
	set(value):
		quad_size = value
		_update_quad()
@export var quad_corner := Vector3(-0.5, -0.5, -0.5):
	set(value):
		quad_corner = value
		_update_quad()
## Multiplies the alpha every particle is drawn with.
@export_range(0.0, 2.0, 0.01) var intensity := 1.0:
	set(value):
		intensity = value
		_set_draw(&"intensity", value)
## Multiplies the drawn size of every particle.
@export_range(0.1, 4.0, 0.01) var size_scale := 1.0:
	set(value):
		size_scale = value
		_update_quad()

var _started := false


func _init() -> void:
	lifetime = LIFETIME
	explosiveness = 1.0
	local_coords = true
	interpolate = false
	# Every frame with its delta (decision 6), not Godot's default 30 steps.
	fixed_fps = 0
	draw_order = GPUParticles3D.DRAW_ORDER_VIEW_DEPTH
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visibility_aabb = AABB(Vector3(-10000, -10000, -10000), Vector3(20000, 20000, 20000))
	sorting_use_aabb_center = false
	var quad := QuadMesh.new()
	var draw := ShaderMaterial.new()
	draw.shader = DRAW_SHADER
	quad.material = draw
	draw_pass_1 = quad


func _ready() -> void:
	_set_draw(&"tex", texture)
	_set_draw(&"intensity", intensity)
	_update_quad()
	if not Engine.is_editor_hint() and not _started:
		emitting = false


## Starts the particles with a fixed seed (drawn from the legacy system's
## generator, so seeded runs repeat) and a warm-up of preprocess_s seconds.
func start(particle_seed: int, preprocess_s := 0.0) -> void:
	if _started:
		return
	_started = true
	use_fixed_seed = true
	seed = particle_seed
	preprocess = preprocess_s
	emitting = true
	restart(true)


## The legacy system's state this frame: "running" (it was updated since the
## last frame: the particles run for the frame's time, else they stand
## still), "shown" (its draw draws them), "facing" (the player's integer
## angle, degrees) and "state", the GL render state its quads would be drawn
## in (Graphics.render_state_3d: the alpha test, fog on or off; the fog's
## values are the floor's style). An empty state: not drawn, standing still.
func show_state(state: Dictionary, style: DungeonStyle) -> void:
	var st: Dictionary = state.get("state", {})
	speed_scale = 1.0 if state.get("running", false) else 0.0
	set_shown(state.get("shown", false))
	_set_draw(&"along_x", along_x(int(state.get("facing", 0))))
	_set_draw(&"alpha_func", int(st.get("alpha_func", 0x0204)))
	_set_draw(&"alpha_ref", float(st.get("alpha_ref", 0.0)))
	_set_draw(&"fog", st.get("fog", false) and style != null)
	if style != null:
		_set_draw(&"fog_color", Vector4(style.fog_color.r, style.fog_color.g, style.fog_color.b, style.fog_color.a))
		_set_draw(&"fog_params", Vector4(0, style.fog_density, 0, 1))


## Shows or hides the particles: hidden, a paused system keeps its state (the
## legacy particles stand still while they are not drawn).
func set_shown(shown: bool) -> void:
	visible = shown


## Whether the legacy quad lies in the x-y plane for the facing (else in the
## z-y plane). Overridden by the systems.
func along_x(_facing: int) -> bool:
	return true


func _update_quad() -> void:
	var size := quad_size * size_scale
	_set_draw(&"quad_size", size)
	_set_draw(&"quad_origin", Vector3(quad_corner.x * size.x, quad_corner.y * size.y, quad_corner.z * size.x))


func _set_process(parameter: StringName, value: Variant) -> void:
	var material := process_material as ShaderMaterial
	if material != null:
		material.set_shader_parameter(parameter, value)


func _set_draw(parameter: StringName, value: Variant) -> void:
	var quad := draw_pass_1 as QuadMesh
	if quad != null and quad.material is ShaderMaterial:
		(quad.material as ShaderMaterial).set_shader_parameter(parameter, value)
