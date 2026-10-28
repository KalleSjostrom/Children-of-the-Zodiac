// The draw pass of a card or enemy effect on the GPU (EffectParticles3D):
// each particle is the quad the legacy draws (Particle.drawParticle,
// Graphics.drawCenteredCurrent2D): centred on the particle, 2 x its size,
// in the x-y plane of eye space (the battle draws with the identity
// modelview and the camera at the origin), u to the right and v down. The
// fragment is GLBackend's unlit path (SHADER_3D_TEMPLATE): texture times
// colour, the GL alpha test, the GL fog of its global uniforms. The texture
// is the particle's of the system's textures (CUSTOM.x).
//
// Include after the render_mode line (EffectParticles3D makes the variants
// of the legacy render states: blending, depth test and write).

uniform sampler2D tex0 : filter_linear, repeat_disable;
uniform sampler2D tex1 : filter_linear, repeat_disable;
uniform sampler2D tex2 : filter_linear, repeat_disable;
uniform sampler2D tex3 : filter_linear, repeat_disable;
uniform bool fog = false;
uniform bool opaque = false;
uniform int alpha_func = 0;
uniform float alpha_ref = 0.0;
// Tuning: multiplies the alpha every particle is drawn with.
uniform float intensity = 1.0;

global uniform vec4 gl_fog_color;
global uniform vec4 gl_fog_params;

varying vec3 v_eye;
varying flat int v_texture;

vec3 to_linear(vec3 c) {
	return mix(pow((c + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)), c * (1.0 / 12.92), lessThan(c, vec3(0.04045)));
}

void vertex() {
	// The mesh is a 2 x 2 QuadMesh; the particle's transform scales it by
	// its size.
	v_eye = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_texture = int(INSTANCE_CUSTOM.x + 0.5);
}

void fragment() {
	vec4 t;
	if (v_texture == 1) { t = texture(tex1, UV); }
	else if (v_texture == 2) { t = texture(tex2, UV); }
	else if (v_texture == 3) { t = texture(tex3, UV); }
	else { t = texture(tex0, UV); }
	vec4 c = COLOR * t;
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
	ALPHA = opaque ? 1.0 : c.a * intensity;
}
