extends "res://scripts/map/map_base.gd"
## Mapa 1: Fruit Bowl — klasyczna otwarta arena, 2 platformy boczne.

func _get_sky_top() -> Color: return Color(0.4, 0.7, 1.0)
func _get_sky_bottom() -> Color: return Color(0.7, 0.85, 1.0)

func _draw_decorations() -> void:
	# Chmurki
	_draw_cloud(Vector2(-140, -90), 0.8)
	_draw_cloud(Vector2(80, -100), 1.0)
	_draw_cloud(Vector2(-30, -80), 0.6)
	_draw_cloud(Vector2(160, -85), 0.7)

	# Trawa na ziemi
	draw_rect(Rect2(-192, 84, 384, 6), Color(0.3, 0.7, 0.2))

	# Krzewy
	_draw_bush(Vector2(-150, 82))
	_draw_bush(Vector2(-50, 82))
	_draw_bush(Vector2(100, 82))
	_draw_bush(Vector2(160, 82))

	# Platformy
	_draw_platform_visual(Rect2(-171, 28, 92, 17), Color(0.45, 0.35, 0.2))
	_draw_platform_visual(Rect2(52, 46, 92, 17), Color(0.45, 0.35, 0.2))
