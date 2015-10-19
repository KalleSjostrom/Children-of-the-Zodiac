#version 400

uniform sampler2D myTextureSampler;
uniform float alpha;

in vec2 uv;
out vec4 color;

void main() {
	vec4 s = texture(myTextureSampler, uv);
	s.a *= alpha;
	color = s;
}