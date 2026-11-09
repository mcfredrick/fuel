// The planet from above: noisy continents with beaches and hills, an ocean with drifting wave marks.
shader_type canvas_item;
#include "res://shaders/ink.gdshaderinc"

uniform vec2 world_size = vec2(3200.0, 2000.0);

void fragment() {
	vec2 px = UV * world_size;
	float land = fbm(px * 0.0016 + vec2(3.7, 1.3));
	// Push land toward the middle so the map isn't mostly ocean at the edges.
	vec2 c = UV - 0.5;
	land += 0.06 - dot(c, c) * 0.6;

	vec3 col;
	float coast = land - 0.5;
	if (coast < 0.0) {
		col = mix(vec3(0.26, 0.55, 0.80), vec3(0.42, 0.72, 0.90), step(-0.06, coast));
		float wave = sin(px.x * 0.05 + sin(px.y * 0.03) * 2.0 + TIME * 0.8);
		float mark = step(0.97, wave) * step(0.5, noise(px * 0.02 + TIME * 0.05));
		col = mix(col, vec3(0.9, 0.97, 1.0), mark * 0.7);
	} else if (coast < 0.02) {
		col = vec3(0.96, 0.87, 0.62);
	} else {
		// Flat bands like the sprites' colors: lowland, then hills, then peaks.
		float height = coast + 0.25 * (fbm(px * 0.006) - 0.5);
		col = vec3(0.46, 0.74, 0.38);
		col = mix(col, vec3(0.64, 0.68, 0.36), step(0.1, height));
		col = mix(col, vec3(0.80, 0.72, 0.58), step(0.17, height));
	}
	// Ink the coastline at a constant width whatever the slope of the noise.
	col = mix(col, INK, ink_line(coast / fwidth(coast), 2.5) * 0.85);

	float sun = dot(normalize(vec2(-1.0, -1.0)), c);
	col = dotted(col, px, 0.1 + 0.4 * smoothstep(-0.2, 0.5, -sun));
	COLOR = vec4(col, 1.0);
}
