shader_type canvas_item;
// The legacy alpha test glAlphaFunc(GL_GREATER, alpha_ref) for scene nodes
// that stand in for legacy drawing (VillageScene): fragments whose alpha
// (texture times modulate) is not above alpha_ref are discarded, as in
// GLBackend's canvas alpha shader. Blending is the canvas default (mix).
uniform float alpha_ref = 0.0;

void fragment() {
	if (COLOR.a <= alpha_ref) {
		discard;
	}
}
