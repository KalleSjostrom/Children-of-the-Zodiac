shader_type particles;
// BodiesSnowParticle (src/bodies/particles/SnowParticle.gd) on the GPU:
// Dellna's snow. No fade (life 1); it falls at the velocity of its first
// step and dies when it is no longer above -height (legacy y up: here, at
// local y >= height).

#include "res://scenes/common/particles/particles.gdshaderinc"

// The snow's height (settings=[height=...]).
uniform float height = 0.0;

void start() {
	uint s = emission_seed(NUMBER, RANDOM_SEED);
	float mass = random_mass(s);
	float size = random_size(s);
	vec2 emit = emit_position(s);
	vec2 v = emit_velocity(s, mass, vec2(0.0));
	TRANSFORM = particle_transform(emit + v / STEPS, size);
	VELOCITY = vec3(v, 0.0);
	USERDATA1 = vec4(size, 0.0, 0.0, 0.0);
	COLOR = vec4(color, intensity);
}

void process() {
	if (TRANSFORM[3].y >= height) {
		ACTIVE = false;
	}
	TRANSFORM = particle_transform(TRANSFORM[3].xy, USERDATA1.x);
	COLOR = vec4(color, intensity);
}
