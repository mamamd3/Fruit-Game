extends Control

@onready var picking_label: Label = $PickingLabel
@onready var card1: Button = $HBoxContainer/Card1
@onready var card2: Button = $HBoxContainer/Card2
@onready var card3: Button = $HBoxContainer/Card3

var pickers = []          # kto wybiera modyfikator ["Grape", "Strawberry"]
var current_picker_index = 0  # który picker teraz wybiera
var current_cards = []    # 3 losowe modyfikatory pokazane teraz

# Ładne nazwy modyfikatorów do wyświetlenia
var modifier_names = {
	"speed":     "👟 +20% prędkość",
	"armor":     "🛡️ Pancerz",
	"poison":    "☠️ Ślad trucizny",
	"lifesteal": "🔴 Kradzież HP",
	"explosive": "💣 Eksplodujące pociski",
	"sticky":    "🐌 Lepkie pociski",
	"bouncy":    "↩️ Odbijające pociski",
	"spinning":  "🌪️ Wirujące pociski"
}

func _ready():
	pickers = Global.modifier_pickers  # ← czytaj z Global
	current_picker_index = 0
	show_cards_for_current_picker()

func show_cards_for_current_picker():
	if current_picker_index >= pickers.size():
		# Użyj call_deferred żeby nie zmieniać sceny w _ready()
		call_deferred("_go_to_main_game")
		return
	var picker = pickers[current_picker_index]
	picking_label.text = picker + " wybiera modyfikator!"
	var pool = Global.all_modifiers.duplicate()
	pool.shuffle()
	current_cards = pool.slice(0, 3)
	card1.text = modifier_names[current_cards[0]]
	card2.text = modifier_names[current_cards[1]]
	card3.text = modifier_names[current_cards[2]]

func _go_to_main_game():
	get_tree().change_scene_to_file("res://scenes/main_game.tscn")

func pick(index: int):
	var picker = pickers[current_picker_index]
	var chosen = current_cards[index]
	# Dodaj modyfikator do gracza — stackuje się!
	Global.modifiers[picker].append(chosen)
	current_picker_index += 1
	show_cards_for_current_picker()

func _on_card_1_pressed():
	pick(0)

func _on_card_2_pressed():
	pick(1)

func _on_card_3_pressed():
	pick(2)
