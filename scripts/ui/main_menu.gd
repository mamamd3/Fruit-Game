extends Control

# ── Tryb lokalny — sloty ──
@onready var slot_buttons: Array = [
	$VBox/LocalPanel/SlotsGrid/Slot1Button,
	$VBox/LocalPanel/SlotsGrid/Slot2Button,
	$VBox/LocalPanel/SlotsGrid/Slot3Button,
	$VBox/LocalPanel/SlotsGrid/Slot4Button,
]
@onready var start_local_btn: Button = $VBox/LocalPanel/StartLocalButton

# ── Tryb LAN ──
@onready var lan_panel:     Control  = $VBox/LANPanel
@onready var ip_input:      LineEdit = $VBox/LANPanel/IPInput
@onready var port_input:    LineEdit = $VBox/LANPanel/PortInput
@onready var join_button:   Button   = $VBox/LANPanel/JoinButton
@onready var status_label:  Label    = $VBox/LANPanel/StatusLabel

# Stan slotów: "player", "bot", "off"
var slot_states: Array = ["player", "player", "bot", "bot"]
const SLOT_CYCLE: Array = ["player", "bot", "off"]
const SLOT_LABELS: Dictionary = {
	"player": "🎮 Gracz",
	"bot":    "🤖 Bot",
	"off":    "❌ Wyłączony",
}

func _ready() -> void:
	ip_input.text   = MultiplayerManager.host_address
	port_input.text = str(MultiplayerManager.port)
	status_label.text = ""
	MultiplayerManager.connected.connect(_on_mp_connected)
	MultiplayerManager.disconnected.connect(_on_mp_disconnected)
	_update_slot_buttons()
	AudioManager.play_bgm()


# ═══════════════════════════════════════════════════════
# TRYB LOKALNY — sloty gracz/bot/off
# ═══════════════════════════════════════════════════════

func _update_slot_buttons() -> void:
	for i in range(4):
		slot_buttons[i].text = "Slot %d: %s" % [i + 1, SLOT_LABELS[slot_states[i]]]
	# Minimum 2 aktywne sloty do startu
	var active = slot_states.filter(func(s): return s != "off")
	start_local_btn.disabled = active.size() < 2

func _cycle_slot(index: int) -> void:
	var current = slot_states[index]
	var ci = SLOT_CYCLE.find(current)
	slot_states[index] = SLOT_CYCLE[(ci + 1) % SLOT_CYCLE.size()]
	# Slot 1 nie może być "off" — zawsze jest ktoś
	if index == 0 and slot_states[0] == "off":
		slot_states[0] = "player"
	_update_slot_buttons()

func _on_slot_1_pressed() -> void: AudioManager.play_ui_click(); _cycle_slot(0)
func _on_slot_2_pressed() -> void: AudioManager.play_ui_click(); _cycle_slot(1)
func _on_slot_3_pressed() -> void: AudioManager.play_ui_click(); _cycle_slot(2)
func _on_slot_4_pressed() -> void: AudioManager.play_ui_click(); _cycle_slot(3)

func _on_start_local_pressed() -> void:
	AudioManager.play_ui_click()
	MultiplayerManager.start_single_player()

	# Ustaw slot_types i total_players
	var active_count = 0
	for i in range(4):
		if slot_states[i] != "off":
			active_count += 1
			Global.slot_types[i + 1] = slot_states[i]
		else:
			Global.slot_types[i + 1] = "off"

	Global.total_players = active_count

	# Auto-assign postaci dla botów, gracze wybierają ręcznie
	# Przechodzimy do choose_character — boty dostaną losowe postaci automatycznie
	get_tree().change_scene_to_file("res://scenes/ui/choose_character.tscn")

func _on_options_pressed() -> void:
	AudioManager.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/ui/options_menu.tscn")

# ═══════════════════════════════════════════════════════
# TRYB LAN
# ═══════════════════════════════════════════════════════

func _on_host_pressed() -> void:
	AudioManager.play_ui_click()
	var p = int(port_input.text)
	if p <= 0: p = 7777
	MultiplayerManager.port = p
	MultiplayerManager.start_server()
	get_tree().change_scene_to_file("res://scenes/ui/lobby.tscn")

func _on_join_pressed() -> void:
	AudioManager.play_ui_click()
	var addr = ip_input.text.strip_edges()
	var p    = int(port_input.text)
	if addr.is_empty(): addr = "127.0.0.1"
	if p <= 0: p = 7777
	MultiplayerManager.host_address = addr
	MultiplayerManager.port         = p
	status_label.text    = "Łączenie z %s:%d..." % [addr, p]
	join_button.disabled = true
	MultiplayerManager.start_client(addr, p)

func _on_mp_connected() -> void:
	if MultiplayerManager.current_mode == MultiplayerManager.Mode.CLIENT:
		get_tree().change_scene_to_file("res://scenes/ui/lobby.tscn")

func _on_mp_disconnected() -> void:
	status_label.text    = "Połączenie nieudane."
	join_button.disabled = false
