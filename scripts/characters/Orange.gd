extends BaseCharacter
# 🍊 Orange | HP:90 SPD:240 FR:0.35s DMG:15 | Godot 4.3 stable

func _ready() -> void:
	MAX_HP      = 90
	MOVE_SPEED  = 240.0
	FIRE_RATE   = 0.35
	DAMAGE      = 15
	JUICE_COLOR = Color(1.0, 0.5, 0.0)
	super._ready()
