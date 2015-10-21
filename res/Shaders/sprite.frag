#version 400

uniform sampler2D sampler;
uniform vec4 color;
uniform float alpha;

in vec2 uv;
out vec4 result_color;

void main() {
	vec4 s = texture(sampler, uv);
	s *= color;
	s.a *= alpha < 0.9 ? 0 : alpha;
	result_color = s;
}