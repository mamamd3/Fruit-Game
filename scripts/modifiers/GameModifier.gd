extends Resource
class_name GameModifier
# GameModifier.gd | Godot 4.3 stable | v3 PRODUKCYJNA

enum ModType { BounceShots, PoisonTrail, SpeedBoost, StickyShots, ExplosiveShots, RegenerationAura }

@export var mod_type : ModType = ModType.SpeedBoost
@export var duration : float   = 15.0

func apply(player: Node) -> void:
	match mod_type:
		ModType.RegenerationAura: _start_regen(player)
		_: player.apply_modifier(ModType.keys()[mod_type])

func _start_regen(player: Node) -> void:
	player.apply_modifier("RegenerationAura")
	var t := Timer.new(); t.wait_time = 1.0
	player.add_child(t)
	t.timeout.connect(func():
		if player.is_inside_tree() and "RegenerationAura" in player.modifiers:
			player.current_hp = mini(player.current_hp + 3, player.MAX_HP))
	t.start()
	await player.get_tree().create_timer(duration).timeout
	player.modifiers.erase("RegenerationAura")
	t.queue_free()
