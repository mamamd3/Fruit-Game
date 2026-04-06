extends VBoxContainer
## Kill feed — wyświetla ostatnie trafienia na ekranie.
##
## WAŻNE: NIE używaj "while get_child_count() > MAX: get_child(0).queue_free()"
## queue_free() jest odroczone — węzeł nie znika natychmiast z drzewa sceny,
## więc get_child_count() nigdy nie maleje w tej pętli → NIESKOŃCZONA PĘTLA → freeze!
## Zamiast tego śledzimy etykiety w tablicy _active_labels.

const MAX_MESSAGES = 4
const FADE_TIME    = 3.0

# Tablica aktywnych etykiet — pop_front() od razu redukuje jej rozmiar,
# więc pętla while zawsze się kończy po MAX_MESSAGES iteracjach.
var _active_labels: Array = []

func _ready() -> void:
	Global.kill_feed_message.connect(_on_message)

func _on_message(text: String) -> void:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(label)
	_active_labels.append(label)

	# Usuń najstarsze — używamy TABLICY, nie get_child_count().
	# pop_front() natychmiast redukuje _active_labels.size(),
	# więc pętla kończy się po maksymalnie jednej iteracji przy normalnym użyciu.
	while _active_labels.size() > MAX_MESSAGES:
		var oldest = _active_labels.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()

	# Fade out po czasie
	var tween = create_tween()
	tween.tween_interval(FADE_TIME)
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(_on_label_faded.bind(label))

func _on_label_faded(label: Node) -> void:
	# Usuń z tablicy i z drzewa sceny
	_active_labels.erase(label)
	if is_instance_valid(label):
		label.queue_free()
