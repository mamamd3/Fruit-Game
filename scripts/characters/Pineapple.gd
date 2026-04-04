extends BaseCharacter
# 🍍 Pineapple | HP:150 SPD:160 FR:0.8s DMG:35 | Godot 4.3 stable

func _ready() -> void:
	MAX_HP      = 150
	MOVE_SPEED  = 160.0
	FIRE_RATE   = 0.8
	DAMAGE      = 35
	JUICE_COLOR = Color(1.0, 0.8, 0.0)
	super._ready()
