extends Node2D
## Rysuje owocowe kształty dla postaci.
## Dodaj jako dziecko CharacterBody2D zamiast ColorRect.

@export var fruit_type: String = "Strawberry"

func _draw():
	match fruit_type:
		"Strawberry":
			_draw_strawberry()
		"Grape":
			_draw_grape()
		"Orange":
			_draw_orange()
		"Pineapple":
			_draw_pineapple()
		"Lemon":
			_draw_lemon()
		"Watermelon":
			_draw_watermelon()

func _draw_strawberry():
	# Czerwone ciało - trójkąt zaokrąglony (od góry szeroki, dół wąski)
	var body_color = Color(0.9, 0.1, 0.15)
	var leaf_color = Color(0.2, 0.7, 0.15)

	# Ciało truskawki
	var points = PackedVector2Array([
		Vector2(-7, -2),
		Vector2(-8, -5),
		Vector2(-6, -8),
		Vector2(6, -8),
		Vector2(8, -5),
		Vector2(7, -2),
		Vector2(4, 6),
		Vector2(0, 8),
		Vector2(-4, 6),
	])
	draw_colored_polygon(points, body_color)

	# Pestki (żółte kropki)
	var seed_color = Color(1.0, 0.9, 0.3)
	draw_circle(Vector2(-3, -3), 0.8, seed_color)
	draw_circle(Vector2(3, -3), 0.8, seed_color)
	draw_circle(Vector2(-2, 1), 0.8, seed_color)
	draw_circle(Vector2(2, 1), 0.8, seed_color)
	draw_circle(Vector2(0, 4), 0.8, seed_color)

	# Listki na górze
	draw_colored_polygon(PackedVector2Array([
		Vector2(-1, -8), Vector2(-5, -12), Vector2(-2, -10), Vector2(0, -9)
	]), leaf_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(1, -8), Vector2(5, -12), Vector2(2, -10), Vector2(0, -9)
	]), leaf_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-1, -9), Vector2(0, -13), Vector2(1, -9)
	]), leaf_color)

	# Oczy
	_draw_eyes(Vector2(-3, -5), Vector2(3, -5))

func _draw_grape():
	var body_color = Color(0.55, 0.1, 0.7)
	var highlight = Color(0.7, 0.3, 0.85)
	var stem_color = Color(0.35, 0.55, 0.15)

	# Kiść winogron — okrągłe gronka
	var grape_positions = [
		Vector2(-4, -4), Vector2(4, -4),
		Vector2(-6, 0), Vector2(0, 0), Vector2(6, 0),
		Vector2(-4, 4), Vector2(4, 4),
		Vector2(0, 7),
	]
	for pos in grape_positions:
		draw_circle(pos, 4.0, body_color)
		draw_circle(pos + Vector2(-1, -1), 1.5, highlight)

	# Łodyżka
	draw_line(Vector2(0, -6), Vector2(0, -10), stem_color, 1.5)
	# Listek
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -9), Vector2(4, -12), Vector2(6, -10), Vector2(3, -8)
	]), Color(0.3, 0.65, 0.2))

	# Oczy (na środkowym gronku)
	_draw_eyes(Vector2(-2, -1), Vector2(2, -1))

func _draw_orange():
	var body_color = Color(1.0, 0.6, 0.1)
	var highlight = Color(1.0, 0.75, 0.35)
	var leaf_color = Color(0.25, 0.6, 0.15)

	# Ciało pomarańczy — koło
	draw_circle(Vector2(0, 0), 9.0, body_color)
	# Odblask
	draw_circle(Vector2(-3, -3), 3.5, highlight)

	# Łodyżka
	draw_line(Vector2(0, -8), Vector2(0, -12), Color(0.4, 0.3, 0.15), 2.0)
	# Listek
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -11), Vector2(5, -13), Vector2(4, -10), Vector2(1, -10)
	]), leaf_color)

	# Tekstura (segmenty)
	var line_color = Color(0.9, 0.5, 0.05, 0.3)
	draw_line(Vector2(0, -8), Vector2(0, 8), line_color, 0.5)
	draw_line(Vector2(-8, 0), Vector2(8, 0), line_color, 0.5)

	# Oczy
	_draw_eyes(Vector2(-3, -1), Vector2(3, -1))

func _draw_pineapple():
	var body_color = Color(0.85, 0.7, 0.15)
	var pattern_color = Color(0.7, 0.5, 0.1)
	var leaf_color = Color(0.2, 0.65, 0.15)

	# Ciało ananasa — owal
	var points: PackedVector2Array = []
	for i in range(20):
		var angle = i * TAU / 20
		points.append(Vector2(cos(angle) * 7, sin(angle) * 10 + 1))
	draw_colored_polygon(points, body_color)

	# Wzór kratki na ananasie
	for y in range(-7, 10, 4):
		draw_line(Vector2(-6, y), Vector2(6, y), pattern_color, 0.5)
	for x in range(-5, 7, 4):
		draw_line(Vector2(x, -7), Vector2(x, 10), pattern_color, 0.5)

	# Liście na górze (korona)
	var leaves = [
		[Vector2(-2, -9), Vector2(-6, -17), Vector2(-1, -12)],
		[Vector2(0, -10), Vector2(0, -18), Vector2(2, -12)],
		[Vector2(2, -9), Vector2(6, -17), Vector2(1, -12)],
		[Vector2(-4, -8), Vector2(-8, -14), Vector2(-2, -10)],
		[Vector2(4, -8), Vector2(8, -14), Vector2(2, -10)],
	]
	for leaf in leaves:
		draw_colored_polygon(PackedVector2Array(leaf), leaf_color)

	# Oczy
	_draw_eyes(Vector2(-3, -2), Vector2(3, -2))

func _draw_eyes(left_pos: Vector2, right_pos: Vector2):
	# Białka
	draw_circle(left_pos, 2.0, Color.WHITE)
	draw_circle(right_pos, 2.0, Color.WHITE)
	# Źrenice
	draw_circle(left_pos + Vector2(0.5, 0.5), 1.0, Color.BLACK)
	draw_circle(right_pos + Vector2(0.5, 0.5), 1.0, Color.BLACK)

func _draw_lemon():
	var body_color = Color(1.0, 0.95, 0.15)
	var highlight  = Color(1.0, 1.0, 0.55)
	var tip_color  = Color(0.75, 0.85, 0.2)

	# Ciało cytryny — owal poziomy z czubkami
	var pts: PackedVector2Array = []
	for i in range(24):
		var a = i * TAU / 24
		pts.append(Vector2(cos(a) * 9.0, sin(a) * 6.5))
	draw_colored_polygon(pts, body_color)

	# Czubki po bokach
	draw_colored_polygon(PackedVector2Array([
		Vector2(8, -1), Vector2(12, 0), Vector2(8, 1)
	]), tip_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8, -1), Vector2(-12, 0), Vector2(-8, 1)
	]), tip_color)

	# Odblask
	draw_circle(Vector2(-3, -2), 2.5, highlight)

	# Oczy
	_draw_eyes(Vector2(-3, 0), Vector2(3, 0))

func _draw_watermelon():
	var flesh_color = Color(0.9, 0.2, 0.3)
	var rind_color  = Color(0.25, 0.6, 0.2)
	var white_color = Color(0.85, 0.9, 0.8)
	var seed_color  = Color(0.1, 0.08, 0.06)

	# Ciało arbuza — duże koło
	draw_circle(Vector2(0, 0), 11.0, rind_color)
	draw_circle(Vector2(0, 0), 9.5, white_color)
	draw_circle(Vector2(0, 0), 8.5, flesh_color)

	# Paski (ciemniejsze)
	var stripe = Color(0.15, 0.5, 0.15)
	draw_line(Vector2(-11, -3), Vector2(11, -3), stripe, 1.5)
	draw_line(Vector2(-10, 3), Vector2(10, 3), stripe, 1.5)

	# Pestki
	for sp in [Vector2(-4, -2), Vector2(2, -3), Vector2(-2, 2), Vector2(4, 1)]:
		draw_circle(sp, 1.2, seed_color)

	# Oczy (przesunięte trochę wyżej bo postać duża)
	_draw_eyes(Vector2(-3, -2), Vector2(3, -2))
