shader_type particles;
// StarParticle (src/bodies/particles/StarParticle.gd) on the GPU: the stars
// of Home of the Gods. A star is placed once (the system's warm-up shape),
// never moves or dies, has a random colour (0.5 + random / 2 per channel)
// and takes a new one with chance 0.01 per step (here: 1 - 0.99^(STEPS *
// DELTA) per frame). It is drawn at its own position on the screen, not the
// village's (the node keeps the screen's origin). The legacy code never
// steps the bottom layer, where the stars are, so they never change colour.

#include "res://scenes/common/particles/particles.gdshaderinc"

vec3 star_color(inout uint s) {
	float r = 0.5 + next_random(s) / 2.0;
	float g = 0.5 + next_random(s) / 2.0;
	return vec3(r, g, 0.5 + next_random(s) / 2.0);
}

void start() {
	uint s = emission_seed(NUMBER, RANDOM_SEED);
	float size = random_size(s);
	vec2 p = emit_position(s);
	TRANSFORM = particle_transform(p, size);
	VELOCITY = vec3(0.0);
	USERDATA1 = vec4(star_color(s), size);
	USERDATA2 = vec4(0.0);
	COLOR = vec4(USERDATA1.rgb, intensity);
}

void process() {
	USERDATA2.x += 1.0;
	uint s = hash_u(NUMBER) ^ hash_u(uint(USERDATA2.x));
	if (next_random(s) < 1.0 - pow(0.99, STEPS * DELTA)) {
		USERDATA1.rgb = star_color(s);
	}
	VELOCITY = vec3(0.0);
	TRANSFORM = particle_transform(TRANSFORM[3].xy, USERDATA1.w);
	COLOR = vec4(USERDATA1.rgb, intensity);
}
