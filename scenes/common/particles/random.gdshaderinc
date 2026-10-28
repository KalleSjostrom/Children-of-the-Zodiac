// The random numbers of the particle shaders (2D and 3D): a hash of the
// particle's state, so that a system with a fixed seed draws the same
// particles in every run.

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
