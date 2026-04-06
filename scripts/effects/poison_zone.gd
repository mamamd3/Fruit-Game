extends Area2D
## Strefa trucizny — zadaje obrażenia co sekundę przez 3 sekundy.
## Tworzona przez mod: poison (trail), radioactive_seed (przy trafieniu).

var shooter_name: String = ""
var lifetime:   float = 3.0
var tick_timer: float = 1.0

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return

	tick_timer -= delta
	if tick_timer > 0:
		return
	tick_timer = 1.0

	for body in get_overlapping_bodies():
		if not is_instance_valid(body):
			continue
		# Używamy receive_damage() zamiast bezpośredniego hp -= X,
		# żeby pancerze i inne mody obronne działały poprawnie.
		if not body.has_method("receive_damage"):
			continue
		var target_name = body.get("character_name")
		if target_name == null or target_name == shooter_name:
			continue
		if not Global.alive.get(target_name, false):
			continue
		if not Global.characters.has(target_name):
			continue
		var actual = body.receive_damage(8.0, shooter_name)
		if actual > 0.0:
			Global.take_damage(target_name, actual, "☠️ Trucizna")
