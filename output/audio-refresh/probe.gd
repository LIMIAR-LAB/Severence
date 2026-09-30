extends SceneTree
func _init():
 var effect := AudioEffectLimiter.new()
 for p in effect.get_property_list():
  if p.name in ["ceiling_db", "threshold_db", "soft_clip_db", "soft_clip_ratio"]: print(p.name, "=", effect.get(p.name))
 quit()
