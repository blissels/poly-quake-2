# res://scripts/sfx_manager.gd
# Daftarkan sebagai Autoload dengan nama "SFXManager"
extends Node

# ✅ Isi path ini dengan file audio kamu nanti
const SFX_PATHS := {
	"place"    : "res://assets/music/Sounds/tap-a.ogg",
	"destroy"  : "res://assets/music/Sounds/tap-a.ogg",
	# "earthquake": "res://assets/music/Sounds/sfx_earthquake.wav",
	# "success"  : "res://assets/music/Sounds/sfx_success.wav",
	# "fail"     : "res://assets/music/Sounds/sfx_fail.wav",
	"click"    : "res://assets/music/Sounds/click-b.ogg",
}

var _players : Dictionary = {}

func _ready():
	# Buat AudioStreamPlayer untuk setiap SFX
	for key in SFX_PATHS:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players[key] = player
		# Load file kalau ada, skip kalau belum ada
		if ResourceLoader.exists(SFX_PATHS[key]):
			player.stream = load(SFX_PATHS[key])

# ✅ Panggil ini dari mana saja: SFXManager.play("place")
func play(sfx_name: String) -> void:
	if not _players.has(sfx_name):
		return
	var player : AudioStreamPlayer = _players[sfx_name]
	if player.stream == null:
		return  # File belum diisi, skip tanpa error
	player.play()
