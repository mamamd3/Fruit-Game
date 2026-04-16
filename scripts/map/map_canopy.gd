extends "res://scripts/map/map_base.gd"
## Mapa 3: Canopy — las, dużo małych platform wysoko, wąski ground.

func _get_sky_top() -> Color: return Color(0.1, 0.25, 0.15)
func _get_sky_bottom() -> Color: return Color(0.2, 0.4, 0.15)

func _draw_decorations() -> void:
	var wood = Color(0.45, 0.3, 0.15)
	var leaf = Color(0.15, 0.5, 0.1)
	var dark_leaf = Color(0.1, 0.35, 0.08)

	# Pnie drzew w tle
	for x in [-160, -60, 40, 140]:
		draw_rect(Rect2(x - 4, -80, 8, 170), Color(0.3, 0.2, 0.1, 0.4))
		# Korona drzewa
		_draw_cloud(Vector2(x, -85), 1.2, dark_leaf)

	# Mech na ziemi
	draw_rect(Rect2(-192, 84, 384, 6), Color(0.2, 0.45, 0.1))

	# Platformy — liście/gałęzie na różnych wysokościach
	_draw_platform_visual(Rect2(-160, 55, 60, 10), wood)
	_draw_platform_visual(Rect2(-70, 35, 50, 10), leaf)
	_draw_platform_visual(Rect2(20, 15, 55, 10), wood)
	_draw_platform_visual(Rect2(110, 40, 60, 10), leaf)
	_draw_platform_visual(Rect2(-30, -15, 60, 10), dark_leaf)
	_draw_platform_visual(Rect2(-130, -5, 50, 10), leaf)
	_draw_platform_visual(Rect2(70, -20, 50, 10), wood)

	# Świetliki (kropki)
	for i in range(15):
		var pos = Vector2(randf_range(-180, 180), randf_range(-100, 70))
		draw_circle(pos, 1.2, Color(0.8, 1.0, 0.3, 0.3))
