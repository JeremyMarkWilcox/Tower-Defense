shader_type canvas_item;
// Red glow at the screen edges. "strength" 0 = invisible, 1 = full.

uniform vec4 tint : source_color = vec4(0.70, 0.15, 0.18, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform float inner : hint_range(0.0, 1.0) = 0.55;  // where the glow starts
uniform float outer : hint_range(0.5, 2.0) = 1.2;   // where it reaches full

void fragment() {
	vec2 uv = UV - 0.5;
	uv.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;  // keep it round on wide screens
	float edge = smoothstep(inner, outer, length(uv) * 2.0);
	COLOR = vec4(tint.rgb, edge * strength * tint.a);
}
