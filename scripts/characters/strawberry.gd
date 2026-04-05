extends CharacterBody2D

@onready var CoyoteTimer: Timer = $Coyote
@onready var JumpBufferTimer: Timer = $JumpBufferTimer
@onready var Reloading: Timer = $ReloadTime
@onready var health_bar: ProgressBar = $HealthBar
signal shoot(pos: Vector2, dir: Vector2)

var character_name = "Strawberry"
var action_left  = ""
var action_right = ""
var action_jump  = ""
var action_shoot = ""

var max_speed: float
var base_speed: float

# Slow (sticky modifier)
var is_slowed: bool = false
var slow_timer: float = 0.0

# Poison
var poison_stacks: int = 0
var poison_timer: float = 0.0

var coyote_time_activated: bool = false
const jump_height: float = -230
var gravity: float = 12
const max_gravity: float = 14.5
const acceleration: float = 8
const friction: float = 10

# Poison trail scene
var poison_zone_scene = preload("res://scenes/effects/poison_zone.tscn")
var poison_spawn_timer: float = 0.0

func _ready():
	if Global.characters.is_empty():
		Global.reset_all()
	base_speed = Global.characters[character_name]["speed"]
	max_speed = base_speed
	var mods = Global.modifiers.get(character_name, [])
	for mod in mods:
		if mod == "speed":
			max_speed *= 1.2
	Reloading.wait_time = Global.characters[character_name]["fire_rate"]
	# Ustaw pasek HP
	health_bar.max_value = Global.base_characters[character_name]["hp"]
	health_bar.value = Global.characters[character_name]["hp"]
	var name_label = Label.new()
	name_label.text = character_name
	name_label.add_theme_font_size_override("font_size", 4)
	name_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.position = Vector2(-12, -22)
	name_label.size = Vector2(24, 8)
	add_child(name_label)


func get_input():
	if Input.is_action_just_pressed(action_shoot) and Reloading.is_stopped():
		shoot.emit(position, get_local_mouse_position().normalized())
		Reloading.start()

func apply_slow():
	is_slowed = true
	slow_timer = 3.0  # sekundy spowolnienia

func apply_poison():
	poison_stacks += 1

func die():
	Global.alive[character_name] = false
	Global.death_order.append(character_name)
	queue_free()

func _physics_process(delta: float) -> void:
	if Global.characters[character_name]["hp"] <= 0:
		die()
		return
	# Aktualizuj pasek HP
	health_bar.value = Global.characters[character_name]["hp"]

	# Slow timer
	if is_slowed:
		slow_timer -= delta
		if slow_timer <= 0:
			is_slowed = false

	# Poison damage
	if poison_stacks > 0:
		poison_timer -= delta
		if poison_timer <= 0:
			poison_timer = 1.0  # co sekundę
			Global.characters[character_name]["hp"] -= 5 * poison_stacks

	# Poison trail — jeśli gracz ma poison modifier
	var mods = Global.modifiers.get(character_name, [])
	if mods.has("poison"):
		poison_spawn_timer -= delta
		if poison_spawn_timer <= 0:
			poison_spawn_timer = 0.4
			var zone = poison_zone_scene.instantiate()
			zone.position = global_position
			zone.shooter_name = character_name
			get_tree().root.add_child(zone)

	get_input()

	var current_max = max_speed * 0.4 if is_slowed else max_speed
	var x_input: float = Input.get_action_strength(action_right) - Input.get_action_strength(action_left)
	var velocity_wieght: float = delta * (acceleration if x_input else friction)
	velocity.x = lerp(velocity.x, x_input * current_max, velocity_wieght)

	if is_on_floor():
		coyote_time_activated = false
		gravity = lerp(gravity, 12.0, 12.0 * delta)
	else:
		if CoyoteTimer.is_stopped() and !coyote_time_activated:
			CoyoteTimer.start()
			coyote_time_activated = true
		if Input.is_action_just_released(action_jump) or is_on_ceiling():
			velocity.y *= 0.5
		gravity = lerp(gravity, max_gravity, 12.0 * delta)

	if Input.is_action_just_pressed(action_jump):
		if JumpBufferTimer.is_stopped():
			JumpBufferTimer.start()

	if !JumpBufferTimer.is_stopped() and (!CoyoteTimer.is_stopped() or is_on_floor()):
		velocity.y = jump_height
		JumpBufferTimer.stop()
		CoyoteTimer.stop()
		coyote_time_activated = true

	if velocity.y < jump_height/2.0:
		var head_collision: Array = [$Left_HeadNudge.is_colliding(), $Left_Head_Nudge2.is_colliding(), $Right_Head_Nudge3.is_colliding(), $Right_Head_Nudge4.is_colliding()]
		if head_collision.count(true) == 1:
			if head_collision[0]: global_position.x += 1.75
			if head_collision[2]: global_position.x -= 1.75

	if velocity.y > -30 and velocity.y < -5 and abs(velocity.x) > 3:
		if $RayCast2D3.is_colliding() and !$RayCast2D4.is_colliding() and velocity.x < 0:
			velocity.y += jump_height/3.25
		if $RayCast2D.is_colliding() and !$RayCast2D2.is_colliding() and velocity.x > 0:
			velocity.y += jump_height/3.25

	velocity.y += gravity
	move_and_slide()
