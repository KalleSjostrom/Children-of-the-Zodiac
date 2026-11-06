// The pixel look's filter (proto/pixel/PixelFilter.gd, PixelLook): the frame
// drawn under it at a virtual low resolution (virtual_size cells, each one
// colour: the mean of the screen pixels it covers, or the one at its centre),
// each channel cut to `levels` levels with a 4x4 ordered dither, and drawn
// back over the game's screen. With `sharp`, neighbouring cells blend over
// one screen pixel at their edges, so the cells look even when the window is
// not a whole multiple of the virtual size (sharp bilinear).
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen : hint_screen_texture, filter_linear, repeat_disable;
uniform vec2 virtual_size = vec2(512.0, 384.0);
uniform float levels = 16.0;
uniform float dither = 1.0;
uniform bool average = true;
uniform bool sharp = true;

const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0,
		3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

// The colour of a cell; a + uv * b is the screen UV of the rect's uv.
vec3 cell_colour(vec2 cell, vec2 a, vec2 b) {
	cell = clamp(cell, vec2(0.0), virtual_size - 1.0);
	vec2 size = 1.0 / virtual_size;
	vec2 uv = cell * size;
	vec3 c;
	if (average) {
		c = texture(screen, a + (uv + size * vec2(0.25, 0.25)) * b).rgb
			+ texture(screen, a + (uv + size * vec2(0.75, 0.25)) * b).rgb
			+ texture(screen, a + (uv + size * vec2(0.25, 0.75)) * b).rgb
			+ texture(screen, a + (uv + size * vec2(0.75, 0.75)) * b).rgb;
		c *= 0.25;
	} else {
		c = texture(screen, a + (uv + size * 0.5) * b).rgb;
	}
	int i = int(mod(cell.x, 4.0)) + 4 * int(mod(cell.y, 4.0));
	float d = (BAYER[i] + 0.5) / 16.0 - 0.5;
	float n = max(levels - 1.0, 1.0);
	return clamp(floor(c * n + 0.5 + d * dither), 0.0, n) / n;
}

void fragment() {
	// The rect's UV to the screen's: linear, so its derivatives give it.
	vec2 b = vec2(dFdx(SCREEN_UV.x) / dFdx(UV.x), dFdy(SCREEN_UV.y) / dFdy(UV.y));
	vec2 a = SCREEN_UV - UV * b;
	vec2 p = UV * virtual_size;
	vec3 col;
	if (sharp) {
		vec2 w = max(fwidth(p), vec2(1e-4));
		vec2 c0 = floor(p - 0.5 * w);
		vec2 t = clamp((p + 0.5 * w - (c0 + 1.0)) / w, 0.0, 1.0);
		vec3 c00 = cell_colour(c0, a, b);
		vec3 c10 = cell_colour(c0 + vec2(1.0, 0.0), a, b);
		vec3 c01 = cell_colour(c0 + vec2(0.0, 1.0), a, b);
		vec3 c11 = cell_colour(c0 + vec2(1.0, 1.0), a, b);
		col = mix(mix(c00, c10, t.x), mix(c01, c11, t.x), t.y);
	} else {
		col = cell_colour(floor(p), a, b);
	}
	COLOR = vec4(col, 1.0);
}
