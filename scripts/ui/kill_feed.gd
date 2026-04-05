extends VBoxContainer
## Kill feed — wyświetla ostatnie trafienia na ekranie.

const MAX_MESSAGES = 4
const FADE_TIME = 3.0

func _ready():
	Global.kill_feed_message.connect(_on_message)

func _on_message(text: String):
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(label)

	# Usuń najstarsze jeśli za dużo
	while get_child_count() > MAX_MESSAGES:
		get_child(0).queue_free()

	# Fade out po czasie
	var tween = create_tween()
	tween.tween_interval(FADE_TIME)
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(label.queue_free)
