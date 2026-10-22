class_name GLBackend
extends RefCounted
## Rendering backend for the OpenGL 2 emulation in Graphics.
##
## The original game drew everything in immediate mode, mixing 2D (orthographic
## 1024x768, y down) and 3D (gluPerspective(45, 4/3, 1, 75)) in one frame.
## This backend keeps the draw order by splitting each frame into "chunks":
##  - 2D chunks are canvas items (children of the canvas node: Main's
##    LegacyLayer/Canvas, above the scene in World; ordered by index),
##  - 3D chunks are SubViewports rendering an ArrayMesh per batch; their
##    textures are composited into the canvas at the chunk's position.
## Batches inside a 3D chunk keep submission order via sorting_offset.
##
## Bridge (phase 2 step B, docs/ARCHITECTURE.md section 10): while the current
## mode shows a 3D scene in the main viewport (a converted dungeon floor),
## the frame's first 3D chunk, when nothing 2D was drawn before it, goes into
## that scene instead of a SubViewport (SceneChunk, under scene_3d): the
## legacy 3D drawn there (a battle, the weather's front pass during it, the
## minimap) shares the depth buffer and the blending with the scene, as it
## shared one chunk with the legacy walls.

const VIRTUAL_SIZE := Vector2(1024, 768)
const MAX_SURFACE_VERTS := 60000

var host: Node # owns the SubViewports; its viewport is the screen
var root_ci: RID

# Canvas items reused between frames (pool), in draw order.
var _ci_pool: Array[RID] = []
var _ci_used := 0
var _cur_ci := RID()
var _cur_kind := 0 # 0 = none, 1 = 2D, 2 = 3D
var _cur_2d_key := ""
var _cur_ci_xform := Transform2D.IDENTITY

var _vp_pool: Array = []
var _vp_used := 0
var _cur_vp: Chunk3D = null

## Bridge: the node of the scene that this frame's first 3D chunk goes into, set by the mode while it draws (Graphics.use_scene_3d);
## null at the start of every frame.
var scene_3d: Node3D = null
var _scene_chunk: SceneChunk = null
var _scene_chunk_used := false

var _canvas_materials := {} # key -> Material (or null)
var _shader_cache := {} # render mode key -> Shader
var _material_cache := {} # material key -> ShaderMaterial
var _canvas_alpha_shaders := {} # blend -> Shader
var _premult_material: CanvasItemMaterial

var vp_pixel_size := Vector2i(1024, 768)
var stats_chunks := 0


## canvas: the parent of the 2D canvas items (default: the host itself).
func _init(p_host: Node, canvas: CanvasItem = null) -> void:
	host = p_host
	root_ci = (canvas if canvas != null else p_host as CanvasItem).get_canvas_item()
	_premult_material = CanvasItemMaterial.new()
	_premult_material.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	_register_globals()


static var _globals_registered := false


static func _register_globals() -> void:
	if _globals_registered:
		return
	_globals_registered = true
	var rs := RenderingServer
	var vec4 := RenderingServer.GLOBAL_VAR_TYPE_VEC4
	var f := RenderingServer.GLOBAL_VAR_TYPE_FLOAT
	var defs := {
		"gl_fog_color": [vec4, Vector4(0, 0, 0, 0)],
		"gl_fog_params": [vec4, Vector4(0, 1, 0, 1)], # mode, density, start, end
		"gl_light_model_ambient": [vec4, Vector4(0.2, 0.2, 0.2, 1)],
		"gl_mat_ambient": [vec4, Vector4(0.2, 0.2, 0.2, 1)],
		"gl_mat_diffuse": [vec4, Vector4(0.8, 0.8, 0.8, 1)],
		"gl_mat_emission": [vec4, Vector4(0, 0, 0, 1)],
	}
	for i in 2:
		defs["gl_light%d_pos" % i] = [vec4, Vector4(0, 0, 1, 0)]
		defs["gl_light%d_amb" % i] = [vec4, Vector4(0, 0, 0, 1)]
		defs["gl_light%d_dif" % i] = [vec4, Vector4(1, 1, 1, 1) if i == 0 else Vector4(0, 0, 0, 1)]
		defs["gl_light%d_att" % i] = [vec4, Vector4(1, 0, 0, 0)] # const, lin, quad, enabled
	for k in defs:
		rs.global_shader_parameter_add(k, defs[k][0], defs[k][1])


static func set_global(name: String, value) -> void:
	RenderingServer.global_shader_parameter_set(name, value)


# ---------------------------------------------------------------------------
# Frame handling
# ---------------------------------------------------------------------------

## Frees the canvas items and viewports (call when the host leaves the tree).
func free_all() -> void:
	for ci in _ci_pool:
		RenderingServer.free_rid(ci)
	_ci_pool.clear()
	_ci_used = 0


func begin_frame() -> void:
	for i in _ci_used:
		RenderingServer.canvas_item_clear(_ci_pool[i])
	_ci_used = 0
	for i in _vp_used:
		_vp_pool[i].begin_frame()
	_vp_used = 0
	if _scene_chunk != null:
		_scene_chunk.begin_frame()
	_scene_chunk_used = false
	scene_3d = null
	_cur_kind = 0
	_cur_ci = RID()
	_cur_vp = null
	_cur_2d_key = ""
	stats_chunks = 0
	_update_viewport_size()


func end_frame() -> void:
	for i in _vp_used:
		_vp_pool[i].end_frame()
	if _scene_chunk != null:
		if _scene_chunk_used:
			_scene_chunk.end_frame()
		else:
			_scene_chunk.set_active(false)
	for i in range(_vp_used, _vp_pool.size()):
		_vp_pool[i].set_active(false)
	for i in range(_ci_used, _ci_pool.size()):
		RenderingServer.canvas_item_clear(_ci_pool[i])


## Discards everything drawn so far this frame (glClear of the color buffer).
func clear_frame() -> void:
	begin_frame()


func _update_viewport_size() -> void:
	var win := host.get_viewport().get_visible_rect().size
	var final_xform := host.get_viewport().get_final_transform()
	var scale := final_xform.get_scale()
	var px := Vector2i(roundi(VIRTUAL_SIZE.x * scale.x), roundi(VIRTUAL_SIZE.y * scale.y))
	if px.x < 16 or px.y < 12:
		px = Vector2i(1024, 768)
	vp_pixel_size = px


func _acquire_ci(material: Material) -> RID:
	var ci: RID
	if _ci_used < _ci_pool.size():
		ci = _ci_pool[_ci_used]
	else:
		ci = RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(ci, root_ci)
		_ci_pool.append(ci)
	RenderingServer.canvas_item_set_draw_index(ci, _ci_used)
	RenderingServer.canvas_item_set_material(ci, material.get_rid() if material else RID())
	_ci_used += 1
	stats_chunks += 1
	return ci


# ---------------------------------------------------------------------------
# 2D
# ---------------------------------------------------------------------------

## Returns the canvas item to draw 2D primitives with the given blend and
## alpha test state on (starting a new chunk if the state changed).
func ci_2d(additive: bool, alpha_func: int, alpha_ref: float) -> RID:
	var key := _canvas_key(additive, alpha_func, alpha_ref)
	if _cur_kind == 1 and key == _cur_2d_key:
		return _cur_ci
	_cur_kind = 1
	_cur_2d_key = key
	_cur_ci = _acquire_ci(_canvas_material(key, additive, alpha_func, alpha_ref))
	_cur_ci_xform = Transform2D.IDENTITY
	return _cur_ci


func set_ci_transform(ci: RID, xform: Transform2D) -> void:
	if xform != _cur_ci_xform:
		RenderingServer.canvas_item_add_set_transform(ci, xform)
		_cur_ci_xform = xform


static func _alpha_passes_all(alpha_func: int, alpha_ref: float) -> bool:
	match alpha_func:
		Graphics.GL_ALWAYS, -1:
			return true
		Graphics.GL_LEQUAL:
			return alpha_ref >= 1.0
		Graphics.GL_LESS:
			return alpha_ref > 1.0
		Graphics.GL_GREATER:
			return alpha_ref < 0.0
		Graphics.GL_GEQUAL:
			return alpha_ref <= 0.0
	return false


func _canvas_key(additive: bool, alpha_func: int, alpha_ref: float) -> String:
	if _alpha_passes_all(alpha_func, alpha_ref):
		return "add" if additive else "mix"
	return "%s|%d|%.4f" % ["add" if additive else "mix", alpha_func, alpha_ref]


func _canvas_material(key: String, additive: bool, alpha_func: int, alpha_ref: float) -> Material:
	if _canvas_materials.has(key):
		return _canvas_materials[key]
	var mat: Material = null
	if key == "mix":
		mat = null
	elif key == "add":
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		mat = m
	else:
		var sm := ShaderMaterial.new()
		sm.shader = _canvas_alpha_shader(additive)
		sm.set_shader_parameter("alpha_func", alpha_func)
		sm.set_shader_parameter("alpha_ref", alpha_ref)
		mat = sm
	_canvas_materials[key] = mat
	return mat


func _canvas_alpha_shader(additive: bool) -> Shader:
	if _canvas_alpha_shaders.has(additive):
		return _canvas_alpha_shaders[additive]
	var s := Shader.new()
	s.code = """shader_type canvas_item;
render_mode %s;
uniform int alpha_func = 0;
uniform float alpha_ref = 0.0;
void fragment() {
	float a = COLOR.a;
	bool pass_test = true;
	if (alpha_func == 0x0204) { pass_test = a > alpha_ref; }
	else if (alpha_func == 0x0206) { pass_test = a >= alpha_ref; }
	else if (alpha_func == 0x0201) { pass_test = a < alpha_ref; }
	else if (alpha_func == 0x0203) { pass_test = a <= alpha_ref; }
	else if (alpha_func == 0x0202) { pass_test = a == alpha_ref; }
	else if (alpha_func == 0x0200) { pass_test = false; }
	if (!pass_test) { discard; }
}
""" % ("blend_add" if additive else "blend_mix")
	_canvas_alpha_shaders[additive] = s
	return s


# ---------------------------------------------------------------------------
# 3D
# ---------------------------------------------------------------------------

## Returns the current 3D chunk, starting a new one if needed.
func vp_3d() -> Chunk3D:
	if _cur_kind == 2:
		return _cur_vp
	if _ci_used == 0 and not _scene_chunk_used and is_instance_valid(scene_3d):
		# Nothing 2D before it in this frame: the chunk is the scene's.
		if _scene_chunk == null:
			_scene_chunk = SceneChunk.new()
		_scene_chunk.attach(scene_3d)
		_scene_chunk_used = true
		_cur_kind = 2
		_cur_vp = _scene_chunk
		_cur_2d_key = ""
		return _scene_chunk
	var vp: Viewport3D
	if _vp_used < _vp_pool.size():
		vp = _vp_pool[_vp_used]
	else:
		vp = Viewport3D.new(host)
		_vp_pool.append(vp)
	_vp_used += 1
	vp.set_active(true)
	vp.set_size(vp_pixel_size)
	vp.begin_frame()
	var ci := _acquire_ci(_premult_material)
	RenderingServer.canvas_item_add_texture_rect(ci, Rect2(Vector2.ZERO, VIRTUAL_SIZE), vp.texture_rid())
	_cur_kind = 2
	_cur_vp = vp
	_cur_2d_key = ""
	return vp


## Forces the next 3D primitive to start in a fresh 3D chunk (fresh depth).
func break_3d() -> void:
	if _cur_kind == 2:
		_cur_kind = 0


func material_3d(st: Dictionary) -> ShaderMaterial:
	var key := "%d|%d|%d|%d|%d|%d|%d|%d|%d|%.4f|%d" % [
		st.tex_id, int(st.additive), int(st.depth_test), int(st.depth_write), st.cull,
		int(st.lit), int(st.fog), int(st.opaque), st.alpha_func, st.alpha_ref, int(st.use_tex)]
	var m: ShaderMaterial = _material_cache.get(key)
	if m != null:
		return m
	m = ShaderMaterial.new()
	m.shader = _shader_3d(st.additive, st.depth_test, st.depth_write, st.cull)
	if st.use_tex and st.texture != null:
		m.set_shader_parameter("tex", st.texture)
	m.set_shader_parameter("use_tex", st.use_tex and st.texture != null)
	m.set_shader_parameter("lit", st.lit)
	m.set_shader_parameter("fog", st.fog)
	m.set_shader_parameter("opaque", st.opaque)
	m.set_shader_parameter("alpha_func", st.alpha_func)
	m.set_shader_parameter("alpha_ref", st.alpha_ref)
	_material_cache[key] = m
	return m


func _shader_3d(additive: bool, depth_test: bool, depth_write: bool, cull: int) -> Shader:
	var key := "%d%d%d%d" % [int(additive), int(depth_test), int(depth_write), cull]
	if _shader_cache.has(key):
		return _shader_cache[key]
	var modes := ["unshaded", "blend_add" if additive else "blend_mix",
		"depth_draw_always" if depth_write else "depth_draw_never"]
	# GL front faces are counter clockwise, Godot's are clockwise, so GL's
	# "cull back faces" is Godot's cull_front.
	modes.append(["cull_disabled", "cull_front", "cull_back"][cull])
	if not depth_test:
		modes.append("depth_test_disabled")
	var s := Shader.new()
	s.code = SHADER_3D_TEMPLATE.replace("$MODES", ", ".join(modes))
	_shader_cache[key] = s
	return s


const SHADER_3D_TEMPLATE := """shader_type spatial;
render_mode $MODES;

uniform sampler2D tex : filter_linear, repeat_disable;
uniform bool use_tex = true;
uniform bool lit = false;
uniform bool fog = false;
uniform bool opaque = false;
uniform int alpha_func = 0;
uniform float alpha_ref = 0.0;

global uniform vec4 gl_fog_color;
global uniform vec4 gl_fog_params;
global uniform vec4 gl_light_model_ambient;
global uniform vec4 gl_mat_ambient;
global uniform vec4 gl_mat_diffuse;
global uniform vec4 gl_mat_emission;
global uniform vec4 gl_light0_pos;
global uniform vec4 gl_light0_amb;
global uniform vec4 gl_light0_dif;
global uniform vec4 gl_light0_att;
global uniform vec4 gl_light1_pos;
global uniform vec4 gl_light1_amb;
global uniform vec4 gl_light1_dif;
global uniform vec4 gl_light1_att;

varying vec4 v_color;
varying vec3 v_eye;

vec3 light_term(vec4 lpos, vec4 amb, vec4 dif, vec4 att, vec3 ep, vec3 en) {
	vec3 l;
	float a = 1.0;
	if (lpos.w != 0.0) {
		vec3 d = lpos.xyz / lpos.w - ep;
		float dist = length(d);
		l = dist > 0.00001 ? d / dist : vec3(0.0, 0.0, 1.0);
		a = 1.0 / max(att.x + att.y * dist + att.z * dist * dist, 0.00001);
	} else {
		float len = length(lpos.xyz);
		l = len > 0.00001 ? lpos.xyz / len : vec3(0.0);
	}
	float ndl = max(dot(en, l), 0.0);
	return a * (amb.rgb * gl_mat_ambient.rgb + ndl * dif.rgb * gl_mat_diffuse.rgb);
}

vec3 to_linear(vec3 c) {
	return mix(pow((c + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)), c * (1.0 / 12.92), lessThan(c, vec3(0.04045)));
}

void vertex() {
	vec3 ep = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_eye = ep;
	v_color = COLOR;
	if (lit) {
		vec3 en = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
		vec3 c = gl_mat_emission.rgb + gl_light_model_ambient.rgb * gl_mat_ambient.rgb;
		if (gl_light0_att.w > 0.5) { c += light_term(gl_light0_pos, gl_light0_amb, gl_light0_dif, gl_light0_att, ep, en); }
		if (gl_light1_att.w > 0.5) { c += light_term(gl_light1_pos, gl_light1_amb, gl_light1_dif, gl_light1_att, ep, en); }
		// OpenGL 2 without GL_COLOR_MATERIAL (the original never enables it):
		// a lit vertex takes the material's colours and its diffuse alpha, not
		// the current colour (glColor).
		v_color = vec4(clamp(c, 0.0, 1.0), gl_mat_diffuse.a);
	}
}

void fragment() {
	vec4 c = v_color;
	if (use_tex) {
		c *= texture(tex, UV);
	}
	bool pass_test = true;
	if (alpha_func == 0x0204) { pass_test = c.a > alpha_ref; }
	else if (alpha_func == 0x0206) { pass_test = c.a >= alpha_ref; }
	else if (alpha_func == 0x0201) { pass_test = c.a < alpha_ref; }
	else if (alpha_func == 0x0203) { pass_test = c.a <= alpha_ref; }
	else if (alpha_func == 0x0202) { pass_test = c.a == alpha_ref; }
	else if (alpha_func == 0x0200) { pass_test = false; }
	if (!pass_test || c.a <= 0.0) { discard; }
	if (fog) {
		float z = length(v_eye);
		float f;
		if (gl_fog_params.x < 0.5) { f = exp(-gl_fog_params.y * z); }
		else if (gl_fog_params.x < 1.5) { f = exp(-pow(gl_fog_params.y * z, 2.0)); }
		else { f = (gl_fog_params.w - z) / max(gl_fog_params.w - gl_fog_params.z, 0.00001); }
		c.rgb = mix(gl_fog_color.rgb, c.rgb, clamp(f, 0.0, 1.0));
	}
	ALBEDO = to_linear(clamp(c.rgb, 0.0, 1.0));
	ALPHA = opaque ? 1.0 : c.a;
}
"""


## One 3D chunk: a pool of mesh instances, one per batch, under parent.
class Chunk3D extends RefCounted:
	var parent: Node
	var instances: Array[MeshInstance3D] = []
	var batches: Array = []
	var used := 0
	## Sorting offset of the first batch (later batches are drawn on top).
	var base_offset := 0.0

	func set_active(active: bool) -> void:
		if not active:
			for mi in instances:
				if is_instance_valid(mi):
					mi.visible = false

	func begin_frame() -> void:
		batches.clear()

	## Adds triangles (eye space) for the given material; merges with the
	## previous batch when the material is the same.
	func add_triangles(mat: Material, v: PackedVector3Array, uv: PackedVector2Array,
			c: PackedColorArray, n: PackedVector3Array) -> void:
		if batches.size() > 0:
			var last: Dictionary = batches[batches.size() - 1]
			# Mesh batches (display lists, see add_mesh) have no "mat"/"v".
			if last.has("v") and last.mat == mat and last.v.size() + v.size() < MAX_SURFACE_VERTS:
				last.v.append_array(v)
				last.uv.append_array(uv)
				last.c.append_array(c)
				last.n.append_array(n)
				return
		batches.append({"mat": mat, "v": v.duplicate(), "uv": uv.duplicate(),
			"c": c.duplicate(), "n": n.duplicate()})

	## Adds an instance of a prebuilt mesh (display list) with a transform.
	func add_mesh(mesh: Mesh, xform: Transform3D) -> void:
		batches.append({"mesh": mesh, "xform": xform})

	func _instance(i: int) -> MeshInstance3D:
		while instances.size() <= i:
			var mi := MeshInstance3D.new()
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.sorting_use_aabb_center = false
			mi.extra_cull_margin = 16384.0
			parent.add_child(mi)
			instances.append(mi)
		return instances[i]

	func end_frame() -> void:
		var i := 0
		for b in batches:
			var mi := _instance(i)
			if b.has("mesh"):
				mi.mesh = b.mesh
				mi.transform = b.xform
			else:
				var am: ArrayMesh = mi.get_meta("own_mesh") if mi.has_meta("own_mesh") else null
				if am == null:
					am = ArrayMesh.new()
					mi.set_meta("own_mesh", am)
				am.clear_surfaces()
				var arrays := []
				arrays.resize(Mesh.ARRAY_MAX)
				arrays[Mesh.ARRAY_VERTEX] = b.v
				arrays[Mesh.ARRAY_TEX_UV] = b.uv
				arrays[Mesh.ARRAY_COLOR] = b.c
				arrays[Mesh.ARRAY_NORMAL] = b.n
				am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
				am.surface_set_material(0, b.mat)
				mi.mesh = am
				mi.transform = Transform3D.IDENTITY
			# Later batches are drawn on top: Godot sorts transparent objects by
			# depth minus sorting_offset.
			mi.sorting_offset = base_offset + float(i) * 1000.0
			mi.visible = true
			i += 1
		for j in range(i, instances.size()):
			instances[j].visible = false
		used = i


## A 3D chunk in the current mode's 3D scene (GLBackend.scene_3d: a node with
## the identity transform, in a world whose camera is at the origin, so the
## batches' eye-space vertices are drawn as in a SubViewport chunk): its
## batches are drawn after the scene's own instances (whose sorting offsets
## are below 1e6).
class SceneChunk extends Chunk3D:
	func _init() -> void:
		base_offset = 1000000.0

	## Moves the chunk to another scene node (the pool of the old one is
	## dropped: freed with its scene, or now).
	func attach(node: Node3D) -> void:
		if node == parent:
			return
		for mi in instances:
			if is_instance_valid(mi):
				mi.queue_free()
		instances.clear()
		parent = node

	func set_active(active: bool) -> void:
		if not is_instance_valid(parent):
			instances.clear()
			parent = null
			return
		super.set_active(active)


## A 3D chunk of its own: a SubViewport with a camera matching the original
## projection, composited into the canvas as a texture.
class Viewport3D extends Chunk3D:
	var vp: SubViewport
	var cam: Camera3D

	func _init(host: Node) -> void:
		vp = SubViewport.new()
		vp.transparent_bg = true
		vp.own_world_3d = true
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		vp.size = Vector2i(1024, 768)
		vp.msaa_3d = Viewport.MSAA_DISABLED
		vp.positional_shadow_atlas_size = 0
		cam = Camera3D.new()
		cam.fov = 45.0
		cam.near = 1.0
		cam.far = 75.0
		cam.keep_aspect = Camera3D.KEEP_HEIGHT
		vp.add_child(cam)
		var env := Environment.new()
		env.background_mode = Environment.BG_CLEAR_COLOR
		env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
		var we := WorldEnvironment.new()
		we.environment = env
		vp.add_child(we)
		host.add_child(vp)
		cam.current = true
		parent = vp

	func texture_rid() -> RID:
		return vp.get_texture().get_rid()

	func set_size(px: Vector2i) -> void:
		if vp.size != px:
			vp.size = px

	func set_active(active: bool) -> void:
		var mode := SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED
		if vp.render_target_update_mode != mode:
			vp.render_target_update_mode = mode
		super.set_active(active)
