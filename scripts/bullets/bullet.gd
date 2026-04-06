extends Area2D
## bullet.gd — uniwersalny skrypt pocisku
## shooter_name ustawiany przez setup() z main_game.gd.

var velocity:     Vector2 = Vector2.ZERO
var shooter_name: String  = ""

const GRAVITY: float = 75.0

# ── Spinning ──────────────────────────────────────────────────────────────────
var spin_timer:     float = 0.0
var spin_direction: float = 1.0

# ── Bouncing ──────────────────────────────────────────────────────────────────
var bounces_left: int  = 1
var has_bounced:  bool = false

# ── Damage modifiers (zmieniane przez on_bounce) ──────────────────────────────
var bonus_dmg:       float = 0.0   # destroying_bounce: +5 DMG co odbicie
var bounce_dmg_mult: float = 1.0   # rage_bounce: x1.3 DMG

# ── Magnetyczny ───────────────────────────────────────────────────────────────
var is_magnetic:           bool  = false
var magnetic_after_bounce: bool  = false
var magnetic_timer:        float = 0.0
const MAGNETIC_RANGE:      float = 200.0
var bullet_speed:          float = 180.0

# ── Dojrzały strzał — TYLKO jeśli gracz wybrał mod "ripe_shot" ───────────────
var ripe_shot_bonus: bool = false

# ── Owocowa passa ─────────────────────────────────────────────────────────────
var streak_bonus: bool = false


# ─────────────────────────────────────────────
# SETUP — wywoływane z main_game.gd po instantiate()
# ─────────────────────────────────────────────
func setup(pos: Vector2, dir: Vector2, p_shooter_name: String) -> void:
	shooter_name   = p_shooter_name
	spin_direction = 1.0 if randf() > 0.5 else -1.0

	var mods = Global.modifiers.get(shooter_name, [])

	# Prędkość — sniper_seed zwiększa o 25%
	bullet_speed = 180.0
	if mods.has("sniper_seed"):
		bullet_speed *= 1.25

	velocity = dir * bullet_speed
	position = pos + dir * 20.0

	# Liczba odbić bazowa + mody
	bounces_left = 1
	if mods.has("extra_bounce"): bounces_left += 1
	if mods.has("bouncy"):       bounces_left  = 4   # stary mod

	# Magnetyczna pestka — pocisk sam skręca w stronę wroga
	is_magnetic = mods.has("magnetic_seed")

	# Dojrzały strzał — licznik rośnie TYLKO jeśli gracz wybrał ten mod.
	# BEZ tego warunku licznik chodził dla wszystkich graczy zawsze —
	# każdy co 3. pocisk zadawał bonus niezależnie od wyboru modu.
	if mods.has("ripe_shot"):
		Global.shot_counter[shooter_name] = Global.shot_counter.get(shooter_name, 0) + 1
		if Global.shot_counter[shooter_name] >= 3:
			Global.shot_counter[shooter_name] = 0
			ripe_shot_bonus = true

	# Owocowa passa — flaga ustawiona przez ModifierSystem po 3 trafieniach z rzędu
	var char_node = _find_shooter()
	if char_node and char_node.streak_bonus_ready:
		streak_bonus                 = true
		char_node.streak_bonus_ready = false
		char_node.streak_count       = 0


# ─────────────────────────────────────────────
# PHYSICS
# ─────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	var mods = Global.modifiers.get(shooter_name, [])

	# Wirujący pocisk — sinusoidalny ruch boczny
	if mods.has("spinning"):
		spin_timer += delta
		var perp     = Vector2(-velocity.normalized().y, velocity.normalized().x)
		var spin_off = sin(spin_timer * 8.0) * 60.0 * spin_direction
		position    += perp * spin_off * delta

	# Magnetyczna pestka — ciągłe skręcanie w stronę najbliższego wroga
	if is_magnetic:
		_apply_homing(delta)

	# Magnetyczne odbicie — homing aktywny przez 2 sekundy po odbiciu
	if magnetic_after_bounce and has_bounced:
		magnetic_timer += delta
		if magnetic_timer < 2.0:
			_apply_homing(delta)

	velocity.y += GRAVITY * delta
	position   += velocity * delta


# ─────────────────────────────────────────────
# KOLIZJE
# ─────────────────────────────────────────────
func _on_body_entered(body: Node2D) -> void:
	if not is_instance_valid(self): return

	# ── Teren ──────────────────────────────────────────────────────────────

	if body.is_in_group("Terrain"):

		bounces_left -= 1

		if bounces_left >= 0:

			velocity.y  = -velocity.y * 0.8

			has_bounced = true

			ModifierSystem.apply_on_bounce(shooter_name, self)

			return

		call_deferred("queue_free")

		return

	if not is_instance_valid(body): return
	if not body.has_method("receive_damage"): return

	var target_name: String = body.get("character_name")
	if target_name == null or target_name == shooter_name: return
	if not Global.characters.has(target_name): return
	if not Global.alive.get(target_name, false): return
	if not Global.characters.has(shooter_name): return

	# NOWE: sprawdź czy strzelec nadal żyje według stanu alive
	# Chroni przed sytuacją wzajemnego zabicia gdy obaj umierają
	# w tej samej klatce i jeden pocisk próbuje działać "w imieniu" trupa
	if not Global.alive.get(shooter_name, false): return



	# ── Oblicz DMG ─────────────────────────────────────────────────────────
	var base_dmg: float = float(Global.characters[shooter_name]["dmg"])
	var dmg:      float = (base_dmg + bonus_dmg) * bounce_dmg_mult

	if ripe_shot_bonus: dmg *= 1.3   # co 3. strzał (mod: ripe_shot)
	if streak_bonus:    dmg *= 1.3   # po 3 trafieniach z rzędu (mod: fruit_streak)

	# Przekaż przez receive_damage() postaci.
	# receive_damage() zwraca faktyczne obrażenia po modyfikacjach (0 = zablokowane).
	var actual: float = body.receive_damage(dmg, shooter_name)

	if actual > 0.0:
		Global.take_damage(target_name, actual, "pocisk od " + shooter_name)
		# Sprawdź jeszcze raz po zadaniu obrażeń — body mogło właśnie umrzeć
		if is_instance_valid(body) and Global.alive.get(target_name, false):
			ModifierSystem.apply_on_hit(shooter_name, body, global_position, actual)

	call_deferred("queue_free")


# ─────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────

func _apply_homing(delta: float) -> void:
	var nearest:      Node2D = null
	var nearest_dist: float  = MAGNETIC_RANGE

	for node in get_tree().get_nodes_in_group("Players"):
		if not is_instance_valid(node): continue
		if node.get("character_name") == shooter_name: continue
		var d = global_position.distance_to(node.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest      = node

	if nearest:
		var desired = (nearest.global_position - global_position).normalized() * bullet_speed
		velocity    = velocity.lerp(desired, delta * 4.0)

func _find_shooter() -> Node:
	for node in get_tree().get_nodes_in_group("Players"):
		if not is_instance_valid(node): continue
		if node.get("character_name") == shooter_name:
			return node
	return null
