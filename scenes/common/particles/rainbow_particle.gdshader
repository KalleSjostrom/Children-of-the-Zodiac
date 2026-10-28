shader_type particles;
// RainbowParticle (src/bodies/particles/RainbowParticle.gd) on the GPU: the
// door systems of Home of the Gods. FireParticle's law with
// (distance² / 1000)³ and a random colour per emission.

#define FADE_DISTANCE 1000.0
#define RANDOM_COLOR
#include "res://scenes/common/particles/particles.gdshaderinc"
#include "res://scenes/common/particles/distance_fade.gdshaderinc"
