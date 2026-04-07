extends Area2D
## Melee hit — obszarowy cios Ananasa.
## Spawna się na pozycji gracza, zadaje obrażenia w zasięgu, znika po efekcie.

var shooter_name: String = ""
var hit_direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	await get_tree().physics_frame

	if not is_instance_valid(self):
		return
	if not Global.characters.has(shooter_name):
		queue_free()
		return

	var dmg = float(Global.characters[shooter_name]["dmg"])

	for body in get_overlapping_bodies():
		if not is_instance_valid(body):
			continue
		if not body.has_method("receive_damage"):
			continue
		var target_name = body.get("character_name")
		if target_name == null or target_name == shooter_name:
			continue
		if not Global.alive.get(target_name, false):
			continue

		var actual = body.receive_damage(dmg, shooter_name)
		if actual > 0.0:
			Global.take_damage(target_name, actual, "🍍 Cios " + shooter_name)
			# Knockback
			if is_instance_valid(body):
				body.velocity.x += hit_direction.x * 200.0
				body.velocity.y -= 100.0
			# Mody on_hit
			if is_instance_valid(body) and Global.alive.get(target_name, false):
				ModifierSystem.apply_on_hit(shooter_name, body, global_position, actual)

	# Wizualny łuk ciosu
	var slash = Line2D.new()
	var angle = hit_direction.angle()
	for i in range(9):
		var a = angle - 0.8 + (1.6 * i / 8.0)
		slash.add_point(Vector2(cos(a), sin(a)) * 35.0)
	slash.width = 3.0
	slash.default_color = Color(1, 0.9, 0.3, 0.9)
	add_child(slash)

	await get_tree().create_timer(0.12).timeout
	if is_instance_valid(self):
		queue_free()
