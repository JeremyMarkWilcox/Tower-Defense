shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 color : source_color = vec4(1.0);
uniform float thickness = 0.06;
uniform float sway = 0.12;
uniform float phase = 0.0;
uniform float seed = 0.0;

void vertex() {
	// UV.x runs 0 at the Stronghold to 1 at the map edge; both ends stay pinned.
	float t = UV.x;
	float pinned = sin(PI * t);
	VERTEX.x += sin(phase + t * 9.0 + seed) * sway * pinned;
	VERTEX.y += cos(phase * 0.8 + t * 7.0 + seed) * sway * 0.5 * pinned;
	// The mesh sits on the rope's centerline; NORMAL pushes it out to the rope's width.
	VERTEX += NORMAL * thickness;
}

void fragment() {
	ALBEDO = color.rgb;
}
