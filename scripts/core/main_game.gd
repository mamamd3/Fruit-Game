extends Node2D

var character_scenes = {
	"Strawberry": {
		"scene":  preload("res://Scenes/characters/strawberry.tscn"),
		"bullet": preload("res://Scenes/bullets/strawberry_bullet.tscn")
	},
	"Grape": {
		"scene":  preload("res://Scenes/characters/grape.tscn"),
		"bullet": preload("res://Scenes/bullets/grape_bullet.tscn")
	},
	"Orange": {
		"scene":  preload("res://Scenes/characters/orange.tscn"),
		"bullet": preload("res://Scenes/bullets/orange_bullet.tscn")
	},
	"Pineapple": {
		"scene":  preload("res://Scenes/characters/pineapple.tscn"),
		"bullet": preload("res://Scenes/bullets/pineapple_bullet.tscn")
	}
}

var bullet_scenes:     Dictionary = {}
var player_characters: Dictionary = {}
var kill_feed_script = preload("res://scripts/ui/kill_feed.gd")
var _ending_round: bool = false


func _ready() -> void:
	# reset_all TUTAJ (nie w round_ended) — dzięki temu stara scena nie widzi
	# pustego alive{} gdy reset następuje przed zmianą sceny.
	Global.reset_all()
	_setup_kill_feed()
	Global.game_started = true
	_ending_round = false

	print("=== RUNDA " + str(Global.round_number) + " ===")
	for character in Global.modifiers:
		if Global.modifiers[character].size() > 0:
			print(character + " mody: " + str(Global.modifiers[character]))

	_spawn_player(Global.player1_character, $Players/SpawnPoint1.position, "p1")
	_spawn_player(Global.player2_character, $Players/SpawnPoint2.position, "p2")
	_spawn_player(Global.player3_character, $Players/SpawnPoint3.position, "p3")
	_spawn_player(Global.player4_character, $Players/SpawnPoint4.position, "p4")

	# Tryb obserwatora: jeśli MultiplayerManager jest dostępny, połącz sygnał.
	if has_node("/root/MultiplayerManager"):
		var mm = get_node("/root/MultiplayerManager")
		if not mm.player_spectating.is_connected(_on_player_spectating):
			mm.player_spectating.connect(_on_player_spectating)

	$Gnicie.start()


func _spawn_player(character_name: String, spawn_pos: Vector2, player_prefix: String) -> void:
	if character_name == "":
		return
	var data   = character_scenes[character_name]
	var player = data["scene"].instantiate()
	player.action_left  = player_prefix + "_left"
	player.action_right = player_prefix + "_right"
	player.action_jump  = player_prefix + "_jump"
	player.action_shoot = player_prefix + "_shoot"
	player.position     = spawn_pos
	bullet_scenes[player_prefix]     = data["bullet"]
	player_characters[player_prefix] = character_name
	player.shoot.connect(func(pos, dir): _on_shoot(pos, dir, player_prefix))
	$Players.add_child(player)


func _setup_kill_feed() -> void:
	var canvas        = CanvasLayer.new()
	canvas.layer      = 10
	add_child(canvas)
	var feed          = VBoxContainer.new()
	feed.script       = kill_feed_script
	feed.anchor_right = 1.0
	feed.offset_left  = 4
	feed.offset_top   = 4
	feed.offset_right = -4
	canvas.add_child(feed)


func _on_shoot(pos: Vector2, dir: Vector2, player_prefix: String) -> void:
	if _ending_round:
		return
	var char_name: String = player_characters[player_prefix]

	# Główny pocisk
	var bullet = bullet_scenes[player_prefix].instantiate() as Area2D
	$Bullets.add_child(bullet)
	bullet.setup(pos, dir, char_name)

	# Dodatkowe pociski z modów (double_shot, shotgun)
	var extra_dirs: Array = ModifierSystem.get_extra_bullet_dirs(char_name, dir)
	for extra_dir in extra_dirs:
		var extra = bullet_scenes[player_prefix].instantiate() as Area2D
		$Bullets.add_child(extra)
		extra.setup(pos, extra_dir, char_name)


func _on_gnicie_timeout() -> void:
	# Gnicie = czas minął, wszyscy żywi remisują — brak zwycięzcy
	_end_round("")


func _physics_process(_delta: float) -> void:
	if _ending_round:
		return
	var alive_count = Global.alive.values().count(true)
	if alive_count <= 1:
		var winner = ""
		for ch in Global.alive:
			if Global.alive[ch]:
				winner = ch
				break
		_end_round(winner)


func _end_round(winning_character: String) -> void:
	# Flaga _ending_round blokuje wielokrotne wywołanie (np. gnicie + physics_process
	# wykrywają koniec rundy w tej samej klatce).
	if _ending_round:
		return
	_ending_round     = true
	Global.round_over = true
	Global.winner     = winning_character

	if has_node("Gnicie"):
		$Gnicie.stop()

	Global.build_ranking()
	Global.assign_points()  # nie przyznaje punktów przy remisoie (winner == "")

	# Remis — defensywnie zerujemy modifier_pickers tutaj też,
	# choć round_ended.gd już to obsługuje po swojej stronie.
	if winning_character == "":
		Global.modifier_pickers = []

	if Global.is_set_complete():
		get_tree().change_scene_to_file("res://Scenes/ui/set_over.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/ui/round_ended.tscn")


## Wyświetla nakładkę "Obserwator" dla gracza który dołączył w trakcie rundy.
func _on_player_spectating(spectator_peer_id: int) -> void:
	# Sprawdź czy to my jesteśmy obserwatorem (dotyczy klientów sieciowych).
	if not multiplayer.has_multiplayer_peer():
		return
	if multiplayer.get_unique_id() != spectator_peer_id:
		return
	_show_spectator_overlay()


func _show_spectator_overlay() -> void:
	var canvas   := CanvasLayer.new()
	canvas.layer = 20
	add_child(canvas)

	var lbl                    := Label.new()
	lbl.text                   = "TRYB OBSERWATORA\nCzekasz na następną rundę…"
	lbl.horizontal_alignment   = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment     = VERTICAL_ALIGNMENT_CENTER
	lbl.anchor_right           = 1.0
	lbl.anchor_bottom          = 1.0
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 0.2, 0.85))
	canvas.add_child(lbl)
