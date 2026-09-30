extends "res://scripts/world_view.gd"
var neutral := false
func _draw() -> void:
	super._draw()
	if neutral: modulate = Color.WHITE
	if light_layer: light_layer.visible = not neutral
