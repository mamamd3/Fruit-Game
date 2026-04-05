extends Node2D
## Rysuje tło i dekoracje mapy.

func _draw():
	# Tło — gradient niebo
	var sky_top = Color(0.4, 0.7, 1.0)
	var sky_bottom = Color(0.7, 0.85, 1.0)
	for y in range(-120, 100, 2):
		var t = inverse_lerp(-120, 100, y)
		var col = sky_top.lerp(sky_bottom, t)
		draw_line(Vector2(-220, y), Vector2(220, y), col, 2.0)

	# Chmurki
	_draw_cloud(Vector2(-140, -90), 0.8)
	_draw_cloud(Vector2(80, -100), 1.0)
	_draw_cloud(Vector2(-30, -80), 0.6)
	_draw_cloud(Vector2(160, -85), 0.7)

	# Trawa na ziemi
	var grass_color = Color(0.3, 0.7, 0.2)
	draw_rect(Rect2(-192, 84, 384, 6), grass_color)

	# Krzewy dekoracyjne
	_draw_bush(Vector2(-150, 82))
	_draw_bush(Vector2(-50, 82))
	_draw_bush(Vector2(100, 82))
	_draw_bush(Vector2(160, 82))

func _draw_cloud(pos: Vector2, size: float):
	var col = Color(1, 1, 1, 0.7)
	draw_circle(pos, 8 * size, col)
	draw_circle(pos + Vector2(-6, 2) * size, 6 * size, col)
	draw_circle(pos + Vector2(6, 2) * size, 6 * size, col)
	draw_circle(pos + Vector2(0, 4) * size, 5 * size, col)

func _draw_bush(pos: Vector2):
	var col = Color(0.2, 0.55, 0.15, 0.8)
	draw_circle(pos, 5, col)
	draw_circle(pos + Vector2(-4, 1), 4, col)
	draw_circle(pos + Vector2(4, 1), 4, col)
