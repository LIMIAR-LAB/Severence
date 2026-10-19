extends SceneTree
const Merchant=preload("res://scripts/merchant_visuals.gd")
func _init() -> void:
	var failed:=0
	var hand:=Vector2(0.25,0.31)
	var baseline:=Merchant.motion(hand,0)
	var reach:=0.0
	var landmarks: Array[Vector2]=[Vector2(0.25,0.31),Vector2(0.72,0.51),Vector2(0.43,0.24),Vector2(0.3,0.96),Vector2(0.7,0.96)]
	for i in 193:
		var t:=float(i)/60.0
		reach=maxf(reach,baseline.distance_to(Merchant.motion(hand,t)))
		if Merchant.motion(Vector2(0.3,0.96),t).length()>2.1: failed+=1
		if Merchant.motion(hand,t).distance_to(Merchant.motion(hand,t+1.0/60.0))>0.3: failed+=1
		for a in landmarks:
			for b in landmarks:
				var original:=a*Merchant.SIZE-b*Merchant.SIZE
				var animated:=original+Merchant.motion(a,t)-Merchant.motion(b,t)
				if absf(original.length()-animated.length())>0.001: failed+=1
		var transform:=Merchant.idle_transform(t)
		if absf(transform.determinant()-1.0)>0.0001: failed+=1
	if reach<2.0: failed+=1
	if Merchant.motion(hand,0).distance_to(Merchant.motion(hand,Merchant.PERIOD))>0.001: failed+=1
	print("MERCHANT_MOTION failures=",failed," hand_travel=",reach," rigid_proportions=true")
	quit(0 if failed==0 else 1)
