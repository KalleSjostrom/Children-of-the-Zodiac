#version 400

uniform sampler2D sampler;
uniform float alpha;
uniform float _time;

in vec2 uv;
out vec4 color;

void main() {
    vec4 sum = vec4(0);

    float hstep = 1.0f;
    float vstep = 1.0f;

    float blur = 0.001f; // TODO(kalle): Fix!
	
	sum += texture(sampler, vec2(uv.x - 4.0*blur*hstep, uv.y - 4.0*blur*vstep)) * 0.0162162162;
    sum += texture(sampler, vec2(uv.x - 3.0*blur*hstep, uv.y - 3.0*blur*vstep)) * 0.0540540541;
    sum += texture(sampler, vec2(uv.x - 2.0*blur*hstep, uv.y - 2.0*blur*vstep)) * 0.1216216216;
    sum += texture(sampler, vec2(uv.x - 1.0*blur*hstep, uv.y - 1.0*blur*vstep)) * 0.1945945946;

    sum += texture(sampler, vec2(uv.x, uv.y)) * 0.2270270270;

    sum += texture(sampler, vec2(uv.x + 1.0*blur*hstep, uv.y + 1.0*blur*vstep)) * 0.1945945946;
    sum += texture(sampler, vec2(uv.x + 2.0*blur*hstep, uv.y + 2.0*blur*vstep)) * 0.1216216216;
    sum += texture(sampler, vec2(uv.x + 3.0*blur*hstep, uv.y + 3.0*blur*vstep)) * 0.0540540541;
    sum += texture(sampler, vec2(uv.x + 4.0*blur*hstep, uv.y + 4.0*blur*vstep)) * 0.0162162162;

	color = vec4(1, 1, 1, sum.r * alpha);
}