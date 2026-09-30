shader_type canvas_item;

// Only the marked draw commands change palette in the shared world/HUD canvas.
// UI TextureRects can opt into the same palette for every pixel.
uniform bool entire_texture = false;
uniform vec4 canvas_tint = vec4(1.0);
varying vec4 draw_color;

void vertex() {
	draw_color = COLOR;
}

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	bool marked = distance(draw_color.rgb, vec3(0.125, 0.25, 0.875) * canvas_tint.rgb) < 0.01;
	if (entire_texture || marked) {
		float value = dot(source.rgb, vec3(0.299, 0.587, 0.114));
		// Discrete ramps keep the original pixel clusters and dark outlines.
		vec3 ink = vec3(0.031, 0.067, 0.125);
		if (value > 0.10) ink = vec3(0.067, 0.176, 0.329);
		if (value > 0.25) ink = vec3(0.098, 0.337, 0.557);
		if (value > 0.42) ink = vec3(0.176, 0.569, 0.737);
		if (value > 0.62) ink = vec3(0.392, 0.808, 0.867);
		if (value > 0.82) ink = vec3(0.784, 0.965, 0.941);
		COLOR = vec4(ink * (entire_texture ? draw_color.rgb : vec3(1.0)), source.a * draw_color.a);
	} else {
		COLOR = source * draw_color;
	}
}
