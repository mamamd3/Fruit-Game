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
}

var p1_bullet_scene
var p2_bullet_scene

func _ready():
	_spawn_player(Global.player1_character, $Players/SpawnPoint1.position, "p1")
	_spawn_player(Global.player2_character, $Players/SpawnPoint2.position, "p2")

func _spawn_player(character_name: String, spawn_pos: Vector2, player_prefix: String):
	var data = character_scenes[character_name]
	var player = data["scene"].instantiate()
	player.action_left  = player_prefix + "_left"
	player.action_right = player_prefix + "_right"
	player.action_jump  = player_prefix + "_jump"
	player.action_shoot = player_prefix + "_shoot"
	player.position = spawn_pos
	if player_prefix == "p1":
		p1_bullet_scene = data["bullet"]
		player.shoot.connect(_on_p1_shoot)
	else:
		p2_bullet_scene = data["bullet"]
		player.shoot.connect(_on_p2_shoot)
	$Players.add_child(player)

func _on_p1_shoot(pos: Vector2, dir: Vector2) -> void:
	var bullet = p1_bullet_scene.instantiate() as Area2D
	$Bullets.add_child(bullet)
	bullet.setup(pos, dir)

func _on_p2_shoot(pos: Vector2, dir: Vector2) -> void:
	var bullet = p2_bullet_scene.instantiate() as Area2D
	$Bullets.add_child(bullet)
	bullet.setup(pos, dir)

func _physics_process(_delta: float) -> void:
	if Global.round_over:
		return
	if Global.alive.values().count(true) == 1:
		Global.round_over = true
		Global.build_ranking()
		get_tree().change_scene_to_file("res://Scenes/round_ended.tscn")
