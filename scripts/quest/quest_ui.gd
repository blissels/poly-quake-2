# res://scripts/quest_ui.gd
# Attach ke node QuestUI di main_level.tscn
extends VBoxContainer

@onready var quest_title    : Label = $QuestTitle
@onready var quest_desc     : Label = $QuestDesc
@onready var quest_progress : Label = $QuestProgress
@onready var coin_label     : Label = $CoinLabel

func _ready() -> void:
	# Sambungkan ke sinyal QuestManager
	QuestManager.quest_step_updated.connect(_on_quest_updated)
	QuestManager.quest_step_done.connect(_on_quest_step_done)
	QuestManager.all_quests_done.connect(_on_all_done)
	
	# Sambungkan coins
	GameState.coins_changed.connect(_on_coins_changed)
	
	# Tampilan awal
	coin_label.text = "💰 0"

func _on_quest_updated(description: String, progress: int, total: int) -> void:
	quest_desc.text     = description
	quest_progress.text = "%d / %d" % [progress, total]

func _on_quest_step_done(description: String, _coins_earned: int) -> void:
	# Flash hijau saat step selesai
	quest_desc.text     = "✅ " + description
	quest_desc.modulate = Color.GREEN
	await get_tree().create_timer(1.0).timeout
	quest_desc.modulate = Color.WHITE

func _on_all_done() -> void:
	quest_desc.text     = "🎉 Semua objektif selesai!"
	quest_desc.modulate = Color.YELLOW

func _on_coins_changed(new_total: int) -> void:
	coin_label.text = "💰 %d" % new_total
	# Efek pop
	coin_label.modulate = Color.GOLD
	await get_tree().create_timer(0.3).timeout
	coin_label.modulate = Color.WHITE
