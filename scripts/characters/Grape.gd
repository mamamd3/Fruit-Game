extends BaseCharacter
# 🍇 Grape | HP:70 SPD:220 FR:0.2s DMG:10 | Godot 4.3 stable

func _ready() -> void:
	MAX_HP      = 70
	MOVE_SPEED  = 220.0
	FIRE_RATE   = 0.2
	DAMAGE      = 10
	JUICE_COLOR = Color(0.5, 0.0, 0.8)
	super._ready()
