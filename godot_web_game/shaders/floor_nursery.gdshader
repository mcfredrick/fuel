// A pastel quilt rug: patchwork squares, dashed stitching, polka dots, a sunbeam drifting across.
shader_type canvas_item;
#include "res://shaders/ink.gdshaderinc"

uniform vec2 world_size = vec2(1800.0, 1100.0);

const float PATCH = 180.0;

void fragment() {
	vec2 px = UV * world_size;
	vec2 cell = floor(px / PATCH);
	vec2 local = fract(px / PATCH) * PATCH;
	vec3 colors[4] = vec3[](vec3(0.72, 0.90, 0.82), vec3(1.0, 0.84, 0.75), vec3(0.84, 0.80, 0.96), vec3(1.0, 0.94, 0.70));
	int pick = int(mod(cell.x + cell.y * 2.0, 4.0));
	vec3 col = colors[pick];

	// Every other patch is polka-dotted.
	if (mod(cell.x + cell.y, 2.0) > 0.5) {
		vec2 d = fract(local / 45.0) - 0.5;
		col = mix(col, vec3(1.0), step(length(d), 0.16) * 0.6);
	}

	float edge = min(min(local.x, PATCH - local.x), min(local.y, PATCH - local.y));
	float seam = ink_line(edge, 3.0);
	float along = (local.x < 14.0 || local.x > PATCH - 14.0) ? local.y : local.x;
	float stitch = ink_line(edge - 12.0, 2.0) * step(0.5, fract(along / 16.0));
	col = mix(col, INK, seam * 0.55);
	col = mix(col, vec3(1.0), stitch * 0.8);

	float beam = sin((px.x + px.y) * 0.004 - TIME * 0.25) * 0.5 + 0.5;
	float shade = 0.15 + 0.35 * (1.0 - beam) + 0.25 * fbm(px * 0.01);
	col = dotted(col, px, shade);
	col += vec3(1.0, 0.95, 0.8) * smoothstep(0.75, 1.0, beam) * 0.12;
	COLOR = vec4(col, 1.0);
}
