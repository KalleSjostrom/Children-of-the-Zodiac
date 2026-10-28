shader_type spatial;
render_mode unshaded, blend_add, depth_draw_always, cull_disabled;
// The draw pass of the dungeon's GPU particles (WeatherParticles3D,
// SaveParticles3D): each particle is the axis-aligned quad the legacy draw
// gives it (WeatherParticle.drawParticle, SaveParticle.drawParticle), not a
// billboard: in the x-y plane or in the z-y plane by the player's facing,
// with its corner at quad_origin from the particle's position, texture u
// along the quad's horizontal side and v up. The fragment is the dungeon
// shader's unlit path (dungeon_gl.gdshaderinc): texture times colour, the GL
// alpha test, the floor's fog; additive (SRC_ALPHA, ONE), depth tested and
// written as the legacy quads are. The legacy quads always face the camera
// (their corner order follows the facing), so no face is culled.
//
// The particle's colour comes from its process shader (COLOR); a particle
// its pass does not draw has a collapsed transform.

uniform sampler2D tex : filter_linear, repeat_disable;
// The quad's size (width, height) and where its first corner is from the
// particle's position (along its horizontal side, up, across it).
uniform vec2 quad_size = vec2(0.075, 0.075);
uniform vec3 quad_origin = vec3(-0.0375, -0.0375, -0.0375);
// The quad lies in the x-y plane (true) or in the z-y plane.
uniform bool along_x = true;
// The legacy alpha test (GL function and reference).
uniform int alpha_func = 0x0204;
uniform float alpha_ref = 0.0;
// The floor's fog (DungeonStyle): on, colour and (mode, density, start, end).
uniform bool fog = false;
uniform vec4 fog_color = vec4(0.0);
uniform vec4 fog_params = vec4(0.0, 1.0, 0.0, 1.0);
// Tuning: multiplies the alpha every particle is drawn with.
uniform float intensity = 1.0;

varying vec3 v_eye;

vec3 to_linear(vec3 c) {
	return mix(pow((c + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)), c * (1.0 / 12.92), lessThan(c, vec3(0.04045)));
}

void vertex() {
	// The mesh is a QuadMesh: UV (0, 0) at its top left corner.
	vec2 corner = vec2(UV.x, 1.0 - UV.y);
	float along = quad_origin.x + corner.x * quad_size.x;
	float up = quad_origin.y + corner.y * quad_size.y;
	VERTEX = along_x ? vec3(along, up, quad_origin.z) : vec3(quad_origin.z, up, along);
	UV = corner;
	v_eye = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// The texture as the legacy drawing samples it: GLBackend passes the
	// texture's sRGB values on as they are, and converts the result (to_linear).
	vec4 c = COLOR * texture(tex, UV);
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
		if (fog_params.x < 0.5) { f = exp(-fog_params.y * z); }
		else if (fog_params.x < 1.5) { f = exp(-pow(fog_params.y * z, 2.0)); }
		else { f = (fog_params.w - z) / max(fog_params.w - fog_params.z, 0.00001); }
		c.rgb = mix(fog_color.rgb, c.rgb, clamp(f, 0.0, 1.0));
	}
	ALBEDO = to_linear(clamp(c.rgb, 0.0, 1.0));
	ALPHA = c.a * intensity;
}
