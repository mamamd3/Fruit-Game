extends Control

@onready var picking_label: Label = $PickingLabel
@onready var buttons = {
	"Strawberry": $Strawberry2,
	"Orange":     $Orange2,
	"Pineapple":  $Pineapple2,
	"Grape":      $Grape2
}

func _ready():
	Global.reset_selection()
	update_ui()

func update_ui():
	picking_label.text = "Gracz " + str(Global.current_picking_player) + " wybiera!"
	for character in buttons:
		buttons[character].disabled = !Global.available_characters.has(character)

func _on_strawberry_2_pressed():
	pick("Strawberry")

func _on_grape_2_pressed():
	pick("Grape")

func _on_orange_2_pressed():
	pick("Orange")

func _on_pineapple_2_pressed():
	pick("Pineapple")

func pick(character_name: String):
	Global.pick_character(character_name)
	if Global.all_picked():
		Global.reset_all()
		get_tree().change_scene_to_file("res://scenes/main_game.tscn")
	else:
		update_ui()
