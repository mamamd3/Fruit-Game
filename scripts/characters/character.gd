extends CharacterBody2D
## character.gd — uniwersalny skrypt postaci
## Ustaw character_name w Inspektorze Godota dla każdej sceny postaci.
## Logika modyfikatorów → ModifierSystem.gd

@export var character_name: String = "Strawberry"

@onready var CoyoteTimer:      Timer       = $Coyote
@onready var JumpBufferTimer:  Timer       = $JumpBufferTimer
@onready var Reloading:        Timer       = $ReloadTime
@onready var health_bar:       ProgressBar = $HealthBar

signal shoot(pos: Vector2, dir: Vector2)

# Input — ustawiane przez main_game.gd po spawnie
var action_left:  String = ""
var action_right: String = ""
var action_jump:  String = ""
var action_shoot: String = ""

var max_speed:  float = 0.0
var base_speed: float = 0.0

# ── KLUCZOWA FLAGA — zapobiega wielokrotnemu wywołaniu die() ─────────────────
# Problem: queue_free() nie usuwa węzła natychmiast. _physics_process może być
# wywołany jeszcze raz po die() zanim węzeł faktycznie zniknie. Bez tej flagi
# die() wywołuje się wielokrotnie → death_order ma duplikaty → crash w ranking.
var _is_dying: bool = false

# ── Interpolacja sieciowa ─────────────────────────────────────────────────────
# Ustawiona na true przez main_game.gd dla postaci sterowanych zdalnie.
# Gdy true: _physics_process jest pomijany, pozycja jest interpolowana w _process.
var is_remote:          bool    = false
var _net_target_pos:    Vector2 = Vector2.ZERO
const NET_LERP_SPEED:   float   = 20.0

# ── Stan modów (flagi odczytywane przez ModifierSystem) ──────────────────────
var wax_active:              bool  = false   # wax_coat
var second_fruit_used:       bool  = false   # second_fruit
var preservative_timer:      float = 0.0     # preservative — odlicza w dół
var regen_timer:             float = 2.0     # still_green
var rot_explosion_triggered: bool  = false   # rot_explosion
var armor_flat:              float = 0.0     # stone_seed
var seed_collector_bonus:    float = 0.0     # seed_collector
var streak_count:            int   = 0       # fruit_streak
var streak_bonus_ready:      bool  = false   # fruit_streak

# ── Slow (mod: sticky / inne) ─────────────────────────────────────────────────
var is_slowed:  bool  = false
var slow_timer: float = 0.0

# ── Poison incoming (stacks) ──────────────────────────────────────────────────
var poison_stacks: int   = 0
var poison_timer:  float = 0.0

# ── Poison trail (stary mod: poison) ─────────────────────────────────────────
var poison_zone_scene   = preload("res://Scenes/effects/poison_zone.tscn")
var poison_spawn_timer: float = 0.0

# ── Fizyka ────────────────────────────────────────────────────────────────────
var coyote_time_activated: bool  = false
const JUMP_HEIGHT:  float = -230.0
var   gravity:      float = 12.0
const MAX_GRAVITY:  float = 14.5
const ACCELERATION: float = 8.0
const FRICTION:     float = 10.0


# ─────────────────────────────────────────────
# READY
# ─────────────────────────────────────────────
func _ready() -> void:
	if Global.characters.is_empty():
		Global.reset_all()

	base_speed = float(Global.characters[character_name]["speed"])
	max_speed  = base_speed

	# Aplikuj mody startowe (on_apply) — prędkość, HP, flagi
	ModifierSystem.apply_on_ready(character_name, self)

	Reloading.wait_time  = Global.characters[character_name]["fire_rate"]
	health_bar.max_value = Global.base_characters[character_name]["hp"]
	health_bar.value     = Global.characters[character_name]["hp"]

	# Etykieta z nazwą nad postacią
	var lbl = Label.new()
	lbl.text = character_name
	lbl.add_theme_font_size_override("font_size", 4)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(-12, -22)
	lbl.size     = Vector2(24, 8)
	add_child(lbl)

	add_to_group("Players")  # wymagane przez ModifierSystem._find_character()


# ─────────────────────────────────────────────
# INPUT
# ─────────────────────────────────────────────
func get_input() -> void:
	if not Input.is_action_just_pressed(action_shoot):
		return
	if not Reloading.is_stopped():
		return
	shoot.emit(position, get_local_mouse_position().normalized())
	Reloading.start()


# ─────────────────────────────────────────────
# INTERPOLACJA SIECIOWA
# ─────────────────────────────────────────────

## Odbiera stan pozycji od serwera i ustawia cel interpolacji.
## Wywołaj to na zdalnym kliencie (is_remote == true) po każdym pakiecie sieciowym.
func receive_remote_state(pos: Vector2, vel: Vector2) -> void:
	_net_target_pos = pos
	# Prędkość zachowana na wypadek przyszłego użycia (np. przewidywanie ruchu).
	velocity = vel


func _process(delta: float) -> void:
	if not is_remote or _is_dying:
		return
	# Płynna interpolacja zamiast teleportacji przy każdym pakiecie.
	global_position = global_position.lerp(_net_target_pos, delta * NET_LERP_SPEED)


# ─────────────────────────────────────────────
# PUBLICZNE API
# ─────────────────────────────────────────────

func apply_slow() -> void:
	if preservative_timer > 0.0:
		return
	is_slowed  = true
	slow_timer = 3.0

func apply_poison() -> void:
	if preservative_timer > 0.0:
		return
	poison_stacks += 1

## Główna brama obrażeń — wywoływana z bullet.gd.
## Zwraca faktyczne obrażenia po modyfikacjach (0.0 = zablokowane).
func receive_damage(raw_dmg: float, attacker_name: String = "") -> float:
	# Jeśli już umieramy, ignoruj dalsze obrażenia
	if _is_dying:
		return 0.0

	var dmg = ModifierSystem.apply_on_receive(character_name, raw_dmg, attacker_name)
	if dmg <= 0.0:
		return 0.0

	# Sprawdź czy cios byłby śmiertelny
	var cur_hp = float(Global.characters[character_name]["hp"])
	if cur_hp - dmg <= 0.0:
		if ModifierSystem.apply_on_lethal(character_name):
			return 0.0  # przeżył dzięki second_fruit

	return dmg

## Śmierć — wywołaj tylko przez tę funkcję, nigdy queue_free() bezpośrednio.
func die() -> void:
	if _is_dying:

		return
	_is_dying = true

	Global.alive[character_name] = false
	Global.death_order.append(character_name)

	queue_free()


# ─────────────────────────────────────────────
# PHYSICS PROCESS
# ─────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	# Jeśli węzeł jest już w trakcie usuwania, nie rób niczego.
	# To jest drugi poziom ochrony — _is_dying powinien wystarczyć,
	# ale is_instance_valid daje dodatkową pewność.
	if _is_dying:
		return

	# Zdalnie sterowane postacie nie przetwarzają lokalnego wejścia —
	# ich pozycja jest interpolowana w _process() na podstawie pakietów sieciowych.
	if is_remote:
		return

	# Sprawdź HP — jeśli <= 0 to śmierć
	if Global.characters[character_name]["hp"] <= 0:
		die()
		return

	health_bar.value = Global.characters[character_name]["hp"]

	# Konserwant — odliczaj timer
	if preservative_timer > 0.0:
		preservative_timer -= delta

	# Slow
	if is_slowed:
		slow_timer -= delta
		if slow_timer <= 0.0:
			is_slowed = false

	# Poison (incoming stacks) — 5 × stacks co sekundę
	if poison_stacks > 0:
		poison_timer -= delta
		if poison_timer <= 0.0:
			poison_timer = 1.0
			Global.characters[character_name]["hp"] -= 5 * poison_stacks

	# Mody pasywne
	ModifierSystem.apply_passive(character_name, delta, self)

	get_input()

	# Ruch poziomy
	var cur_max    = max_speed * 0.4 if is_slowed else max_speed
	var x_input    = Input.get_action_strength(action_right) - Input.get_action_strength(action_left)
	var vel_weight = delta * (ACCELERATION if x_input else FRICTION)
	velocity.x     = lerp(velocity.x, x_input * cur_max, vel_weight)

	# Grawitacja i coyote time
	if is_on_floor():
		coyote_time_activated = false
		gravity = lerp(gravity, 12.0, 12.0 * delta)
	else:
		if CoyoteTimer.is_stopped() and not coyote_time_activated:
			CoyoteTimer.start()
			coyote_time_activated = true
		if Input.is_action_just_released(action_jump) or is_on_ceiling():
			velocity.y *= 0.5
		gravity = lerp(gravity, MAX_GRAVITY, 12.0 * delta)

	# Jump buffer
	if Input.is_action_just_pressed(action_jump) and JumpBufferTimer.is_stopped():
		JumpBufferTimer.start()

	if not JumpBufferTimer.is_stopped() and (not CoyoteTimer.is_stopped() or is_on_floor()):
		velocity.y = JUMP_HEIGHT
		JumpBufferTimer.stop()
		CoyoteTimer.stop()
		coyote_time_activated = true

	# Head nudge — pozwala wejść pod niskie platformy
	if velocity.y < JUMP_HEIGHT / 2.0:
		var hc = [
			$Left_HeadNudge.is_colliding(),
			$Left_Head_Nudge2.is_colliding(),
			$Right_Head_Nudge3.is_colliding(),
			$Right_Head_Nudge4.is_colliding()
		]
		if hc.count(true) == 1:
			if hc[0]: global_position.x += 1.75
			if hc[2]: global_position.x -= 1.75

	# Wall climb nudge
	if velocity.y > -30 and velocity.y < -5 and abs(velocity.x) > 3:
		if $RayCast2D3.is_colliding() and not $RayCast2D4.is_colliding() and velocity.x < 0:
			velocity.y += JUMP_HEIGHT / 3.25
		if $RayCast2D.is_colliding()  and not $RayCast2D2.is_colliding() and velocity.x > 0:
			velocity.y += JUMP_HEIGHT / 3.25

	velocity.y += gravity
	move_and_slide()
