extends "res://scripts/map/map_base.gd"
## Mapa 4: Blender — otwarta arena, centralna platforma, ściany boczne.

func _get_sky_top() -> Color: return Color(0.9, 0.85, 0.95)
func _get_sky_bottom() -> Color: return Color(0.7, 0.6, 0.75)

func _draw_decorations() -> void:
	var glass = Color(0.8, 0.85, 0.9, 0.3)
	var blade = Color(0.6, 0.6, 0.65)
	var base_col = Color(0.35, 0.35, 0.4)

	# Szklane ściany blendera (boczne)
	draw_rect(Rect2(-192, -120, 8, 210), glass)
	draw_rect(Rect2(184, -120, 8, 210), glass)

	# Ostrza blendera — dekoracja w tle (krzyż)
	var center = Vector2(0, 30)
	for angle in [0, 0.785, 1.57, 2.356]:
		var dir_a = Vector2(cos(angle), sin(angle))
		draw_line(center - dir_a * 60, center + dir_a * 60, Color(0.5, 0.5, 0.55, 0.15), 2.0)

	# Podłoga — metalowa
	draw_rect(Rect2(-192, 84, 384, 6), base_col)

	# Centralna platforma — duża
	_draw_platform_visual(Rect2(-50, 30, 100, 14), blade)

	# Boczne małe półki na ścianach
	_draw_platform_visual(Rect2(-188, 10, 40, 10), base_col)
	_draw_platform_visual(Rect2(148, 10, 40, 10), base_col)

	# Górne boczne
	_draw_platform_visual(Rect2(-188, -40, 40, 10), base_col)
	_draw_platform_visual(Rect2(148, -40, 40, 10), base_col)

	# Sok na dnie — kolorowy gradient
	for y in range(78, 84):
		var t = inverse_lerp(78, 84, y)
		var juice = Color(1.0, 0.5, 0.2, 0.15).lerp(Color(0.9, 0.2, 0.3, 0.25), t)
		draw_line(Vector2(-184, y), Vector2(184, y), juice, 2.0)
