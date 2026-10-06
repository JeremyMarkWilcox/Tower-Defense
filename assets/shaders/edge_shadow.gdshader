shader_type canvas_item;
render_mode unshaded, blend_mix;

// Nearly black with a subtle green tint.
uniform vec4 shadow_color : source_color =
	vec4(0.015, 0.025, 0.020, 1.0);

// Darkness across the entire scene.
uniform float base_darkness : hint_range(0.0, 0.3) = 0.03;

// Maximum darkness at the outer edges.
uniform float edge_darkness : hint_range(0.0, 1.0) = 0.55;

// Where the edge fade begins and how gradually it increases.
uniform float edge_start : hint_range(0.0, 1.4) = 0.55;
uniform float edge_softness : hint_range(0.05, 1.0) = 0.65;

// Leave at zero for a clean gradient.
// Increase slightly for an uneven border.
uniform float irregularity : hint_range(0.0, 0.3) = 0.0;
uniform float noise_scale : hint_range(1.0, 12.0) = 4.0;

// Static by default.
uniform bool animate = false;
uniform float drift_speed : hint_range(0.0, 0.2) = 0.025;


float hash_2d(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}


float smooth_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 local = fract(p);
	vec2 blend = local * local * (3.0 - 2.0 * local);

	float a = hash_2d(cell);
	float b = hash_2d(cell + vec2(1.0, 0.0));
	float c = hash_2d(cell + vec2(0.0, 1.0));
	float d = hash_2d(cell + vec2(1.0, 1.0));

	return mix(mix(a, b, blend.x), mix(c, d, blend.x), blend.y);
}


void fragment() {
	// Screen-shaped ellipse: 0 at center, 1 at side midpoints,
	// approximately 1.41 at corners.
	vec2 centered = (UV - vec2(0.5)) * 2.0;
	float distance_from_center = length(centered);

	float offset = 0.0;

	if (irregularity > 0.0) {
		vec2 drift = vec2(0.0);

		if (animate) {
			drift = vec2(0.7, -0.4) * TIME * drift_speed;
		}

		float noise_value = smooth_noise(UV * noise_scale + drift);
		offset = (noise_value - 0.5) * 2.0 * irregularity;
	}

	float edge_mask = smoothstep(
		edge_start,
		edge_start + edge_softness,
		distance_from_center + offset
	);

	float opacity = mix(base_darkness, edge_darkness, edge_mask);

	COLOR = vec4(
		shadow_color.rgb,
		clamp(opacity * shadow_color.a, 0.0, 1.0)
	);
}