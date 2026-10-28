shader_type particles;
render_mode disable_force, disable_velocity;
// The particles of a save point on the GPU (SaveParticles3D): the legacy
// SaveParticle laws (src/particleSystem). They step once per frame and never
// had the 30 Hz correction, so (decision 6) every per-step law is a
// per-second rate at 60 steps a second, applied with each frame's DELTA.
//
// Coordinates: the node's local coordinates are the floor's dungeon units.
//
// A particle stands on a ring of radius 0.9 around the save point (at one of
// 360 whole degrees, for good) and rises from y -2 at its speed, fading; above
// y 1 or faded out it starts again with a new colour, speed and fade. Its
// colour cycles (red, green and blue grow at different rates and start again
// at 0 above 1); it is drawn with alpha = life. It never dies otherwise, so a
// slot is never emitted again.
//
// VELOCITY.y: the speed per legacy step; USERDATA1: x = the fade per step,
// w = how often the particle restarted (the random state of its restarts).
// COLOR: the colour, alpha = life.

#include "res://scenes/common/particles/random.gdshaderinc"

const float STEPS = 60.0;

// The save point's centre (x, z): SaveSystem.pos, its node's position.
uniform vec2 center = vec2(0.0);

// SaveParticle.resurrect: speed, fade, colour; y -2 and life 1.
void resurrect(inout uint s, inout vec3 p, inout vec4 color, inout vec3 velocity, inout float fade) {
	velocity = vec3(0.0, (next_random(s) * 4.0 + 8.0) * 0.001, 0.0);
	p.y = -2.0;
	fade = next_random(s) / 100.0 + 0.0025;
	color = vec4(next_random(s), next_random(s), next_random(s), 1.0);
}

void start() {
	uint s = emission_seed(INDEX, RANDOM_SEED);
	vec3 p = vec3(0.0);
	vec4 color;
	vec3 velocity;
	float fade;
	resurrect(s, p, color, velocity, fade);
	// SaveParticle._init: a whole degree of the ring.
	float theta = radians(floor(next_random(s) * 360.0) - 180.0);
	p.xz = center + 0.9 * vec2(cos(theta), sin(theta));
	TRANSFORM = mat4(1.0);
	TRANSFORM[3].xyz = p;
	VELOCITY = velocity;
	COLOR = color;
	USERDATA1 = vec4(fade, 0.0, 0.0, 0.0);
}

void process() {
	float k = STEPS * DELTA;
	vec3 p = TRANSFORM[3].xyz;
	vec4 color = COLOR;
	p.y += VELOCITY.y * k;
	if (p.y > 1.0 || color.a <= 0.0) {
		USERDATA1.w += 1.0;
		uint s = emission_seed(uint(USERDATA1.w), RANDOM_SEED + uint(INDEX) * 2654435761u);
		vec3 velocity;
		float fade;
		resurrect(s, p, color, velocity, fade);
		VELOCITY = velocity;
		USERDATA1.x = fade;
	} else {
		color.a -= USERDATA1.x * k;
	}
	// The colour cycle: red +0.01, green +0.02, blue +0.03 a step, 0 again
	// above 1.
	color.rgb += vec3(0.01, 0.02, 0.03) * k;
	color.rgb = mix(color.rgb, vec3(0.0), vec3(greaterThan(color.rgb, vec3(1.0))));
	TRANSFORM[3].xyz = p;
	COLOR = color;
}
