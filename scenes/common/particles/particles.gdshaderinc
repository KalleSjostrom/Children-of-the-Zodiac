// The laws the village and cutscene particle shaders share (the GPU
// versions of src/bodies and src/commands, docs/ARCHITECTURE.md section 9):
// the emitter shapes, the emit force, the first step and the random numbers.
// The legacy systems step 30 times a second (Values.originalFrameStep); here
// every per-step law is a per-second rate at STEPS steps a second, applied
// with each frame's DELTA.
//
// Coordinates: the particles are in the system node's local coordinates,
// which are the legacy body coordinates with y down (legacy (x, y) is
// (x, -y) here). The legacy settings (forces, shape points) keep their y-up
// values; shape_offset and emit_velocity flip them.
//
// Include after the shader_type line. A shader that includes it calls
// emit_particle() in start(), then its own first step.

const float STEPS = 30.0;

// The emitter shape (bodies.emitter): 0 line, 1 box, 2 circle, 3 image.
uniform int shape_kind = 0;
// The shape's position (local, y down). The node sets it every frame from the
// legacy emitter, which a cutscene actor moves (BodiesParticleSystem.setPos).
uniform vec2 emitter_origin = vec2(0.0);
// Line: the point; box: the first vector; circle: the radii (legacy, y up).
uniform vec2 shape_a = vec2(0.0);
// Box: the second vector (legacy, y up).
uniform vec2 shape_b = vec2(0.0);
// Line: the direction spread, tan(-angle) and tan(angle) (LineShape.modifyDirection).
uniform float spread_min = 0.0;
uniform float spread_max = 0.0;
// Image: the pixels with alpha >= 100 of the scaled image (ImageShape), one per
// texel: R = x & 255, G = y & 255, B = (x >> 8) | ((y >> 8) << 4); x right and y
// down from the shape's position.
uniform sampler2D emission_points : filter_nearest, repeat_disable;
uniform int emission_point_count = 0;
// The emitter's force (legacy, y up): direction and size of the push a body
// gets when it is emitted.
uniform vec2 force = vec2(0.0);
// Mass and size of a particle: random between min and max. A legacy body keeps
// its mass for every emission, so a light (fast) body comes back more often:
// masses are drawn log-uniformly.
uniform float mass_min = 0.01;
uniform float mass_max = 0.01;
uniform float size_min = 1.0;
uniform float size_max = 1.0;
// The particle colour (ParticleSettings COLOR).
uniform vec3 color = vec3(1.0);
// Tuning (VillageParticles2D.intensity and size_scale): the drawn alpha and size.
uniform float intensity = 1.0;
uniform float size_scale = 1.0;

uint hash_u(uint x) {
	x ^= x >> 16u;
	x *= 0x7feb352du;
	x ^= x >> 15u;
	x *= 0x846ca68bu;
	x ^= x >> 16u;
	return x;
}

// A random number in [0, 1) from the state s, which it advances.
float next_random(inout uint s) {
	s = hash_u(s + 0x9e3779b9u);
	return float(s >> 8u) / 16777216.0;
}

// The random state of an emission: NUMBER is new for every emission.
uint emission_seed(uint number, uint random_seed) {
	return hash_u(number * 747796405u + hash_u(random_seed));
}

float random_mass(inout uint s) {
	float r = next_random(s);
	if (mass_max <= mass_min) {
		return mass_min;
	}
	return mass_min * pow(mass_max / mass_min, r);
}

float random_size(inout uint s) {
	return mix(size_min, size_max, next_random(s));
}

// EmitterShape.getEmittancePos, as an offset from the shape's position in
// legacy coordinates (y up).
vec2 shape_offset(inout uint s) {
	if (shape_kind == 0) {
		float x = next_random(s) * shape_a.x;
		return vec2(x, next_random(s) * shape_a.y);
	} else if (shape_kind == 1) {
		vec2 a = shape_a * next_random(s);
		return a + shape_b * next_random(s);
	} else if (shape_kind == 2) {
		float theta = next_random(s) * TAU;
		return vec2(shape_a.x * cos(theta), shape_a.y * sin(theta));
	} else if (emission_point_count > 0) {
		int k = min(int(next_random(s) * float(emission_point_count)), emission_point_count - 1);
		int w = textureSize(emission_points, 0).x;
		vec4 c = texelFetch(emission_points, ivec2(k % w, k / w), 0);
		vec3 b = round(c.rgb * 255.0);
		float x = b.r + 256.0 * mod(b.b, 16.0);
		float y = b.g + 256.0 * floor(b.b / 16.0);
		return vec2(x, -y);
	}
	return vec2(0.0);
}

// Where a particle is emitted (local, y down).
vec2 emit_position(inout uint s) {
	vec2 p = shape_offset(s);
	return emitter_origin + vec2(p.x, -p.y);
}

// The velocity a body has after its first step (local, y down): the emit
// force (its direction turned by a line shape's spread) for one step of
// 1 / STEPS s on the body's mass. The default force (+9.82 * mass) and the
// GravityCommand (-9.82 * mass) cancel, so it keeps this velocity. push is
// an acceleration in that first step (the wind on a smoke particle), legacy
// coordinates.
vec2 emit_velocity(inout uint s, float mass, vec2 push) {
	float magnitude = length(force);
	vec2 direction = magnitude > 0.0 ? force / magnitude : vec2(0.0);
	if (shape_kind == 0) {
		direction.x += mix(spread_min, spread_max, next_random(s));
	}
	if (length(direction) > 0.0) {
		direction = normalize(direction);
	}
	vec2 v = (direction * magnitude + push * mass) / (STEPS * mass);
	return vec2(v.x, -v.y);
}

// A 2D particle transform: position and uniform scale.
mat4 particle_transform(vec2 position, float scale) {
	mat4 m = mat4(1.0);
	m[0].x = scale * size_scale;
	m[1].y = scale * size_scale;
	m[3].xy = position;
	return m;
}
