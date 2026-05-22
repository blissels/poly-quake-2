# res://scripts/game_state.gd
# Autoload name: GameState
extends Node

# --- Level State ---
var current_level : String = "tutorial"   # "tutorial" atau "level_01"
var tutorial_done : bool   = false

# Urutan level untuk progression
const LEVEL_ORDER := ["tutorial", "level_01"]

func next_level() -> String:
	var idx := LEVEL_ORDER.find(current_level)
	if idx == -1:
		return current_level
	if idx + 1 >= LEVEL_ORDER.size():
		return current_level
	return LEVEL_ORDER[idx + 1]

func go_to_next_level() -> void:
	var nxt := next_level()
	if nxt == current_level:
		print("[GameState] Tidak ada level berikutnya")
		return
	go_to_level(nxt)

# --- Coins ---
var total_coins   : int = 0

signal coins_changed(new_total: int)
signal level_changed(level_name: String)

func add_coins(amount: int) -> void:
	total_coins += amount
	emit_signal("coins_changed", total_coins)
	print("💰 +%d coins! Total: %d" % [amount, total_coins])

func go_to_level(level_name: String) -> void:
	current_level = level_name
	emit_signal("level_changed", level_name)
