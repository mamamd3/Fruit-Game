extends Node2D
## Klasa bazowa mapy — rysuje tło na podstawie kolorów.
## Każda mapa dziedziczy i nadpisuje _get_colors() + _draw_decorations().

func _get_sky_top() -> Color:
	return Color(0.4, 0.7, 1.0)

func _get_sky_bottom() -> Color:
	return Color(0.7, 0.85, 1.0)

func _get_ground_color() -> Color:
	return Color(0.3, 0.7, 0.2)

func _draw():
	# Gradient tło
	var top = _get_sky_top()
	var bot = _get_sky_bottom()
	for y in range(-120, 100, 2):
		var t = inverse_lerp(-120, 100, y)
		draw_line(Vector2(-220, y), Vector2(220, y), top.lerp(bot, t), 2.0)

	# Dekoracje — nadpisywane przez podklasy
	_draw_decorations()

func _draw_decorations() -> void:
	pass

func _draw_cloud(pos: Vector2, size: float, col: Color = Color(1, 1, 1, 0.7)) -> void:
	draw_circle(pos, 8 * size, col)
	draw_circle(pos + Vector2(-6, 2) * size, 6 * size, col)
	draw_circle(pos + Vector2(6, 2) * size, 6 * size, col)
	draw_circle(pos + Vector2(0, 4) * size, 5 * size, col)

func _draw_bush(pos: Vector2, col: Color = Color(0.2, 0.55, 0.15, 0.8)) -> void:
	draw_circle(pos, 5, col)
	draw_circle(pos + Vector2(-4, 1), 4, col)
	draw_circle(pos + Vector2(4, 1), 4, col)

func _draw_platform_visual(rect: Rect2, col: Color) -> void:
	draw_rect(rect, col)
	# Ciemniejsza krawędź na górze
	draw_line(Vector2(rect.position.x, rect.position.y), Vector2(rect.end.x, rect.position.y), col.darkened(0.3), 1.5)
