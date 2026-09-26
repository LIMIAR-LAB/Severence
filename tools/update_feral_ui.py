from pathlib import Path
p=Path('scripts/terminal_ui.gd')
s=p.read_text(encoding='utf-8')
s=s.replace('var info_title: Label\nvar info_body: Label','var info_title: Label\nvar info_body: Label\nvar armor_body: Label\nvar companion_body: Label')
start=s.index('\t# Descrição do item selecionado (muda a cada clique)')
end=s.index('\tfor i in range(3):', start)
s=s[:start]+'''\t# Three permanent information regions; selection only changes the preview.
\tpanel(content, Rect2(895, 20, 310, 505), Color("081e29"), Color("497381"))
\tinfo_title = label(content, Rect2(910, 30, 280, 27), "", 18, GOLD)
\tinfo_body = label(content, Rect2(910, 62, 280, 125), "", 14, Color("b6dfdc"))
\tinfo_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
\tlabel(content, Rect2(910, 198, 280, 27), "ARMADURA TEMPORÁRIA", 18, CYAN)
\tarmor_body = label(content, Rect2(910, 230, 280, 145), "", 14, Color("b6dfdc"))
\tarmor_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
\tlabel(content, Rect2(910, 383, 280, 27), "COMPANHEIRO", 18, CYAN)
\tcompanion_body = label(content, Rect2(910, 413, 280, 104), "", 14, Color("b6dfdc"))
\tcompanion_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
''' + s[end:]
s=s.replace('elif key.begins_with("armor_"): armor_choice = key.trim_prefix("armor_")  # não troca a imagem do personagem','elif key == "armor_omega": armor_choice = "omega"; preview_kind = key')
s=s.replace('elif preview_kind == "spectre": preview.texture = load("res://assets/mech/spectre.png")','elif preview_kind == "spectre": preview.texture = atlas("res://assets/mech/spectre-feral.png", Rect2(0, 0, 128, 128))')
start=s.index('\t# Descrição do que foi clicado por último')
end=s.index('\tcurrent_choice.text',start)
s=s[:start]+'''\tinfo_title.text = "UNIFORME " + uni.name
\tinfo_body.text = uni.desc + "\\nArma: " + uni.weapon_name
\tarmor_body.text = "ÔMEGA • R • 5s / recarga 60s\\nLâmina: 38/38/64, final com onda.\\nVelocidade 430 • resistência 60%.\\nTiros: mínimo de 1 coração após resistência. Baús recarregam."
\tcompanion_body.text = ("TITAN • C invoca, E pilota.\\nCanhão, bomba e turbo (Shift).\\nIntegridade absorve impactos." if robot_choice == "titan" else "SPECTRE FERAL • C invoca.\\nPredador de apoio; G funde/separa.\\nFusão: +velocidade/dano. Energia absorve impactos; incompatível com Ômega.")
''' + s[end:]
# Replace baked hologram with the actual creature thumbnail.
needle='\t\tb.disabled = i == 2; slot_buttons["robot" + str(i)] = b'
s=s.replace(needle,needle+'''\n\t\tif i == 1:
\t\t\tpanel(b, Rect2(3, 3, 195, 114), Color("082331"), Color("082331"))
\t\t\tvar icon := TextureRect.new(); icon.texture = atlas("res://assets/mech/spectre-feral.png", Rect2(0, 0, 128, 128))
\t\t\ticon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.position = Vector2(40, 0); icon.size = Vector2(120, 112); icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; icon.mouse_filter = Control.MOUSE_FILTER_IGNORE; icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; b.add_child(icon)''')
s=s.replace('Drone de apoio.','Predador simbionte de apoio.')
p.write_text(s,encoding='utf-8')
p=Path('scripts/simulation.gd'); s=p.read_text(encoding='utf-8').replace('−15% de dano recebido • mais lento (290).','−15% dano • velocidade 290.\\nTiros: mínimo de 1 coração.').replace('−60% de dano • MUITO mais rápido (430) • corte reflete tiros.','−60% dano • velocidade 430 • reflete tiros.\\nTiros: mínimo de 1 coração após resistência.'); s=s.replace('\tfor e in enemies:\n\t\te.hurt =', '\tfor e in enemies:\n\t\tif e.hp <= 0: continue\n\t\te.hurt ='); p.write_text(s,encoding='utf-8')
