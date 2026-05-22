# res://scripts/quest_manager.gd
# Autoload name: QuestManager
extends Node

signal quest_step_updated(description: String, progress: int, total: int)
signal quest_step_done(description: String, coins_earned: int)
signal all_quests_done()

# =============================================
# DATA QUEST PER LEVEL
# =============================================
const QUEST_DATA := {
	"tutorial": [
		{
			"desc"    : "Buka Build Mode (tekan B)",
			"trigger" : "build_mode_opened",
			"count"   : 1,
			"coins"   : 5,
		},
		{
			"desc"    : "Letakkan 1 dinding di slot kosong",
			"trigger" : "slot_filled",
			"count"   : 1,
			"coins"   : 10,
		},
		{
			"desc"    : "Lengkapi semua bagian rumah (3/3)",
			"trigger" : "slot_filled",
			"count"   : 3,   # Total kumulatif slot untuk tutorial
			"coins"   : 20,
		},
	],
	"level_01": [
		{
			"desc"    : "Lengkapi semua 6 bagian rumah sebelum gempa!",
			"trigger" : "slot_filled",
			"count"   : 6,
			"coins"   : 50,
		},
	],
}

# =============================================
var current_steps    : Array   = []
var step_index       : int     = 0
var step_progress    : int     = 0
var slots_filled_total: int    = 0

# =============================================
func start_quest(level_name: String) -> void:
	current_steps      = QUEST_DATA.get(level_name, [])
	step_index         = 0
	step_progress      = 0
	slots_filled_total = 0
	_emit_current_step()
	print("📋 Quest dimulai: %s" % level_name)

# =============================================
# TRIGGER FUNCTIONS — dipanggil dari script lain
# =============================================
func trigger_build_mode_opened() -> void:
	_handle("build_mode_opened", 1)

func trigger_slot_filled() -> void:
	slots_filled_total += 1
	# Cek step saat ini apakah minta "slot_filled"
	_handle("slot_filled", slots_filled_total)

# =============================================
func _handle(trigger: String, cumulative_value: int) -> void:
	if step_index >= current_steps.size(): return

	var step : Dictionary = current_steps[step_index]
	if step.get("trigger", "") != trigger: return

	var required : int = step.get("count", 1)
	step_progress = min(cumulative_value, required)

	if step_progress >= required:
		# ✅ Step selesai
		var coins : int = step.get("coins", 0)
		GameState.add_coins(coins)
		emit_signal("quest_step_done", step.get("desc", ""), coins)
		SFXManager.play("success")
		step_index += 1
		step_progress = 0

		if step_index >= current_steps.size():
			# ✅ Semua quest selesai
			emit_signal("all_quests_done")
		else:
			_emit_current_step()
	else:
		_emit_current_step()

func _emit_current_step() -> void:
	if step_index >= current_steps.size(): return
	var step     : Dictionary = current_steps[step_index]
	var required : int        = step.get("count", 1)
	emit_signal("quest_step_updated",
		step.get("desc", ""),
		step_progress,
		required
	)
