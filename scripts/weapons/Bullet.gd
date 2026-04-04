extends Area2D
class_name Bullet
# Bullet.gd v3 — BounceShots/StickyShots/ExplosiveShots

signal hit_player(bullet: Bullet, target: Node)

var direction    : Vector2  = Vector2.ZERO
var speed        : float    = 600.0
var damage       : int      = 10
var mods         : Array[String] = []
var owner_id     : int      = -1
var _bounces_left: int      = 0

func setup(dir: Vector2, dmg: int, modifiers: Array[String], pid: int) -> void:
	direction = dir
	damage    = dmg
	mods      = modifiers
	owner_id  = pid
	_bounces_left = 3 if "BounceShots" in mods else 0
	if "StickyShots" in mods: speed = 300.0

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("players") and body.get_meta("player_id",-1) != owner_id:
		if "StickyShots" in mods:
			speed = 0.0
			await get_tree().create_timer(2.0).timeout
		if "ExplosiveShots" in mods:
			_explode()
		else:
			body.take_damage(damage)
		emit_signal("hit_player", self, body)
	elif body.is_in_group("walls"):
		if _bounces_left > 0:
			_bounces_left -= 1
			_reflect(body)
		else:
			emit_signal("hit_player", self, body)

func _reflect(wall: Node) -> void:
	var normal = (global_position - wall.global_position).normalized()
	direction = direction.bounce(normal)

func _explode() -> void:
	var bodies := get_tree().get_nodes_in_group("players")
	for b in bodies:
		if b.global_position.distance_to(global_position) < 80.0:
			if b.get_meta("player_id",-1) != owner_id:
				b.take_damage(damage)

func reset() -> void:
	direction = Vector2.ZERO
	speed     = 600.0
	damage    = 10
	mods.clear()
	owner_id  = -1
	_bounces_left = 0
