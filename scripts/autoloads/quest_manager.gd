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
			"desc"    : "Letakkan 1 Dinding di Slot A",
			"trigger" : "slot_filled",
			"count"   : 1,
			"coins"   : 10,
			"required_slot": "slot_01", # Strict check
			"required_block": "Wall"    # Strict check
		},
		{
			"desc"    : "Lengkapi semua bagian rumah (3/3)",
			"trigger" : "slot_filled",
			"count"   : 3,
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
var filled_slot_ids  : Array   = []

func start_quest(level_name: String) -> void:
	current_steps      = QUEST_DATA.get(level_name, [])
	step_index         = 0
	step_progress      = 0
	slots_filled_total = 0
	filled_slot_ids.clear()
	_emit_current_step()
	print("📋 Quest dimulai: %s" % level_name)

func trigger_build_mode_opened() -> void:
	_handle("build_mode_opened", 1)

func trigger_slot_filled(slot_id: String = "", block_type: String = "Unknown") -> void:
	# 1. Validation for current step requirements
	if step_index < current_steps.size():
		var step: Dictionary = current_steps[step_index]
		if step.get("trigger") == "slot_filled":
			var req_slot: String = step.get("required_slot", "")
			var req_block: String = step.get("required_block", "")
			
			# Strict check: If requirements exist, they must match
			if req_slot != "" and slot_id != req_slot:
				print("[QuestManager] Strict Failure: Wrong slot! Expected %s, got %s" % [req_slot, slot_id])
				return
			if req_block != "" and block_type != req_block:
				print("[QuestManager] Strict Failure: Wrong block! Expected %s, got %s" % [req_block, block_type])
				return

	# 2. Prevent counting the same slot twice
	if slot_id != "" and slot_id in filled_slot_ids:
		print("[QuestManager] slot %s already counted" % slot_id)
		return
		
	if slot_id != "":
		filled_slot_ids.append(slot_id)
		
	slots_filled_total += 1
	_handle("slot_filled", 1)

func is_building_complete() -> bool:
	# Returns true if the last step of the current quest sequence is reached or finished
	return step_index >= current_steps.size()

func kurangi_objektif() -> void:
	if step_index < current_steps.size():
		var step : Dictionary = current_steps[step_index]
		if step.get("trigger", "") == "slot_filled":
			step_progress = max(0, step_progress - 1)
			slots_filled_total = max(0, slots_filled_total - 1)
			_emit_current_step()
			print("📉 Objective reduced: %d" % step_progress)

func _handle(trigger: String, delta: int) -> void:
	if step_index >= current_steps.size(): return

	var step : Dictionary = current_steps[step_index]
	if step.get("trigger", "") != trigger: return

	var required : int = step.get("count", 1)
	
	if trigger == "slot_filled":
		step_progress += delta
	else:
		step_progress = min(step_progress + delta, required)

	if step_progress >= required:
		_emit_current_step()
		var coins : int = step.get("coins", 0)
		GameState.add_coins(coins)
		emit_signal("quest_step_done", step.get("desc", ""), coins)
		if has_node("/root/SFXManager"):
			get_node("/root/SFXManager").play("success")
		step_index += 1
		step_progress = 0

		if step_index >= current_steps.size():
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
