#version 400

uniform mat4 projection;
uniform mat4 model_view;

layout(location=0) in vec2 position;
layout(location=1) in vec2 vertex_uv;

out vec2 uv;

void main() {
	gl_Position = projection * model_view * vec4(position, 0.0f, 1.0f);
	uv = vertex_uv;
}