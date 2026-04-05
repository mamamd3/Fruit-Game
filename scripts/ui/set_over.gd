extends Control

@onready var ranking_label: Label = $RankingLabel  # ← sprawdź nazwę w scenie!

func _ready() -> void:
	var sorted = Global.points.keys()
	sorted.sort_custom(func(a, b): return Global.points[a] > Global.points[b])
	var text = "Wyniki po " + str(Global.round_number) + " rundach:\n\n"
	for i in range(sorted.size()):
		text += str(i + 1) + ". " + sorted[i] + " — " + str(Global.points[sorted[i]]) + " pkt\n"
	ranking_label.text = text

func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/round_ended.tscn")

func _on_reset_pressed() -> void:
	Global.reset_full_game()
	get_tree().change_scene_to_file("res://scenes/ui/choose_character.tscn")
