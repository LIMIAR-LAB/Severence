extends RefCounted
static func density(source: Vector2, target: Vector2, expected: float = 1.0) -> Dictionary:
	if source.x <= 0 or source.y <= 0 or target.x <= 0 or target.y <= 0:
		return {"ok": false, "reason": "non-positive dimensions"}
	var ratio := target / source
	var uniform := is_equal_approx(ratio.x, ratio.y)
	return {"ok": uniform and is_equal_approx(ratio.x, expected), "ratio": ratio, "uniform": uniform,
		"reason": "" if uniform and is_equal_approx(ratio.x, expected) else "density mismatch; no automatic stretching"}
