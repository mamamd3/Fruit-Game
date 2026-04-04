extends Node
# MapGenerator.gd | Godot 4.3 stable | v3 PRODUKCYJNA

signal mutator_activated(mutator: String)
enum Mutator { NONE, METEORS, ICE, MICRO, DARKNESS }

@export var map_seed : int = 0
const MUTATOR_CHANCE : float = 0.15
const TILE_SIZE : int = 64
const MAP_W : int = 20
const MAP_H : int = 15

var active_mutator : Mutator = Mutator.NONE
var _rng : RandomNumberGenerator

func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	if map_seed == 0: map_seed = Time.get_ticks_msec()
	_rng.seed = map_seed

func generate() -> void:
	_roll_mutator()
	_place_obstacles()

func _roll_mutator() -> void:
	if _rng.randf() < MUTATOR_CHANCE:
		active_mutator = _rng.randi_range(1, 4) as Mutator
		mutator_activated.emit(Mutator.keys()[active_mutator])

func _place_obstacles() -> void:
	for _i in _rng.randi_range(4, 10):
		var x := _rng.randi_range(1, MAP_W - 2) * TILE_SIZE
		var y := _rng.randi_range(1, MAP_H - 2) * TILE_SIZE
		push_warning("[MapGenerator] Obstacle @ (%d,%d)" % [x, y])
