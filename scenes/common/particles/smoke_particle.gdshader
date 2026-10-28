shader_type particles;
// SmokeParticle (src/bodies/particles/SmokeParticle.gd) on the GPU: the
// chimney smokes and the fire's smoke. A particle starts with life 0.001
// and a random fade f (random / 200 + 0.001, SmokeParticle.getFadeValue);
// every step f grows by f * distance / 10000 (the distance from where it
// was emitted), and the life rises by 2 f until it reaches max (it turns),
// then drops by f; it dies at life 0. It is drawn with alpha = life and
// scale (1 + life) * size, after the turn (1.5 (max - life) + 1 + max) * size
// (modifySize, which also clamps the life to 1 while drawing). The wind
// (WindCommand: the village's wind line, drifting with its turbulence)
// accelerates it. Here every per-step law is a per-second rate at STEPS
// steps a second.
//
// A slave system (MasterSlaveEmitter: Pass to Zazo's fire smoke) emits on
// its own, at the rate the master's deaths feed it in the legacy system
// (the generator's rate), and each particle starts where a master particle
// dies, with half its velocity plus its own emit force: start() steps that
// master particle (FireParticle's law at STEPS steps a second, from the
// shared emitter shape) until it dies. (A Godot sub-emitter would do this
// with the real master particles, but which slot takes which request
// differs from run to run, so seeded runs would not repeat.)
//
// Particle state: USERDATA1 = (emit position, fade, life), USERDATA2 =
// (turned, max, size).

#include "res://scenes/common/particles/particles.gdshaderinc"

// SmokeParticle's max (settings=[max=...]): random between max_min and max_max
// per particle, drawn log-uniformly (a legacy body keeps its max).
uniform float max_min = 0.0;
uniform float max_max = 0.0;
// The wind (legacy, y up): the shared WindCommand vector, set every frame.
uniform vec2 wind = vec2(0.0);
// A slave system: its particles start where a master particle dies; the
// master particle's mass, fade and FireParticle's fade distance.
uniform bool from_master = false;
uniform float master_mass = 0.01;
uniform vec3 master_fade = vec3(1000.0, 0.001, 2000.0);
uniform float master_fade_distance = 300.0;

// Where a master particle emitted with the state s dies (xy) and its
// velocity (zw), local coordinates: FireParticle's steps (the fade grows by
// (distance² / master_fade_distance)³ / fade.z, the life drops by the fade).
vec4 master_death(inout uint s) {
	vec2 emit = emit_position(s);
	vec2 v = emit_velocity(s, master_mass, vec2(0.0));
	float f = next_random(s) / master_fade.x + master_fade.y;
	float life = 1.0;
	vec2 p = emit;
	for (int n = 0; n < 3000 && life > 0.0; n++) {
		p += v / STEPS;
		vec2 d = p - emit;
		f += pow(dot(d, d) / master_fade_distance, 3.0) / master_fade.z;
		life -= f;
	}
	return vec4(p, v);
}

void start() {
	uint s = emission_seed(NUMBER, RANDOM_SEED);
	float mass = random_mass(s);
	float size = random_size(s);
	float r = next_random(s);
	float top = max_max > max_min && max_min > 0.0 ? max_min * pow(max_max / max_min, r) : max_min;
	vec2 emit;
	vec2 v = vec2(0.0);
	if (from_master) {
		vec4 death = master_death(s);
		emit = death.xy;
		v = death.zw * 0.5;
	} else {
		emit = emit_position(s);
	}
	v += emit_velocity(s, mass, wind);
	float f = next_random(s) / 200.0 + 0.001;
	// The emission's own step.
	vec2 p = emit + v / STEPS;
	f *= 1.0 + length(p - emit) / 10000.0;
	float life = 0.001 + 2.0 * f;
	bool turned = life >= top;
	USERDATA1 = vec4(emit, f, life);
	USERDATA2 = vec4(turned ? 1.0 : 0.0, top, size, 0.0);
	float l = min(life, 1.0);
	TRANSFORM = particle_transform(p, (turned ? 1.5 * (top - l) + 1.0 + top : 1.0 + l) * size);
	VELOCITY = vec3(v, 0.0);
	COLOR = vec4(color, l * intensity);
}

void process() {
	vec2 p = TRANSFORM[3].xy;
	float f = USERDATA1.z * pow(1.0 + length(p - USERDATA1.xy) / 10000.0, STEPS * DELTA);
	float life = USERDATA1.w;
	bool turned = USERDATA2.x > 0.5;
	float top = USERDATA2.y;
	life += (turned ? -f : 2.0 * f) * STEPS * DELTA;
	if (!turned && life >= top) {
		turned = true;
	}
	USERDATA1.zw = vec2(f, life);
	USERDATA2.x = turned ? 1.0 : 0.0;
	if (life <= 0.0) {
		ACTIVE = false;
	}
	VELOCITY.xy += vec2(wind.x, -wind.y) * DELTA;
	float l = min(life, 1.0);
	TRANSFORM = particle_transform(p, (turned ? 1.5 * (top - l) + 1.0 + top : 1.0 + l) * USERDATA2.z);
	COLOR = vec4(color, max(l, 0.0) * intensity);
}
