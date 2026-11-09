// Lawns with mowing stripes, crossed by streets with sidewalks and dashed center lines.
shader_type canvas_item;
#include "res://shaders/ink.gdshaderinc"

uniform vec2 world_size = vec2(2800.0, 1700.0);

const float BLOCK = 760.0;
const float ROAD = 110.0;
const float WALK = 26.0;

void fragment() {
	vec2 px = UV * world_size;
	vec2 m = mod(px + vec2(BLOCK * 0.5), BLOCK);
	vec2 to_road = abs(m - BLOCK * 0.5);

	float stripe = step(0.5, fract(px.x / 70.0 + floor(px.y / 210.0) * 0.5));
	vec3 col = mix(vec3(0.48, 0.74, 0.38), vec3(0.56, 0.80, 0.44), stripe);
	col *= 0.9 + 0.15 * fbm(px * 0.02);

	float road_d = min(to_road.x, to_road.y);
	if (road_d < ROAD * 0.5 + WALK) {
		col = vec3(0.86, 0.85, 0.80);
		float slab = max(ink_line(mod(px.x, 48.0), 1.5), ink_line(mod(px.y, 48.0), 1.5));
		col = mix(col, INK, slab * 0.25);
	}
	if (road_d < ROAD * 0.5) {
		col = vec3(0.36, 0.37, 0.42);
		bool vertical = to_road.x < to_road.y;
		float along = vertical ? px.y : px.x;
		float across = vertical ? to_road.x : to_road.y;
		bool crossing = max(to_road.x, to_road.y) < ROAD * 0.5 + WALK;
		if (!crossing) {
			float dash = ink_line(across, 5.0) * step(0.5, fract(along / 60.0));
			col = mix(col, vec3(1.0, 0.84, 0.25), dash);
		}
	}
	col = mix(col, INK, ink_line(road_d - ROAD * 0.5 - WALK, 3.0) * 0.7);
	col = mix(col, INK, ink_line(road_d - ROAD * 0.5, 2.0) * 0.4);

	float cloud = fbm(px * 0.002 + vec2(TIME * 0.02, 0.0));
	col = dotted(col, px, 0.1 + 0.45 * smoothstep(0.45, 0.75, cloud));
	COLOR = vec4(col, 1.0);
}
