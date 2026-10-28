// The life law of FireParticle and RainbowParticle (src/bodies/particles):
// a particle starts with life 1 and a random fade (random / fade.x + fade.y,
// Particle.getFadeValue); every step the fade grows by
// (distance² / FADE_DISTANCE)³ / fade.z, the distance from where the
// particle was emitted, and the life drops by the fade. The particle dies at
// life 0 and is drawn with alpha = life. Here both are per-second rates at
// STEPS steps a second.
//
// Particle state: USERDATA1 = (emit position, fade, life), USERDATA2 = the
// random colour, USERDATA3 = (size).
//
// A master system's slave (MasterSlaveEmitter: Pass to Zazo's fire and its
// smoke) is a system of its own: see smoke_particle.gdshader.
//
// Include after particles.gdshaderinc, with FADE_DISTANCE defined and
// RANDOM_COLOR defined for a random colour per emission (RainbowParticle).

// The particle's fade (x, y, z) of particleSystems.info (default 1000;0.001;2000).
uniform vec3 fade = vec3(1000.0, 0.001, 2000.0);

// The drawn colour: rgb (USERDATA2, the random colour) or the system's.
vec4 particle_color(vec3 rgb, float life) {
#ifdef RANDOM_COLOR
	return vec4(rgb, clamp(life, 0.0, 1.0) * intensity);
#else
	return vec4(color, clamp(life, 0.0, 1.0) * intensity);
#endif
}

void start() {
	uint s = emission_seed(NUMBER, RANDOM_SEED);
	float mass = random_mass(s);
	float size = random_size(s);
	vec2 emit = emit_position(s);
	vec2 v = emit_velocity(s, mass, vec2(0.0));
	float f = next_random(s) / fade.x + fade.y;
#ifdef RANDOM_COLOR
	float r = next_random(s);
	float g = next_random(s);
	USERDATA2 = vec4(r, g, next_random(s), 0.0);
#endif
	// The emission's own step.
	vec2 p = emit + v / STEPS;
	vec2 d = p - emit;
	f += pow(dot(d, d) / FADE_DISTANCE, 3.0) / fade.z;
	float life = 1.0 - f;
	USERDATA1 = vec4(emit, f, life);
	TRANSFORM = particle_transform(p, size);
	VELOCITY = vec3(v, 0.0);
	COLOR = particle_color(USERDATA2.rgb, life);
	USERDATA3 = vec4(size, 0.0, 0.0, 0.0);
}

void process() {
	vec2 p = TRANSFORM[3].xy;
	vec2 d = p - USERDATA1.xy;
	float f = USERDATA1.z + STEPS * DELTA * pow(dot(d, d) / FADE_DISTANCE, 3.0) / fade.z;
	float life = USERDATA1.w - STEPS * DELTA * f;
	USERDATA1.zw = vec2(f, life);
	if (life <= 0.0) {
		ACTIVE = false;
	}
	TRANSFORM = particle_transform(p, USERDATA3.x);
	COLOR = particle_color(USERDATA2.rgb, life);
}
