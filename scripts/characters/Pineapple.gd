extends CharacterBody2D
# 🍍 Pineapple | HP:150 SPD:160 FR:0.8s DMG:35 | Godot 4.3 stable
# v3 PRODUKCYJNA — BulletPool + StateMachine + GPUParticles2D

const MAX_HP       : int   = 150
const MOVE_SPEED   : float = 160.0
const FIRE_RATE    : float = 0.8
const DAMAGE       : int   = 35
const JUICE_COLOR  : Color = Color(1.0, 0.8, 0.0)

var current_hp     : int   = MAX_HP
var rot_progress   : float = 0.0
var modifiers      : Array[String] = []

@onready var state_machine  : StateMachine    = $StateMachine
@onready var fire_timer     : Timer           = $FireTimer
@onready var rot_timer      : Timer           = $RotTimer
@onready var sprite         : AnimatedSprite2D = $AnimatedSprite2D
@onready var juice_particles: GPUParticles2D  = $JuiceParticles
@onready var rot_particles  : GPUParticles2D  = $RotParticles
@onready var bullet_pool: Node = $BulletPool

signal died(player_id: int)
signal hp_changed(new_hp: int, max_hp: int)
signal rotted_out

func _ready() -> void:
	add_to_group("players")
	fire_timer.wait_time = FIRE_RATE
	rot_timer.start(1.0)
	fire_timer.timeout.connect(func(): state_machine.transition(StateMachine.State.IDLE))
	rot_timer.timeout.connect(_apply_rot)
	state_machine.state_changed.connect(_on_state_changed)
	juice_particles.process_material = _make_juice_material()

func _physics_process(_delta: float) -> void:
	if not state_machine.can_move(): return
	var dir := Input.get_vector("move_left","move_right","move_up","move_down")
	velocity = dir * MOVE_SPEED * _speed_mult()
	if dir != Vector2.ZERO:
		if get_meta("ice_mode", false): velocity *= 1.4
		state_machine.transition(StateMachine.State.MOVE)
	else:
		state_machine.transition(StateMachine.State.IDLE)
	move_and_slide()

func shoot(target_pos: Vector2) -> void:
	if not state_machine.can_shoot(): return
	state_machine.transition(StateMachine.State.SHOOT)
	fire_timer.start()
	var bullet: Node = bullet_pool.call("acquire")
	if bullet is Bullet:
		bullet.global_position = global_position
		bullet.setup((target_pos - global_position).normalized(), DAMAGE, modifiers, get_meta("player_id", 0))
		bullet.hit_player.connect(_on_bullet_hit_player)

func take_damage(amount: int) -> void:
	if not state_machine.is_alive(): return
	current_hp -= amount
	hp_changed.emit(current_hp, MAX_HP)
	state_machine.transition(StateMachine.State.HIT)
	juice_particles.emitting = true
	if current_hp <= 0: _die()

func _apply_rot() -> void:
	rot_progress += 0.05 * (3.0 if rot_progress > 0.95 else 1.0)
	if rot_progress > 0.7 and not rot_particles.emitting:
		rot_particles.emitting = true
	sprite.modulate = Color(1.0 - rot_progress*0.4, 1.0 - rot_progress*0.5, 1.0 - rot_progress*0.3)
	if rot_progress >= 1.0:
		rotted_out.emit()
		_die()

func _die() -> void:
	state_machine.transition(StateMachine.State.DEAD)
	died.emit(get_meta("player_id", 0))
	juice_particles.emitting = true
	await get_tree().create_timer(0.5).timeout
	queue_free()

func _make_juice_material() -> ParticleProcessMaterial:
	var mat := ParticleProcessMaterial.new()
	mat.color = JUICE_COLOR
	mat.initial_velocity_min = 80.0
	mat.initial_velocity_max = 200.0
	mat.gravity = Vector3(0, 400, 0)
	mat.spread  = 120.0
	return mat

func _speed_mult() -> float:
	return 1.2 if "SpeedBoost" in modifiers else 1.0

func apply_modifier(mod_name: String) -> void:
	if mod_name not in modifiers: modifiers.append(mod_name)

func _on_state_changed(_from: StateMachine.State, to: StateMachine.State) -> void:
	match to:
		StateMachine.State.IDLE:  sprite.play("idle")
		StateMachine.State.MOVE:  sprite.play("walk")
		StateMachine.State.SHOOT: sprite.play("shoot")
		StateMachine.State.HIT:   sprite.play("hit")
		StateMachine.State.DEAD:  sprite.play("death")

func _on_bullet_hit_player(bullet: Bullet, _target: Node) -> void:
	bullet_pool.call("release", bullet)
