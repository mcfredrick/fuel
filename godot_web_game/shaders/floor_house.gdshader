// Wood floorboards with staggered seams and grain, and a couple of round braided rugs.
shader_type canvas_item;
#include "res://shaders/ink.gdshaderinc"

uniform vec2 world_size = vec2(2300.0, 1400.0);

const float BOARD = 56.0;
const float LENGTH = 340.0;

float rug(vec2 px, vec2 center, vec2 radius) {
	return length((px - center) / radius);
}

void fragment() {
	vec2 px = UV * world_size;
	float row = floor(px.y / BOARD);
	float shift = hash(vec2(row, 3.0)) * LENGTH;
	float board_x = floor((px.x + shift) / LENGTH);
	float tone = hash(vec2(board_x, row));
	vec3 col = mix(vec3(0.78, 0.56, 0.36), vec3(0.88, 0.67, 0.44), tone);

	float grain = fbm(vec2(px.x * 0.01, px.y * 0.12) + vec2(board_x * 7.0, row * 3.0));
	col *= 0.9 + 0.2 * grain;
	float seam_y = ink_line(mod(px.y, BOARD), 2.5);
	float seam_x = ink_line(mod(px.x + shift, LENGTH), 2.5);
	col = mix(col, INK, max(seam_y, seam_x) * 0.5);

	// Braided rugs: rings of alternating color with an inked edge.
	vec2 centers[2] = vec2[](world_size * vec2(0.3, 0.55), world_size * vec2(0.72, 0.35));
	for (int i = 0; i < 2; i++) {
		float r = rug(px, centers[i], vec2(300.0, 200.0));
		if (r < 1.0) {
			float band = step(0.5, fract(r * 7.0));
			col = mix(vec3(0.85, 0.36, 0.38), vec3(0.98, 0.86, 0.62), band);
			if (i == 1) {
				col = mix(vec3(0.33, 0.55, 0.72), vec3(0.95, 0.92, 0.8), band);
			}
		}
		col = mix(col, INK, ink_line((r - 1.0) * 220.0, 3.0));
	}

	float light = sin(px.x * 0.0025 + px.y * 0.0015 + TIME * 0.15) * 0.5 + 0.5;
	col = dotted(col, px, 0.12 + 0.3 * (1.0 - light));
	COLOR = vec4(col, 1.0);
}
