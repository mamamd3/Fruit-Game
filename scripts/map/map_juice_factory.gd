extends "res://scripts/map/map_base.gd"
## Mapa 2: Juice Factory — industrialna, 3 piętra platform, ciemne tło.

func _get_sky_top() -> Color: return Color(0.15, 0.12, 0.2)
func _get_sky_bottom() -> Color: return Color(0.25, 0.18, 0.12)

func _draw_decorations() -> void:
	var metal = Color(0.4, 0.4, 0.45)
	var dark_metal = Color(0.3, 0.3, 0.35)
	var rust = Color(0.55, 0.35, 0.2)

	# Tło — rury industrialne
	for i in range(-180, 200, 60):
		draw_line(Vector2(i, -120), Vector2(i, 100), Color(0.2, 0.2, 0.25, 0.3), 3.0)
	for j in range(-100, 100, 40):
		draw_line(Vector2(-220, j), Vector2(220, j), Color(0.2, 0.2, 0.25, 0.2), 2.0)

	# Podłoga — metal
	draw_rect(Rect2(-192, 84, 384, 6), dark_metal)

	# Platformy — 3 piętra
	# Dolne boczne
	_draw_platform_visual(Rect2(-170, 50, 80, 12), metal)
	_draw_platform_visual(Rect2(90, 50, 80, 12), metal)

	# Środkowe
	_draw_platform_visual(Rect2(-60, 20, 120, 12), rust)

	# Górne boczne
	_draw_platform_visual(Rect2(-150, -10, 70, 12), metal)
	_draw_platform_visual(Rect2(80, -10, 70, 12), metal)

	# Żółte światła ostrzegawcze
	for x in [-180, -60, 60, 180]:
		draw_circle(Vector2(x, -110), 3, Color(1.0, 0.8, 0.1, 0.5))
