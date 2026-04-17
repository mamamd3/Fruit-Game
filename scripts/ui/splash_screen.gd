extends Control

@onready var timer = $Timer

func _ready() -> void:
	# Wymuszamy wyśrodkowanie
	$CenterContainer.set_anchors_preset(PRESET_FULL_RECT)
	# Efekt pojawiania się
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.0)
	
	# Po 2.5 sekundach przejdź do głównego menu
	timer.wait_time = 2.5
	timer.start()

func _on_timer_timeout() -> void:
	# Efekt zanikania
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or event is InputEventMouseButton:
		timer.stop()
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
