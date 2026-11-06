// The HD look's moving fog (docs/LOOK_PROTOTYPES_PLAN.md 4.2): a FogVolume
// over the floor whose density is a 3D noise that drifts with the wind, thick
// near the ground and thinning out by `height` above it.
shader_type fog;

uniform sampler3D noise : repeat_enable;
uniform float density = 0.06;
uniform vec3 albedo : source_color = vec3(0.8, 0.8, 0.85);
uniform vec3 wind = vec3(0.35, 0.02, 0.15);
uniform float noise_scale = 0.07;
uniform float floor_y = -2.0;
uniform float height = 1.8;
// The noise below `cover` is clear air; above it the fog thickens.
uniform float cover = 0.45;

void fog() {
	vec3 p = (WORLD_POSITION - wind * TIME) * noise_scale;
	float n = texture(noise, p).r * 0.65 + texture(noise, p * 2.7 + vec3(0.37)).r * 0.35;
	float h = clamp(1.0 - (WORLD_POSITION.y - floor_y) / height, 0.0, 1.0);
	DENSITY = density * smoothstep(cover, cover + 0.3, n) * h * h;
	ALBEDO = albedo;
}
