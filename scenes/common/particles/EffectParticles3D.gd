class_name EffectParticles3D
extends GPUParticles3D
## A card or enemy effect on the GPU (the battle effects phase,
## docs/MODERNIZATION_PLAN.md 6.11): the particles of one legacy battle
## ParticleSystem (src/particleSystem). The process shader
## (effect_particle.gdshader) runs the legacy particle laws as per-second
## rates at 30 steps a second; the draw pass (effect_draw.gdshaderinc) draws
## each particle as the legacy quad, in the legacy render state.
##
## Step B: the legacy ParticleSystem stays in charge. It is built, stepped
## and asked for its drawing as before (with a smaller pool, whose particle
## counts decide when the battle goes on, ParticleSystem.reduce_for_waits);
## where its draw would draw, it asks GLBackend for this node in the frame's
## 3D chunk (Graphics.show_node, a batch slot among the legacy batches) and
## hands it its state (show_state): its settings at the first frame, then
## the game time it ran, its body, gravity, emitter and destroy events, and
## the GL render state. A node its system no longer draws is freed at the
## end of the frame (GLBackend).
##
## The node is in eye space: the battle draws with the identity modelview
## and the chunk's camera at the origin.

const PROCESS_SHADER := preload("res://scenes/common/particles/effect_particle.gdshader")
const DRAW_INCLUDE := "res://scenes/common/particles/effect_draw.gdshaderinc"
## Far beyond any battle (s): a slot is never emitted a second time by Godot.
const LIFETIME := 1000000.0

static var _draw_shaders := {}

var _started := false
var _elapsed := 0.0
var _render_key := ""
var _path_time := 0.0


## A new node for GLBackend.show_node.
static func make() -> EffectParticles3D:
	return EffectParticles3D.new()


func _init() -> void:
	lifetime = LIFETIME
	explosiveness = 1.0
	local_coords = true
	interpolate = false
	# Every frame with its delta (decision 6), not Godot's default 30 steps.
	fixed_fps = 0
	emitting = false
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visibility_aabb = AABB(Vector3(-1000, -1000, -1000), Vector3(2000, 2000, 2000))
	sorting_use_aabb_center = false
	var material := ShaderMaterial.new()
	material.shader = PROCESS_SHADER
	process_material = material
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)
	quad.material = ShaderMaterial.new()
	draw_pass_1 = quad


## The legacy system's state this frame (ParticleSystem.gpu_state): at the
## first call also "seed", "amount", "preprocess" and "settings" (the
## process shader's constant uniforms: the emitter, the particles' laws, the
## path, the image points); every frame "elapsed" (s of game time it ran
## since the last frame), "body_position", "body_velocity", "emitting",
## "gravity" (null: none), "destroy_events", "plain_events", "kill_events",
## "flare_pull", "path_time" (the interpolating emitter's time on its path:
## it lags while the pool is empty), "render" (Graphics.render_state_3d: blending, depth, the
## alpha test, fog) and "textures" (the system's, in order).
func show_state(state: Dictionary) -> void:
	if not _started:
		_start(state)
	_elapsed += float(state.get("elapsed", 0.0))
	var p := process_material as ShaderMaterial
	p.set_shader_parameter(&"body_position", state.body_position)
	p.set_shader_parameter(&"body_velocity", state.body_velocity)
	p.set_shader_parameter(&"emitting", state.emitting)
	p.set_shader_parameter(&"has_gravity", state.gravity != null)
	p.set_shader_parameter(&"gravity", state.gravity if state.gravity != null else Vector3.ZERO)
	p.set_shader_parameter(&"destroy_events", float(state.destroy_events))
	p.set_shader_parameter(&"plain_events", float(state.plain_events))
	p.set_shader_parameter(&"kill_events", float(state.kill_events))
	p.set_shader_parameter(&"flare_pull", state.get("flare_pull", false))
	var path_time: float = state.get("path_time", 0.0)
	p.set_shader_parameter(&"path_time_from", _path_time)
	p.set_shader_parameter(&"path_time_to", path_time)
	_path_time = path_time
	_show_render(state.render, state.textures)


## The legacy system's time runs the particles: the game time it ran since
## the last frame over the frame's delta.
func _process(delta: float) -> void:
	if not _started:
		return
	speed_scale = _elapsed / delta if delta > 0.0 else 0.0
	_elapsed = 0.0


func _start(state: Dictionary) -> void:
	_started = true
	amount = maxi(int(state.amount), 1)
	var p := process_material as ShaderMaterial
	var settings: Dictionary = state.settings
	for key: String in settings:
		p.set_shader_parameter(StringName(key), settings[key])
	if state.has("points"):
		_set_points(p, state.points)
	use_fixed_seed = true
	seed = int(state.seed)
	preprocess = float(state.get("preprocess", 0.0))
	emitting = true
	restart(true)


## Image points (Flame2Emitter, ShatterEmitter): "positions" (eye space) and,
## for shatter, "colors" (colour and alpha), one per texel of two float
## textures.
func _set_points(p: ShaderMaterial, points: Dictionary) -> void:
	var positions: PackedVector3Array = points.positions
	var count := positions.size()
	p.set_shader_parameter(&"emission_point_count", count)
	if count == 0:
		return
	var width := mini(count, 1024)
	@warning_ignore("integer_division")
	var height := (count + width - 1) / width
	var pos_image := Image.create_empty(width, height, false, Image.FORMAT_RGBAF)
	var color_image := Image.create_empty(width, height, false, Image.FORMAT_RGBAF)
	var colors: PackedColorArray = points.get("colors", PackedColorArray())
	for i in count:
		var v := positions[i]
		pos_image.set_pixel(i % width, i / width, Color(v.x, v.y, v.z, 1.0))
		if i < colors.size():
			color_image.set_pixel(i % width, i / width, colors[i])
	p.set_shader_parameter(&"emission_points", ImageTexture.create_from_image(pos_image))
	p.set_shader_parameter(&"emission_colors", ImageTexture.create_from_image(color_image))


## The draw pass in the legacy render state: the shader variant of its
## blending and depth (cached), its alpha test, fog and textures.
func _show_render(render: Dictionary, textures: Array) -> void:
	var quad := draw_pass_1 as QuadMesh
	var m := quad.material as ShaderMaterial
	var key := "%d%d%d" % [int(render.additive), int(render.depth_test), int(render.depth_write)]
	if key != _render_key:
		_render_key = key
		m.shader = _draw_shader(render.additive, render.depth_test, render.depth_write)
		for i in textures.size():
			m.set_shader_parameter(StringName("tex%d" % i), textures[i])
	m.set_shader_parameter(&"fog", render.fog)
	m.set_shader_parameter(&"opaque", render.opaque)
	m.set_shader_parameter(&"alpha_func", render.alpha_func)
	m.set_shader_parameter(&"alpha_ref", render.alpha_ref)


## The draw shader of a render state (GLBackend._shader_3d's modes). The
## legacy quads face the camera whatever the GL culling (their corners turn
## counter-clockwise), and the QuadMesh does too: no culling.
static func _draw_shader(additive: bool, depth_test: bool, depth_write: bool) -> Shader:
	var key := "%d%d%d" % [int(additive), int(depth_test), int(depth_write)]
	if _draw_shaders.has(key):
		return _draw_shaders[key]
	var modes := ["unshaded", "blend_add" if additive else "blend_mix",
		"depth_draw_always" if depth_write else "depth_draw_never"]
	modes.append("cull_disabled")
	if not depth_test:
		modes.append("depth_test_disabled")
	var s := Shader.new()
	s.code = "shader_type spatial;\nrender_mode %s;\n\n#include \"%s\"\n" % [", ".join(modes), DRAW_INCLUDE]
	_draw_shaders[key] = s
	return s
