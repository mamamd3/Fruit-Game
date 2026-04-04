extends BaseCharacter
# 🍓 Strawberry | HP:100 SPD:200 FR:0.5s DMG:20 | Godot 4.3 stable

func _ready() -> void:
	MAX_HP      = 100
	MOVE_SPEED  = 200.0
	FIRE_RATE   = 0.5
	DAMAGE      = 20
	JUICE_COLOR = Color(0.9, 0.1, 0.2)
	super._ready()
