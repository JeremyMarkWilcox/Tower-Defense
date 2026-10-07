shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec4 mist_color : source_color =
	vec4(0.48, 0.55, 0.52, 1.0);

uniform float opacity : hint_range(0.0, 0.5) = 0.10;

// Higher values make smaller patches.
uniform float patch_scale : hint_range(1.0, 10.0) = 3.0;

// Higher coverage fills more of the screen with mist.
uniform float coverage : hint_range(0.0, 1.0) = 0.45;

// Movement in screen-height units per second.
uniform vec2 drift = vec2(0.018, -0.006);

// Slowly changes the shape of the patches.
uniform float shape_change_speed : hint_range(0.0, 0.1) = 0.012;

// Fraction of mist strength allowed in the center.
// 0 = clear center, 1 = same strength everywhere.
uniform float center_strength : hint_range(0.0, 1.0) = 0.15;

uniform float edge_start : hint_range(0.0, 1.0) = 0.35;

// Change this to get a different arrangement.
uniform float seed : hint_range(0.0, 100.0) = 12.0;


float hash_2d(vec2 p) {
	return fract(
		sin(dot(p, vec2(127.1, 311.7))) * 43758.5453
	);
}


float smooth_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 local = fract(p);
	vec2 weight = local * local * (3.0 - 2.0 * local);

	float a = hash_2d(cell);
	float b = hash_2d(cell + vec2(1.0, 0.0));
	float c = hash_2d(cell + vec2(0.0, 1.0));
	float d = hash_2d(cell + vec2(1.0, 1.0));

	return mix(
		mix(a, b, weight.x),
		mix(c, d, weight.x),
		weight.y
	);
}


float layered_noise(vec2 p) {
	float value = 0.57 * smooth_noise(p);
	value += 0.29 * smooth_noise(
		p * 2.03 + vec2(17.1, 9.2)
	);
	value += 0.14 * smooth_noise(
		p * 4.07 + vec2(31.7, 23.4)
	);
	return value;
}


void fragment() {
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 screen_position = vec2(UV.x * aspect, UV.y);

	vec2 p = (screen_position - drift * TIME) * patch_scale;
	p += vec2(seed * 3.17, seed * 1.73);

	// Shift the fine detail independently so patches slowly evolve.
	vec2 detail_motion =
		vec2(-0.6, 0.8) * TIME * shape_change_speed;

	float broad = layered_noise(p);
	float detail = smooth_noise(
		p * 1.6 + detail_motion + vec2(8.3, 19.7)
	);

	float cloud = broad * 0.8 + detail * 0.2;

	float threshold = mix(0.7, 0.2, coverage);
	float mist = smoothstep(
		threshold,
		threshold + 0.25,
		cloud
	);

	// Leave the central combat area clearer.
	float radius = length((UV - vec2(0.5)) * 2.0);
	float edge_mask = smoothstep(edge_start, 1.2, radius);
	float placement = mix(center_strength, 1.0, edge_mask);

	float alpha = mist * placement * opacity * mist_color.a;
	COLOR = vec4(mist_color.rgb, clamp(alpha, 0.0, 1.0));
}