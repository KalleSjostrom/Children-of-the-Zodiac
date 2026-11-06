// The HD look's heat haze (HDLook._make_haze, docs/LOOK_PROTOTYPES_PLAN.md
// 10.10): a pass over the whole frame as drawn so far (the opaque surfaces,
// the sky and the volumetric fog) that shifts each pixel by a rising noise,
// as hot air bends the light: more the farther the surface, and the lower it
// lies (the heat rises from the floor), with the distance blurred a little and
// a warm grade. The quad covers the screen in the vertex shader. It is drawn
// first of the transparent objects (HDLook gives it the lowest render
// priority), so those drawn after it stay sharp: the legacy objects, the
// battle, the rain, the embers.
shader_type spatial;
render_mode unshaded, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled, shadows_disabled;

uniform sampler2D screen : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform sampler2D depth : hint_depth_texture, filter_nearest, repeat_disable;
// A seamless 3D noise, sampled by the view's direction: the ripples stay with
// the world as the camera turns.
uniform sampler3D noise : filter_linear, repeat_enable;

// How far the image shifts at full strength, in pixels of a 768-pixel frame.
uniform float strength = 4.0;
// How fast the ripples rise (noise periods a second).
uniform float speed = 0.3;
// The ripples' frequency: noise periods a radian of view (larger: finer).
uniform float scale = 6.0;
// No haze nearer than near (units), all of it from far.
uniform float near = 2.0;
uniform float far = 24.0;
// 0: the same at every height; 1: all of it at the floor, none at the roof.
uniform float ground = 0.5;
// The distance's blur at full strength (a mipmap level of the frame).
uniform float blur = 0.5;
// A warm, sun-bleached grade over the frame (0: none).
uniform float tint = 0.0;
uniform float floor_y = -2.0;
uniform float roof_y = 2.0;

const vec3 WARM = vec3(1.12, 0.97, 0.78);

void vertex() {
	// The quad (2×2) covers the screen, at the near plane (reversed Z).
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

// The view-space position of the surface drawn at the screen's uv.
vec3 view_at(vec2 uv, mat4 inv_projection) {
	float d = texture(depth, uv).r;
	vec4 v = inv_projection * vec4(uv * 2.0 - 1.0, d, 1.0);
	return v.xyz / v.w;
}

// How much haze (0..1) lies before the surface at view.
float amount(vec3 view, mat4 inv_view) {
	float a = smoothstep(near, max(far, near + 0.001), length(view));
	float y = (inv_view * vec4(view, 1.0)).y;
	float h = clamp((y - floor_y) / (roof_y - floor_y), 0.0, 1.0);
	return a * mix(1.0, 1.0 - h, ground);
}

void fragment() {
	vec3 view = view_at(SCREEN_UV, INV_PROJECTION_MATRIX);
	float a = amount(view, INV_VIEW_MATRIX);
	vec3 dir = normalize(mat3(INV_VIEW_MATRIX) * view);
	// Two octaves rising, the finer one faster and drifting sideways; two
	// samples of each, apart in the noise, for the shift's x and y.
	vec3 p = dir * scale - vec3(0.0, speed * TIME, 0.0);
	vec3 q = dir * scale * 2.3 - vec3(0.13, 1.7, 0.07) * speed * TIME;
	vec2 n = vec2(texture(noise, p).r, texture(noise, p + vec3(0.5, 0.31, 0.77)).r) * 0.65
		+ vec2(texture(noise, q).r, texture(noise, q + vec3(0.29, 0.61, 0.43)).r) * 0.35;
	vec2 shift = (n - 0.5) * 2.0 * strength / 768.0 * vec2(VIEWPORT_SIZE.y / VIEWPORT_SIZE.x, 1.0);
	// Where the shift lands on a nearer surface (less haze before it), the
	// shift is that surface's: a near wall's edge stays sharp and does not
	// smear over the distance behind it.
	float landed = amount(view_at(SCREEN_UV + shift * a, INV_PROJECTION_MATRIX), INV_VIEW_MATRIX);
	vec3 c = textureLod(screen, SCREEN_UV + shift * min(a, landed), blur * a).rgb;
	ALBEDO = mix(c, c * WARM, tint);
	ALPHA = 1.0;
}
