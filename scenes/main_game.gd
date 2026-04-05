extends Node2D

var character_scenes = {
	"Strawberry": {
		"scene":  preload("res://Scenes/strawberry.tscn"),
		"bullet": preload("res://Scenes/strawberry_bullet.tscn")
	},
	"Grape": {
		"scene":  preload("res://Scenes/grape.tscn"),
		"bullet": preload("res://Scenes/grape_bullet.tscn")
	},
	"Orange": {
		"scene":  preload("res://Scenes/orange.tscn"),
		"bullet": preload("res://Scenes/orange_bullet.tscn")
	},
	"Pineapple": {
		"scene":  preload("res://Scenes/pineapple.tscn"),
		"bullet": preload("res://Scenes/pineapple_bullet.tscn")
	}
}

var bullet_scenes = {}

func _ready():
	Global.game_started = true
	_spawn_player(Global.player1_character, $Players/SpawnPoint1.position, "p1")
	_spawn_player(Global.player2_character, $Players/SpawnPoint2.position, "p2")
	_spawn_player(Global.player3_character, $Players/SpawnPoint3.position, "p3")
	_spawn_player(Global.player4_character, $Players/SpawnPoint4.position, "p4")
	$Gnicie.start()

func _spawn_player(character_name: String, spawn_pos: Vector2, player_prefix: String):
	if character_name == "":
		return
	var data = character_scenes[character_name]
	var player = data["scene"].instantiate()
	player.action_left  = player_prefix + "_left"
	player.action_right = player_prefix + "_right"
	player.action_jump  = player_prefix + "_jump"
	player.action_shoot = player_prefix + "_shoot"
	player.position = spawn_pos
	bullet_scenes[player_prefix] = data["bullet"]
	player.shoot.connect(func(pos, dir): _on_shoot(pos, dir, player_prefix))
	$Players.add_child(player)

func _on_shoot(pos: Vector2, dir: Vector2, player_prefix: String) -> void:
	var bullet = bullet_scenes[player_prefix].instantiate() as Area2D
	$Bullets.add_child(bullet)
	bullet.setup(pos, dir)

func _on_gnicie_timeout() -> void:
	if Global.round_over:
		return
	Global.round_over = true
	Global.winner = ""
	get_tree().change_scene_to_file("res://Scenes/round_ended.tscn")

func _physics_process(_delta: float) -> void:
	if Global.round_over:
		return
	if Global.alive.values().count(true) == 1:
		Global.round_over = true
		for character in Global.alive:
			if Global.alive[character]:
				Global.winner = character
		Global.build_ranking()
		get_tree().change_scene_to_file("res://Scenes/round_ended.tscn")
