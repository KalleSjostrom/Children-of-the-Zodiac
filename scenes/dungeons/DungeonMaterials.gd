@tool
class_name DungeonMaterials
extends RefCounted
## Materials of the dungeon scenes: the dungeon shader
## (dungeon_gl.gdshaderinc, GLBackend's spatial shader with material
## uniforms) in the render-mode variant of a GL render state, with the light,
## material and fog values of a DungeonStyle (decision 2: the fixed-function
## look, exactly).
##
## A render state is what GLBackend.material_3d keys its materials by: the
## texture, additive blending, depth test and write, the cull mode (0 none,
## 1 GL back faces, 2 GL front faces), lighting, fog, opaque (blending off)
## and the alpha test. The geometry is built like the legacy quads (counter
## clockwise front faces, as GL), so GL back faces are culled with Godot's
## cull_front, as GLBackend does.

const INCLUDE := "res://scenes/dungeons/dungeon_gl.gdshaderinc"

static var _shaders := {}
static var _materials := {}


## A render state with GLBackend's defaults for lit, textured geometry with
## depth test and GL back face culling (the state the walls are compiled in).
static func state(texture: Texture2D = null) -> Dictionary:
	return {"texture": texture, "use_tex": texture != null, "additive": false, "depth_test": true,
		"depth_write": true, "cull": 1, "lit": true, "fog": false, "opaque": false,
		"alpha_func": 0x0207, "alpha_ref": 0.0} # GL_ALWAYS


## The shared material of a render state and style.
static func material(st: Dictionary, style: DungeonStyle) -> ShaderMaterial:
	var tex: Texture2D = st.texture
	var key := "%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%.4f|%d" % [tex.get_instance_id() if tex else 0,
		int(st.use_tex), int(st.additive), int(st.depth_test), int(st.depth_write), st.cull, int(st.lit),
		int(st.fog), int(st.opaque), st.alpha_func, st.alpha_ref,
		style.get_instance_id() if style else 0]
	var m: ShaderMaterial = _materials.get(key)
	if m != null:
		return m
	m = ShaderMaterial.new()
	m.shader = shader(st.additive, st.depth_test, st.depth_write, st.cull)
	if st.use_tex and tex != null:
		m.set_shader_parameter("tex", tex)
	m.set_shader_parameter("use_tex", st.use_tex and tex != null)
	m.set_shader_parameter("lit", st.lit)
	m.set_shader_parameter("fog", st.fog)
	m.set_shader_parameter("opaque", st.opaque)
	m.set_shader_parameter("alpha_func", st.alpha_func)
	m.set_shader_parameter("alpha_ref", st.alpha_ref)
	if style != null:
		apply_style(m, style)
	_materials[key] = m
	return m


## Drops the shared materials and shaders (Main, when the game quits).
static func clear_cache() -> void:
	_materials.clear()
	_shaders.clear()


## The shader variant of a render mode (GLBackend._shader_3d).
static func shader(additive: bool, depth_test: bool, depth_write: bool, cull: int) -> Shader:
	var key := "%d%d%d%d" % [int(additive), int(depth_test), int(depth_write), cull]
	if _shaders.has(key):
		return _shaders[key]
	var modes := ["unshaded", "blend_add" if additive else "blend_mix",
		"depth_draw_always" if depth_write else "depth_draw_never"]
	modes.append(["cull_disabled", "cull_front", "cull_back"][cull])
	if not depth_test:
		modes.append("depth_test_disabled")
	var s := Shader.new()
	s.code = "shader_type spatial;\nrender_mode %s;\n\n#include \"%s\"\n" % [", ".join(modes), INCLUDE]
	_shaders[key] = s
	return s


## Sets the light, material and fog uniforms as LabyrinthRenderer.addLight,
## setMaterial and addFog set the GL state at the floor's first frame (the
## modelview is the identity then, so a light position is in eye space).
## The light model ambient keeps GL's default; fog start and end are never
## set (GL_EXP ignores them).
static func apply_style(m: ShaderMaterial, style: DungeonStyle) -> void:
	m.set_shader_parameter("fog_color", _v4(style.fog_color))
	m.set_shader_parameter("fog_params", Vector4(0, style.fog_density, 0, 1))
	m.set_shader_parameter("light_model_ambient", Vector4(0.2, 0.2, 0.2, 1))
	m.set_shader_parameter("mat_ambient", _v4(style.material_ambient))
	m.set_shader_parameter("mat_diffuse", _v4(style.material_diffuse))
	m.set_shader_parameter("mat_emission", _v4(style.material_emission))
	# GLBackend lights the first two enabled GL lights (light0, then light1).
	var lights: Array = []
	if style.light0:
		lights.append([style.light0_position, style.light0_ambient, style.light0_diffuse, style.light0_attenuation])
	if style.light1:
		lights.append([style.light1_position, style.light1_ambient, style.light1_diffuse, style.light1_attenuation])
	for slot in 2:
		var p := "light%d_" % slot
		if slot >= lights.size():
			m.set_shader_parameter(p + "att", Vector4(1, 0, 0, 0))
			continue
		var l: Array = lights[slot]
		var pos: Vector4 = l[0]
		if pos.w != 0.0:
			pos = Vector4(pos.x * pos.w, pos.y * pos.w, pos.z * pos.w, pos.w)
		m.set_shader_parameter(p + "pos", pos)
		m.set_shader_parameter(p + "amb", _v4(l[1]))
		m.set_shader_parameter(p + "dif", _v4(l[2]))
		var att: Vector3 = l[3]
		m.set_shader_parameter(p + "att", Vector4(att.x, att.y, att.z, 1))


static func _v4(c: Color) -> Vector4:
	return Vector4(c.r, c.g, c.b, c.a)
