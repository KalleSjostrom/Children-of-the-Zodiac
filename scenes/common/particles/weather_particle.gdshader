shader_type particles;
render_mode disable_force, disable_velocity;
// The rain or snow of a dungeon floor on the GPU (WeatherParticles3D): the
// legacy WeatherParticle laws (src/weather) and the view test of its draw.
// The legacy particles step once per frame and never had the 30 Hz
// correction, so (decision 6) every per-step law is a per-second rate at 60
// steps a second, applied with each frame's DELTA: the look of today's 60 FPS
// at any frame rate.
//
// Coordinates: the node's local coordinates are the dungeon units of the
// floor (4 per cell, y up), as the legacy particles' positions.
//
// A particle keeps a column of its own (x in [0, 52), z in (-52, 0]) and
// falls by the system's force plus a drift it draws when it (re)starts; below
// respawn_below it starts again at y in [2, 4) in its column. It never dies
// otherwise, so a slot is never emitted again (the node's lifetime is
// longer than any run).
//
// USERDATA1: x, z = the column, w = how often the particle restarted (the
// random state of its restarts). VELOCITY: the drift per legacy step.

#include "res://scenes/common/particles/random.gdshaderinc"

const float STEPS = 60.0;

// The system's force per step (WeatherSystem.getForce: rain -0.2, snow -0.003).
uniform float force_y = -0.2;
// Below this height a particle starts again (shouldResurrect: rain -2, snow -2.2).
uniform float respawn_below = -2.0;
// The columns' area (WeatherParticle.getWorldSize: 13 x 13 cells).
uniform vec2 world_size = vec2(52.0, 52.0);
// The view test of the pass this node draws (WeatherParticle.drawParticle):
// the player's location (x, z), the facing (the legacy integer angle in
// degrees) and the band of distances ahead that the pass draws.
uniform vec2 player_location = vec2(0.0);
uniform float facing_angle = 0.0;
uniform float near_clip = 7.5;
uniform float far_clip = 20.0;

// WeatherParticle.resurrect's drift, per legacy step.
vec3 random_drift(inout uint s) {
	float x = (next_random(s) - 0.5) / 500.0;
	float y = -next_random(s) / 300.0;
	float z = (next_random(s) - 0.5) / 500.0;
	return vec3(x, y, z);
}

// Drawn by this pass: the distance ahead s within the band and inside the
// view cone (3.7 dist^2 < 5 s^2: a half-angle of about 30.7 degrees).
bool in_view(vec3 p) {
	float a = radians(facing_angle);
	vec2 d = p.xz - player_location;
	float s = d.x * cos(a) + d.y * sin(a);
	return s > near_clip && s < far_clip && 3.7 * dot(d, d) < 5.0 * s * s;
}

// The particle's transform: its position, collapsed when the pass does not
// draw it (no fragments).
mat4 view_transform(vec3 p) {
	mat4 m = mat4(in_view(p) ? 1.0 : 0.0);
	m[3] = vec4(p, 1.0);
	return m;
}

void start() {
	uint s = emission_seed(INDEX, RANDOM_SEED);
	// WeatherParticle._init: a column, a drift, a height in [-2, 4).
	float x = next_random(s) * world_size.x;
	float z = -next_random(s) * world_size.y;
	VELOCITY = random_drift(s);
	USERDATA1 = vec4(x, 0.0, z, 0.0);
	TRANSFORM = view_transform(vec3(x, next_random(s) * 6.0 - 2.0, z));
	COLOR = vec4(1.0);
}

void process() {
	vec3 p = TRANSFORM[3].xyz + (vec3(0.0, force_y, 0.0) + VELOCITY) * (STEPS * DELTA);
	if (p.y < respawn_below) {
		// WeatherParticle.resurrect: back to the column at y in [2, 4).
		USERDATA1.w += 1.0;
		uint s = emission_seed(uint(USERDATA1.w), RANDOM_SEED + uint(INDEX) * 2654435761u);
		p = vec3(USERDATA1.x, next_random(s) * 2.0 + 2.0, USERDATA1.z);
		VELOCITY = random_drift(s);
	}
	TRANSFORM = view_transform(p);
}
