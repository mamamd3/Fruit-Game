extends Node
## Bot AI — kontroluje CharacterBody2D zamiast inputu gracza.
## Dodawany jako child postaci przez main_game.gd.

var character: CharacterBody2D
var char_name: String = ""

# Cel i zachowanie
var target: CharacterBody2D = null
var retarget_timer: float = 0.0
var shoot_timer: float = 0.0
var jump_timer: float = 0.0
var direction: float = 0.0  # -1, 0, 1

func setup(p_character: CharacterBody2D, p_char_name: String) -> void:
	character = p_character
	char_name = p_char_name
	# Losowy offset na timery — żeby boty nie strzelały synchronicznie
	shoot_timer = randf() * 0.5
	jump_timer  = randf() * 1.0

func _physics_process(delta: float) -> void:
	if not is_instance_valid(character):
		return
	if character._is_dying:
		return

	retarget_timer -= delta
	shoot_timer    -= delta
	jump_timer     -= delta

	# Co 0.5s szukaj najbliższego wroga
	if retarget_timer <= 0.0:
		retarget_timer = 0.5
		_find_target()

	# Ruch w stronę celu
	if is_instance_valid(target) and not target._is_dying:
		var dx = target.global_position.x - character.global_position.x
		var dy = target.global_position.y - character.global_position.y

		# Idź w stronę celu
		if abs(dx) > 40.0:
			direction = sign(dx)
		else:
			# Blisko — losowe uniki
			direction = [-1.0, 0.0, 1.0].pick_random()

		# Skok gdy cel jest wyżej lub losowo
		if dy < -20.0 and jump_timer <= 0.0:
			jump_timer = 0.8 + randf() * 0.5
			_do_jump()
		elif jump_timer <= 0.0 and randf() < 0.02:
			jump_timer = 1.0
			_do_jump()

		# Strzelaj w kierunku celu
		var fire_rate = float(Global.characters.get(char_name, {}).get("fire_rate", 0.5))
		if shoot_timer <= 0.0:
			shoot_timer = fire_rate + randf() * 0.2
			var shoot_dir = (target.global_position - character.global_position).normalized()
			# Dodaj losowy rozrzut ±10°
			shoot_dir = shoot_dir.rotated(deg_to_rad(randf_range(-10.0, 10.0)))
			character.shoot.emit(character.position, shoot_dir)
			character.Reloading.start()
	else:
		# Brak celu — chodź losowo
		if jump_timer <= 0.0 and randf() < 0.01:
			jump_timer = 1.5
			direction = [-1.0, 1.0].pick_random()
		if randf() < 0.005:
			_do_jump()

	# Aplikuj ruch (nadpisz input)
	_apply_movement(delta)

func _apply_movement(delta: float) -> void:
	var cur_max = character.max_speed * 0.4 if character.is_slowed else character.max_speed
	var vel_weight = delta * (character.ACCELERATION if direction != 0.0 else character.FRICTION)
	character.velocity.x = lerp(character.velocity.x, direction * cur_max, vel_weight)

func _do_jump() -> void:
	if character.is_on_floor():
		character.velocity.y = character.JUMP_HEIGHT

func _find_target() -> void:
	var best: CharacterBody2D = null
	var best_dist: float = 9999.0
	for node in character.get_tree().get_nodes_in_group("Players"):
		if not is_instance_valid(node):
			continue
		if node == character:
			continue
		if node.get("_is_dying"):
			continue
		var d = character.global_position.distance_to(node.global_position)
		if d < best_dist:
			best_dist = d
			best      = node
	target = best
