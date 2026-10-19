extends RefCounted

# A mesma silhueta identifica a arma no mundo e no seletor.
const PATHS := {
	"pistol": "res://assets/weapons/pistol.png",
	"shotgun": "res://assets/weapons/shotgun.png",
	"smg": "res://assets/weapons/smg.png",
	"bazooka": "res://assets/weapons/bazooka_v2.png",
	"mosquete": "res://assets/weapons/mosquete_hd.png",
	"tesla": "res://assets/weapons/tesla_hd.png",
	"arpoador": "res://assets/weapons/arpoador_hd.png",
}

const SIZES := {"mosquete": Vector2(104, 30), "tesla": Vector2(86, 40), "arpoador": Vector2(100, 36)}
static var cached: Dictionary = {}

static func texture(weapon: String) -> Texture2D:
	if cached.has(weapon): return cached[weapon]
	var path: String = PATHS.get(weapon, "")
	if path == "" or not ResourceLoader.exists(path): return null
	var source: Texture2D = load(path)
	if SIZES.has(weapon):
		var cropped := AtlasTexture.new()
		cropped.atlas = source
		cropped.region = source.get_image().get_used_rect()
		cached[weapon] = cropped
	else: cached[weapon] = source
	return cached[weapon]
