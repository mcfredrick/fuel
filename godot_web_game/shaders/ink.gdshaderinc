// Shared bits for the floor shaders: noise, and the halftone dots and ink color the sprites use.

const vec3 INK = vec3(0.10, 0.06, 0.14);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

// 1 inside a halftone dot. `amount` 0..1 grows the dots; cells are `cell` pixels on a 45 degree grid.
float halftone(vec2 px, float amount, float cell) {
	vec2 r = mat2(vec2(0.7071, 0.7071), vec2(-0.7071, 0.7071)) * px / cell;
	return step(length(fract(r) - 0.5), amount * 0.62);
}

// Shade `color` toward its shadow tone with halftone dots, the way the comic material does.
vec3 dotted(vec3 color, vec2 px, float amount) {
	// Lighter than the sprites' shading so floors stay calm behind them.
	vec3 shade = mix(color * 0.8, INK, 0.06);
	return mix(color, shade, halftone(px, clamp(amount * 0.75, 0.0, 1.0), 9.0));
}

// 1 within `width` pixels of a line through the distance field `d` (in pixels).
float ink_line(float d, float width) {
	return 1.0 - smoothstep(width * 0.5, width * 0.5 + 1.0, abs(d));
}
