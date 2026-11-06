shader_type spatial;
// The HD look's embers (HDLook._make_embers): a particle quad turned to the
// camera, within reach of it, a round glow that falls off to the edge, in
// the particle's colour (COLOR: its colour ramps), added to the frame.
// Unshaded: embers glow.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;

// The glow's strength: above 1 it blooms with the Environment's glow.
uniform float energy = 2.0;
// Embers closer to the camera than near_hidden are hidden, and fade in up to
// near_full: right at the camera they would be big blobs.
uniform float near_hidden = 0.35;
uniform float near_full = 1.2;
// How far the embers reach from the camera along the floor's axes: the half
// width of the box they are emitted in (HDLook sets both). One further away
// (it drifted out, or the camera left it behind) is drawn a box's width
// over, back in reach: so the embers are as thick all round the camera
// however it moved, and each stays in its place in the floor while in
// reach. They fade out over the last reach_fade, where they jump.
uniform float reach = 7.0;
uniform float reach_fade = 2.0;

void vertex() {
	vec3 eye = INV_VIEW_MATRIX[3].xyz;
	vec3 at = MODEL_MATRIX[3].xyz;
	vec2 off = mod(at.xz - eye.xz + reach, 2.0 * reach) - reach;
	at.xz = eye.xz + off;
	COLOR.a *= 1.0 - smoothstep(max(reach - reach_fade, 0.0), reach, max(abs(off.x), abs(off.y)));
	// As StandardMaterial3D's BILLBOARD_PARTICLES: facing the camera, with
	// the particle's place and scale.
	mat4 world = mat4(normalize(INV_VIEW_MATRIX[0]), normalize(INV_VIEW_MATRIX[1]),
			normalize(INV_VIEW_MATRIX[2]), vec4(at, 1.0));
	world = world * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
			vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
			vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = VIEW_MATRIX * world;
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 d = UV * 2.0 - 1.0;
	// A hot core and a soft falloff to zero at the quad's inscribed circle.
	float glow = clamp(1.0 - dot(d, d), 0.0, 1.0);
	glow *= glow;
	glow *= smoothstep(near_hidden, near_full, -VERTEX.z);
	ALBEDO = COLOR.rgb * energy;
	ALPHA = glow * COLOR.a;
}
