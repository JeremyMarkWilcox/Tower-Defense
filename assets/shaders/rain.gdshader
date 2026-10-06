shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec4 rain_color : source_color =
	vec4(0.65, 0.73, 0.77, 1.0);

uniform float opacity : hint_range(0.0, 0.5) = 0.14;
uniform float density : hint_range(0.0, 1.0) = 0.35;

// Speed in screen-heights per second.
uniform float fall_speed : hint_range(0.0, 2.0) = 0.65;

// Positive values lean toward the right.
uniform float slant : hint_range(-0.6, 0.6) = 0.15;

// Size relative to the screen's height.
uniform float streak_length : hint_range(0.005, 0.08) = 0.025;
uniform float streak_width : hint_range(0.0005, 0.004) = 0.0012;


float hash_2d(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}


void fragment() {
	// Use screen-height units so streaks retain their proportions.
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 p = vec2(UV.x * aspect, UV.y);

	// Slant the streaks and move the pattern downward.
	p.x -= p.y * slant;
	p.y -= TIME * fall_speed;

	vec2 grid = vec2(48.0, 8.0);
	vec2 cell = floor(p * grid);
	vec2 local = fract(p * grid);

	float seed = hash_2d(cell);

	// Random position inside each cell, away from its boundaries.
	float center_x = mix(
		0.2, 0.8, hash_2d(cell + vec2(13.7, 9.2))
	);
	float center_y = mix(
		0.3, 0.7, hash_2d(cell + vec2(4.1, 27.6))
	);

	vec2 distance_to_drop =
		abs((local - vec2(center_x, center_y)) / grid);

	float half_width = streak_width * 0.5;
	float half_length = streak_length * 0.5;

	// Soften the narrow edges to reduce pixel shimmer.
	float aa = max(fwidth(p.x), 0.00001);

	float across = 1.0 - smoothstep(
		max(half_width - aa, 0.0),
		half_width + aa,
		distance_to_drop.x
	);

	float along = 1.0 - smoothstep(
		0.0,
		half_length,
		distance_to_drop.y
	);

	float present = 1.0 - step(density, seed);
	float brightness = mix(
		0.5, 1.0, hash_2d(cell + vec2(38.2, 3.8))
	);

	float alpha =
		across * along * present * brightness * opacity;

	COLOR = vec4(rain_color.rgb, alpha * rain_color.a);
}