extends SceneTree

const EncyclopediaData = preload("res://scripts/encyclopedia_data.gd")
var failures := 0

func check(ok: bool, label: String) -> void:
	if not ok: failures += 1; push_error("FAIL: " + label)
	else: print("PASS: ", label)

func _initialize() -> void:
	EncyclopediaData.reload()
	var all := EncyclopediaData.entries()
	check(all.size() >= 16, "catálogo inicial possui conteúdo representativo")
	for category in EncyclopediaData.CATEGORIES:
		check(not EncyclopediaData.by_category(category).is_empty(), "categoria " + category + " possui entradas")
	check(EncyclopediaData.item("monstro_almirante").nome == "O ALMIRANTE DAS PROFUNDEZAS", "chefe atual está documentado")
	check(EncyclopediaData.item("robo_titan").categoria == "robos" and EncyclopediaData.item("robo_spectre").categoria == "robos", "Titan e Spectre estão documentados")
	for monster in EncyclopediaData.by_category("monstros"):
		check(not EncyclopediaData.image_path(monster).is_empty(), "retrato do monstro %s resolve como textura" % monster.id)
	for item in EncyclopediaData.by_category("itens"):
		check(not EncyclopediaData.image_path(item).is_empty(), "card do item %s resolve como textura" % item.id)
	check(EncyclopediaData.image_path({"imagem":""}) == "", "imagem opcional ausente produz fallback seguro")
	check(not EncyclopediaData.image_path(EncyclopediaData.item("robo_titan")).is_empty(), "imagem existente é aceita")
	check(EncyclopediaData.item("item_bazuca").imagem == "res://assets/items/encyclopedia/bazuca_card.png", "Bazuca usa seu card de enciclopédia")
	check(EncyclopediaData.image_path({"imagem":"res://nao-existe.png"}) == "", "caminho de imagem indisponível produz fallback")
	check(EncyclopediaData.image_path({"imagem":"res://scripts/main.gd"}) == "", "recurso existente que não é textura é rejeitado")

	var malformed := [
		{"id":"ok_b", "categoria":"itens", "nome":"B", "descricao":"válido", "ordem":20, "imagem":"", "tracos":[]},
		{"id":"ok_a", "categoria":"itens", "nome":"A", "descricao":"válido", "ordem":10, "imagem":"", "tracos":["um"]},
		{"id":"ok_a", "categoria":"itens", "nome":"DUPLICADO", "descricao":"inválido", "imagem":"", "tracos":[]},
		{"id":"sem_nome", "categoria":"itens", "nome":"", "descricao":"inválido", "imagem":"", "tracos":[]},
		{"id":"categoria_ruim", "categoria":"lugares", "nome":"X", "descricao":"inválido", "imagem":"", "tracos":[]},
		{"id":"traco_ruim", "categoria":"robos", "nome":"X", "descricao":"inválido", "imagem":"", "tracos":[3]},
		{"id":"ordem_ruim", "categoria":"robos", "nome":"X", "descricao":"inválido", "ordem":{}, "imagem":"", "tracos":[]},
		{"id":"id com espaço", "categoria":"robos", "nome":"X", "descricao":"inválido", "imagem":"", "tracos":[]}
	]
	var clean := EncyclopediaData.valid_entries(malformed)
	check(clean.size() == 2, "entradas malformadas e IDs duplicados são ignorados")
	check(clean[0].id == "ok_a" and clean[1].id == "ok_b", "ordem do catálogo é determinística")
	var appended := EncyclopediaData.valid_entries(clean + [{"id":"novo_item", "categoria":"itens", "nome":"NOVO ITEM", "descricao":"adicionado depois", "ordem":30, "imagem":"", "tracos":[]}])
	check(appended.size() == 3 and appended[-1].id == "novo_item", "nova entrada válida é aceita em ordem sem alterar o leitor")
	check(EncyclopediaData.valid_entries({}).is_empty(), "raiz que não é lista falha com segurança")
	print("ENCYCLOPEDIA_DATA_TESTS_DONE failures=%d" % failures)
	quit(1 if failures > 0 else 0)
