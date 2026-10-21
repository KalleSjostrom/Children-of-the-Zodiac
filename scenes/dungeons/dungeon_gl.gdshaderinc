// The fixed-function look of the legacy GL emulation (decision 2 of
// docs/MODERNIZATION_PLAN.md: keep it exactly): GLBackend's spatial shader
// (src/graphics/GLBackend.gd, SHADER_3D_TEMPLATE) with material uniforms in
// place of its global uniforms, so that a dungeon scene shows the same pixels
// in the editor and at run time, with the values of its DungeonStyle.
// Per-vertex lighting in eye space from light0 and light1 and the material
// (no specular term, as in GLBackend), per-fragment fog (exp, exp2 or linear
// by eye distance), the GL alpha test and texture modulation. The arithmetic
// is GLBackend's, line by line; keep the two in step.
//
// Include after the render_mode line; the shader that includes it adds
// nothing else.

uniform sampler2D tex : filter_linear, repeat_disable;
uniform bool use_tex = true;
uniform bool lit = false;
uniform bool fog = false;
uniform bool opaque = false;
uniform int alpha_func = 0;
uniform float alpha_ref = 0.0;

uniform vec4 fog_color = vec4(0.0, 0.0, 0.0, 0.0);
uniform vec4 fog_params = vec4(0.0, 1.0, 0.0, 1.0); // mode (0 exp, 1 exp2, 2 linear), density, start, end
uniform vec4 light_model_ambient = vec4(0.2, 0.2, 0.2, 1.0);
uniform vec4 mat_ambient = vec4(0.2, 0.2, 0.2, 1.0);
uniform vec4 mat_diffuse = vec4(0.8, 0.8, 0.8, 1.0);
uniform vec4 mat_emission = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 light0_pos = vec4(0.0, 0.0, 1.0, 0.0); // eye space
uniform vec4 light0_amb = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 light0_dif = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 light0_att = vec4(1.0, 0.0, 0.0, 0.0); // constant, linear, quadratic, enabled
uniform vec4 light1_pos = vec4(0.0, 0.0, 1.0, 0.0);
uniform vec4 light1_amb = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 light1_dif = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 light1_att = vec4(1.0, 0.0, 0.0, 0.0);

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
	return a * (amb.rgb * mat_ambient.rgb + ndl * dif.rgb * mat_diffuse.rgb);
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
		vec3 c = mat_emission.rgb + light_model_ambient.rgb * mat_ambient.rgb;
		if (light0_att.w > 0.5) { c += light_term(light0_pos, light0_amb, light0_dif, light0_att, ep, en); }
		if (light1_att.w > 0.5) { c += light_term(light1_pos, light1_amb, light1_dif, light1_att, ep, en); }
		v_color = vec4(clamp(c, 0.0, 1.0) * COLOR.rgb, mat_diffuse.a * COLOR.a);
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
		if (fog_params.x < 0.5) { f = exp(-fog_params.y * z); }
		else if (fog_params.x < 1.5) { f = exp(-pow(fog_params.y * z, 2.0)); }
		else { f = (fog_params.w - z) / max(fog_params.w - fog_params.z, 0.00001); }
		c.rgb = mix(fog_color.rgb, c.rgb, clamp(f, 0.0, 1.0));
	}
	ALBEDO = to_linear(clamp(c.rgb, 0.0, 1.0));
	ALPHA = opaque ? 1.0 : c.a;
}
