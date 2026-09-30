shader_type canvas_item;

// Keep the painted logo and command console while the dock footage moves behind them.
void fragment() {
	vec4 art = texture(TEXTURE, UV);
	// Keep the painted cast opaque. Only the upper-right temporal sky
	// reveals the original moving background through a feathered opening.
	float animated_sky = smoothstep(0.83, 0.98, UV.x) * (1.0 - smoothstep(0.11, 0.30, UV.y));
	art.a *= 1.0 - animated_sky;
	COLOR = art;
}
