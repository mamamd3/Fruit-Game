extends Node
## ╔══════════════════════════════════════════════════════════════════╗
## ║              ModifierSystem.gd  —  AUTOLOAD                     ║
## ╚══════════════════════════════════════════════════════════════════╝
##
## JAK DODAĆ NOWY MODYFIKATOR (3 kroki):
##
##  KROK 1 — Global.gd
##    Dodaj wpis do modifier_registry i ID do all_modifiers.
##
##  KROK 2 — ModifierSystem.gd
##    Znajdź funkcję odpowiadającą triggerowi i dodaj case w match:
##      "on_apply"   → apply_on_ready()
##      "on_shoot"   → get_extra_bullet_dirs()
##      "on_hit"     → apply_on_hit()
##      "on_receive" → apply_on_receive()
##      "on_lethal"  → apply_on_lethal()
##      "on_bounce"  → apply_on_bounce()
##      "passive"    → apply_passive()
##
##  KROK 3 — modifier_select.gd
##    Nic nie rób — mod pojawi się automatycznie w puli losowania.


# ╔══════════════════════════════════════════════════════════════════╗
# ║  TRIGGER: on_apply                                               ║
# ║  Kiedy: RAZ, w _ready() postaci na starcie każdej rundy.        ║
# ║  Użyj do: bonusów HP, zmian prędkości, flag startowych.         ║
# ╚══════════════════════════════════════════════════════════════════╝
func apply_on_ready(char_name: String, char_node: Node) -> void:
	var mods = Global.modifiers.get(char_name, [])
	for mod in mods:
		match mod:

			# ── Gruba skórka — +25 max HP ─────────────────────────────
			"thick_skin":
				Global.characters[char_name]["hp"]      += 25
				Global.base_characters[char_name]["hp"] += 25
				char_node.health_bar.max_value = Global.base_characters[char_name]["hp"]

			# ── Kamienna pestka — płaski pancerz i -10% speed ─────────
			"stone_seed":
				char_node.armor_flat += 8.0
				char_node.max_speed  *= 0.9

			# ── Dojrzały sprint — +15% speed ──────────────────────────
			"ripe_sprint":
				char_node.max_speed *= 1.15

			# ── Woskowa powłoka — aktywuj tarczę na pierwszą rundę ────
			"wax_coat":
				char_node.wax_active = true

			# ── Konserwant — 15 sek odporności na starcie rundy ───────
			"preservative":
				char_node.preservative_timer = 15.0

			# ── Duplikator modów — kopiuje losowy posiadany mod ───────
			"mod_duplicator":
				_duplicate_mod(char_name)

			# ── Stary mod: speed — +20% speed (kompatybilność) ────────
			"speed":
				char_node.max_speed *= 1.20

			# ── Antyzgnilizna — +5 sek do czasu gnicia ───────────────
			"antirot":
				char_node.rot_time_remaining += 5.0

			# ── Stary mod: armor — obsługiwany w apply_on_receive ─────
			"armor":
				pass


# ╔══════════════════════════════════════════════════════════════════╗
# ║  TRIGGER: on_shoot                                               ║
# ║  Kiedy: gdy gracz strzela (main_game.gd → _on_shoot).           ║
# ║  Zwraca tablicę DODATKOWYCH kierunków (główny pocisk już jest).  ║
# ╚══════════════════════════════════════════════════════════════════╝
func get_extra_bullet_dirs(char_name: String, base_dir: Vector2) -> Array:
	var mods:       Array = Global.modifiers.get(char_name, [])
	var extra_dirs: Array = []

	for mod in mods:
		match mod:

			# ── Podwójny strzał — 1 extra pocisk lekko obok ───────────
			"double_shot":
				var perp = Vector2(-base_dir.y, base_dir.x) * 0.15
				extra_dirs.append((base_dir + perp).normalized())

			# ── Shotgun pestek — 4 pociski w wachlarzu ±15° i ±30° ───
			"shotgun":
				for deg in [-30, -15, 15, 30]:
					extra_dirs.append(base_dir.rotated(deg_to_rad(float(deg))).normalized())

	return extra_dirs


# ╔══════════════════════════════════════════════════════════════════╗
# ║  TRIGGER: on_hit                                                 ║
# ║  Kiedy: pocisk trafia w gracza (bullet.gd → _on_body_entered).  ║
# ║  target_node = CharacterBody2D trafionego gracza.               ║
# ╚══════════════════════════════════════════════════════════════════╝
func apply_on_hit(shooter_name: String, target_node: Node, hit_pos: Vector2, dmg: float) -> void:
	# Zabezpieczenie — węzeł mógł umrzeć między wywołaniem a wykonaniem
	if not is_instance_valid(target_node):
		return

	var mods        = Global.modifiers.get(shooter_name, [])
	var target_name = target_node.get("character_name")

	if target_name == null:
		return

	# Dodatkowe sprawdzenie żywości — chroni przed "zombie" węzłami
	if not Global.alive.get(target_name, false):
		return

	for mod in mods:
		match mod:

			# ── Fermentacja — zatruwa trafionego na 3 sek ─────────────
			"fermentation":
				if is_instance_valid(target_node):
					target_node.apply_poison()

			# ── Radioaktywna pestka — toksyczna plama w miejscu trafienia
			"radioactive_seed":
				_spawn_poison_zone(hit_pos, shooter_name)

			# ── Strzał zgnilizny — trafiony gnije o 3 sek szybciej ───
			"rot_shot":
				var rot_target = _find_character(target_name)
				if rot_target:
					rot_target.rot_time_remaining -= 3.0

			# ── Lifesteal — odzyskujesz 30% zadanych obrażeń jako HP ──
			"lifesteal":
				_apply_lifesteal(shooter_name, dmg)

			# ── Soczyste wnętrze — 15% brakującego HP ─────────────────
			"juicy_core":
				_apply_juicy_core(shooter_name)

			# ── Lepkie pociski — spowalnia trafionego (3 sek) ─────────
			"sticky":
				if is_instance_valid(target_node):
					target_node.apply_slow()

			# ── Eksplodujące pociski — eksplozja w miejscu trafienia ──
			"explosive":
				_spawn_explosion(hit_pos, shooter_name)

			# ── Kolekcjoner pestek — +1 DMG za każde trafienie bez ciosu
			"seed_collector":
				var shooter_node = _find_character(shooter_name)
				if shooter_node:
					shooter_node.seed_collector_bonus += 1.0
					_update_base_dmg(shooter_name, shooter_node.seed_collector_bonus)

			# ── Owocowa passa — 3 trafienia = następny pocisk +30% DMG
			"fruit_streak":
				var shooter_node = _find_character(shooter_name)
				if shooter_node:
					shooter_node.streak_count += 1
					if shooter_node.streak_count >= 3:
						shooter_node.streak_bonus_ready = true
						shooter_node.streak_count       = 0


# ╔══════════════════════════════════════════════════════════════════╗
# ║  TRIGGER: on_receive                                             ║
# ║  Kiedy: character.gd receive_damage() — zanim obrażenia padną.  ║
# ║  Zwraca faktyczne obrażenia (0.0 = zablokowane całkowicie).     ║
# ╚══════════════════════════════════════════════════════════════════╝
func apply_on_receive(target_name: String, raw_dmg: float, attacker_name: String = "") -> float:
	var mods      = Global.modifiers.get(target_name, [])
	var char_node = _find_character(target_name)
	var dmg       = raw_dmg

	# ── Woskowa powłoka — blokuje pierwsze trafienie ───────────────
	if mods.has("wax_coat") and char_node and char_node.wax_active:
		char_node.wax_active = false
		Global.kill_feed_message.emit("🕯️ " + target_name + " zablokował trafienie!")
		return 0.0

	# ── Konserwant — pełna odporność przez 15 sek ─────────────────
	if char_node and char_node.preservative_timer > 0:
		return 0.0

	# ── Lustrzana skórka — 10% szansa odbicia ataku ───────────────
	if mods.has("mirror_skin") and randf() < 0.10:
		if attacker_name != "" and Global.characters.has(attacker_name):
			Global.take_damage(attacker_name, raw_dmg, "🪞 Lustrzana skórka " + target_name)
		Global.kill_feed_message.emit("🪞 " + target_name + " odbił atak!")
		if char_node and char_node.seed_collector_bonus > 0:
			char_node.seed_collector_bonus = 0.0
			_update_base_dmg(target_name, 0.0)
		return 0.0

	# ── Kolczasta tarcza — atakujący dostaje 3 obrażeń ────────────
	if mods.has("thorn_shield") and attacker_name != "" and Global.characters.has(attacker_name):
		Global.take_damage(attacker_name, 3.0, "🌵 Kolczasta tarcza")

	# ── Kamienna pestka — stały płaski pancerz (8 pkt) ────────────
	if mods.has("stone_seed"):
		var flat = char_node.armor_flat if char_node else 8.0
		dmg = max(0.0, dmg - flat)

	# ── Stary mod: armor — -30% obrażeń ───────────────────────────
	if mods.has("armor"):
		dmg *= 0.7

	# ── Twardy owoc — -10% obrażeń ────────────────────────────────
	if mods.has("hard_fruit"):
		dmg *= 0.9

	# ── Kolekcjoner pestek — reset passy przy otrzymaniu ciosu ────
	if mods.has("seed_collector") and char_node and char_node.seed_collector_bonus > 0:
		char_node.seed_collector_bonus = 0.0
		_update_base_dmg(target_name, 0.0)
		Global.kill_feed_message.emit("🌰 " + target_name + " stracił passę!")

	return dmg


# ╔══════════════════════════════════════════════════════════════════╗
# ║  TRIGGER: on_lethal                                              ║
# ║  Kiedy: cios zabiłby gracza (character.gd → receive_damage).    ║
# ║  Zwraca true = gracz przeżył / false = gracz umiera.            ║
# ╚══════════════════════════════════════════════════════════════════╝
func apply_on_lethal(target_name: String) -> bool:
	var mods      = Global.modifiers.get(target_name, [])
	var char_node = _find_character(target_name)

	# ── Drugi owoc — jednorazowe przeżycie z 5 HP ─────────────────
	if mods.has("second_fruit") and char_node and not char_node.second_fruit_used:
		char_node.second_fruit_used          = true
		Global.characters[target_name]["hp"] = 5
		Global.kill_feed_message.emit("🍀 " + target_name + " przeżył śmiertelny cios!")
		return true

	return false


# ╔══════════════════════════════════════════════════════════════════╗
# ║  TRIGGER: on_bounce                                              ║
# ║  Kiedy: pocisk odbił się od terenu (bullet.gd).                 ║
# ╚══════════════════════════════════════════════════════════════════╝
func apply_on_bounce(shooter_name: String, bullet_node: Node) -> void:
	if not is_instance_valid(bullet_node):
		return

	var mods = Global.modifiers.get(shooter_name, [])

	for mod in mods:
		match mod:

			"accelerating_bounce":
				bullet_node.velocity     *= 1.1

			"destroying_bounce":
				bullet_node.bonus_dmg    += 5.0

			"rage_bounce":
				bullet_node.bounce_dmg_mult = 1.3

			"magnetic_bounce":
				bullet_node.magnetic_after_bounce = true
				bullet_node.magnetic_timer        = 0.0


# ╔══════════════════════════════════════════════════════════════════╗
# ║  TRIGGER: passive                                                ║
# ║  Kiedy: co klatkę, z _physics_process() postaci.                ║
# ╚══════════════════════════════════════════════════════════════════╝
func apply_passive(char_name: String, delta: float, char_node: Node) -> void:
	if not is_instance_valid(char_node):
		return

	var mods = Global.modifiers.get(char_name, [])

	for mod in mods:
		match mod:

			"still_green":
				_passive_still_green(char_name, delta, char_node)

			"rot_explosion":
				_passive_rot_explosion(char_name, char_node)

			"rot_accelerator":
				_passive_rot_accelerator(char_name, delta, char_node)

			"poison":
				_passive_poison_trail(char_name, delta, char_node)


# ═══════════════════════════════════════════════════════════════════
# PRYWATNE HELPERY
# ═══════════════════════════════════════════════════════════════════

func _duplicate_mod(char_name: String) -> void:
	var mods     = Global.modifiers.get(char_name, [])
	var copyable = mods.filter(func(m): return m != "mod_duplicator")
	if copyable.is_empty():
		return
	copyable.shuffle()
	var chosen: String = copyable[0]
	Global.modifiers[char_name].append(chosen)
	if Global.modifier_registry.has(chosen):
		Global.kill_feed_message.emit("🔄 " + char_name + " skopiował: " + Global.modifier_registry[chosen]["name"])

func _apply_lifesteal(shooter_name: String, dmg: float) -> void:
	if not Global.characters.has(shooter_name):
		return
	var max_hp = float(Global.base_characters[shooter_name]["hp"])
	var cur_hp = float(Global.characters[shooter_name]["hp"])
	Global.characters[shooter_name]["hp"] = min(cur_hp + dmg * 0.3, max_hp)

func _apply_juicy_core(shooter_name: String) -> void:
	if not Global.characters.has(shooter_name):
		return
	var max_hp  = float(Global.base_characters[shooter_name]["hp"])
	var cur_hp  = float(Global.characters[shooter_name]["hp"])
	Global.characters[shooter_name]["hp"] = min(cur_hp + (max_hp - cur_hp) * 0.15, max_hp)

func _passive_still_green(char_name: String, delta: float, char_node: Node) -> void:
	var max_hp = float(Global.base_characters[char_name]["hp"])
	var cur_hp = float(Global.characters[char_name]["hp"])
	if cur_hp >= max_hp * 0.3:
		return
	char_node.regen_timer -= delta
	if char_node.regen_timer <= 0.0:
		char_node.regen_timer = 2.0
		Global.characters[char_name]["hp"] = min(cur_hp + 1.0, max_hp)

func _passive_rot_explosion(char_name: String, char_node: Node) -> void:
	if char_node.rot_explosion_triggered:
		return
	var max_hp = float(Global.base_characters[char_name]["hp"])
	var cur_hp = float(Global.characters[char_name]["hp"])
	if cur_hp >= max_hp * 0.2:
		return
	char_node.rot_explosion_triggered  = true
	Global.characters[char_name]["hp"] = min(cur_hp + 10.0, max_hp)
	Global.kill_feed_message.emit("🌋 " + char_name + " — Gnilna eksplozja!")

func _passive_poison_trail(char_name: String, delta: float, char_node: Node) -> void:
	char_node.poison_spawn_timer -= delta
	if char_node.poison_spawn_timer > 0.0:
		return
	char_node.poison_spawn_timer = 0.4
	var zone: Node    = char_node.poison_zone_scene.instantiate()
	zone.position     = char_node.global_position
	zone.shooter_name = char_name
	char_node.get_tree().root.add_child(zone)

func _update_base_dmg(char_name: String, bonus: float) -> void:
	if not Global.base_characters.has(char_name):
		return
	var base = float(Global.base_characters[char_name]["dmg"])
	Global.characters[char_name]["dmg"] = base + bonus

func _spawn_poison_zone(pos: Vector2, shooter_name: String) -> void:
	var scene = load("res://scenes/effects/poison_zone.tscn")
	if not scene:
		return
	var zone: Node    = scene.instantiate()
	zone.position     = pos
	zone.shooter_name = shooter_name
	get_tree().root.add_child(zone)

func _spawn_explosion(pos: Vector2, shooter_name: String) -> void:
	var scene = load("res://scenes/effects/explosion.tscn")
	if not scene:
		return
	var expl: Node   = scene.instantiate()
	expl.position    = pos
	expl.shooter_name = shooter_name  # tylko raz — była zduplikowana linia
	get_tree().root.add_child(expl)

func _find_character(char_name: String) -> Node:
	for node in get_tree().get_nodes_in_group("Players"):
		if not is_instance_valid(node):
			continue
		if node.get("character_name") == char_name:
			return node
	return null

# Przyspieszacz gnicia — wrogowie w zasięgu 150px gniją 15% szybciej.
# Zamiast Area2D (wymagałoby zmiany .tscn) sprawdzamy dystans co klatkę.
const ROT_ACCEL_RANGE: float = 150.0
func _passive_rot_accelerator(char_name: String, delta: float, char_node: Node) -> void:
	for node in get_tree().get_nodes_in_group("Players"):
		if not is_instance_valid(node):
			continue
		if node.get("character_name") == char_name:
			continue
		if char_node.global_position.distance_to(node.global_position) <= ROT_ACCEL_RANGE:
			node.rot_time_remaining -= delta * 0.15  # 15% szybsze gnicie
