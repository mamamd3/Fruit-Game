extends Node2D
## Rysuje owocowe pociski — nasiona, pestki, cząstki soku.

@export var bullet_type: String = "Strawberry"
var rot_angle: float = 0.0

func _process(delta: float):
	rot_angle += delta * 12.0
	queue_redraw()

func _draw():
	match bullet_type:
		"Strawberry":
			_draw_strawberry_seed()
		"Grape":
			_draw_grape_seed()
		"Orange":
			_draw_orange_pip()
		"Pineapple":
			_draw_pineapple_chunk()

func _draw_strawberry_seed():
	# Pestka truskawki — mała żółto-zielona łezka + ślad soku
	draw_set_transform(Vector2.ZERO, rot_angle)

	# Czerwona kropla soku
	draw_circle(Vector2(0, 0), 2.5, Color(0.85, 0.1, 0.15, 0.7))

	# Pestka (żółta łezka)
	var seed_points = PackedVector2Array([
		Vector2(0, -2), Vector2(1.2, 0), Vector2(0, 2.5), Vector2(-1.2, 0)
	])
	draw_colored_polygon(seed_points, Color(0.9, 0.85, 0.3))

	draw_set_transform(Vector2.ZERO, 0)

func _draw_grape_seed():
	# Gronko winogronowe — mała fioletowa kulka z sokiem
	draw_set_transform(Vector2.ZERO, rot_angle * 0.5)

	# Sok (rozprysk)
	draw_circle(Vector2(-1, -1), 1.5, Color(0.5, 0.1, 0.6, 0.4))
	draw_circle(Vector2(1, 1), 1.0, Color(0.5, 0.1, 0.6, 0.3))

	# Gronko
	draw_circle(Vector2(0, 0), 3.0, Color(0.55, 0.1, 0.7))
	# Odblask
	draw_circle(Vector2(-0.8, -0.8), 1.0, Color(0.7, 0.3, 0.85))

	draw_set_transform(Vector2.ZERO, 0)

func _draw_orange_pip():
	# Cząstka pomarańczy — plasterek z pestką
	draw_set_transform(Vector2.ZERO, rot_angle)

	# Plasterek (półkole pomarańczowe)
	var slice_points: PackedVector2Array = []
	for i in range(10):
		var angle = i * PI / 9
		slice_points.append(Vector2(cos(angle) * 3.5, sin(angle) * 3.5 - 1))
	slice_points.append(Vector2(-3.5, -1))
	draw_colored_polygon(slice_points, Color(1.0, 0.6, 0.1))

	# Skórka
	draw_arc(Vector2(0, -1), 3.5, 0, PI, 12, Color(1.0, 0.75, 0.2), 0.8)

	# Biała pestka w środku
	draw_circle(Vector2(0, 0), 1.0, Color(1.0, 0.95, 0.85))

	draw_set_transform(Vector2.ZERO, 0)

func _draw_pineapple_chunk():
	# Kawałek ananasa — żółty klocek z kolcem
	draw_set_transform(Vector2.ZERO, rot_angle)

	# Kawałek miąższu
	var chunk = PackedVector2Array([
		Vector2(-2.5, -2), Vector2(2.5, -2),
		Vector2(3, 2), Vector2(-3, 2)
	])
	draw_colored_polygon(chunk, Color(0.85, 0.7, 0.15))

	# Wzór kratki
	draw_line(Vector2(-2, -1), Vector2(2, -1), Color(0.7, 0.5, 0.1, 0.5), 0.5)
	draw_line(Vector2(0, -2), Vector2(0, 2), Color(0.7, 0.5, 0.1, 0.5), 0.5)

	# Kolec (listek)
	var spike = PackedVector2Array([
		Vector2(-1, -2), Vector2(0, -5), Vector2(1, -2)
	])
	draw_colored_polygon(spike, Color(0.25, 0.6, 0.15))

	draw_set_transform(Vector2.ZERO, 0)
