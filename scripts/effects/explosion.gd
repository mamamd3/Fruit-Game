extends Area2D
## Eksplozja — zadaje obrażenia w zasięgu przy trafieniu (mod: explosive).

var shooter_name: String = ""

func _ready() -> void:
	# Czekamy jedną klatkę fizyki żeby Area2D zdążyła zarejestrować nakładające się ciała.
	await get_tree().physics_frame

	# Jeśli scena zmieniła się podczas await (np. runda się skończyła),
	# węzeł mógł już zostać zwolniony — is_instance_valid to wyłapuje.
	if not is_instance_valid(self):
		return

	# Zabezpieczenie: jeśli strzelec umarł i reset_all() wyczyścił characters,
	# nie próbuj odczytywać jego statystyk — to by crashowało.
	if not Global.characters.has(shooter_name):
		queue_free()
		return

	var dmg = float(Global.characters[shooter_name]["dmg"]) * 0.5

	for body in get_overlapping_bodies():
		if not is_instance_valid(body):
			continue
		# Używamy receive_damage() zamiast bezpośredniej modyfikacji HP —
		# dzięki temu działają pancerze, woskowa powłoka, lustrzana skórka itp.
		if not body.has_method("receive_damage"):
			continue
		var target_name = body.get("character_name")
		if target_name == null or target_name == shooter_name:
			continue
		if not Global.alive.get(target_name, false):
			continue
		if not Global.characters.has(target_name):
			continue
		var actual = body.receive_damage(dmg, shooter_name)
		if actual > 0.0:
			Global.take_damage(target_name, actual, "💥 Eksplozja od " + shooter_name)

	queue_free()
