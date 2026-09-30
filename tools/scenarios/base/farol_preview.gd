extends "res://scripts/scenarios/room_preview.gd"
## Isolated support projection experiment; inherited runtime remains untouched.
## Source SHA256: 1E03B979522C077B0B1CDACA3DA269026A17006FF2A216F24776D45EEB43863F
func draw_actor(a: Dictionary) -> void:
	var foot: Vector2 = a.p
	var support: Vector2 = foot - Vector2(0, sim.height_at(foot))
	var player_color := CYAN if a.id == 0 else GOLD
	visual_transform(support, 0, Vector2(1, 0.42)); draw_circle(Vector2.ZERO, 17, Color(0, 0, 0, 0.4)); visual_transform(Vector2.ZERO)
	draw_arc(support, 16, 0, TAU, 20, player_color, 2)
	if a.dead:
		if a.fused and fusion_actions.has("defeat"):
			var defeat_texture: Texture2D = fusion_actions["defeat"]
			draw_character_action(defeat_texture, FUSION_ACTION_CELL, 128.0, foot, a.facing, maxi(0, int(defeat_texture.get_width() / FUSION_ACTION_CELL) - 1))
		elif sim.outfit_of(a) == "padrao":
			draw_marty_padrao_frame("defeat", a.facing, MARTY_PADRAO_FRAMES.defeat - 1, foot, Color.WHITE)
		elif sim.outfit_of(a) == "omega":
			draw_marty_omega_frame("defeat", a.facing, MARTY_OMEGA_FRAMES.defeat - 1, foot, Color.WHITE)
		else:
			draw_line(foot - Vector2(9, 9), foot + Vector2(9, 9), Color("f77c89"), 5)
			draw_line(foot + Vector2(9, -9), foot + Vector2(-9, 9), Color("f77c89"), 5)
		text_at(foot + Vector2(-35, -25), "E • REANIMAR", Color("f77c89"), 12)
		return
	var jump_height := sin((1.0 - a.jump / 0.65) * PI) * 68 if a.jump > 0 else 0.0
	var elevation := sim.height_at(foot)
	var draw_pos := foot - Vector2(0, jump_height + elevation)
	if a.fused:
		var col := 3 if a.slash > 0 or a.get("fire_flash", 0.0) > 0 else (1 + int(a.step) % 2 if a.move.length() > 0.1 else 0)
		var tint := Color(1.5, 1.5, 1.5, 0.65) if a.hurt > 0 else Color.WHITE
		var fusion_action := fusion_sprite_action(a)
		if fusion_actions.has(fusion_action):
			var direction: Vector2 = a.dash_dir if fusion_action == "evade" else (a.move if fusion_action == "run" else fusion_visual_direction(a))
			var frame := character_action_frame(fusion_actions[fusion_action], FUSION_ACTION_CELL, fusion_action, a)
			draw_character_action(fusion_actions[fusion_action], FUSION_ACTION_CELL, 128.0, draw_pos, direction, frame, tint)
		else:
			draw_feral(fusion_texture, draw_pos, fusion_visual_direction(a), col, 160, 144, tint)
		text_at(draw_pos + Vector2(-36, -115), "MARTY • FUSÃO", CYAN, 11)
		return
	# Roupa atual: COM armadura = Ômega; SEM armadura = Padrão / Londres / Mecânico.
	# marty_anim.png: linha = roupa*5 + vista; colunas = parado, passo 1-4, tiro, salto.
	var pose := marty_pose(a.facing)
	var view: int = pose[0]; var flip: bool = pose[1]
	var outfit_key: String = sim.outfit_of(a)
	var transforming: float = a.get("transform", 0.0)
	var charge_t: float = sim.TRANSFORM_TIME - transforming
	if transforming > 0:
		outfit_key = a.get("outfit", "padrao")  # a armadura nova entra como camada progressiva sobre a roupa
	var row: int = OUTFIT_ROW[outfit_key] * 5 + view
	var walking: bool = a.move.length() > 0.1
	var firing: bool = a.get("fire_flash", 0.0) > 0
	var column := 0; var bob := 0.0
	var slash_dur := 0.32 if a.armor else 0.45
	if a.slash > 0 and not a.mech:
		var sp: float = 1.0 - a.slash / slash_dur
		column = 7 if sp < 0.2 else (8 if sp < 0.6 else 9)
	elif a.jump > 0 or a.dodge > 0:
		column = 6
		if a.dodge > 0 and view != 2: row = OUTFIT_ROW[sim.outfit_of(a)] * 5 + 2; flip = a.dash_dir.x < 0
	elif walking:
		var phase := int(a.step) % 4
		column = 1 + phase
		bob = -2.0 if phase % 2 == 0 else 0.0
	elif firing: column = 5
	else: bob = -1.0 if fmod(sim.tick_time + a.id * 0.7, 1.6) < 0.8 else 0.0  # respiração
	var tint := Color.WHITE
	if a.get("roll_visual", a.dodge) <= 0 and a.hurt > 0 and int(a.hurt * 20) % 2 == 0: tint.a = 0.45
	if a.slash > 0.24: tint = tint.lightened(0.25)
	if transforming > 0:
		bob -= sin(clampf(charge_t / 0.8, 0, 1) * PI) * 8.0   # flutua enquanto carrega
		tint = Color(1.4, 1.4, 1.25) if charge_t < 0.75 else Color.WHITE
		draw_power_aura(draw_pos, clampf(1.0 - absf(charge_t - 0.6) / 0.8, 0.25, 1.0), true)
	elif a.armor and not a.mech:
		draw_power_aura(draw_pos, 0.28, false)
	if outfit_key == "padrao":
		var padrao_action := marty_padrao_action(a, walking, firing)
		var padrao_direction: Vector2 = a.dash_dir if padrao_action == "evade" else (a.move if padrao_action == "run" else a.facing)
		var padrao_frame := marty_padrao_frame(a, padrao_action, slash_dur)
		draw_marty_padrao_frame(padrao_action, padrao_direction, padrao_frame, draw_pos + Vector2(0, bob), tint)
		# A arma aparece somente enquanto Marty dispara.
		if marty_padrao_shows_weapon(padrao_action, transforming): draw_weapon(a, draw_pos)
	elif outfit_key == "omega":
		var omega_action := marty_omega_action(a, walking)
		var omega_direction: Vector2 = a.dash_dir if omega_action == "evade" else (a.move if omega_action == "run" else a.facing)
		var omega_frame := marty_omega_frame(a, omega_action, slash_dur)
		if walking and omega_action == "idle":
			bob = -7.0 + sin(sim.tick_time * 7.0 + a.id) * 2.0
		var omega_pos := draw_pos + Vector2(0, bob)
		var sword_visible := omega_sword_should_draw(omega_action, omega_frame)
		var sword_anchor := omega_melee_hand_anchor(omega_direction, omega_frame) if sword_visible else Vector2.ZERO
		if sword_visible and omega_sword_behind_body(omega_direction):
			draw_weapon(a, omega_pos, Vector2.ZERO, sword_anchor)
		draw_marty_omega_frame(omega_action, omega_direction, omega_frame, omega_pos, tint)
		if sword_visible and not omega_sword_behind_body(omega_direction):
			draw_weapon(a, omega_pos, Vector2.ZERO, sword_anchor)
	elif a.get("roll_visual", a.dodge) > 0 and not a.mech:
		draw_marty_dodge(a, draw_pos + Vector2(0, bob), outfit_key, tint)
	else:
		visual_transform(draw_pos + Vector2(0, bob), 0, Vector2(-1 if flip else 1, 1))
		draw_texture_rect_region(marty_anim, Rect2(-48, -92, 96, 96), Rect2(column * 96, row * 96, 96, 96), tint)
		visual_transform(Vector2.ZERO)
		# A arma é uma camada separada; durante a esquiva as mãos ficam livres.
		draw_weapon(a, draw_pos)
	if transforming > 0:
		draw_omega_assembly_overlay(draw_pos + Vector2(0, bob), 1.0 - transforming / sim.TRANSFORM_TIME)
	if a.jump > 0 and a.armor: draw_circle(draw_pos + Vector2(0, -13), 5, CYAN)
	if a.get("shield", 0.0) > 0: draw_shield_hex(draw_pos - Vector2(0, 40), a.shield / (sim.OMEGA_SHIELD_HEARTS * sim.HEART))
	if a.fused: text_at(draw_pos + Vector2(-30, 24), "FUSÃO • G", CYAN, 12)
	text_at(draw_pos + Vector2(-25, -112 if a.armor else -86), "MARTY" if a.id == 0 else ("ECHO • IA" if sim.coop == "ai" else "ECHO • P2"), player_color, 11)

func draw_mech(m: Dictionary) -> void:
	var p: Vector2 = m.p
	var support: Vector2 = p - Vector2(0, sim.height_at(p))
	visual_transform(support, 0, Vector2(1, 0.45)); draw_circle(Vector2.ZERO, 43, Color(0, 0, 0, 0.5)); visual_transform(Vector2.ZERO)
	if m.hp <= 0:
		crate(Rect2(p - Vector2(40, 25), Vector2(80, 30))); text_at(p + Vector2(-40, -35), "INUTILIZADO", Color("b78c84"), 12); return
	# Titan v2: 8 direções (5 vistas + espelho), viseira acesa quando pilotado, passada pesada.
	if m.get("cockpit_t", 0.0) > 0:
		draw_cockpit(m); return
	var facing: Vector2 = titan_visual_direction(m)
	var pose := titan_pose(facing)
	var piloted: bool = m.occupant >= 0
	var column := 0; var bob := 0.0; var squash := 1.0
	var pilot: Dictionary = sim.actors[m.occupant] if piloted else {}
	var attacking: bool = piloted and (pilot.get("fire_flash", 0.0) > 0 or pilot.get("slash", 0.0) > 0)
	# 0.18: disparar não interrompe o ciclo dos pés.
	if piloted and m.get("moving", false):
		var phase := int(m.step) % 4
		column = 1 + phase
		# peso: afunda e achata quando o pé bate (quadros 1 e 3)
		var sub: float = fposmod(m.step, 1.0)
		if phase % 2 == 1: bob = 5.0 * (1.0 - sub); squash = 1.0 - 0.05 * (1.0 - sub)
		else: bob = -2.0 * sin(sub * PI)
	elif not piloted: bob = 0.0
	else:
		column = 0
		bob = sin(sim.tick_time * 2.0) * 1.0  # motor ligado
	var base: Vector2 = p - Vector2(0, sim.height_at(p) - bob)
	if m.get("boosting", false):
		var back := -facing.normalized()
		for k in range(3):
			var jet := base + Vector2(0, -60) + back * (40 + k * 10) + Vector2(sin(sim.tick_time * 50 + k) * 3, 0)
			draw_circle(jet, 14 - k * 3, Color(0.4, 0.9, 1, 0.45 - k * 0.1))
	visual_transform(base, 0, Vector2(-1.0 if pose[1] else 1.0, squash))
	# O atlas limpo mantém uma margem transparente entre todas as poses.
	draw_texture_rect_region(titan_v2, Rect2(-88, -164, 176, 176), Rect2(column * 176, pose[0] * 176, 176, 176))
	visual_transform(Vector2.ZERO)
	if not piloted: text_at(support + Vector2(-50, 27), "E • PILOTAR TITAN", CYAN, 13)
	else:
		draw_rect(Rect2(p + Vector2(-35, 16), Vector2(70, 3)), Color("161824"))
		draw_rect(Rect2(p + Vector2(-35, 16), Vector2(70 * pilot.get("boost", 1.0), 3)), Color(1, 0.8, 0.35))
	draw_rect(Rect2(p + Vector2(-35, 10), Vector2(70, 4)), Color("161824"))
	draw_rect(Rect2(p + Vector2(-35, 10), Vector2(70 * m.hp / 240, 4)), CYAN)

