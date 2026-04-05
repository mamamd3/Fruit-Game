extends Area2D

var velocity: Vector2
var shooter_name = "Pineapple"
const GRAVITY = 75.0

# Spinning
var spin_timer: float = 0.0
var spin_direction: float = 1.0

# Bouncy
var bounces_left: int = 1

var explosion_scene = preload("res://scenes/effects/explosion.tscn")

func setup(pos: Vector2, dir: Vector2):
	position = pos + dir * 20
	velocity = dir * 180
	spin_direction = 1.0 if randf() > 0.5 else -1.0
	if Global.modifiers.get(shooter_name, []).has("bouncy"):
		bounces_left = 4

func _physics_process(delta: float) -> void:
	# Spinning modifier
	var mods = Global.modifiers.get(shooter_name, [])
	if mods.has("spinning"):
		spin_timer += delta
		var spin_offset = sin(spin_timer * 8.0) * 60.0 * spin_direction
		var perp = Vector2(-velocity.normalized().y, velocity.normalized().x)
		position += perp * spin_offset * delta

	velocity.y += GRAVITY * delta
	position += velocity * delta

func _on_body_entered(body: Node2D) -> void:
	var mods = Global.modifiers.get(shooter_name, [])

	if body.is_in_group("Terrain"):
		bounces_left -= 1
		if bounces_left >= 0:
			velocity.y = -velocity.y * 0.8
			return
		call_deferred("queue_free")
		return

	if not body.has_method("apply_slow"):
		return
	var target_name = body.character_name
	if target_name == shooter_name:
		return

	var dmg = Global.characters[shooter_name]["dmg"]
	Global.take_damage(target_name, dmg, "pocisk od " + shooter_name)

	if mods.has("lifesteal"):
		var max_hp = Global.base_characters[shooter_name]["hp"]
		Global.characters[shooter_name]["hp"] = min(
			Global.characters[shooter_name]["hp"] + dmg * 0.3, max_hp
		)
		print(shooter_name + " HP: " + str(Global.characters[shooter_name]["hp"]) + " (lifesteal)")

	if mods.has("sticky"):
		body.apply_slow()

	if mods.has("explosive"):
		var explosion = explosion_scene.instantiate()
		explosion.position = position
		explosion.shooter_name = shooter_name
		get_tree().root.add_child(explosion)

	call_deferred("queue_free")  # ← zmiana
