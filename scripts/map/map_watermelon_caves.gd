extends "res://scripts/map/map_base.gd"

func _get_sky_top() -> Color: return Color(0.95, 0.4, 0.5) # Jasnoczerwony miąższ arbuzowy
func _get_sky_bottom() -> Color: return Color(0.1, 0.3, 0.1) # Ciemnozielona skórka

func _draw_decorations() -> void:
	var seed_col = Color(0.1, 0.08, 0.08)
	var flesh_col = Color(0.85, 0.25, 0.35)
	var rind_col = Color(0.4, 0.7, 0.3)
	
	# Podłoga gówna - skórka
	draw_rect(Rect2(-400, 200, 800, 50), rind_col)
	draw_rect(Rect2(-400, 200, 800, 10), Color(0.8, 0.9, 0.8)) # Biała część pod skórką
	
	# Lewa i Prawa granica (olbrzymia szerokość)
	draw_rect(Rect2(-410, -300, 20, 500), rind_col)
	draw_rect(Rect2(390, -300, 20, 500), rind_col)
	
	# Wiszące platformy (jaskinie wewnątrz arbuza)
	_draw_platform_visual(Rect2(-250, 100, 150, 20), flesh_col)
	_draw_platform_visual(Rect2(100, 100, 150, 20), flesh_col)
	
	_draw_platform_visual(Rect2(-100, 0, 200, 20), flesh_col)
	
	_draw_platform_visual(Rect2(-350, -100, 120, 20), flesh_col)
	_draw_platform_visual(Rect2(230, -100, 120, 20), flesh_col)
	
	_draw_platform_visual(Rect2(-150, -200, 300, 20), flesh_col)
	
	# Narysuj pestki arbuza rozsiane po mapie jako tło
	for i in range(40):
		var x = -380 + (i * 201) % 760
		var y = -280 + (i * 137) % 480
		# Rysujemy małe pestki w tle
		draw_circle(Vector2(x, y), 3.0, seed_col)
		draw_circle(Vector2(x, y+2), 2.5, seed_col)
