extends SceneTree
const Metrics = preload("res://scripts/scenarios/inspection_metrics.gd")
func _init() -> void:
	assert(Metrics.density(Vector2(64,64), Vector2(64,64)).ok)
	assert(not Metrics.density(Vector2(688,384), Vector2(1700,1300)).ok)
	assert(not Metrics.density(Vector2(688,384), Vector2(1700,1300)).uniform)
	assert(not Metrics.density(Vector2.ZERO, Vector2(100,100)).ok)
	assert(not Metrics.density(Vector2(64,64), Vector2(128,128)).ok)
	print("INSPECTION_TESTS_DONE failures=0")
	quit()
