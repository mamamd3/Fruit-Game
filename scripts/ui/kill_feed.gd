extends VBoxContainer
## Kill feed — wyświetla ostatnie trafienia na ekranie.

const MAX_MESSAGES = 4
const FADE_TIME    = 3.0

var _active_labels: Array = []

func _ready() -> void:
	Global.kill_feed_message.connect(_on_message)

func _on_message(text: String) -> void:
	if not is_instance_valid(self):
		return
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(label)
	_active_labels.append(label)

	while _active_labels.size() > MAX_MESSAGES:
		var oldest = _active_labels.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()

	# Fade out — zabezpieczony przed freed node
	var tween = create_tween()
	tween.tween_interval(FADE_TIME)
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(func():
		if is_instance_valid(label):
			_active_labels.erase(label)
			label.queue_free()
	)

func _exit_tree() -> void:
	# Zabij wszystkie tweeny przy zmianie sceny
	for label in _active_labels:
		if is_instance_valid(label):
			label.queue_free()
	_active_labels.clear()
