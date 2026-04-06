extends Control

@onready var picking_label: Label  = $PickingLabel
@onready var card1: Button         = $HBoxContainer/Card1
@onready var card2: Button         = $HBoxContainer/Card2
@onready var card3: Button         = $HBoxContainer/Card3

var pickers:              Array = []  # kto wybiera, np. ["Grape", "Strawberry"]
var current_picker_index: int   = 0   # który picker teraz wybiera
var current_cards:        Array = []  # 3 ID modyfikatorów aktualnie na kartach

# Stary słownik modifier_names USUNIĘTY —
# teraz czytamy z Global.modifier_registry, które ma wszystkie 30+ modów.
# Jeśli dodasz nowy mod do Global.gd, automatycznie pojawi się tutaj.

func _ready() -> void:
	pickers              = Global.modifier_pickers
	current_picker_index = 0
	show_cards_for_current_picker()

func show_cards_for_current_picker() -> void:
	# Wszyscy wybrali — lecimy do gry
	if current_picker_index >= pickers.size():
		call_deferred("_go_to_main_game")
		return

	var picker: String = pickers[current_picker_index]
	picking_label.text = picker + " wybiera modyfikator!"

	# Losuj 3 unikalne mody z puli
	var pool: Array = Global.all_modifiers.duplicate()
	pool.shuffle()
	current_cards = pool.slice(0, 3)

	# Ustaw tekst kart z rejestru — emoji + nazwa + opis
	_set_card_text(card1, current_cards[0])
	_set_card_text(card2, current_cards[1])
	_set_card_text(card3, current_cards[2])

## Buduje tekst przycisku z danych w Global.modifier_registry.
## Dzięki temu dodanie nowego modu w Global.gd wystarczy —
## nie trzeba tu nic zmieniać.
func _set_card_text(card: Button, mod_id: String) -> void:
	# Zabezpieczenie: jeśli mod nie istnieje w rejestrze, pokaż samo ID
	if not Global.modifier_registry.has(mod_id):
		card.text = mod_id
		return

	var entry: Dictionary = Global.modifier_registry[mod_id]
	var emoji: String     = entry.get("emoji", "")
	var name:  String     = entry.get("name",  mod_id)
	var desc:  String     = entry.get("desc",  "")

	# Format: "💥 Shotgun pestek\nWystrzelasz 4 dodatkowe pociski w wachlarzu."
	card.text = emoji + " " + name + "\n" + desc

func _go_to_main_game() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_game.tscn")

func pick(index: int) -> void:
	var picker: String = pickers[current_picker_index]
	var chosen: String = current_cards[index]

	# Dodaj mod do gracza — stackuje się między rundami
	Global.modifiers[picker].append(chosen)

	# Wyświetl w kill feedzie co wybrał
	var entry: Dictionary = Global.modifier_registry.get(chosen, {})
	var msg:   String     = entry.get("emoji", "") + " " + picker + \
							" wybrał: " + entry.get("name", chosen)
	Global.kill_feed_message.emit(msg)  # widoczne jak wejdziesz do gry

	current_picker_index += 1
	show_cards_for_current_picker()

func _on_card_1_pressed() -> void: pick(0)
func _on_card_2_pressed() -> void: pick(1)
func _on_card_3_pressed() -> void: pick(2)
