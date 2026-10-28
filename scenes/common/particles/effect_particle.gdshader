shader_type particles;
render_mode disable_force, disable_velocity;
// A card or enemy effect on the GPU (EffectParticles3D): the particles of one
// legacy battle ParticleSystem (src/particleSystem), whose laws (Particle,
// ParticleSystem._updateParticles, PointBody, the emitters) run here. The
// legacy effects step 30 times a second (Values.originalFrameStep); every
// per-step law is a per-second rate at STEPS steps a second, applied with
// each frame's DELTA (decision 6). The legacy system stays in charge
// (EffectParticles3D.show_state): its body's position and velocity, its
// gravity, whether its emitter still emits, and its destroy, plain destroy
// and kill events come as uniforms.
//
// Coordinates: eye space (the battle draws with the identity modelview), as
// the legacy particles' positions.
//
// The pool: a legacy emitter emits one particle per time step while its pool
// of pool_size bodies has one, and a dead body goes back to the pool. A slot
// here is first emitted at INDEX * emit_step and again at the later of its
// death and its last emission + pool_size * emit_step (both limits of the
// legacy rate); with an emit_step of 0 every slot starts at once and again
// as soon as it dies. A slot never dies for good (the node's lifetime is
// longer than any battle).
//
// Per particle: CUSTOM x = texture index, y = life, z = fade, w = flags
// (1 alive, 2 system dead, 4 target point); USERDATA1 x = mass, y = next
// emission (s of the system's age), z = the destroy events seen, w = the
// plain destroy events seen; USERDATA2 x = the kill events seen, y =
// emissions so far, w = the last emission; USERDATA3 x = size; USERDATA4 x =
// the system's age (s since the start; preprocess runs too); COLOR = the
// particle's colour, alpha = its life times the life multiplier.

#include "res://scenes/common/particles/random.gdshaderinc"

const float STEPS = 30.0;
const float ALIVE = 1.0;
const float DEAD_SYSTEM = 2.0;
const float TARGETING = 4.0;
const float NEVER = 1.0e9;

// The emitter (ParticleSystem.*_EMITTER_TYPE): 0 default (at the body), 1
// interpolating (along the path), 2 line (the Line equation), 3 flare, 4
// flame (image points), 5 shatter (image points with their colours, each
// once), 6 demolish (the particles follow the path).
uniform int emitter_kind = 0;
uniform float emit_step = 0.0;
uniform float pool_size = 1.0;
// Particle: mass and size (each slot keeps its own), noise around the body,
// the velocity a particle takes from the body.
uniform float particle_mass = 0.01;
uniform float mass_random = 0.0;
uniform float size = 0.2;
uniform float size_random = 0.0;
uniform float life_multiplier = 1.0;
uniform vec3 position_noise = vec3(0.0);
uniform bool set_velocity = false;
uniform float velocity_random_mult = 0.0;
uniform float velocity_random_add = 0.0;
// The fade per step: random at emission, growing with the distance to the
// body (pow(distance^2, power) * mult a step) until the system is dead.
uniform float fade_random_mult = 0.01;
uniform float fade_random_add = 0.006;
uniform float fade_distance_power = 1.0;
uniform float fade_distance_mult = 0.0;
// destroy(): a kick for one step and a new fade (DESTROY_ONCE first stops
// every particle); plainDestroy(): a new fade.
uniform float destroy_force = 0.0;
uniform float destroy_fade_mult = 0.0;
uniform float destroy_fade_add = 0.0;
uniform bool destroy_stops = false;
// DESTROY_GRAVITY_TARGET_POINT: a spring towards the point (in place of the
// other forces), killed on arrival or sent back near (0, 0, -2) below y 0.
uniform bool has_target_point = false;
uniform vec3 target_point = vec3(0.0);
uniform float target_point_mult = 0.0;
uniform bool kill_on_arrive = false;
// COLLISION_VECTOR: bounces off x <= .x, x >= .y and y <= .z at 0.8.
uniform bool has_collision = false;
uniform vec3 collision = vec3(0.0);
// The colour of every particle, or a random one per slot (COLOR_RANDOM).
uniform vec3 color = vec3(1.0);
uniform bool random_color = false;
uniform int texture_count = 1;
// The path (ParticleSystem.InterpolationInfo): source + source_to_target *
// t / total_time, moved by the vector equation: 0 none, 1 CircularWave, 2
// UpDownSideWave, 3 WhirlWind, 4 Line, 5 DemolishEquation, 6 CircularShape.
uniform vec3 source = vec3(0.0);
uniform vec3 source_to_target = vec3(0.0);
uniform float total_time = 1.0;
uniform int equation_kind = 0;
// equation_a: omega, amplifier, phi, and 1.0 for clockwise (CircularWave,
// WhirlWind, DemolishEquation, CircularShape) or horizontal
// (UpDownSideWave). equation_b: a point (WhirlWind's and DemolishEquation's
// source, CircularShape's origin, Line's source) with w = CircularWave's
// static z flag, WhirlWind's total time or Line's length. equation_z:
// CircularWave's static z.
uniform vec4 equation_a = vec4(0.0);
uniform vec4 equation_b = vec4(0.0);
uniform float equation_z = 0.0;
// Image points (flame, shatter): one per texel, rgb = position (eye space),
// and for shatter the pixel's colour and alpha in emission_colors (shuffled).
uniform sampler2D emission_points : filter_nearest, repeat_disable;
uniform sampler2D emission_colors : filter_nearest, repeat_disable;
uniform int emission_point_count = 0;

// The legacy system's state this frame.
uniform vec3 body_position = vec3(0.0);
uniform vec3 body_velocity = vec3(0.0);
uniform bool emitting = true;
uniform bool has_gravity = false;
uniform vec3 gravity = vec3(0.0);
uniform float destroy_events = 0.0;
uniform float plain_events = 0.0;
uniform float kill_events = 0.0;
// FlareEmitter: after 0.7 s it pulls its particles to their axis.
uniform bool flare_pull = false;
// InterpolatingEmitter: where on the path it emits, by its time counter at
// the frame's start and end (it advances by a share of the elapsed time per
// emitted particle, so it lags while the pool is empty).
uniform float path_time_from = 0.0;
uniform float path_time_to = 0.0;

bool flag(float flags, float f) {
	return mod(floor(flags / f), 2.0) > 0.5;
}

float with_flag(float flags, float f, bool on) {
	bool has = flag(flags, f);
	return flags + (on && !has ? f : (!on && has ? -f : 0.0));
}

// ParticleSystem.getRandomSphereVector (not uniform on a sphere: y and z
// share the sine).
vec3 sphere_vector(inout uint s, float scalar) {
	float theta = next_random(s) * TAU;
	return vec3(cos(theta), sin(theta), sin(theta)) * scalar * next_random(s);
}

// The path at time t (InterpolationInfo.interpolate with its equation's
// getVectorAfterTime); s for the equations' random parts.
vec3 path_at(float t, inout uint s) {
	vec3 v = source + source_to_target * (t / max(total_time, 0.00001));
	float theta = equation_a.x * t + equation_a.z;
	float turn = equation_a.w > 0.5 ? TAU - theta : theta;
	if (equation_kind == 1) {
		v.x += cos(turn) * equation_a.y;
		v.y += sin(turn) * equation_a.y;
		if (equation_b.w > 0.5) {
			v.z = equation_z;
		}
	} else if (equation_kind == 2) {
		float side = sin(theta) * equation_a.y;
		if (equation_a.w > 0.5) {
			v.x += side;
		} else {
			v.y += side;
		}
	} else if (equation_kind == 3) {
		float percent = pow(t / max(equation_b.w, 0.00001), 2.0) * 8.0 + 0.5 + 2.0 * t;
		v.z = equation_b.z + sin(turn) * equation_a.y * percent;
		v.x = equation_b.x + cos(turn) * equation_a.y * percent;
		v.y += (next_random(s) - 0.5) * 0.3;
	} else if (equation_kind == 4) {
		v = equation_b.xyz;
		v.x += next_random(s) * equation_b.w;
	} else if (equation_kind == 5) {
		v.y = equation_b.y + sin(turn) * equation_a.y;
		v.x = equation_b.x + cos(turn) * equation_a.y;
	} else if (equation_kind == 6) {
		v = vec3(equation_b.x + cos(turn) * equation_a.y, equation_b.y + sin(turn) * equation_a.y, equation_b.z);
	}
	return v;
}

vec4 point_at(sampler2D points, int k) {
	int w = textureSize(points, 0).x;
	return texelFetch(points, ivec2(k % w, k / w), 0);
}

// Particle.resurrect at emission time te (an age of the system) for slot
// index: life 1, a new fade, where the emitter emits, the body's velocity if
// asked.
void emit(inout uint s, uint index, float now, float te, float frame_share, inout vec3 p, inout vec3 v, inout vec4 custom, inout vec4 col) {
	vec3 body = body_position - body_velocity * (now - te);
	v = vec3(0.0);
	custom.y = 1.0;
	custom.z = next_random(s) * fade_random_mult + fade_random_add;
	if (emitter_kind == 1) {
		p = path_at(mix(path_time_from, path_time_to, frame_share), s);
	} else if (emitter_kind == 2) {
		p = path_at(0.0, s);
	} else if (emitter_kind == 4) {
		int k = min(int(next_random(s) * float(emission_point_count)), max(emission_point_count - 1, 0));
		p = point_at(emission_points, k).xyz;
	} else if (emitter_kind == 5) {
		int k = int(index) % max(emission_point_count, 1);
		vec4 pixel = point_at(emission_colors, k);
		col.rgb = pixel.rgb;
		custom.y = pixel.a;
		p = point_at(emission_points, k).xyz;
	} else {
		p = body + (vec3(next_random(s), next_random(s), next_random(s)) - 0.5) * position_noise;
	}
	if (set_velocity) {
		v = body_velocity * (next_random(s) * velocity_random_mult + velocity_random_add);
	}
}

void start() {
	uint s = emission_seed(INDEX, RANDOM_SEED);
	float mass = particle_mass + next_random(s) * mass_random;
	float scale = size + next_random(s) * size_random;
	vec3 rgb = random_color ? vec3(next_random(s), next_random(s), next_random(s)) : color;
	float first = emit_step > 0.0 ? float(INDEX) * emit_step : 0.0;
	float flags = has_target_point ? TARGETING : 0.0;
	vec3 p = body_position;
	vec3 v = vec3(0.0);
	vec4 custom = vec4(float(INDEX % uint(max(texture_count, 1))), 0.0, 0.0, flags);
	vec4 col = vec4(rgb, 0.0);
	if (emitter_kind == 3) {
		// FlareEmitter: 400 particles on a disc of radius 4 at the source's z,
		// fading in (life 0, a negative fade); the others wait at the body until
		// the destroy throws them out.
		float theta = next_random(s) * TAU;
		float r = 4.0 * next_random(s);
		custom.z = next_random(s) * fade_random_mult + fade_random_add;
		if (INDEX < 400u) {
			p = vec3(vec2(cos(theta), sin(theta)) * r, source.z);
			custom.w = flags + ALIVE;
		} else {
			p = body_position + (vec3(next_random(s), next_random(s), next_random(s)) - 0.5) * position_noise;
			custom.y = 1.0;
		}
		first = NEVER;
	} else if (emitter_kind == 6) {
		// DemolishEmitter: every particle starts at the body, once.
		emit(s, INDEX, 0.0, 0.0, 0.0, p, v, custom, col);
		custom.w = flags + ALIVE;
		first = NEVER;
	} else if (emitter_kind == 5 && int(INDEX) >= emission_point_count) {
		first = NEVER;
	}
	TRANSFORM = mat4(0.0);
	TRANSFORM[3] = vec4(p, 1.0);
	VELOCITY = v;
	CUSTOM = custom;
	COLOR = vec4(col.rgb, 0.0);
	USERDATA1 = vec4(mass, first, destroy_events, plain_events);
	USERDATA2 = vec4(kill_events, 0.0, 0.0, 0.0);
	USERDATA4 = vec4(0.0);
	USERDATA3 = vec4(scale, 0.0, 0.0, 0.0);
}

void process() {
	vec3 p = TRANSFORM[3].xyz;
	vec3 v = VELOCITY;
	vec4 custom = CUSTOM;
	vec4 col = COLOR;
	float mass = USERDATA1.x;
	float flags = custom.w;
	float dt = DELTA;
	// The system's age: every slot is processed every frame, from the start.
	float age = USERDATA4.x + DELTA;
	USERDATA4.x = age;
	uint s = emission_seed(uint(USERDATA2.y) * 7919u + uint(age * 1000.0), RANDOM_SEED + INDEX * 2654435761u);

	// The flare's reserve joins at the destroy (FlareEmitter.destroy).
	if (emitter_kind == 3 && INDEX >= 400u && !flag(flags, ALIVE) && destroy_events > 0.0) {
		flags += ALIVE;
		USERDATA1.z = 0.0;
	}
	// Emission: a dead slot whose turn has come, while the emitter emits; a
	// slot that waits stays collapsed.
	bool waiting = false;
	if (!flag(flags, ALIVE)) {
		if (!emitting || age < USERDATA1.y) {
			waiting = true;
		} else {
			float te = max(USERDATA1.y, age - dt);
			emit(s, INDEX, age, te, clamp((te - (age - DELTA)) / max(DELTA, 0.00001), 0.0, 1.0), p, v, custom, col);
			flags = (has_target_point ? TARGETING : 0.0) + ALIVE;
			USERDATA1.zw = vec2(destroy_events, plain_events);
			USERDATA2.x = kill_events;
			USERDATA2.y += 1.0;
			USERDATA2.w = te;
			// The particle moves for the rest of the frame.
			dt = age - te;
		}
	}

	if (waiting) {
		TRANSFORM = mat4(0.0);
		TRANSFORM[3] = vec4(p, 1.0);
		CUSTOM = vec4(custom.xyz, flags);
	} else {
		// The legacy system's events since the last frame: destroy (the stop of
		// DESTROY_ONCE, one kick per destroy, a new fade, the system dead), plain
		// destroys (a new fade), kills (the system dead).
		vec3 kick = vec3(0.0);
		if (USERDATA1.z < destroy_events) {
			if (destroy_stops) {
				v = vec3(0.0);
			}
			for (float k = USERDATA1.z; k < destroy_events; k += 1.0) {
				kick += sphere_vector(s, 1.0) * ((next_random(s) + 0.1) * destroy_force);
			}
			custom.z = next_random(s) * destroy_fade_mult + destroy_fade_add;
			flags = with_flag(flags, DEAD_SYSTEM, true);
			USERDATA1.z = destroy_events;
		}
		if (USERDATA1.w < plain_events) {
			custom.z = next_random(s) * destroy_fade_mult + destroy_fade_add;
			USERDATA1.w = plain_events;
		}
		if (USERDATA2.x < kill_events) {
			flags = with_flag(flags, DEAD_SYSTEM, true);
			USERDATA2.x = kill_events;
		}

		// The forces of a step, as accelerations: the system's gravity, whose x is
		// jittered every step (here a random walk with the variance of STEPS steps
		// a second); a target point's spring in their place; the flare's pull.
		vec3 acc = vec3(0.0);
		if (flag(flags, TARGETING)) {
			acc = (target_point - p) * target_point_mult / mass;
		} else {
			if (has_gravity) {
				acc = vec3(0.0, gravity.y, gravity.z) / mass;
				v.x += gravity.x / (STEPS * mass) * sqrt(dt * STEPS) * (next_random(s) - 0.5);
			}
			if (emitter_kind == 3 && INDEX < 400u && flare_pull && !flag(flags, DEAD_SYSTEM)) {
				vec2 dir = length(p.xy) > 0.0 ? normalize(p.xy) : vec2(0.0);
				acc += vec3(dir * -0.03, 0.0) / mass;
			}
		}
		// Particle.isDestroyed (Flare): at the source it stops.
		if (emitter_kind == 3 && !flag(flags, DEAD_SYSTEM) && dot(p - source, p - source) < 0.01) {
			v = vec3(0.0);
		} else {
			v += acc * dt + kick / (STEPS * mass);
			p += v * dt;
		}
		// DemolishEmitter: the path (its time is the system's age), z kept.
		if (emitter_kind == 6 && emitting) {
			vec3 q = path_at(age, s);
			p.xy = q.xy;
		}

		// The life: the fade grows with the distance to the body until the system
		// is dead; life falls by the fade every step.
		if (!flag(flags, DEAD_SYSTEM) && fade_distance_mult != 0.0) {
			vec3 d = p - body_position;
			custom.z += pow(dot(d, d), fade_distance_power) * fade_distance_mult * STEPS * dt;
		}
		custom.y -= custom.z * STEPS * dt;

		// The target point: killed on arrival, or sent back near (0, 0, -2) below
		// y 0 (without the spring from then on).
		if (flag(flags, TARGETING)) {
			if (kill_on_arrive) {
				if (dot(p.xy, p.xy) > dot(target_point.xy, target_point.xy)) {
					custom.y = 0.0;
				}
			} else if (p.y < 0.0) {
				p = sphere_vector(s, 0.05);
				p.z -= 2.0;
				v = vec3(0.0);
				custom.y = 1.0;
				flags = with_flag(flags, TARGETING, false);
			}
		}
		// The collision vector's bounces.
		if (has_collision) {
			if (p.x <= collision.x && v.x < 0.0) {
				v.x *= -0.8;
			} else if (p.x >= collision.y && v.x > 0.0) {
				v.x *= -0.8;
			}
			if (p.y <= collision.z && v.y < 0.0) {
				v.y *= -0.8;
			}
		}

		bool alive = custom.y > 0.0 && !isnan(p.x) && !isinf(p.x);
		if (!alive && flag(flags, ALIVE)) {
			// Dead: back to the pool, emitted again at the emitter's turn (a shatter
			// pixel is taken once).
			flags -= ALIVE;
			USERDATA1.y = emitter_kind == 5 ? NEVER : max(age, USERDATA2.w + emit_step * pool_size);
		}
		TRANSFORM = mat4(alive ? USERDATA3.x : 0.0);
		TRANSFORM[3] = vec4(p, 1.0);
		VELOCITY = v;
		CUSTOM = vec4(custom.xyz, flags);
		COLOR = vec4(col.rgb, max(custom.y, 0.0) * life_multiplier);
	}
}
