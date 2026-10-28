shader_type particles;
// FireParticle (src/bodies/particles/FireParticle.gd) on the GPU: the
// village and cutscene fires, the Menthu and god systems. The law is in
// distance_fade.gdshaderinc (the fade grows with (distance² / 300)³).

#define FADE_DISTANCE 300.0
#include "res://scenes/common/particles/particles.gdshaderinc"
#include "res://scenes/common/particles/distance_fade.gdshaderinc"
