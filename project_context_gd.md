# [gra] Project Context File: .gd

## res://

### scripts

#### ai

##### Modules

**default_crime_report.gd**
```gdscript
extends AIModule


func _ready() -> void:
	CrimeMaster.crime_committed.connect(react.bind())


## React to a committed crime. If the perpetrator can be seen, the crime will be reported. 
func react(crime:Crime, pos:Vector3) -> void:
	if _npc.can_see_entity(crime.perpetrator):
		# TODO: take in whether they report crimes against other covens. 
		# TODO: Try aggress
		_npc.printe("Witnessed crime.")
		CrimeMaster.add_crime(crime, _npc.parent_entity.name)
		_npc.crime_witnessed.emit()


func get_type() -> String:
	return "DefaultCrimeReportModule"

```

**default_damage_module.gd**
```gdscript
extends AIModule
## Example implementation of a damage processing AI Module.


@export_category("Physical")
@export var sharp_modifier:float = 1.0
@export var piercing_modifier:float = 1.0
@export var blunt_modifier:float = 1.0
@export var poison_modifier:float = 1.0
@export_category("Magic")
@export var magic_modifier:float = 1.0
@export var light_modifier:float = 1.0
@export var frost_modifier:float = 1.0
@export var flame_modifier:float = 1.0
@export var plant_modifier:float = 1.0
@export_category("Attribute")
@export var stamina_modifier:float = 1.0
@export var will_modifier:float = 1.0

var spell_component:SpellTargetComponent
var vitals_component:VitalsComponent

signal damage_received


func _initialize() -> void:
	_npc.parent_entity.get_component("DamageableComponent").damaged.connect(func(info):
		process_damage(info)
	)
	spell_component = _npc.parent_entity.get_component("SpellTargetComponent")
	vitals_component = _npc.parent_entity.get_component("VitalsComponent")


func process_damage(info:DamageInfo) -> void:
	# Damage effects
	var accumulated_damage = 0
	for effect in info.damage_effects:
		var effect_amount = info.damage_effects[effect]
		# if you have many more than these, some sort of dictionary may be in order.
		match effect:
			# Physical
			&"sharp":
				accumulated_damage = effect_amount * sharp_modifier
			&"piercing":
				accumulated_damage = effect_amount * piercing_modifier
			&"blunt":
				accumulated_damage = effect_amount * blunt_modifier
			&"poison":
				accumulated_damage = effect_amount * poison_modifier
			# Magic
			&"light":
				accumulated_damage = effect_amount * light_modifier * magic_modifier
			&"frost":
				accumulated_damage = effect_amount * frost_modifier * magic_modifier
			&"flame":
				accumulated_damage = effect_amount * flame_modifier * magic_modifier
			&"plant":
				accumulated_damage = effect_amount * plant_modifier * magic_modifier
			# Attribute
			&"moxie":
				vitals_component.vitals["moxie"] -= effect_amount * stamina_modifier
			&"will":
				vitals_component.vitals["will"] -= effect_amount * will_modifier
		
		_npc.damaged_with_effect.emit(effect)
	
	# Apply damage
	vitals_component.vitals["health"] -= accumulated_damage
	
	# Add magic effects
	for eff in info.spell_effects:
		spell_component.add_effect(eff)
	
	# Send damaging signal if we are hit by an entity
	# Could also add behavior somewhere to avoid areas that cause damage. Looking at you, Lydia Skyrim.
	if not info.offender == "":
		_npc.hit_by.emit(info.offender)
	
	damage_received.emit()


func get_type() -> String:
	return "DefaultDamageModule"

```

**default_interact_response.gd**
```gdscript
extends AIModule


func _initialize() -> void:
	_npc.interacted.connect(on_interact.bind())
	_npc._interactive_component.interact_verb = "TALK"


func on_interact(refID:StringName) -> void:
	_npc.start_dialogue.emit()
	_npc._busy = true


func get_type() -> String:
	return "DefaultInteractResponseModule"

```

**default_movement.gd**
```gdscript
extends AIModule


## Default movement that doesn't interface with animations at all. Just gliding across the floor like Jamiroquai.


func get_type() -> String:
	return "DefaultMovementModule"


func _initialize() -> void:
	_npc.puppet_request_move.connect(move.bind())


func move(puppet:NPCPuppet) -> void:
	if puppet.navigation_agent.is_navigation_finished():
		return
	
	var target:Vector3 = puppet.navigation_agent.get_next_path_position()
	var pos:Vector3 = puppet.global_position
	
	puppet.velocity = pos.direction_to(pos) * puppet.movement_speed
	puppet.move_and_slide()

```

**default_stealth_detection.gd**
```gdscript
extends AIModule


@export var view_dist:float = 30


func _process(delta: float) -> void:
	_update_fsm(_npc.perception_memory, delta)


func _update_fsm(data:Dictionary, delta:float) -> void:
	for ref_id:StringName in data:
		if has_node(NodePath(ref_id)):
			(get_node(NodePath(ref_id)) as FSM).update(data[ref_id], delta, _npc._puppet.global_position.distance_to(data[ref_id].last_seen_position))
		else:
			var fsm := FSM.new()
			fsm.name = ref_id
			fsm.state_changed.connect(func(s:int) -> void:
				_npc.awareness_state_changed.emit(ref_id, s)
				)
			add_child(fsm)
			fsm.update(data[ref_id], delta, _npc._puppet.global_position.distance_to(data[ref_id].last_seen_position))


class FSM:
	extends Node
	
	
	enum {
		UNAWARE,
		AWARE_VISIBLE,
		AWARE_INVISIBLE,
		WARY
	}
	
	
	const LOSE_TIMER_MAX := 120.0
	
	var state:int = UNAWARE
	var seek_timer:float = INF
	
	signal state_changed(new_state:int)
	
	
	func update(data:Dictionary, delta:float, dist:float) -> void:
		var vis:float = data[&"visibility"]
		var in_view_cone:bool = not is_zero_approx(vis)
		
		match state:
			UNAWARE, WARY:
				if in_view_cone:
					state = AWARE_VISIBLE
			AWARE_VISIBLE:
				if is_zero_approx(vis):
					state = AWARE_INVISIBLE
					seek_timer = LOSE_TIMER_MAX
			AWARE_INVISIBLE:
				if not is_zero_approx(vis):
					state = AWARE_VISIBLE
				else: 
					seek_timer -= delta
					if seek_timer <= 0.0:
						state = WARY
	

```

**default_threat_response.gd**
```gdscript
extends AIModule


# How many levels weaker something needs to be to be considered "weaker".
const THREAT_LEVEL_WEAKER_INTERVAL = 1
# How many levels greater to be considered "stronger".
const THREAT_LEVEL_GREATER_INTERVAL = 1
# How many levels greater to be considered "significantly stronger".
const THREAT_LEVEL_MUCH_GREATER_INTERVAL = 5

const StealthDetectorModule = preload("default_stealth_detection.gd")

@export_category("Combat info")
## Will this actor initiate combat? [br]
## Peaceful: Will not initiate combat. [br]
## Bluffing: Variant of peaceful, they will warn and try to act tough, but never attack. [br
## Aggressive: Will attack anything below the [member attack_threshold] on sight. [br]
## Frenzied: Will attack anything, ignoring opinion.
@export_enum("Peaceful", "Bluffing", "Aggressive", "Frenzied") var aggression:int = 2
## Agressive NPCs will attack any entity with an opinion below this threshold.
@export_range(-100, 100) var attack_threshold:int = -50
## Response to combat. [br]
## Coward: Flees from combat. [br]
## Cautious: Cautious: Will flee unless stronger than target. [br]
## Average: Will fight unless outmatched. [br]
## Brave: Will fight unless very outmatched. [br]
## Foolhardy: Will never flee.
@export_enum("Coward", "Cautious", "Average", "Brave", "Foolhardy") var confidence:int = 2
## Response to witnessing combat. [br]
## Helps Nobody: Does not help anybody. [br]
## Helps people: Helps people above [member assistance_threshold].
@export_enum("Helps nobody", "Helps people") var assistance:int = 1
## If [member assistance] is "Helps people", it will assist entities with an opinion above this threshold.
@export_range(-100, 100) var assistance_threshold:int = 0
## How NPCs behave when hit by friends. [br]
## Neutral: Aggro friends immediately when hit. [br]
## Friend: During combat, won't attack player unless hit a number of times in an amount of time. Outside of combat, it will aggro the friendly immediately. [br]
## Ally: During combat, will ignore all attacks from friend. Outside of combat, behaves in the same way is "Friend" in combat. [br]
@export_enum("Neutral", "Friend", "Ally") var friendly_fire_behavior:int = 1

@export var warn_radius:float = 20
@export var attack_radius:float = 8

## Thread for an NPC to keep watch when alerted
var vigilant_thread:Thread
## Set to true to stop [member vigilant_thread]
var pull_out_of_thread = false


func _ready() -> void:
	_npc.awareness_state_changed.connect(_handle_perception_info.bind())
	_npc.hit_by.connect(func(who): _aggress(SKEntityManager.instance.get_entity(who)))


func _handle_perception_info(what:StringName, state:int) -> void:
	var opinion = _npc.determine_opinion_of(what)
	var last_seen:Vector3 = _npc.perception_memory[what].last_seen_position
	var below_attack_threshold = (opinion <= attack_threshold) or aggression == 3 # will be below attack threshold by default if frenzied

	match state:
		StealthDetectorModule.FSM.AWARE_INVISIBLE:
			if aggression == 0: # if peaceful
				return
			# if threat, seek last known position
			if below_attack_threshold:
				_npc.printe("seek last known position")
				_npc.goap_memory["last_seen_position"] = NavPoint.new(_npc.parent_entity.world, last_seen) # commit to memory
				_npc.add_objective({"enemy_sought" = true}, true, 10) # add goal to seek position
		StealthDetectorModule.FSM.AWARE_VISIBLE:
			if aggression == 0: # if peaceful
				return

			if below_attack_threshold: # if attack threshold or frenzied
				if not _npc.in_combat:
					_npc.printe("start vigilance")
					var e = SKEntityManager.instance.get_entity(what)

					# attack immediately if frenzied
					if aggression == 3:
						_begin_attack(e)
						return

					_enter_vigilant_stance()
					if vigilant_thread:
						pull_out_of_thread = true
						vigilant_thread.wait_to_finish()
					vigilant_thread = Thread.new()
					vigilant_thread.start(_stay_vigilant.bind(e))
				else:
					_npc.printe("needs to attack")
		StealthDetectorModule.FSM.WARY:
			# may be useless
			return
		StealthDetectorModule.FSM.UNAWARE:
			if aggression == 0: # if peaceful
				return

			# if threat, do "huh?" behavior
			if below_attack_threshold:
				_npc.printe("needs to investigate")
				# TODO: Stop, investigate
				return


## Will keep watch until the entity is out of range. TODO: Visibility?
func _stay_vigilant(e:SKEntity) -> void:
	# may need to change the order of this, im not sure where to put it yet
	if _npc.in_combat: # don't react if already in combat
		_add_enemy(e)
		return

	var warned:bool = false

	while true:
		# check if out of world
		if not _npc.parent_entity.world == e.world:
			_enter_normal_state()
			return
		# leave thread early if need be
		if pull_out_of_thread:
			pull_out_of_thread = false
			return
		# range checks
		var distance_to_e = _npc.parent_entity.position.distance_squared_to(e.position)
		# check if out of range
		if distance_to_e > warn_radius ** 2:
			_enter_normal_state()
			return
		# if within ring and not player, attack
		if distance_to_e <= attack_radius ** 2 and not e.get_component("PlayerComponent").some():
			print("frenzied immediate attack")
			_begin_attack(e)
			return
		# if frenzied and within ring attack immediately
		if distance_to_e <= warn_radius ** 2 and aggression == 3:
			print("frenzied immediate attack")
			_begin_attack(e)
			return
		# if within warn ring
		if distance_to_e <= warn_radius ** 2 and distance_to_e > attack_radius ** 2:
			# if not already warned, warn and set warned
			if not warned:
				print("become warned")
				_warn(e)
				warned = true
		# if in attack distance, attack
		if distance_to_e <= attack_radius ** 2:
			print("in attack distance")
			_begin_attack(e)
			return


func _begin_attack(e:SKEntity) -> void:
	# figure out response to confrontation
	print("beginning attack")
	match aggression:
		0: # Peaceful
			print("peaceful response")
			return
		1: # Bluffing
			print("bluffing response")
			_flee(e)
		2, 3:
			# Add to goap memory
			print("aggressive/frenzied response")
			_npc.in_combat = true
			_add_enemy(e)
			# This will begin combat, because NPCs have a recurring goal where all enemies must be dead


func _add_enemy(e:SKEntity) -> void:
	if _npc.goap_memory.has("enemies"):
		if not _npc.goap_memory["enemies"].has(e.name):
			print("Adding enemy %s" % e.name)
			_npc.goap_memory["enemies"].append(e)
	else:
		_npc.goap_memory["enemies"] = [e.name]
		print("Adding enemy %s" % e.name)
		_npc._goap_component.interrupt() # interrupt current task if entering combat


func _warn(e:SKEntity) -> void:
	# Issue warning to entity
	print("warning!")
	_npc.warning.emit(e.name)


func _enter_normal_state() -> void:
	# undo vigilant stance
	print("exit vigilant stance")


func _enter_vigilant_stance() -> void:
	# draw weapons, turn towards threat
	print("enter vigilant stance")


func _flee(e:SKEntity) -> void:
	# tell GOAP to flee from enemies
	print("flee")
	_npc.add_objective({"flee_from_enemies" : true}, true, 10)
	_npc.flee.emit(e.name)


## Response to being hit.
func _aggress(e:SKEntity) -> void:
	# "Coward", "Cautious", "Average", "Brave", "Foolhardy"
	# TODO: Friendly fire
	var threat = _determine_threat(e)
	match confidence:
		0: # Coward - flee
			_flee(e)
			return
		1: # Cautious - only attack if target weaker
			if threat == -1:
				_begin_attack(e)
				return
			else:
				_flee(e)
				return
		2: # Average - attack if evenly matched or stronger
			if threat <= 0:
				_begin_attack(e)
				return
			else:
				_flee(e)
				return
		3: # Brave - Fight unless significantly outmatched
			if threat <= 1:
				_begin_attack(e)
				return
			else:
				_flee(e)
				return
		4: # Foolhardy - always attack, no matter the threat
			_begin_attack(e)
			return


## Determines the threat level of another entity by conparing levels in a [SkillsComponent]. Returns: [br]
## -1: Weaker [br]
## 0: About the same or no skills component [br]
## 1: Stronger [br]
## 2: Significantly stronger [br]
## See [constant THREAT_LEVEL_WEAKER_INTERVAL], [constant THREAT_LEVEL_GREATER_INTERVAL], [constant THREAT_LEVEL_MUCH_GREATER_INTERVAL]
func _determine_threat(e:SKEntity) -> int:
	var e_sc = e.get_component("SkillsComponent")
	# if no skills component associated with the entity, default is 0
	if not e_sc.some():
		return 0

	var npc_level = _npc.parent_entity.get_component("SkillsComponent").level
	var e_level = e_sc.level
	var difference = e_level - npc_level # negative is weaker

	# Check if it's a bit weaker
	if difference < -THREAT_LEVEL_WEAKER_INTERVAL:
		return -1
	# Check for much greater
	if difference > THREAT_LEVEL_MUCH_GREATER_INTERVAL:
		return 2
	# Then check for a bit greater
	if difference > THREAT_LEVEL_GREATER_INTERVAL:
		return 1
	# Else about the same
	return 0


func _clean_up() -> void:
	if vigilant_thread:
		vigilant_thread.wait_to_finish()


func get_type() -> String:
	return "DefaultThreatResponseModule"

```

##### PerceptionFSM

**machine_perception.gd**
```gdscript
class_name PerceptionFSM_Machine
extends FSMMachine
## The NPC perpection tracking is a finite state machine for easily tweakable behavior.
## This is where the stealth mechanics come in- how the NPC processes seeing stuff. The ? -> ! pipeline in MGS games. I dunno. I'm tired. I hope you get it.
## The current state machine looks like this: [br]
## [codeblock]
## ┌───────┐                 ┌──────────────┐
## │Unaware│   ┌─────────────┤Lost track of │
## └───┬───┘   │             └──────────────┘
##     │       │                   ▲
##     │       │                   │
##     ▼       ▼                   │
## ┌────────────┐            ┌─────┴────────┐
## │AwareVisible├──────────► │AwareInvisible│
## └────────────┘ ◄──────────┴──────────────┘
## [/codeblock]


## RefID of tracked entity.
var tracked:String
## The current visibility of the entity. 0 means it is not visible.
var visibility:float
## The last known position of the entity.
var last_seen_position:Vector3
## The last known world of this entity.
var last_seen_world:String


func _init(tracked_obj:String, vis:float) -> void:
	tracked = tracked_obj
	visibility = vis


func _ready() -> void:
	print("Machine created")


## Remove this FSM from the system.
func remove_fsm() -> void:
	(get_parent() as NPCComponent).perception_forget(tracked)

```

**state_aware_invisible.gd**
```gdscript
class_name PerceptionFSM_Aware_Invisible
extends FSMState
## In this state, the line of sight has been broken. THe NPC may look for the target here.


## The time it takes to lose track of something, in seconds
var lose_timer_max:float = 60
var _npc:NPCComponent
var lose_timer:float


func _get_state_name() -> String:
	return "AwareInvisible"


func on_ready() -> void:
	_npc = owner as NPCComponent


func enter(msg:Dictionary = {}) -> void:
	lose_timer = lose_timer_max


func update(delta:float) -> void:
	lose_timer -= delta # decrease timer
	if lose_timer <= 0:
		state_machine.transition("Lost")
	if not (state_machine as PerceptionFSM_Machine).visibility == 0:
		state_machine.transition("AwareVisible")

```

**state_aware_visible.gd**
```gdscript
class_name PerceptionFSM_Aware_Visible
extends FSMState
## In this state, it is actively looking at the target.


var _npc:NPCComponent
var e:SKEntity


func _get_state_name() -> String:
	return "AwareVisible"


func on_ready() -> void:
	_npc = owner as NPCComponent


func update(delta:float) -> void:
	(state_machine as PerceptionFSM_Machine).last_seen_position = e.position
	(state_machine as PerceptionFSM_Machine).last_seen_world = e.world
	if (state_machine as PerceptionFSM_Machine).visibility == 0: # we need the player to be completely invisible to evade detection. We can't just vanish into the shadows
		state_machine.transition("AwareInvisible")


func enter(msg:Dictionary = {}) -> void:
	e = SKEntityManager.instance.get_entity((state_machine as PerceptionFSM_Machine).tracked)

```

**state_lost.gd**
```gdscript
class_name PerceptionFSM_Lost
extends FSMState


const forget_timer_max:float = 600
var _npc:NPCComponent
var forget_timer:float = 0


func _get_state_name() -> String:
	return "Lost"


func on_ready() -> void:
	_npc = owner as NPCComponent


func update(delta:float) -> void:
	# if the thing is visible again, we are aware of it again.
	# if it is in state lost, this NPC will "recognize" it, and immediately remember it.
	if (state_machine as PerceptionFSM_Machine).visibility >= _npc.visibility_threshold:
		state_machine.transition("AwareVisible")
	
	forget_timer -= delta
	if forget_timer < 0:
		(state_machine as PerceptionFSM_Machine).remove_fsm()


func enter(msg:Dictionary) -> void:
	forget_timer = forget_timer_max

```

**state_unaware.gd**
```gdscript
class_name PerceptionFSM_Unaware
extends FSMState
## In this state, the NPC is processing what it's seeing.


var detection_timer_max: float = 1
var _npc:NPCComponent
var detection_speed:float = 1
var detection_timer:float = 0


func _get_state_name() -> String:
	return "Unaware"


func on_ready() -> void:
	_npc = owner as NPCComponent


func update(delta:float) -> void:
	detection_timer += detection_speed * (state_machine as PerceptionFSM_Machine).visibility * delta
	if detection_timer >= detection_timer_max:
		state_machine.transition("AwareVisible")
		return
	if (state_machine as PerceptionFSM_Machine).visibility <= _npc.visibility_threshold:
		(state_machine as PerceptionFSM_Machine).remove_fsm()


func enter(message:Dictionary) -> void:
	# if we are tracking an item, skip right to aware visible
	if SKEntityManager.instance.get_entity((state_machine as PerceptionFSM_Machine).tracked).get_component("ItemComponent"):
		state_machine.transition("AwareVisible")

```

#### ai

**ai_module.gd**
```gdscript
@tool
class_name AIModule
extends Node
## Base class for AI Packages for NPCs.
## Skelerealms uses 2 AI systems, each with different roles.
## The AI Package system determines what goals the NPC should attempt to achieve, and the GOAP AI system figures out how to achieve it.
## Override this to set custom behaviors by attaching to [NPCComponent]'s many signals.


@onready var _npc:NPCComponent = get_parent()


## Link this module to the component.
func link(npc:NPCComponent) -> void:
	self._npc = npc


## The "ready" function if you depend on the NPC's variables.
func initialize() -> void:
	pass


func _clean_up() -> void:
	return


func get_type() -> String:
	return "AIModule"


## Prints a rich text message to the console prepended with the entity name. Used for easier debugging. 
func printe(text:String) -> void:
	_npc.printe(text)

```

**goap_action.gd**
```gdscript
class_name GOAPAction
extends Node


## The cost of this action when making a plan.
var cost:float = 1.0
## Whether this objective is actively being worked on
var running:bool = false
var parent_goap:GOAPComponent
var entity:SKEntity
## The duration of this action.
var duration: float


func is_achievable_given(state:Dictionary) -> bool:
	return state.has_all(get_prerequisites().keys())


func is_achievable() -> bool:
	return true


func pre_perform() -> bool:
	return true


func target_reached() -> bool:
	return true


func post_perform() -> bool:
	return true


func is_target_reached(agent:NavigationAgent3D) -> bool:
	return agent.is_navigation_finished()


func interrupt() -> void:
	return


func get_prerequisites() -> Dictionary:
	return {}


func get_effects() -> Dictionary:
	return {}


func get_id() -> StringName:
	return &""

```

**light_estimation_provider.gd**
```gdscript
class_name LightEstimation
extends Node3D

const interpolation_method:Image.Interpolation = Image.INTERPOLATE_BILINEAR
var svpt: SubViewport
var svpb: SubViewport
#@export var render_target: ViewportTexture


## Calculates a light level at a given point.
## Output appears to be vaguely logarithmic, but has been scaled to have 1 be roughly
## in direct sunlight.
func get_light_level_for_point(point:Vector3) -> float:
	# Move the octahedron to point
	position = point
	# reset location
	await RenderingServer.frame_post_draw
	# camera render both sides
	var img:Image = svpt.get_texture().get_image()
	# resize to 1x1
	img.resize(1,1, interpolation_method)
	# return luminance
	var top = img.get_pixel(0,0).get_luminance()
	
	# Do the other thing for the other side 
	img = svpb.get_texture().get_image()
	img.resize(1,1, interpolation_method)
	var bottom = img.get_pixel(0,0).get_luminance()
	
	return ((top + bottom) / 2) / 0.4 # average top and bottom


func _ready() -> void:
	svpt = $SViewportTop
	svpb = $SViewportBottom

```

**perception_ears.gd**
```gdscript
class_name PerceptionEars
extends CollisionShape3D
## Add to something to make it be able to hear.
## Isn't an [SKEntityComponent], so can be added to anything.
## Be sure to add a shape.


## Called when it hears something.
signal heard_something(emitter:AudioEventEmitter)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("audio_listener")


func hear_audio(emitter:AudioEventEmitter):
	heard_something.emit(emitter)

```

**perception_eyes.gd**
```gdscript
class_name EyesPerception
extends Node3D
## This handles seeing, and it attached to the head of the character.


const perception_interval:float = 0.25

## FOV is the field of view of the eyes, in degrees. The default value is 90 degrees.
@export var fov_h:float = 90
@export var fov_v:float = 90
@export var view_distance:float = 30
@export var light_level_threshold:float = 0.1

var light_probe:LightEstimation
var t:Timer


signal perceived(percieved:PerceptionData)
signal not_perceived(percieved:PerceptionData)


func _ready() -> void:
	t = Timer.new()
	add_child(t)
	t.start(perception_interval)
	t.timeout.connect(try_perception.bind())
	light_probe = $Probe


## Check if this can see a target
func check_sees_collider(pt:PhysicsBody3D) -> PerceptionData:
	if not is_inside_tree():
		return PerceptionData.new("", 0)
	# 1) See if target in range
	if global_position.distance_to(pt.global_position) > view_distance:
		#print("Rejected: Too far (%s)" % global_position.distance_to(pt.global_position))
		return PerceptionData.new(_find_ref_id(pt), 0)
	# 2) See if direction to target within fovs
	var direction_to = (pt.global_position - global_position).normalized()
	var angle_to = (-global_transform.basis.z).dot(direction_to)
	if angle_to < (fov_h / 2 / 180):
		#print("Rejected: bad angle (%s, %s)" % [angle_to, (fov_h / 2 / 180)])
		return PerceptionData.new(_find_ref_id(pt), 0)
	# TODO: vertical fov using pitch, horizontal using yaw
	# 3) Raycast check
	await get_tree().physics_frame
	if not get_world_3d():
		return PerceptionData.new("", 0)
	var state = get_world_3d().direct_space_state
	var q = PhysicsRayQueryParameters3D.create(global_position, pt.global_position)
	var c = state.intersect_ray(q)
	if c: # if collider hit
		if not (c["collider"] == pt or (c["collider"] as Node).is_ancestor_of(pt)): # if collider hit is this or ancestor
			return PerceptionData.new(_find_ref_id(pt), 0)
	# 4) Calculate light level
	var light_level = await light_probe.get_light_level_for_point(pt.position)
	if light_level < light_level_threshold:
		return null
	# 5) Calculate percent of coverage with AABBs <- TODO
	return PerceptionData.new(_find_ref_id(pt), light_level)


## Looks at a point and sees if it can see whatever it is. ID is blank if it doesn't hit an entity puppet.
func get_thing_under_sight(pt:NavPoint) -> PerceptionData:
	if not pt.world == GameInfo.world:
		return null
	# 1) See if target in range
	if position.distance_to(pt.position) > view_distance:
		return null
	# 2) See if direction to target within fovs
	var direction_to = pt.global_position - global_position
	var angle_to = direction_to.dot(transform.basis.z)
	if angle_to < 1 - (fov_h / 2 / 180):
		return null
	# TODO: vertical fov using pitch, horizontal using yaw
	# 3) Raycast check
	await get_tree().physics_frame
	var state = get_world_3d().direct_space_state
	var q = PhysicsRayQueryParameters3D.create(global_position, pt.global_position)
	var c = state.intersect_ray(q)
	if not c: # if collider not hit
		return null
	var id = _find_ref_id(c["collider"])
	var light_level = await light_probe.get_light_level_for_point(pt.position)
	if light_level < light_level_threshold:
		return null
	return PerceptionData.new(id, light_level)


## Looks for a specific entity, and returns with the data. Null if not found.
func look_for_entity(refID:StringName) -> PerceptionData:
	var entity = SKEntityManager.instance.get_entity(refID)
	if entity:
		var pt = NavPoint.new(entity.world, entity.position)
		var res = await get_thing_under_sight(pt)
		if res:
			if res.object == refID:
				return res
	return null


## Try looking at everything in range.
func try_perception() -> void:
	var perception_targets = get_tree()\
		.get_nodes_in_group("perception_target")\
		.filter(func(x:Node):
#			if x.is_ancestor_of(self):
#				return false
#			print("""
#			Node: %s
#			Type: %s
#			Distance check: %s (%s) 
#			""" % [
#				x,
#				(x is CollisionShape3D or x is PhysicsBody3D),
#				(x as Node3D).global_position.distance_to(global_position) <= view_distance,
#				(x as Node3D).global_position.distance_to(global_position)
#			])
			return not x.is_ancestor_of(self) and\
			(x is CollisionShape3D or x is PhysicsBody3D) and \
			(x as Node3D).global_position.distance_to(global_position) <= view_distance
			)
	# Loop through targets and get check info.
	for target in perception_targets:
		var res = await check_sees_collider(target)
		if res.visibility > 0: # If we see it, emit signal
			perceived.emit(res)
			# print("percieved %s" % res)
		else:
			not_perceived.emit(res)


func _find_ref_id(n:Node) -> String:
	var check:Node = n.get_parent()
	while check.get_parent():
		if check is SKEntity:
			return (check as SKEntity).name
		check = check.get_parent()
	return ""


class PerceptionData:
	var object:String
	var visibility:float
	
	
	func _init(obj:String, vis:float) -> void:
		object = obj
		visibility = vis

```

#### barter

**barter.gd**
```gdscript
class_name BarterSystem
extends Node


var current_transaction:Transaction

## Emitted when the barter process begins
signal begun_barter(vendor:InventoryComponent, customer:InventoryComponent, tx:Transaction)
## Emitted when the barter process is ended - cancelled or accepted.
signal ended_barter
## Emitted when the barter is cancelled. Note that `ended_barter` is also called when this happens.
signal cancelled_barter


## Begin the barter process.
func start_barter(vendor:InventoryComponent, customer:InventoryComponent) -> void:
	current_transaction = Transaction.new(vendor, customer)
	begun_barter.emit(vendor, customer, current_transaction)


# TODO: Allow for checking what items can and cannot be sold to this vendor
# TODO: Allow haggling?
## Sell or cancel buying an item. Returns whether it succeeded.
## Will return false if the item cannot be sold, or is cancelling a buy.
func sell_item(item:String) -> bool:
	# Skip if no transaction
	if not current_transaction:
		return false
	# can't sell if already selling item
	if current_transaction.selling.has(item):
		return false
	# Cancel buying
	if current_transaction.buying.has(item):
		current_transaction.buying.erase(item)
		return true
	# Else, add to selling
	current_transaction.selling.append(item)
	return true


## Buy or cancel selling an item. Returns whether it succeeded.
## Will return false if the item cannot be bought, or is cancelling a sell.
func buy_item(item:String) -> bool:
	# Skip if no transaction
	if not current_transaction:
		return false
	# can't sell if already buying item
	if current_transaction.buying.has(item):
		return false
	# Cancel selling
	if current_transaction.selling.has(item):
		current_transaction.selling.erase(item)
		return true
	# Else, add to buying
	current_transaction.buying.append(item)
	return true


## Cancel the current barter session if applicable.
func cancel_barter() -> void:
	if current_transaction:
		current_transaction = null
		ended_barter.emit()
		cancelled_barter.emit()


## Resolve the transaction, and stop the trandaction. The arguments are multipliers for the money being moved around - for vendor to customer, and customer to vendor, respectively.
## Will return false if either part doesn't have enough money to complete the transaction.
func accept_barter(selling_modifier:float, buying_modifier:float, currency: StringName) -> bool:
	if not current_transaction:
		return false

	var total: int = current_transaction.total_transaction(selling_modifier, buying_modifier)
	# Adding and subtracting is done here because the total is how much money is leaving the customer
	# If vendor cash is less than 0 when the balance is applied, return failure
	if current_transaction.vendor.currencies[currency] - total < 0: # subtracting because if selling the total will be positive flow to customer
		return false
	# If customer cash is less than 0 when the balance is applied, return failure
	if current_transaction.customer.currencies[currency] + total < 0: # plus because if buying the total will be negative flow to customer
		return false

	# Add total
	current_transaction.vendor.remove_money(total, currency)
	current_transaction.customer.add_money(total, currency)

	# Move items
	#? Could optimize
	for item in current_transaction.selling:
		# Move from customer to vendor.
		SKEntityManager.instance\
			.get_entity(item)\
			.get_component("ItemComponent")\
			.move_to_inventory(current_transaction.vendor.parent_entity.name)
	for item in current_transaction.buying:
		# Move from vendor to customer.
		SKEntityManager.instance\
			.get_entity(item)\
			.get_component("ItemComponent")\
			.move_to_inventory(current_transaction.customer.parent_entity.name)

	#clean up
	current_transaction = null
	ended_barter.emit()
	return true


## Determine whether a shop will accept an item or not.
## NOTE: Broken right now.
func shop_will_accept_item(shop:Resource, item:StringName) -> bool:
	var ic:ItemComponent = SKEntityManager.instance.get_entity(item).get_component("ItemComponent")
	
	if not shop.whitelist.is_empty():
		if not ic.data.tags.any(func(tag): return shop.whitelist.has(tag)): # if no tags in whitelist
			return false
	
	if not shop.blacklist.is_empty():
		if ic.data.tags.any(func(tag): return shop.blacklist.has(tag)): # if any tag in blacklist
			return false
	
	if not shop.accept_stolen and ic.stolen: # if item stolen and vendor accepts no stolen
		return false
	
	return true

```

**transaction.gd**
```gdscript
class_name Transaction
extends RefCounted
## An object keeping track of stuff being bought and sold while bartering.


## Who is selling
var vendor:InventoryComponent
## Who is buying (Player)
var customer:InventoryComponent
## What the customer is selling
var selling:Array[String] = []
## What the customer is buying
var buying:Array[String] = []
## Balance of transaction
var balance:int


func _init(v:InventoryComponent, c:InventoryComponent) -> void:
	vendor = v
	customer = c


## Get the total amount for the transaction, in terms of change in the customer's money.
func total_transaction(selling_modifier:float, buying_modifier:float) -> int:
	var total:int = 0
	# Total selling amount and add
	total += selling.reduce(
		func(accum: int, item:String):
			return accum + roundi(( SKEntityManager.instance.get_entity(item)\
				.get_component("ItemComponent")\
				as ItemComponent)\
				.data\
				.worth * selling_modifier)
	,0
	)
	# Total selling amount and subtract
	total -= buying.reduce(
		func(accum: int, item:String):
			return accum + roundi(( SKEntityManager.instance.get_entity(item)\
				.get_component("ItemComponent")\
				as ItemComponent)\
				.data\
				.worth * buying_modifier)
	,0
	)
	return total

```

#### bullets

**bullet.gd**
```gdscript
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

```

**pociski.gd**
```gdscript
extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))extends Node

# --- Konfiguracja ---
# Upewnij się, że masz do importowania odpowiednie sceny (np. Bullet.tscn, Bot.tscn)
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOT_SCENE = preload("res://Bot.tscn")

# Lista graczy i statusów
var players_present: Array = []
var bots_to_spawn: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("System zarządzania grą uruchomiony.")
	# Przykład: Inicjalizacja gry (np. dodanie pierwszego gracza)
	setup_initial_players()


# Called every frame.
func _process(delta: float) -> void:
	# Tutaj możesz umieścić logikę sprawdzania stanu graczy i AI
	check_for_missing_players()
	
	# Możesz dodać tu logikę strzelania lub ruchu postaci
	pass


# --- Funkcje do zarządzania pociskami ---

## Tworzy nowy pocisk w określonej pozycji.
func spawn_bullet(position: Vector2, direction: Vector2) -> void:
	var bullet_instance = BULLET_SCENE.instantiate()
	
	# Ustawienie pozycji i kierunku pocisku
	bullet_instance.global_position = position
	# W tym miejscu musisz dodać logikę ruchu pocisku (np. używając velocity lub Tweenów)
	
	# Dodanie pocisku do drzewa scen
	get_parent().add_child(bullet_instance)
	print("Pocisk wygenerowany w pozycji: ", position)


# --- Funkcje do zarządzania botami ---

## Sprawdza, czy brakuje graczy i generuje boty.
func check_for_missing_players() -> void:
	# W tym miejscu musisz porównać obecnych graczy z oczekiwanymi
	
	# PRZYKŁAD: Zakładamy, że oczekujemy 4 graczy, a mamy tylko 2.
	var required_players = 4
	var current_players = players_present.size()
	
	if current_players < required_players:
		var missing_count = required_players - current_players
		print("Brakuje ", missing_count, " graczy. Generowanie botów...")
		
		for i in range(missing_count):
			# Tworzenie nowego bota
			var new_bot = BOT_SCENE.instantiate()
			
			# Ustawienie pozycji bota (np. w określonym miejscu na mapie)
			var spawn_pos = Vector2(500, 500) # Zmień to na właściwą pozycję
			new_bot.global_position = spawn_pos
			
			# Dodanie bota do sceny
			get_parent().add_child(new_bot)
			
			# Ustawienie jego celu (np. by postępował zgodnie z innymi graczami)
			new_bot.set_target(players_present[0]) # Przykład ustawienia celu
			
			bots_to_spawn.append(new_bot)
			print("Bot został dodany. ID: ", new_bot.get_instance_id())


# --- Funkcje pomocnicze (do testowania) ---

## Funkcja symulująca dodawanie graczy
func setup_initial_players() -> void:
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))
	# Symulacja, że załadowaliśmy istniejących graczy
	players_present.append(load("res://Player1.tscn"))
	players_present.append(load("res://Player2.tscn"))
	print("Wykryto ", players_present.size(), " graczy.")


## Funkcja symulująca strzelanie (dla testu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): # Jeśli naciśniesz Enter/Spację
		# Symulacja strzału w kierunku w górę
		spawn_bullet(global_position, Vector2(0, -1))

```

#### characters

**character.gd**
```gdscript
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

```

**fruit_drawer.gd**
```gdscript
extends Node2D
## Rysuje owocowe kształty dla postaci.
## Dodaj jako dziecko CharacterBody2D zamiast ColorRect.

@export var fruit_type: String = "Strawberry"

func _draw():
	match fruit_type:
		"Strawberry":
			_draw_strawberry()
		"Grape":
			_draw_grape()
		"Orange":
			_draw_orange()
		"Pineapple":
			_draw_pineapple()

func _draw_strawberry():
	# Czerwone ciało - trójkąt zaokrąglony (od góry szeroki, dół wąski)
	var body_color = Color(0.9, 0.1, 0.15)
	var leaf_color = Color(0.2, 0.7, 0.15)

	# Ciało truskawki
	var points = PackedVector2Array([
		Vector2(-7, -2),
		Vector2(-8, -5),
		Vector2(-6, -8),
		Vector2(6, -8),
		Vector2(8, -5),
		Vector2(7, -2),
		Vector2(4, 6),
		Vector2(0, 8),
		Vector2(-4, 6),
	])
	draw_colored_polygon(points, body_color)

	# Pestki (żółte kropki)
	var seed_color = Color(1.0, 0.9, 0.3)
	draw_circle(Vector2(-3, -3), 0.8, seed_color)
	draw_circle(Vector2(3, -3), 0.8, seed_color)
	draw_circle(Vector2(-2, 1), 0.8, seed_color)
	draw_circle(Vector2(2, 1), 0.8, seed_color)
	draw_circle(Vector2(0, 4), 0.8, seed_color)

	# Listki na górze
	draw_colored_polygon(PackedVector2Array([
		Vector2(-1, -8), Vector2(-5, -12), Vector2(-2, -10), Vector2(0, -9)
	]), leaf_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(1, -8), Vector2(5, -12), Vector2(2, -10), Vector2(0, -9)
	]), leaf_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-1, -9), Vector2(0, -13), Vector2(1, -9)
	]), leaf_color)

	# Oczy
	_draw_eyes(Vector2(-3, -5), Vector2(3, -5))

func _draw_grape():
	var body_color = Color(0.55, 0.1, 0.7)
	var highlight = Color(0.7, 0.3, 0.85)
	var stem_color = Color(0.35, 0.55, 0.15)

	# Kiść winogron — okrągłe gronka
	var grape_positions = [
		Vector2(-4, -4), Vector2(4, -4),
		Vector2(-6, 0), Vector2(0, 0), Vector2(6, 0),
		Vector2(-4, 4), Vector2(4, 4),
		Vector2(0, 7),
	]
	for pos in grape_positions:
		draw_circle(pos, 4.0, body_color)
		draw_circle(pos + Vector2(-1, -1), 1.5, highlight)

	# Łodyżka
	draw_line(Vector2(0, -6), Vector2(0, -10), stem_color, 1.5)
	# Listek
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -9), Vector2(4, -12), Vector2(6, -10), Vector2(3, -8)
	]), Color(0.3, 0.65, 0.2))

	# Oczy (na środkowym gronku)
	_draw_eyes(Vector2(-2, -1), Vector2(2, -1))

func _draw_orange():
	var body_color = Color(1.0, 0.6, 0.1)
	var highlight = Color(1.0, 0.75, 0.35)
	var leaf_color = Color(0.25, 0.6, 0.15)

	# Ciało pomarańczy — koło
	draw_circle(Vector2(0, 0), 9.0, body_color)
	# Odblask
	draw_circle(Vector2(-3, -3), 3.5, highlight)

	# Łodyżka
	draw_line(Vector2(0, -8), Vector2(0, -12), Color(0.4, 0.3, 0.15), 2.0)
	# Listek
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -11), Vector2(5, -13), Vector2(4, -10), Vector2(1, -10)
	]), leaf_color)

	# Tekstura (segmenty)
	var line_color = Color(0.9, 0.5, 0.05, 0.3)
	draw_line(Vector2(0, -8), Vector2(0, 8), line_color, 0.5)
	draw_line(Vector2(-8, 0), Vector2(8, 0), line_color, 0.5)

	# Oczy
	_draw_eyes(Vector2(-3, -1), Vector2(3, -1))

func _draw_pineapple():
	var body_color = Color(0.85, 0.7, 0.15)
	var pattern_color = Color(0.7, 0.5, 0.1)
	var leaf_color = Color(0.2, 0.65, 0.15)

	# Ciało ananasa — owal
	var points: PackedVector2Array = []
	for i in range(20):
		var angle = i * TAU / 20
		points.append(Vector2(cos(angle) * 7, sin(angle) * 10 + 1))
	draw_colored_polygon(points, body_color)

	# Wzór kratki na ananasie
	for y in range(-7, 10, 4):
		draw_line(Vector2(-6, y), Vector2(6, y), pattern_color, 0.5)
	for x in range(-5, 7, 4):
		draw_line(Vector2(x, -7), Vector2(x, 10), pattern_color, 0.5)

	# Liście na górze (korona)
	var leaves = [
		[Vector2(-2, -9), Vector2(-6, -17), Vector2(-1, -12)],
		[Vector2(0, -10), Vector2(0, -18), Vector2(2, -12)],
		[Vector2(2, -9), Vector2(6, -17), Vector2(1, -12)],
		[Vector2(-4, -8), Vector2(-8, -14), Vector2(-2, -10)],
		[Vector2(4, -8), Vector2(8, -14), Vector2(2, -10)],
	]
	for leaf in leaves:
		draw_colored_polygon(PackedVector2Array(leaf), leaf_color)

	# Oczy
	_draw_eyes(Vector2(-3, -2), Vector2(3, -2))

func _draw_eyes(left_pos: Vector2, right_pos: Vector2):
	# Białka
	draw_circle(left_pos, 2.0, Color.WHITE)
	draw_circle(right_pos, 2.0, Color.WHITE)
	# Źrenice
	draw_circle(left_pos + Vector2(0.5, 0.5), 1.0, Color.BLACK)
	draw_circle(right_pos + Vector2(0.5, 0.5), 1.0, Color.BLACK)

```

#### components

**attributes_component.gd**
```gdscript
class_name AttributesComponent
extends SKEntityComponent
## Holds the attributes of an SKEntity, such as the D&D abilities - Charisma, Dexterity, etc.


## The attributes of this SKEntity.
## It is in a dictionary so you can add, remove, and customize at will.
@export var attributes:Dictionary:
	get:
		return attributes
	set(val):
		attributes = val
		dirty = true
# I yearn for Ruby's symbols, but StingName is an adequate substitute.
# I yearn for ruby just in general.

func _init() -> void:
	name = "AttributesComponent"


func save() -> Dictionary:
	dirty = false
	return attributes


func load_data(data:Dictionary):
	attributes = data
	dirty = false


func gather_debug_info() -> String:
	return """
[b]AttributesComponent[/b]
	Attributes: 
%s
""" % [
	JSON.stringify(attributes, '\t').indent("\t\t")
]

```

**chest_component.gd**
```gdscript
@tool
class_name ChestComponent
extends SKEntityComponent


## Optionally refreshing inventories.


@onready var loot_table:SKLootTable = get_child(0)
@export_range(0, 100, 1, "or_greater") var reset_time_minutes:int ## How long it takes to refresh this chest, in in-game minutes. 0 will not refresh.
@export var owner_id:StringName
var looted_time:Timestamp


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if reset_time_minutes > 0:
		GameInfo.minute_incremented.connect(_check_should_restore.bind())
	# If none provided, just generate a dummy loot table that will do nothing.
	if loot_table == null:
		var nlt := SKLootTable.new()
		add_child(nlt)
		loot_table = nlt


func _check_should_restore() -> void:
	if not looted_time:
		return
	if parent_entity.in_scene or Timestamp.dict_to_minutes(Timestamp.build_from_world_timestamp().time_since(looted_time)) < reset_time_minutes: # will not refresh while in scene
		return
	clear()
	reroll()


func clear() -> void:
	var ic:InventoryComponent = parent_entity.get_component("InventoryComponent")
	for i:StringName in ic.inventory:
		SKEntityManager.instance.remove_entity(i)
	ic.inventory.clear() # Doing this instead of the remove item function since looping and removing stuff is bad and I don't need the signal
	ic.currencies.clear()


func reroll() -> void:
	var ic:InventoryComponent = parent_entity.get_component("InventoryComponent")
	var res: Dictionary = loot_table.resolve()
	
	for id:PackedScene in res.items:
		var e:SKEntity = SKEntityManager.instance.add_entity(id)
		ic.add_to_inventory(e.name)
	for id:StringName in res.entities:
		ic.add_to_inventory(id)
	ic.currencies = res.currencies


func on_generate() -> void:
	reroll()


func get_dependencies() -> Array[String]:
	return [
		"InventoryComponent",
	]

```

**covens_component.gd**
```gdscript
class_name CovensComponent
extends SKEntityComponent
## Allows an SKEntity to be part of a [Coven].
## Covens in this context are analagous to Bethesda games' Factions- groups of NPCs that behave in a similar way.
## Coven membership is also reflected in groups that the entity is in.


## IDs of covens this entity is a member of.
## This dictionary is of type StringName:Int, where key is the coven, and int is the rank of this member.
@export var covens:Dictionary


func _init(coven_list:Array[CovenRankData] = []) -> void:
	name = "CovensComponent"
	if coven_list.is_empty():
		return
	# Load rank info
	for crd in coven_list:
		#printe("Adding to coven %s" % crd.coven.coven_id)
		covens[crd.coven.coven_id] = crd.rank


func _ready():
	super._ready()
	# Add corresponding covens.
	for c in covens:
		parent_entity.add_to_group(c)


## Add this entity to a coven.
func add_to_coven(coven:StringName, rank:int = 1):
	covens[coven] = 1
	parent_entity.add_to_group(coven)


## Remove this entity from the coven.
func remove_from_coven(coven:StringName):
	covens.erase(coven)
	parent_entity.remove_from_group(coven)


## Whether the entity is in a coven or not.
func is_in_coven(coven:StringName) -> bool:
	return covens.has(coven)


## Get this entity's rank in a coven. Returns 0 if they aren't in the coven.
func get_coven_rank(coven:StringName) -> int:
	return covens[coven] if covens.has(coven) else 0

```

**damageable_component.gd**
```gdscript
class_name DamageableComponent
extends SKEntityComponent
## Allows an entity to be damaged.


signal damaged(info:DamageInfo)


func damage(info:DamageInfo):
	damaged.emit(info)


func _init() -> void:
	name = "DamageableComponent"

```

**effects_component.gd**
```gdscript
class_name EffectsComponent
extends SKEntityComponent


## This component governs active effects on this entity. 


var host:StatusEffectHost


func _init() -> void:
	name = "EffectsComponent"


func _ready() -> void:
	host = StatusEffectHost.new()
	add_child(host)
	host.message_broadcast.connect(parent_entity.broadcast_message.bind())


## Pass-through for [method StatusEffectHost.add_effect].
func add_effect(what:StringName) -> void:
	host.add_effect(what)


func remove_effect(e:StringName) -> void:
	host.remove_effect(e)

```

**equipment_component.gd**
```gdscript
class_name EquipmentComponent
extends SKEntityComponent


var equipment_slot:Dictionary

signal equipped(item:StringName, slot:StringName)
signal unequipped(item:StringName, slot:StringName)


func _init() -> void:
	name = "EquipmentComponent"


func _ready() -> void:
	super._ready()


func equip(item:StringName, slot:StringName, silent:bool = false) -> bool:
	# Get component
	var e = SKEntityManager.instance.get_entity(item)
	if not e:
		return false
	# Get item component
	var ic = e.get_component("ItemComponent")
	if not ic:
		return false
	# Get equippable data component
	var ec = (ic as ItemComponent).get_component("EquippableDataComponent")
	if not ec:
		return false
	# Check slot validity
	if not (ec as EquippableDataComponent).valid_slots.has(slot):
		return false
	# Unequip if already in slot so we ca nput it in a new slot
	unequip_item(item)

	equipment_slot[slot] = item
	if not silent:
		equipped.emit(item, slot)
	return true


## Unequip anything in a slot.
func clear_slot(slot:StringName, silent:bool = false) -> void:
	if equipment_slot.has(slot):
		var to_unequip = equipment_slot[slot]
		equipment_slot[slot] = null
		if not silent:
			unequipped.emit(to_unequip, slot)


## Unequip a specific item, no matter what slot it's in.
func unequip_item(item:StringName, silent:bool = false) -> void:
	for s in equipment_slot:
		if equipment_slot[s] == item:
			equipment_slot[s] = null
			if not silent:
				unequipped.emit(item, s)
			return


func is_item_equipped(item:StringName, slot:StringName) -> bool:
	if not equipment_slot.has(slot):
		return false
	return equipment_slot[slot] == item


func is_slot_occupied(slot:StringName) -> Option:
	if equipment_slot.has(slot):
		return Option.wrap(equipment_slot[slot])
	else:
		return Option.none()

```

**goap_component.gd**
```gdscript
class_name GOAPComponent
extends SKEntityComponent
## Planner for [GOAPAction]s that creates action sequences to complete a set of [Objective]s.


var agent_state:Dictionary = {}
var objectives:Array[Objective] = []
var action_queue:Array[GOAPAction] = []

var _current_action:GOAPAction
var _current_objective:Objective
var _agent:NavigationAgent3D
var _invoked:bool
var _timer:Timer
var _rebuild_plan:bool


func _init() -> void:
	name = "GOAPComponent"
	# add timer
	_timer = Timer.new()
	_timer.name = "Timer"
	_timer.one_shot = true
	add_child(_timer)


func _ready() -> void:
	for a:Node in get_children():
		if a is GOAPAction:
			a.entity = parent_entity
			a.parent_goap = self


func _process(delta:float) -> void:
	if GameInfo.is_loading:
		return
	# if we are set to rebuild our plan
	if _rebuild_plan:
		# Find the highest priority objective
		objectives.sort_custom(func(a:Objective, b:Objective): return a.priority > b.priority)
		for o in objectives:
			action_queue = _plan(get_children()\
				.filter(func(x): return x is GOAPAction)\
				.map(func(x): return x as GOAPAction), o.goals, {}\
			)
			# if we made a plan, stop sorting through objectives
			if not action_queue.is_empty():
				_pop_action()
				_current_objective = o # logically, this should be uncommented. But commenting it before made things work but now it's broken? what a load of crap
				_rebuild_plan = false
				break
	
	# if we are done with the plan
	if _current_objective and not _rebuild_plan and action_queue.is_empty() and not _current_action:
		# if we need to remove the objective, remove it
		if _current_objective.remove_after_satisfied:
			objectives.erase(_current_objective)
		# trigger plan rebuild next frame
		_rebuild_plan = true
	
	# if we are not done with the current action
	if not _current_action == null: 
		if _current_action.running:
			if _current_action.is_target_reached(_agent): # if agent navigation is finished
				if not _invoked: # if we aren't actively waiting for an action to be completed
					if _current_action.target_reached(): # call the target reached callback
						_invoke_in_time(_complete_current_action.bind(), _current_action.duration)
					else:
						_rebuild_plan = true
		else:
			if not action_queue.is_empty():
				_pop_action()
			else:
				_rebuild_plan = true


func _pop_action() -> void:
	_current_action = action_queue.pop_back()
	_current_action.running = true
	# if pre perform fails, rebuild plan
	if not _current_action.pre_perform():
		_rebuild_plan = true


## Creates a plan to satisfy a set of goals from all child [GOAPAction]s.
func _plan(actions:Array, goal:Dictionary, world_states:Dictionary) -> Array[GOAPAction]:
	var action_pool:Array = actions.filter(func(a:GOAPAction): return a.is_achievable()) # get all of the actions currently achievable.
	
	var leaves:Array[PlannerNode] = [] # create an array keeping track of all of the possible nodes that could make up our path.
	var start = PlannerNode.new(null, world_states, null, 0) # build the starting node.
	var success = _build_graph(start, leaves, goal, action_pool) # try to find a path.
	
	if not success: # if we have not found a path, we have failed.
		return []
		
	leaves.sort_custom(func(a:PlannerNode,b:PlannerNode): return a.cost < b.cost ) #Sort to find valid node with least cost.
	var cheapest:PlannerNode = leaves[0]
	
	var new_plan:Array[GOAPAction] = [] # create the plan for the AI to use. This will be treated like a queue.
	# walk back up the parent chain that the selected node has kept (sorta like a linked list) and build a queue from that.
	var n = cheapest 
	while not n.parent == null: # if it is null, we have reached the root node, since it will have no parents.
		new_plan.push_back(n.action)
		n = n.parent
	
	#new_plan.reverse()
	return new_plan


## Recursive method to try to find all possible action chains that could satisfy the goal.
func _build_graph(parent:PlannerNode, leaves:Array[PlannerNode], goal:Dictionary, action_pool:Array) -> bool:
	var found_path:bool = false
	# FIXME: We need to be doing breadth first search
	
	# get all actions that are 
	# 1) achievable
	# 2) achievable given prerequisites
	# 3) has not already had effects satisfied <- may cause issues
	var achievable_actions = action_pool.filter(func(x:GOAPAction): return x.is_achievable() and x.is_achievable_given(parent.states) and not parent.states.has_all(x.get_effects().keys()))
	achievable_actions.sort_custom(func(a,b): return a.cost < b.cost ) #Sort to resolve actions with least cost first.
	
	# due to the recursive nature of this function, we will be building branching paths from all of the actions until a valid path is found.
	for action:GOAPAction in achievable_actions:
		# if we can achieve this action,
		# duplicate our working set of states.
		var current_state:Dictionary = parent.states.duplicate(true)
		
		# Continue to accumulate effects in state, for passing on to the next node.
		current_state.merge(action.get_effects(), true) # overwrite to keep the state up to date.
			
		# create a new child planner node, which will have an accumulation of all the previous costs.
		# this will help us find the shortest path later.
		var next_node:PlannerNode = PlannerNode.new(parent, current_state, action, parent.cost + action.cost)
		
		if _goal_achieved(goal, current_state):
			# if we have reached the state we are looking for, append the node to the leaves, and set found_path.
			leaves.append(next_node)
			found_path = true
		else:
			# if we have not reached the goal,
			# create a subset of the action pool that removes the current action.
			# this will prevent circular action chains.
			var subset:Array = action_pool.duplicate() # no deep copy, we don't want to clone the nodes.
			subset.erase(action)
			
			# then, recurse and find the next possible node.
			if _build_graph(next_node, leaves, goal, subset):
				found_path = true
	
	return found_path


## Determine whether we have satisfied all goals in our state.
func _goal_achieved(goal:Dictionary, current_state:Dictionary) -> bool:
	return current_state.has_all(goal.keys())


## Invoke a callable in a set amount of time.
func _invoke_in_time(f:Callable, time:float) -> void:
	# Invoke immediately if no duration
	if time == 0:
		f.call()
		return
	
	_invoked = true
	_timer.start(time)
	_timer.timeout.connect(func():
		# disconnect all events
		_clear_timer()
		# call function
		f.call()
	)


func _clear_timer() -> void:
	for c in _timer.timeout.get_connections():
		_timer.timeout.disconnect(c.callable)


## Wrap up the running action.
func _complete_current_action() -> void:
	_current_action.running = false
	# if post perform fails, rebuild plan
	if not _current_action.post_perform():
		_rebuild_plan = true
	_invoked = false


## Add an objective for this asgent to attempt to satisfy.
func add_objective(goals:Dictionary, remove_after_satisfied:bool, priority:float) -> Objective:
	var o = Objective.new(goals, remove_after_satisfied, priority)
	objectives.append(o)
	_rebuild_plan = true
	return o


func remove_objective_by_goals(goals:Dictionary) -> void:
	var to_remove = objectives.filter(func(x:Objective): return x.goals == goals)
	for o in to_remove:
		objectives.erase(o)


func regenerate_plan() -> void:
	_rebuild_plan = true


func interrupt() -> void:
	if _current_action:
		_current_action.interrupt()
		_timer.stop() # cancel callback
	regenerate_plan()


func gather_debug_info() -> String:
	return """
[b]GOAPComponent[/b]
	Objectives: %s
	Current objective: %s
	Current action: %s (Running: %s)
	Action queue: %s
	Current action duration: %s
	Remaining action time: %s / %s (Timer running: %s)
	Target reached: %s (Final point: %s, Target Distance: %s)
""" % [
	objectives\
		.map(func(o:Objective): return o.serialize())\
		.reduce(func(sum, next): return sum + next, ""),
	_current_objective.serialize() if _current_objective else "None",
	_current_action.name if _current_action else "None",
	_current_action.running if _current_action else "false",
	" -> ".join(
		(
			func():
				var x = action_queue.map(func(action:GOAPAction): return action.name)
				x.reverse()
				return x
				).call()
		),
	-1 if _current_action == null else _current_action.duration,
	_timer.time_left,
	_timer.wait_time,
	not _timer.is_stopped(),
	"No agent" if _agent == null else _agent.is_target_reached(),
	"No agent" if _agent == null else _agent.get_final_position(),
	"No agent" if _agent == null else _agent.target_desired_distance
]


## An objective for the AI to try to solve for.
class Objective:
	## Goals to satisfy this objective.
	var goals:Dictionary
	## Whether to remove this goal after it is satisfied.
	var remove_after_satisfied:bool
	## Priority
	var priority:float
	
	func _init(g:Dictionary, rem:bool, p:float) -> void:
		goals = g
		remove_after_satisfied = rem
		priority = p
	
	func serialize() -> String:
		return """
		Remove after satisfied: %s
		Priority: %s
		Goals: %s
		""" % [
			remove_after_satisfied,
			priority,
			JSON.stringify(goals, '\t')
		]


## Internal node for planning a GOAP chain.
class PlannerNode:
	var parent:PlannerNode
	var action:GOAPAction
	var cost:float
	var states:Dictionary
	
	
	func _init(p:PlannerNode, s:Dictionary, a:GOAPAction, c:float) -> void:
		parent = p
		action = a
		cost = c
		states = s

```

**interactive_component.gd**
```gdscript
class_name InteractiveComponent
extends SKEntityComponent
## Handles interactions on an entity

## Emitted when this entity is interacted with.
signal interacted(id:String)

## Whether it can be interacted with.
@export var interactible:bool = true
## What tooltip to display when the cursor hovers over this. The RefID is used as the object name.
@export var interact_verb:String = "INTERACT"
## A callback (that returns String) that allows you to get a custom string for interact text rather than
## using the RefID.
## For example: If you dynamically created an NPC (eg. spawning is a Spider enemy), you could instead grab
## a translated version of your handmade NPCData's ID rather than trying to translate a randomly generated
## RefID.
var translation_callback:Callable
## Gets the translated RefID, or, if applicable, whatever is returned by [member translation_callback]
var interact_name:String:
	get:
		if not translation_callback.is_null():
			return translation_callback.call()
		else:
			return tr(parent_entity.name)


func _init() -> void:
	name = "InteractiveComponent"

## Interact with this as the player.
## Shorthand for [codeblock] interact("Player") [/codeblock].
func interact_by_player():
	interacted.emit("Player")

## Interact with this entity. Pass in the refID of the interactor.
func interact(refID:String):
	interacted.emit(refID)

```

**inventory_component.gd**
```gdscript
class_name InventoryComponent
extends SKEntityComponent


## Keeps track of an inventory and currencies.
## If you add an [SKLootTable] node underneath, the loot table will be rolled upon generating. See [method SKEntityComponent.on_generate].


## The RefIDs of the items in the inventory. Put any unique items in here.
@export var inventory: PackedStringArray
## The amount of cash moneys.
var currencies = {}

signal added_to_inventory(id:String)
signal removed_from_inventory(id:String)
signal inventory_changed
signal added_money(amount:int)
signal removed_money(amount:int)


func _ready() -> void:
	added_to_inventory.connect(func(x): inventory_changed.emit())
	removed_from_inventory.connect(func(x): inventory_changed.emit())


## Add an item to the inventory.
func add_to_inventory(id:String):
	var e = SKEntityManager.instance.get_entity(id)
	if e:
		var ic = e.get_component("ItemComponent")
		if ic:
			inventory.append(id)
			added_to_inventory.emit(id)


## Remove an item from the inventory.
func remove_from_inventory(id:String):
	var index = inventory.find(id)
	if index == -1: # catch if it doesnt have the item
		return
	inventory.remove_at(index)
	removed_from_inventory.emit(id)


## Add an amount of snails to the inventory.
func add_money(amount:int, currency:StringName):
	added_money.emit(amount)
	if currencies.has(currency):
		currencies[currency] += amount
	else:
		currencies[currency] = amount
	_clamp_money(currency)


## Remove some snails from the inventory.
func remove_money(amount:int, currency:StringName):
	removed_money.emit(amount)
	if not currencies.has(currency):
		currencies[currency] = 0
		return
	currencies[currency] -= amount
	_clamp_money(currency)


## Keeps the number of snails from going below 0.
func _clamp_money(currency:StringName):
	if currencies[currency] < 0:
		currencies[currency] = 0


func count_item_by_data(data_id:String) -> int:
	var amount: int = 0
	for i in inventory:
		var ic:ItemComponent = SKEntityManager.instance.get_entity(i).get_component("ItemComponent")
		if ic.data.id == data_id:
			amount += 1
	return amount


func has_item(ref_id:String) -> bool:
	return inventory.has(ref_id)


func get_items_that(fn: Callable) -> Array[StringName]:
	var pt: Array[StringName] = []
	for i in inventory:
		if fn.call(i):
			pt.append(i)
	return pt


func get_items_of_form(id:String) -> Array[StringName]:
	return get_items_that(func(x:StringName): return ItemComponent.get_item_component(x).parent_entity.form_id == id)


func on_generate() -> void:
	if get_child_count() == 0:
		return
	var lt:SKLootTable = get_child(0) as SKLootTable
	if not lt:
		return
	
	var res: Dictionary = lt.resolve()
	
	for id:PackedScene in res.items:
		var e:SKEntity = SKEntityManager.instance.add_entity(id)
		add_to_inventory(e.name)
	for id:StringName in res.entities:
		add_to_inventory(id)
	currencies = res.currencies


func gather_debug_info() -> String:
	return """
[b]InventoryComponent[/b]
	Currency: %s
	Inventory: %s
	""" % [
		JSON.stringify(currencies, "\t"),
		JSON.stringify(inventory, "\t"),
	]

```

**item_component.gd**
```gdscript
@tool
class_name ItemComponent
extends SKEntityComponent
## Keeps track of item data


const DROP_DISTANCE:float = 2
const NONE:StringName = &""


## What inventory this item is in.
@export var contained_inventory: StringName = NONE:
	get:
		return contained_inventory
	set(val):
		contained_inventory = val
		if parent_entity:
			parent_entity.supress_spawning = not contained_inventory == NONE # prevent spawning if item is in inventory
## Whether this item is in inventory or not.
@export var in_inventory:bool:
	get:
		return not contained_inventory == NONE
## If this is a quest item.
@export var quest_item:bool
## If this item is "owned" by someone.
@export var item_owner:StringName = NONE:
	get:
		return item_owner
	set(val):
		item_owner = val
		if get_parent() == null: #stops this from being called while setting up
			return
		if val == &"":
			inv.interact_verb = "TAKE"
		else:
			# TODO: Determine using worth and owner relationships
			inv.interact_verb = "STEAL"
var stolen:bool ## If this has been stolen or not.
var durability:float ## This item's durability, if your game has condition/durability mechanics like Fallout or Morrowind.
var psc:PuppetSpawnerComponent
var inv:InteractiveComponent


## Shorthand to get an item component for an entity by ID.
static func get_item_component(id:StringName) -> ItemComponent:
	var eop = SKEntityManager.instance.get_entity(id)
	if not eop:
		return null
	var icop = eop.get_component("ItemComponent")
	if icop:
		return icop
	else:
		return null


func _init() -> void:
	name = "ItemComponent"


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	super._ready()
	if parent_entity:
			parent_entity.supress_spawning = in_inventory
	psc = parent_entity.get_component("PuppetSpawnerComponent")
	inv = parent_entity.get_component("InteractiveComponent")


func _entity_ready() -> void:
	inv.interacted.connect(interact.bind())
	inv.translation_callback = get_translated_name.bind()
	if item_owner == &"":
		inv.interact_verb = "TAKE"
	else:
		# TODO: Determine using worth and owner relationships
		inv.interact_verb = "STEAL"


func _process(delta):
	if Engine.is_editor_hint():
		return
	if in_inventory:
		parent_entity.position = SKEntityManager.instance.get_entity(contained_inventory).position
		parent_entity.world = SKEntityManager.instance.get_entity(contained_inventory).world


## Move this to another inventory. Adds and removes the item from the inventories.
func move_to_inventory(refID:StringName):
	# remove from inventory if we are in one
	if in_inventory:
		SKEntityManager.instance\
			.get_entity(contained_inventory)\
			.get_component("InventoryComponent")\
			.remove_from_inventory(parent_entity.name)
	
	# drop if moved to inventory is empty
	if refID == "":
		drop()
		return
	
	# add to new inventory
	SKEntityManager.instance\
		.get_entity(refID)\
		.get_component("InventoryComponent")\
		.add_to_inventory(parent_entity.name)
	
	contained_inventory = refID
	
	if in_inventory:
		psc.despawn()


## Drop this on the ground.
func drop():
	var e:SKEntity = SKEntityManager.instance.get_entity(contained_inventory)
	var drop_dir:Quaternion = e.quaternion
	print(drop_dir.get_euler().normalized() * DROP_DISTANCE)
	# This whole bit is genericizing dropping the item in front of the player. It's meant to be used with the player, it should work with anything with a puppet.
	if in_inventory:
		SKEntityManager.instance.get_entity(contained_inventory)\
			.get_component(&"InventoryComponent")\
			.remove_from_inventory(parent_entity.name)

	# raycast in front of puppet if possible to do wall check
	if e.in_scene and psc:
		print("has puppet component, in scene")
		if psc.puppet:
			print("puppet exists")
			# construct raycast
			var from = parent_entity.position + Vector3(0, 1.5, 0)
			var to = parent_entity.position + Vector3(0, 1.5, 0) + (drop_dir.get_euler().normalized() * DROP_DISTANCE)
			var query = PhysicsRayQueryParameters3D.create(from, to, 0xFFFFFFFF, SkeleRealmsGlobal.get_child_rids(psc.unwrap().puppet))
			await get_tree().physics_frame
			var space = (psc.puppet as Node3D).get_world_3d().direct_space_state
			# FIXME: Direction is weird
			var res = space.intersect_ray(query)
			if res.is_empty():
				# else spawn in front
				print("didn't hit anything")
				parent_entity.position = to
				contained_inventory = NONE
				psc.spawn()
				return
			else:
				# if hit something, spawn at hit position
				print(res)
				parent_entity.position = res["position"] # TODO: Compensate for item size
				contained_inventory = NONE
				psc.spawn()
				return

	parent_entity.position = parent_entity.position + Vector3(0, 1.5, 0)

	contained_inventory = NONE
	psc.spawn()


## Interact with this item. Called from [InteractiveComponent].
func interact(interacted_refID):
	move_to_inventory(interacted_refID)
	if not interacted_refID == item_owner and not item_owner == "":
		printe("Stolen.")
		stolen = true
		CrimeMaster.crime_committed.emit(
			Crime.new(&"theft",
			interacted_refID,
			item_owner),
			parent_entity.position
			)


## Allows an item to be taken without being stolen.
func allow() -> void:
	item_owner = &"";


## Whether it has a component type. [code]c[/code] is the name of the component type, like "HoldableDataComponent".
func has_component(c:String) -> bool:
	return get_children().any(func(x:ItemDataComponent): return x.get_type() == c)


## Gets the first component of a type. [code]c[/code] is the name of the component type, like "HoldableDataComponent".
func get_component(c:String) -> ItemDataComponent:
	var valid_components = get_children().filter(func(x:ItemDataComponent): return x.get_type() == c)
	if valid_components.is_empty():
		return null
	else:
		return valid_components[0]


func save() -> Dictionary:
	return {
		"contained_inventory" = contained_inventory,
		"item_owner" = item_owner
	}


func load_data(data:Dictionary):
	contained_inventory = data["contained_inventory"]
	item_owner = data["item_owner"]


func get_translated_name() -> String:
	var t = tr(parent_entity.name)
	if t == parent_entity.name:
		return tr(parent_entity.form_id)
	else :
		return t


func gather_debug_info() -> String:
	return """
[b]ItemComponent[/b]
	Contained Inventory: %s
	Owner: %s
	Quest Item?: %s
	""" % [
		contained_inventory if in_inventory else "None",
		item_owner,
		quest_item
	]


func get_dependencies() -> Array[String]:
	return [
		"PuppetSpawnerComponent",
		"InteractiveComponent"
	]

```

**marker_component.gd**
```gdscript
@tool
class_name MarkerComponent
extends SKEntityComponent
## Component tag for [WorldMarker]s.


var rotation:Quaternion


func _init(rot:Quaternion = Quaternion.IDENTITY) -> void:
	name = "MarkerComponent"
	rotation = rot


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	super._ready()
	parent_entity.rotation = rotation


func get_world_entity_preview() -> Node:
	var sphere := MeshInstance3D.new()
	sphere.mesh = SphereMesh.new()
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.BLUE
	mat.albedo_color.a = 0.5
	
	sphere.set_surface_override_material(0, mat)
	return sphere

```

**navigator_component.gd**
```gdscript
class_name NavigatorComponent
extends SKEntityComponent
## Handles finding paths through the granular navigation system. See [NavigationMaster].


## Calculate a path from the entity's current position to a [NavPoint].
## Array is empty if no path is found.
func calculate_path_to(pt:NavPoint) -> Array[NavPoint]:
	var start := NavPoint.new(parent_entity.world, parent_entity.position)
	return NavMaster.instance.calculate_path(start, pt)


func _init() -> void:
	name = "NavigatorComponent"

```

**npc_component.gd**
```gdscript
@tool
class_name NPCComponent
extends SKEntityComponent
## The brain for an NPC. Handles AI behavior, scheduling, combat, dialogue interactions.
## The component itself is a blank slate, being comprised largely of state trackers and utility functions, and will likely do nothing without an [AIModule] to determine its behavior.
## It also has aobut a million signals that AI modules, the GOAP system, animation controllers, dialogue systems, etc. can hook into. Think of them as an API.
## @tutorial(In-depth look at the NPC system): https://github.com/SlashScreen/skelerealms/wiki/NPCs
## @tutorial(In-depth view of opinion system): https://github.com/SlashScreen/skelerealms/wiki/NPCs#opinions-and-how-the-npc-determines-its-opinions


@export_category("Flags")
## Whether this NPC is essential to the story, and them dying would screw things up.
@export var essential:bool = true
## Whether this NPC is a ghost.
@export var ghost:bool
## Whether this NPC can't take damage.
@export var invulnerable:bool
## Whether this NPC is unique.
@export var unique:bool = true
## Whether this NPC affects the stealth meter when it sees you.
@export var affects_stealth_meter:bool = true
## Whether you can interact with this NPC.
@export var interactive:bool = true
@export_category("AI")
## NPC relationships.
@export var relationships:Array[Relationship]
## Component types that the AI will looks for to determine threats. 
@export var threatening_enemy_types = [
	"NPCComponent",
	"PlayerComponent",
]
## Opinions of entities. StringName:float
@export var npc_opinions = {}
## Loyalty of this NPC. Determines weights of opinion calculations.
@export_enum("None", "Covens", "Self") var loyalty:int = 0
## How the opinion of something is calculated.
@export_enum("Minimum", "Maximum", "Average") var opinion_mode:int = 0

#* Public
var player_opinion:int
var visibility_threshold:float = 0.3
## Stores data of interest for GOAP to access.
var goap_memory:Dictionary = {}
#* Properties
var in_combat:bool:
	get:
		return in_combat
	set(val):
		if val and not in_combat: # these checks prevent spamming
			printe("entering combat")
			entered_combat.emit()
		elif not val and in_combat:
			printe("leaving combat")
			left_combat.emit()
		in_combat = val
var _current_target_point:NavPoint:
	set(val):
		_current_target_point = val
		if _puppet:
			_puppet.set_movement_target(val.position)
	get:
		return _current_target_point
var ai_modules:Array[AIModule] = []
## Keeps track of entities and vision data. Used for stealth mechanics. Pattern is ref_id:StringName -> data:Variant.
var perception_memory:Dictionary = {}
#* Private
## Navigator.
var _nav_component:NavigatorComponent
## Puppet manager component.
var _puppet_component:PuppetSpawnerComponent
## Interactive component.
var _interactive_component:InteractiveComponent
## Behavior planner.
var _goap_component:GOAPComponent
## The schedule event the NPC is following, if applicable.
var _current_schedule_event:ScheduleEvent
## Scheduler node.
var _schedule:Schedule
## Simulation level of the npc.
var _sim_level:SimulationLevel = SimulationLevel.FULL
## Indexes of the doors in the current path. THis is important to keeo track of due to the nature of doors going between worlds.
var _doors_in_path:Array[int] = []
## How close to a path marker the NPC must be to have reached it.
var _path_follow_end_distance:float = 1
## Off-world navigation walk speed.
var _walk_speed:float = 1
## Puppet root node.
var _puppet:NPCPuppet
## Target entity during combat.
var _combat_target:String
## Navigation path.
var _path:Array[NavPoint]
## Whether this character is in dialogue or a cutscene or in combat. Will stop/continue the puppet's pathfinding if applicable (not in combat).
var _busy:bool:
		get:
			return _busy or in_combat # is also busy if in combat
		set(val):
			printe("Set busy to %s" % val)
			if val and _puppet:
				_puppet.pause_nav()
			elif not val and _puppet:
				_puppet.continue_nav()
			_busy = val


## Signal emitted when this NPC enters combat.
signal entered_combat
## Signal emitted when this NPC leaved combat.
signal left_combat
## Signal emitted when it starts to see the player.
signal start_saw_player
## Signal emitted when it stops seeing the player.
signal end_saw_player
## Signal emitted when it reaches its target destination.
signal destination_reached
## Signal emitted when its schedule has been updated.
signal schedule_updated(ev:ScheduleEvent)
## Signal emitted when this NPC enters dialogue.
signal start_dialogue
## Signal emitted when the awareness state changes on an entity. Used for stealth mechanics.
signal awareness_state_changed(ref_id:String, state:int)
## Signal emitted when it wants to flee from an entity. Passes ref id of who it is warning.
signal flee(ref_id:String)
## Signal emitted when it hears an audio event.
signal heard_something(emitter:AudioEventEmitter)
## Signal emitted when this NPC is interacted with.
signal interacted(refID:String)
## Signal emitted when this NPC reacts to being hit by a friendly entity.
signal friendly_fire_response
## Signal emitted when the NPC wants to draw weapons.
signal draw_weapons
## Signal emitted when the NPC wants to put away its weapons.
signal put_away_weapons
## Signal emitted when the NPC is hit by somebody.
signal hit_by(who:String)
## Signal emitted when the NPC is hit with a particular damage effect - blunt, piercing, magic, etc.
signal damaged_with_effect(effect:StringName)
## Signal emitted when the NPC is added to a conversation.
signal added_to_conversation
## Signal emitted when the NPC is removed from a conversation.
signal removed_from_conversation
## Signal emitted when a crime is witnessed
signal crime_witnessed 
signal updated(delta:float)
signal puppet_request_move(puppet:NPCPuppet)
signal puppet_request_raise_weapons(puppet:NPCPuppet)
signal puppet_request_lower_weapons(puppet:NPCPuppet)


## Shorthand to get an npc component for an entity by ID.
static func get_npc_component(id:StringName) -> NPCComponent:
	var eop = SKEntityManager.instance.get_entity(id)
	if not eop:
		return null
	var icop = eop.get_component("NPCComponent")
	if icop:
		return icop
	else:
		return null


#region perception


## Wrapper for stealth providers' get_visible_objects. Empty if there is no puppet. 
## See the docs section on stealth providers for more info.
func get_visible_objects() -> Dictionary:
	if _puppet == null:
		return {}
	if _puppet.eyes == null:
		return {}
	return _puppet.eyes.get_visible_objects()


#endregion perception

#region overrides


func _init() -> void:
	name = "NPCComponent"


func _ready():
	if Engine.is_editor_hint():
		return 
	
	super._ready()
	
	# Initialize all AI Modules
	var modules:Array[AIModule] = []
	for module:Node in get_children():
		if not module is AIModule:
			continue
		modules.append(module)

	_nav_component = parent_entity.get_component("NavigatorComponent") as NavigatorComponent
	# Puppet manager component.
	_puppet_component = parent_entity.get_component("PuppetSpawnerComponent") as PuppetSpawnerComponent
	# Interactive component.
	_interactive_component = parent_entity.get_component("InteractiveComponent") as InteractiveComponent
	# Behavior planner.
	_goap_component = parent_entity.get_component("GOAPComponent") as GOAPComponent
	_interactive_component.interacted.connect(func(x:String): interacted.emit(x))
	
	# sync nav agent
	_puppet_component.spawned_puppet.connect(func(x:Node):
		_puppet = x as NPCPuppet
		_goap_component._agent = (x as NPCPuppet).navigation_agent
		)
	_puppet_component.despawned_puppet.connect(func():
		_puppet = null
		_goap_component._agent = null
		)
	# schedule
	var s := get_node_or_null("Schedule")
	if s:
		_schedule = s
	else:
		var n := Schedule.new()
		n.name = "Schedule"
		add_child(n)
		_schedule = n
	# misc setup
	_interactive_component.translation_callback = get_translated_name.bind()
	
	GameInfo.minute_incremented.connect(_calculate_new_schedule.bind())
	for a:AIModule in modules:
		a.initialize()


func _on_enter_scene():
	_sim_level = SimulationLevel.FULL


func _on_exit_scene():
	_sim_level = SimulationLevel.GRANULAR


func _process(delta):
	if Engine.is_editor_hint():
		return
	#* Section 1: Path following
	# If in scene, use navmesh agent.
	if _current_target_point:
		if parent_entity.in_scene:
			if _puppet.target_reached: # If puppet reached target
				_next_point()
		else: # If not in scene, move between points.
			if parent_entity.position.distance_to(_current_target_point.position) < _path_follow_end_distance: # if reached point
				_next_point() # get next point
				parent_entity.world = _current_target_point.world # set world
			parent_entity.position = parent_entity.position.move_toward(_current_target_point.position, delta * _walk_speed) # move towards position
	
	if _puppet:
		if _puppet.eyes:
			var d:Dictionary = _puppet.eyes.get_visible_objects()
			for obj:Object in d:
				if obj is not Node:
					continue
				var e:SKEntity = SkeleRealmsGlobal.get_entity_in_tree(obj)
				if not e:
					continue 
				
				if perception_memory.has(e.name):
					perception_memory[e.name][&"visibility"] = d[obj][&"visibility"]
					perception_memory[e.name][&"last_seen_position"] = d[obj][&"last_seen_position"]
				else:
					perception_memory[e.name] = {
						&"visibility": d[obj][&"visibility"],
						&"last_seen_position": d[obj][&"last_seen_position"],
					}
	
	updated.emit(delta)


func get_dependencies() -> Array[String]:
	return [
		"InteractiveComponent",
		"PuppetSpawnerComponent",
		"NavigatorComponent",
		"GOAPComponent",
	]


func _exit_tree() -> void:
	for m in ai_modules:
		m._clean_up()


#endregion overrides

#region dialogue


## Make this NPC Leave dialogue.
func leave_dialogue() -> void:
	_busy = false


## Ask this NPC to interact with something.
func interact_with(refID:String) -> void:
	goap_memory["interact_target"] = refID
	add_objective ( # Add goal to interact with an object.
		{"interacted" : true},
		true,
		2
	)


func add_to_conversation() -> void:
	added_to_conversation.emit()


func remove_from_conversation() -> void:
	removed_from_conversation.emit()


#endregion dialogue

#region pathfinding


## Calculate this NPC's path to a [NavPoint].
func set_destination(dest:NavPoint) -> void:
	# Recalculate path
	_path = _nav_component.calculate_path_to(dest)
	# if no path calculated, try to set it to the destination for the navigation master
	if parent_entity.in_scene and _path.size() == 0 and dest.world == parent_entity.world:
		_current_target_point = dest
		return
	# detect any doors
	for i in range(_path.size() - 1):
		if not _path[i].world == _path[i + 1].world: # if next world that isnt this world then it is a door
			_doors_in_path.append(i)
	# set current point
	_next_point()


## Make the npc go to the next point in its path
func _next_point() -> void:
	# return early if the path has no elements
	if _path.size() == 0:
		return

	if not parent_entity.in_scene: # if we arent in scene, we follow the path exactly
		_current_target_point = _pop_path()
		return

	# we do this rigamarole because it will look weird if an NPC follows the granular path exactly
	if _doors_in_path.size() > 0: # if we have doors
		var next_door:int = _doors_in_path[0] # get next door
		if _path[next_door].position.distance_to(parent_entity.position) < ProjectSettings.get_setting("skelerealms/actor_fade_distance"): # TODO: fine tune these
			# if the next door is close enough, jsut go to it next because it will look awkward following the path
			# skip all until door
			# TODO: Interact with door?
			for i in range(next_door): # this will make the target point the door
				_current_target_point = _pop_path()
			return
	else: # if we dont have doors (we can assume that the destination is in same world
		if _path.back().position.distance_to(parent_entity.position) < ProjectSettings.get_setting("skelerealms/actor_fade_distance"):
			# if the last point is close enough, skip all until until last
			_current_target_point = _path.back()
			# clear path
			_path.clear()
			_doors_in_path.clear()
			return


## Gets the length of a slice of the path in meters. Doors are considered to be 0 distance, since they are different sides of the same object, at least theoretically.
func _get_path_length(slice:Array[NavPoint]) -> float:
	if slice.size() < 2: # if 0 or 1 length is 0
		return 0
	# else total everything
	var accum:float = 0
	for i in range(slice.size() - 1):
		if slice[i].world == slice[i + 1].world:
			accum += slice[i].position.distance_to(slice[i + 1].position)
	# maybe square root everything after, and use distance_to_squared?
	return accum


## Pop the next path value. Also shifts [member _doors_in_path] to match that.
func _pop_path() -> NavPoint:
	_doors_in_path = _doors_in_path\
						.map(func(x:int): return x-1)\
						.filter(func(x:int): return x >= 0) # shift doors forward and remove ines that have passed
	return _path.pop_front() # may be reversed, i dont remember


## Add a Goap objective.
func add_objective(goals:Dictionary, remove_after_satisfied:bool, priority:float):
	_goap_component.add_objective(goals, remove_after_satisfied, priority)


## Remove objectives that have a set of goals. Goals must match exactly.
func remove_objective_by_goals(goals:Dictionary) -> void:
	_goap_component.remove_objective_by_goals(goals)


#endregion pathfinding

#region schedule


## Ask this NPC to go to its schedule point.
func go_to_schedule_point() -> void:
	# Resolve schedule
	_calculate_new_schedule()

	# Don't recalculate if we are already at point
	if _current_schedule_event.satisfied_at_location(parent_entity):
		return

	# Go to the schedule point
	var loc = _current_schedule_event.get_event_location()
	if loc:
		_current_target_point = loc


## Get the current schedule for this NPC.
func _calculate_new_schedule() -> void:
	# Don't do this if we are not being simulated.
	if _sim_level == SimulationLevel.NONE:
		return

	var ev = _schedule.find_schedule_activity_for_current_time() # Scan schedule
	if ev.some():
		if not ev.unwrap() == _current_schedule_event:
			if _current_schedule_event:
				_current_schedule_event.on_event_ended()

			_current_schedule_event = ev.unwrap()

			if _current_schedule_event.has_method("attach_npc"):
				_current_schedule_event.attach_npc(self)
			_current_schedule_event.on_event_started()
			schedule_updated.emit(_current_schedule_event)
	else:
		# Else we have no schewdule for this time period
		_current_schedule_event = null
		schedule_updated.emit(null)


#endregion schedule 

#region misc


## Get a relationship this NPC has of [RelationshipType]. Pass in the type's key. Returns the relationship if found, none if none found.
func get_relationship_of_type(key:String) -> Option:
	var res = relationships.filter(func(r:Relationship): return r.relationship_type and r.relationship_type.relationship_key == key)
	if res.is_empty():
		return Option.none()
	return Option.from(res[0])


## Gets this NPC's relationship with someone by ref id. Returns the relationship if found, none if none found.
func get_relationship_with(ref_id:String) -> Option:
	var res = relationships.filter(func(r:Relationship): return r.relationship_type and r.other_person == ref_id)
	if res.is_empty():
		return Option.none()
	return Option.from(res[0])


## Determines the opinion of some entity. See the tutorial in the class docs for a more in-depth look at NPC opinions.
func determine_opinion_of(id:StringName) -> float:
	var e:SKEntity = SKEntityManager.instance.get_entity(id)

	if not threatening_enemy_types.any(func(x:String): return not e.get_component(x) == null): # if it doesn't have any components that are marked as threatening, return neutral.
		return 0

	var e_cc = e.get_component("CovensComponent")
	var opinions = []
	var opinion_total = 0

	# calculate modifiers
	var covens_modifier = 2 if loyalty == 1 else 1 # if values covens, increase modifier
	var self_modifier = 2 if loyalty == 2 else 1 # ditto

	# if has other covens, compare against ours
	if e_cc:
		var covens = parent_entity.get_component("CovensComponent").covens
		var covennpc_opinions_unfiltered = []
		var e_covens_component = e_cc

		# get all opinions
		for coven in covens:
			var c = CovenSystem.get_coven(coven)
			# get the other coven opinions
			covennpc_opinions_unfiltered.append_array(c.get_covennpc_opinions(e_covens_component.covens.keys())) # FIXME: Get this coven opinions on other
			# take crimes into account
			opinions.append(CrimeMaster.max_crime_severity(id, coven) * -10) # sing opinion by -10 for each severity point

		opinions.append_array(covennpc_opinions_unfiltered.filter(func(x:int): return not x == 0)) # filter out zeroes
		opinion_total += opinions.size() * covens_modifier # calculate total
	# if has an opinion of the player, take into account
	if npc_opinions.has(id) and not npc_opinions[id] == 0:
		opinions.append(npc_opinions[id])
		opinion_total += self_modifier # avoid 1 * self_modifier because that's an identity function so we can just do self_modifier
	# Return weighted average
	match opinion_mode:
		0:
			var o:Variant = opinions.min()
			return 0.0 if o == null else o
		1:
			var o:Variant = opinions.max()
			return 0.0 if o == null else o
		2:
			return opinions.reduce(func(sum, next): return sum + next, 0) / (1 if opinion_total == 0 else opinion_total)
		_:
			return 0.0


func gather_debug_info() -> String:
	return """
[b]NPCComponent[/b]
	Visibility threshold: %s
	In combat: %s
	Busy: %s
	GOAP Memory: %s
	Current Target Point: %s
	Path: %s
	Simulation Level: %s
""" % [
	visibility_threshold,
	in_combat,
	_busy,
	goap_memory,
	_current_target_point,
	_path,
	_sim_level
]


func get_translated_name() -> String:
	var t = tr(parent_entity.name)
	if t == parent_entity.name:
		if parent_entity.form_id.is_empty():
			return parent_entity.name
		else:
			return tr(parent_entity.form_id)
	else:
		return t

#endregion misc

## Current simulation level for an NPC.
enum SimulationLevel {
	FULL, ## When the actor is in the scene.
	GRANULAR, ## When the actor is outside of the scene. Will still follow a schedule and go from point to point, but will not walk around using the navmesh, interact with things in the world, or do anything that involves the puppet.
	NONE, ## When the actor is outside of the simulation distance. It will not do anything.
}

```

**player_component.gd**
```gdscript
class_name PlayerComponent
extends SKEntityComponent
## Player component.


var _set_up:bool


func _init() -> void:
	name = "PlayerComponent"


func _ready():
	($"../TeleportComponent" as TeleportComponent).teleporting.connect(teleport.bind())
	(parent_entity.get_component("DamageableComponent") as DamageableComponent).damaged.connect(on_damage.bind())


func on_damage(info:DamageInfo) -> void:
	# TODO: Genericize, calculate buffs and debuffs
	(parent_entity.get_component("VitalsComponent") as VitalsComponent).change_health(-info.damage_effects[&"blunt"])


## Set the entity's position.
func set_entity_position(pos:Vector3):
	parent_entity.position = pos


func set_entity_rotation(q:Quaternion) -> void:
	parent_entity.quaternion = q


func _process(delta):
	if not parent_entity.world == GameInfo.world:
		parent_entity.world = GameInfo.world
	
	if _set_up:
		return
	
	var pc = $"../PuppetSpawnerComponent".puppet
	
	if not pc == null:
		pc.update_position.connect(set_entity_position.bind())
		_set_up = true


## Teleport the player.
func teleport(world:String, pos:Vector3):
	print("teleporting player to %s : %s" % [world, pos])
	GameInfo.world = world # Set the game's world to destination world
	parent_entity.world = world # Set this entity world to the destination
	(%WorldLoader as WorldLoader).load_world(world) # Load world
	($"../PuppetSpawnerComponent" as PuppetSpawnerComponent).set_puppet_position(pos) # Set player puppet position

```

**puppet_spawner_component.gd**
```gdscript
@tool
class_name PuppetSpawnerComponent
extends SKEntityComponent
## Manages spawning and despawning of puppets.


var prefab: PackedScene
## The puppet node.
var puppet:Node 

signal spawned_puppet(puppet:Node)
signal despawned_puppet


func _init() -> void:
	name = "PuppetSpawnerComponent"


func _ready():
	if Engine.is_editor_hint():
		return
	super._ready()
	# brute force getting the puppet for the player if it already exists.
	if get_child_count() > 0:
		puppet = get_child(0)


func get_world_entity_preview() -> Node:
	return get_child(0)


func _on_enter_scene() -> void:
	spawn()


func _on_exit_scene() -> void:
	despawn()


## Spawn a new puppet.
func spawn():
	var n:Node3D
	if not prefab and get_child_count() > 0:
		var ps: PackedScene = PackedScene.new()
		ps.pack(get_child(0))
		prefab = ps
		n = get_child(0)
	else:
		if not prefab:
			printe("Failed spawning: no prefab.")
			return
		n = prefab.instantiate()
		add_child(n)
	n.set_position(parent_entity.position)
	puppet = n
	spawned_puppet.emit(puppet)
	printe("spawned at %s : %s" % [parent_entity.world, parent_entity.position])


## Despawn a puppet.
func despawn():
	printe("despawned.")
	if not prefab:
		var ps: PackedScene = PackedScene.new()
		ps.pack(get_child(0))
		prefab = ps
	
	for n in get_children():
		n.queue_free()
	puppet = null
	despawned_puppet.emit()


## Set the puppet's position.
func set_puppet_position(pos:Vector3):
	if not puppet == null:
		(puppet as Node3D).position = pos

```

**script_component.gd**
```gdscript
class_name ScriptComponent
extends SKEntityComponent
## This class can be bound to any entity and acts as a way to make ad-hoc components, to fill the role Papyrus plays in Creation Kit.
## To create a script for this, simply extend this class, and add it to the [RefData] or [InstanceData] of the appropriate object. 
## If you want to add a custom script to a world object instead, you can.... write a normal script...


## Stores references to all components of this entity, save for this one.
## Dictionary layout is "ComponentType" : SKEntityComponent.
## This is declared in _ready(), so be careful when overriding.
var _components:Dictionary = {}


func _init(sc:Script) -> void:
	if not sc.get_base_script().get_instance_base_type() == get_script().get_instance_base_type():
		push_warning("The script \"%s\" does not inherit ScriptComponent. Deleting component to prevent unexpected behavior." % sc.get_instance_base_type())
		call_deferred("queue_free") ## Queue next frame. I think. May not work.
	set_script(sc)


func _ready() -> void:
	super._ready()
	name = "ScriptComponent"
	await parent_entity.instantiated
	for c in parent_entity.get_children():
		if c == self:
			continue
		_components[c.name] = c

```

**shop_component.gd**
```gdscript
class_name ShopComponent
extends ChestComponent


## Base value of how much (from 0-1) of the total price that the merchant will tollerate haggling.
@export var haggle_tolerance:float
## Only items with at least one of these tags can be sold to this vendor.
@export var whitelist:Array[StringName] = []
## No items with at least one of these tags can be sold to this vendor. Supercedes [member whitelist].
@export var blacklist:Array[StringName] = []
## Whether this merchant accepts stolen goods.
@export var accept_stolen:bool

```

**skills_component.gd**
```gdscript
class_name SkillsComponent
extends SKEntityComponent
## Component holding the skills of this entity. 
## Examples in Skyrim would be Destruction, Sneak, Alteration, Smithing.


## The skills of this SKEntity.
## It is in a dictionary so you can add, remove, and customize at will.
@export var skills:Dictionary:
	get:
		return skills
	set(val):
		skills = val
		dirty = true
## Character level of this character
var level:int = 0
## Used to determine how to save levels.
var _manually_set_level = false
var skill_xp:Dictionary = {}
var character_xp:int = 0

signal skill_levelled_up(skill:StringName, new_level:int)
signal character_levelled_up(new_level:int)


func _init() -> void:
	name = "SkillsComponent"


func save() -> Dictionary:
	dirty = false
	return {
		"skills": skills,
		"level": level if _manually_set_level else -1
	}


func load_data(data:Dictionary):
	skills = data["skills"]
	level = data["level"]
	dirty = false


func gather_debug_info() -> String:
	return """
[b]SkillsComponent[/b]
	Skills:
%s
""" % [
	JSON.stringify(skills, '\t').indent("\t\t")
]


func add_skill_xp(skill:StringName, amount:int) -> void:
	if not skills.has(skill):
		push_warning("SKEntity %s has no skill %s." % [parent_entity.name, skill])
		return 
	skill_xp[skill] += amount
	var target:int = SkeleRealmsGlobal.config.compute_skill(skills[skill])
	if target == -1:
		return
	if skill_xp[skill] >= target:
		skills[skill] += 1
		skill_levelled_up.emit(skill, skills[skill])


func add_character_xp(amount:int) -> void:
	character_xp += amount
	var target:int = SkeleRealmsGlobal.config.compute_character(level)
	if target == -1:
		return
	if character_xp >= amount:
		level += 1
		character_levelled_up.emit(level)

```

**spell_target_component.gd**
```gdscript
class_name SpellTargetComponent
extends SKEntityComponent
## Allows entities to be hit with spells, and keeps track of any applied spell effects.


var status_effect:EffectsComponent


signal hit_with_spell(spell:Spell)


## Hit this entity with a spell. Doesn't actually do anything apart from emit [signal hit_with_spell]. To apply effects, you can do that on the [Spell] side.
func hit(spell:Spell) -> void:
	hit_with_spell.emit(spell)


func _init() -> void:
	name = "SpellTargetComponent"


func _entity_ready() -> void:
	status_effect = parent_entity.get_component(&"EffectsComponent")


func add_effect(effect:StringName) -> void:
	status_effect.add_effect(effect)


func remove_effect(eff:StringName) -> void:
	status_effect.remove_effect(eff)

```

**teleport_component.gd**
```gdscript
class_name TeleportComponent
extends SKEntityComponent
## Allows an entity to warp.


## Emitted when teleporting. Used to let puppet holders know to move their puppets.
signal teleporting(world:String, position:Vector3)


## Teleport the entity to a world and position.
func teleport(world:String, position:Vector3):
	parent_entity.world = world
	parent_entity.position = position
	teleporting.emit(world, position)


func _init() -> void:
	name = "TeleportComponent"

```

**view_direction_component.gd**
```gdscript
class_name ViewDirectionComponent
extends SKEntityComponent


var view_rot:Vector3 = Vector3.FORWARD


func _init() -> void:
	name = "ViewDirectionComponent"

```

**vitals_component.gd**
```gdscript
class_name VitalsComponent
extends SKEntityComponent
## Component keeping check of the main 3 attributes of an entity - health, stamina, and magica.

# TODO: This is for player only, make a generalized one 
## Called when this entity's health reaches 0. See [member health].
signal dies
## Called when the stamina value reaches 0. See [member moxie].
signal exhausted
## Called when the magica value reaches 0. See [member will].
signal drained
signal hurt
signal vitals_updated(data:Dictionary)


const DISHONORED_MODE:bool = false
## Health, stamina, magica, and max of values.
var vitals = {
	"health" = 100.0,
	"moxie" = 100.0,
	"will" = 100.0,
	"max_health" = 100.0,
	"max_moxie" = 100.0,
	"max_will" = 100.0,
	"return_to_will" = 0.0,
}:
	get:
		return vitals
	set(val):
		vitals = val
		dirty = true
		vitals_updated.emit(vitals)
var moxie_recharge_rate:float = 2
var moxie_just_changed:bool
var will_recharge_rate:float = 1
var will_just_changed:bool


## Whether this agent is dead.
var is_dead:bool: 
	get:
		return vitals["health"] < 1
## Whether this agent is exhausted.
var is_exhausted:bool: 
	get:
		return vitals["moxie"] < 1
## Whether this agent is drained.
var is_drained:bool: 
	get:
		return vitals["will"] < 1
var will_timer:Timer
var tween:Tween


func _init() -> void:
	name = "VitalsComponent"


func _ready() -> void:
	will_timer = Timer.new()
	add_child(will_timer)
	will_timer.timeout.connect(do_return_to_will.bind())
	will_timer.one_shot = true


func set_health(val:float) -> void:
	vitals["health"] = clampf(val, 0.0, vitals["max_health"])
	vitals_updated.emit(vitals)
	if is_dead:
		dies.emit()


func change_health(val:float) -> void:
	set_health(vitals["health"] + val)


func set_moxie(val:float) -> void:
	vitals["moxie"] = clampf(val, 0.0, vitals["max_moxie"])
	vitals_updated.emit(vitals)
	moxie_just_changed = true
	if is_exhausted:
		exhausted.emit()


func change_moxie(val:float) -> void:
	set_moxie(vitals["moxie"] + val)


func set_will(val:float) -> void:
	vitals["will"] = clampf(val, 0.0, vitals["max_will"])
	vitals_updated.emit(vitals)
	will_just_changed = true
	if is_drained:
		drained.emit()


func cast_spell(cost:float) -> void:
	if DISHONORED_MODE:
		if tween:
			tween.kill()
		vitals.return_to_will = vitals["will"]
		will_just_changed = true
		will_timer.start(1.0)
	change_will(-cost)


func do_return_to_will() -> void:
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_method(set_will.bind(), vitals.will, vitals.return_to_will, 1.0)
	tween.tween_callback(func(): 
		will_just_changed = false)


func change_will(val:float) -> void:
	set_will(vitals["will"] + val)


func save() -> Dictionary:
	dirty = false
	return vitals


func load_data(data:Dictionary):
	vitals = data
	dirty = false


func _physics_process(delta: float) -> void:
	if not moxie_just_changed and not vitals.moxie == vitals.max_moxie:
		change_moxie(moxie_recharge_rate * delta)
	moxie_just_changed = false
	
	if not will_just_changed and not vitals.will == vitals.max_will:
		change_will(will_recharge_rate * delta)
	if not DISHONORED_MODE:
		will_just_changed = false


func gather_debug_info() -> String:
	return """
[b]VitalsComponent[/b]
	Vitals: 
%s
""" % [
	JSON.stringify(vitals, '\t').indent("\t\t")
]

```

### scripts

**constants.gd**
```gdscript
class_name SKConstants


## The defacto currency of this game.
const DE_FACTO_CURRENCY = &"snails"

```

#### core

**Modifier_System.gd**
```gdscript
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
				Global.rot_bonus[target_name] = Global.rot_bonus.get(target_name, 0.0) + 3.0

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
				pass  # TODO: wymaga Area2D w scenie postaci

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
	var scene = load("res://Scenes/effects/poison_zone.tscn")
	if not scene:
		return
	var zone: Node    = scene.instantiate()
	zone.position     = pos
	zone.shooter_name = shooter_name
	get_tree().root.add_child(zone)

func _spawn_explosion(pos: Vector2, shooter_name: String) -> void:
	var scene = load("res://Scenes/effects/explosion.tscn")
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

```

**global.gd**
```gdscript
extends Node
signal kill_feed_message(text: String)

var player1_character: String = ""
var player2_character: String = ""
var player3_character: String = ""
var player4_character: String = ""

var round_over:   bool   = false
var game_started: bool   = false
var winner:       String = ""
var total_players: int   = 4
var current_picking_player: int = 1

var selected_characters:  Dictionary = {}
var available_characters: Array      = []
var alive:                Dictionary = {}

var round_number:   int = 1
var rounds_per_set: int = 5

var points:    Dictionary = {}
var modifiers: Dictionary = {}
var rot_bonus: Dictionary = {}

var death_order:      Array = []
var ranking:          Array = []
var modifier_pickers: Array = []

var shot_counter: Dictionary = {}

var base_characters: Dictionary = {
	"Strawberry": { "hp": 100, "speed": 80,  "dmg": 25, "range": 100, "fire_rate": 0.8 },
	"Orange":     { "hp": 50,  "speed": 90,  "dmg": 50, "range": 400, "fire_rate": 2.5 },
	"Pineapple":  { "hp": 200, "speed": 150, "dmg": 30, "range": 80,  "fire_rate": 0.5 },
	"Grape":      { "hp": 80,  "speed": 100, "dmg": 15, "range": 150, "fire_rate": 0.2 },
}
var characters: Dictionary = {}

var modifier_registry: Dictionary = {
	"double_shot":        { "name": "Podwójny strzał",       "emoji": "✌️",  "category": "projectile", "trigger": "on_shoot",   "desc": "Wystrzelasz dodatkowy pocisk obok głównego." },
	"sniper_seed":        { "name": "Pestka snajpera",        "emoji": "🎯",  "category": "projectile", "trigger": "on_shoot",   "desc": "Pocisk leci o 25% szybciej." },
	"fermentation":       { "name": "Fermentacja",            "emoji": "🧪",  "category": "projectile", "trigger": "on_hit",     "desc": "Każdy pocisk zatruwa wroga na 3 sek." },
	"ripe_shot":          { "name": "Dojrzały strzał",        "emoji": "🍑",  "category": "projectile", "trigger": "on_shoot",   "desc": "Co 3. strzał zadaje +30% obrażeń." },
	"shotgun":            { "name": "Shotgun pestek",         "emoji": "💥",  "category": "projectile", "trigger": "on_shoot",   "desc": "Wystrzelasz 4 dodatkowe pociski w wachlarzu." },
	"radioactive_seed":   { "name": "Radioaktywna pestka",    "emoji": "☢️",  "category": "projectile", "trigger": "on_hit",     "desc": "Przy trafieniu zostaje toksyczna plama na 3 sek." },
	"rot_shot":           { "name": "Strzał zgnilizny",       "emoji": "🦠",  "category": "projectile", "trigger": "on_hit",     "desc": "Trafiony wróg gnije o 3 sek szybciej." },
	"magnetic_seed":      { "name": "Magnetyczna pestka",     "emoji": "🧲",  "category": "projectile", "trigger": "on_shoot",   "desc": "Pocisk skręca w kierunku wroga w zasięgu 2m." },
	"thick_skin":         { "name": "Gruba skórka",           "emoji": "🥊",  "category": "defense",    "trigger": "on_apply",   "desc": "Maksymalne HP +25." },
	"juicy_core":         { "name": "Soczyste wnętrze",       "emoji": "💧",  "category": "defense",    "trigger": "on_hit",     "desc": "Odzyskujesz 15% brakującego HP przy trafieniu wroga." },
	"wax_coat":           { "name": "Woskowa powłoka",        "emoji": "🕯️",  "category": "defense",    "trigger": "on_receive", "desc": "Blokujesz pierwsze trafienie w rundzie." },
	"thorn_shield":       { "name": "Kolczasta tarcza",       "emoji": "🌵",  "category": "defense",    "trigger": "on_receive", "desc": "Wrogowie trafiający cię dostają -3 HP." },
	"hard_fruit":         { "name": "Twardy owoc",            "emoji": "🪨",  "category": "defense",    "trigger": "on_receive", "desc": "Redukcja wszystkich obrażeń o 10%." },
	"antirot":            { "name": "Antyzgnilizna",          "emoji": "🧴",  "category": "defense",    "trigger": "passive",    "desc": "Gnijesz o 5 sek wolniej." },
	"preservative":       { "name": "Konserwant",             "emoji": "🛡️",  "category": "defense",    "trigger": "on_apply",   "desc": "Przez pierwsze 15 sek rundy jesteś odporny na efekty negatywne." },
	"second_fruit":       { "name": "Drugi owoc",             "emoji": "🍀",  "category": "defense",    "trigger": "on_lethal",  "desc": "Raz na rundę przeżywasz śmiertelny cios z 5 HP." },
	"still_green":        { "name": "Zielony jeszcze",        "emoji": "🌿",  "category": "defense",    "trigger": "passive",    "desc": "Gdy HP < 30%, regenerujesz 1 HP co 2 sek." },
	"stone_seed":         { "name": "Kamienna pestka",        "emoji": "🗿",  "category": "defense",    "trigger": "on_apply",   "desc": "+8 pancerza, ale -10% prędkości ruchu." },
	"extra_bounce":       { "name": "Dodatkowe odbicie",      "emoji": "↩️",  "category": "bounce",     "trigger": "on_shoot",   "desc": "Pocisk odbija się o +1 powierzchnię więcej." },
	"accelerating_bounce":{ "name": "Przyspieszające odbicie","emoji": "⚡",  "category": "bounce",     "trigger": "on_bounce",  "desc": "Każde odbicie zwiększa prędkość pocisku o 10%." },
	"destroying_bounce":  { "name": "Niszczące odbicie",      "emoji": "💢",  "category": "bounce",     "trigger": "on_bounce",  "desc": "Każde odbicie dodaje +5 DMG." },
	"magnetic_bounce":    { "name": "Magnetyczne odbicie",    "emoji": "🧲",  "category": "bounce",     "trigger": "on_bounce",  "desc": "Po odbiciu pocisk leci w stronę najbliższego wroga przez 2 sek." },
	"mirror_skin":        { "name": "Lustrzana skórka",       "emoji": "🪞",  "category": "defense",    "trigger": "on_receive", "desc": "10% szansa na odbicie ataku wroga." },
	"rage_bounce":        { "name": "Wściekłe odbicie",       "emoji": "😡",  "category": "bounce",     "trigger": "on_bounce",  "desc": "Odbity pocisk zadaje 30% więcej obrażeń." },
	"ripe_sprint":        { "name": "Dojrzały sprint",        "emoji": "👟",  "category": "passive",    "trigger": "on_apply",   "desc": "Prędkość ruchu +15%." },
	"rot_accelerator":    { "name": "Przyspieszacz gnicia",   "emoji": "💀",  "category": "area",       "trigger": "passive",    "desc": "Wrogowie w twoim zasięgu gniją 15% szybciej." },
	"rot_explosion":      { "name": "Gnilna eksplozja",       "emoji": "🌋",  "category": "defense",    "trigger": "passive",    "desc": "Gdy HP < 20%, odpychasz wrogów i leczysz 10 HP (jednorazowo)." },
	"seed_collector":     { "name": "Kolekcjoner pestek",     "emoji": "🌰",  "category": "projectile", "trigger": "on_hit",     "desc": "Każde trafienie bez otrzymania ciosu daje +1 DMG. Reset przy ciosie." },
	"fruit_streak":       { "name": "Owocowa passa",          "emoji": "🔥",  "category": "projectile", "trigger": "on_hit",     "desc": "3 trafienia z rzędu = następny pocisk +30% obrażeń." },
	"mod_duplicator":     { "name": "Duplikator modów",       "emoji": "🔄",  "category": "passive",    "trigger": "on_apply",   "desc": "Losowy posiadany modyfikator zostaje skopiowany." },
	"bouncy":   { "name": "Odbijające pociski", "emoji": "↩️", "category": "bounce",     "trigger": "on_shoot",   "desc": "Pociski odbijają się 4 razy." },
	"spinning": { "name": "Wirujące pociski",   "emoji": "🌪️", "category": "projectile", "trigger": "passive",    "desc": "Pociski poruszają się sinusoidalnie." },
	"poison":   { "name": "Ślad trucizny",      "emoji": "☠️", "category": "area",       "trigger": "passive",    "desc": "Gracz zostawia toksyczny ślad." },
	"lifesteal":{ "name": "Kradzież HP",        "emoji": "🔴", "category": "projectile", "trigger": "on_hit",     "desc": "Odzyskujesz 30% zadanych obrażeń jako HP." },
	"explosive":{ "name": "Eksplodujące",       "emoji": "💣", "category": "projectile", "trigger": "on_hit",     "desc": "Pociski eksplodują przy trafieniu." },
	"sticky":   { "name": "Lepkie pociski",     "emoji": "🐌", "category": "projectile", "trigger": "on_hit",     "desc": "Trafiony wróg jest spowolniony przez 3 sek." },
	"armor":    { "name": "Pancerz",            "emoji": "🛡️", "category": "defense",    "trigger": "on_receive", "desc": "Redukuje obrażenia o 30%." },
	"speed":    { "name": "+20% prędkość",      "emoji": "👟", "category": "passive",    "trigger": "on_apply",   "desc": "Prędkość ruchu +20%." },
}

var all_modifiers: Array = [
	"double_shot", "sniper_seed", "fermentation", "ripe_shot", "shotgun",
	"radioactive_seed", "rot_shot", "magnetic_seed",
	"thick_skin", "juicy_core", "wax_coat", "thorn_shield", "hard_fruit",
	"antirot", "preservative", "second_fruit", "still_green", "stone_seed",
	"extra_bounce", "accelerating_bounce", "destroying_bounce",
	"magnetic_bounce", "mirror_skin", "rage_bounce",
	"ripe_sprint", "rot_accelerator", "rot_explosion",
	"seed_collector", "fruit_streak", "mod_duplicator",
]

func _ready() -> void:
	# Pełny reset przy każdym starcie gry
	round_number = 1
	points       = {}
	modifiers    = {}
	reset_selection()
	reset_all()

func reset_selection() -> void:
	available_characters   = base_characters.keys()
	selected_characters    = {}
	current_picking_player = 1
	player1_character = ""
	player2_character = ""
	player3_character = ""
	player4_character = ""

func reset_all() -> void:
	characters   = base_characters.duplicate(true)
	shot_counter = {}
	rot_bonus    = {}
	alive        = {}
	var all_chars = [player1_character, player2_character, player3_character, player4_character]
	for ch in all_chars:
		if ch == "": continue
		alive[ch] = true
		if not points.has(ch):    points[ch]    = 0
		if not modifiers.has(ch): modifiers[ch] = []
	round_over   = false
	game_started = false
	winner       = ""
	death_order  = []
	ranking      = []

func reset_full_game() -> void:
	round_number = 1
	points       = {}
	modifiers    = {}
	reset_selection()
	reset_all()

func pick_character(character_name: String) -> void:
	selected_characters[current_picking_player] = character_name
	match current_picking_player:
		1: player1_character = character_name
		2: player2_character = character_name
		3: player3_character = character_name
		4: player4_character = character_name
	available_characters.erase(character_name)
	current_picking_player += 1

func all_picked() -> bool:
	return current_picking_player > total_players

func is_set_complete() -> bool:
	return round_number % rounds_per_set == 0

func assign_points() -> void:
	# Remis (gnicie) — nikt nie dostaje punktów
	if Global.winner == "":
		return

	var point_values = [3, 2, 1, 0]
	for i in range(ranking.size()):
		if i < point_values.size():
			var ch = ranking[i]
			if not points.has(ch): points[ch] = 0
			points[ch] += point_values[i]

func get_modifier_pickers() -> Array:
	var half: int = ranking.size() / 2
	var pickers = []
	for i in range(ranking.size() - 1, ranking.size() - half - 1, -1):
		pickers.append(ranking[i])
	return pickers

func build_ranking() -> void:
	ranking = []
	for ch in alive:
		if alive[ch]: ranking.append(ch)
	var rev = death_order.duplicate()
	rev.reverse()
	for ch in rev: ranking.append(ch)

func take_damage(target: String, amount: float, reason: String = "") -> void:
	if amount <= 0.0 or not characters.has(target): return
	characters[target]["hp"] -= amount
	var msg = reason + "  →  " + target + " -" + str(int(amount)) + " HP"
	print(msg)
	kill_feed_message.emit(msg)

# _physics_process USUNIĘTY CAŁKOWICIE
# Koniec rundy wykrywa wyłącznie main_game.gd

```

**main_game.gd**
```gdscript
extends Node2D

var character_scenes = {
	"Strawberry": {
		"scene":  preload("res://Scenes/characters/strawberry.tscn"),
		"bullet": preload("res://Scenes/bullets/strawberry_bullet.tscn")
	},
	"Grape": {
		"scene":  preload("res://Scenes/characters/grape.tscn"),
		"bullet": preload("res://Scenes/bullets/grape_bullet.tscn")
	},
	"Orange": {
		"scene":  preload("res://Scenes/characters/orange.tscn"),
		"bullet": preload("res://Scenes/bullets/orange_bullet.tscn")
	},
	"Pineapple": {
		"scene":  preload("res://Scenes/characters/pineapple.tscn"),
		"bullet": preload("res://Scenes/bullets/pineapple_bullet.tscn")
	}
}

var bullet_scenes:     Dictionary = {}
var player_characters: Dictionary = {}
var kill_feed_script = preload("res://scripts/ui/kill_feed.gd")
var _ending_round: bool = false


func _ready() -> void:
	# reset_all TUTAJ (nie w round_ended) — dzięki temu stara scena nie widzi
	# pustego alive{} gdy reset następuje przed zmianą sceny.
	Global.reset_all()
	_setup_kill_feed()
	Global.game_started = true
	_ending_round = false

	print("=== RUNDA " + str(Global.round_number) + " ===")
	for character in Global.modifiers:
		if Global.modifiers[character].size() > 0:
			print(character + " mody: " + str(Global.modifiers[character]))

	_spawn_player(Global.player1_character, $Players/SpawnPoint1.position, "p1")
	_spawn_player(Global.player2_character, $Players/SpawnPoint2.position, "p2")
	_spawn_player(Global.player3_character, $Players/SpawnPoint3.position, "p3")
	_spawn_player(Global.player4_character, $Players/SpawnPoint4.position, "p4")

	$Gnicie.start()


func _spawn_player(character_name: String, spawn_pos: Vector2, player_prefix: String) -> void:
	if character_name == "":
		return
	var data   = character_scenes[character_name]
	var player = data["scene"].instantiate()
	player.action_left  = player_prefix + "_left"
	player.action_right = player_prefix + "_right"
	player.action_jump  = player_prefix + "_jump"
	player.action_shoot = player_prefix + "_shoot"
	player.position     = spawn_pos
	bullet_scenes[player_prefix]     = data["bullet"]
	player_characters[player_prefix] = character_name
	player.shoot.connect(func(pos, dir): _on_shoot(pos, dir, player_prefix))
	$Players.add_child(player)


func _setup_kill_feed() -> void:
	var canvas        = CanvasLayer.new()
	canvas.layer      = 10
	add_child(canvas)
	var feed          = VBoxContainer.new()
	feed.script       = kill_feed_script
	feed.anchor_right = 1.0
	feed.offset_left  = 4
	feed.offset_top   = 4
	feed.offset_right = -4
	canvas.add_child(feed)


func _on_shoot(pos: Vector2, dir: Vector2, player_prefix: String) -> void:
	if _ending_round:
		return
	var char_name: String = player_characters[player_prefix]

	# Główny pocisk
	var bullet = bullet_scenes[player_prefix].instantiate() as Area2D
	$Bullets.add_child(bullet)
	bullet.setup(pos, dir, char_name)

	# Dodatkowe pociski z modów (double_shot, shotgun)
	var extra_dirs: Array = ModifierSystem.get_extra_bullet_dirs(char_name, dir)
	for extra_dir in extra_dirs:
		var extra = bullet_scenes[player_prefix].instantiate() as Area2D
		$Bullets.add_child(extra)
		extra.setup(pos, extra_dir, char_name)


func _on_gnicie_timeout() -> void:
	# Gnicie = czas minął, wszyscy żywi remisują — brak zwycięzcy
	_end_round("")


func _physics_process(_delta: float) -> void:
	if _ending_round:
		return
	var alive_count = Global.alive.values().count(true)
	if alive_count <= 1:
		var winner = ""
		for ch in Global.alive:
			if Global.alive[ch]:
				winner = ch
				break
		_end_round(winner)


func _end_round(winning_character: String) -> void:
	# Flaga _ending_round blokuje wielokrotne wywołanie (np. gnicie + physics_process
	# wykrywają koniec rundy w tej samej klatce).
	if _ending_round:
		return
	_ending_round     = true
	Global.round_over = true
	Global.winner     = winning_character

	if has_node("Gnicie"):
		$Gnicie.stop()

	Global.build_ranking()
	Global.assign_points()  # nie przyznaje punktów przy remisoie (winner == "")

	# Remis — defensywnie zerujemy modifier_pickers tutaj też,
	# choć round_ended.gd już to obsługuje po swojej stronie.
	if winning_character == "":
		Global.modifier_pickers = []

	if Global.is_set_complete():
		get_tree().change_scene_to_file("res://Scenes/ui/set_over.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/ui/round_ended.tscn")

```

#### covens

**coven.gd**
```gdscript
class_name Coven
extends Resource
## Analagous to a Faction in creation kit games, where a Coven is a group of Entities that behave a certain way.
## Entities must have a [CovensComponent] to be a part of a coven.
## Entities are automatically added to a group with the coven's ID when they are a part of a coven, so to get all entities part of a coven, you can get all of group.
## Unlike Creation Kit, Entties are assigned to a coven on the SKEntity side- the Coven just holds information.
## To give them a default response to the player, create a "Player" coven, and give them a default reaction to that.


@export_category("Information")
## ID for this coven. Also used as a key in translations. See [member coven_name].
@export var coven_id:StringName
## The opinion this coven has of other covens. The dictionary shopuld be of StringName:int.
@export var other_coven_opinions:Dictionary
## Whether the player should see this in the menu if they are a part of the coven.
@export var hidden_from_player:bool
## The ranks of this coven. Shape is int:String, where key is the rank, and value is the translation key for the rank.
@export var ranks:Dictionary
@export_category("Crime")
## Whether members of this coven ignore crimes perpetrated to other members.
@export var ignore_crimes_against_others:bool = false
## Whether members care abourt crimes done against their own members.
@export var ignore_crimes_against_members:bool = false
## Whether this coven remembers crimes done against it.
@export var track_crime:bool = true


## Translated coven name.
var coven_name:String:
	get:
		return tr(coven_id)


## Get the translated name of a rank.
func rank_name(rank:int) -> String:
	return tr(ranks[rank]) if ranks.has(rank) else ""


## Returns a list of the opinions it has of a list of covens.
func get_coven_opinions(covens:Array) -> Array[int]:
	var opinion_list:Array[int] = []
	
	for coven in covens:
		if other_coven_opinions.has(coven):
			opinion_list.append(other_coven_opinions[coven])
		else:
			opinion_list.append(0)
	
	return opinion_list


## Get the crime opinion modifier for an entity against this coven.
## The formula is [code]max_crime_severity * -10[/code].
func get_crime_modifier(who:StringName) -> int:
	return CrimeMaster.max_crime_severity(who, coven_id) * -10


func get_debug_info() -> String:
	return """
[b]%s[/b]
	Opinions: %s
	Hidden from player: %s
	Ranks: %s
	Ignores crimes against others: %s
	Ignores crimes against members: %s
	Track Crime: %s
	""" % [
		coven_id,
		JSON.stringify(other_coven_opinions),
		hidden_from_player,
		JSON.stringify(ranks),
		ignore_crimes_against_others,
		ignore_crimes_against_members,
		track_crime
	]

```

**coven_rank_data.gd**
```gdscript
class_name CovenRankData
extends Resource


@export var coven:Coven
@export var rank:int

```

**coven_system.gd**
```gdscript
extends Node
## Tracks all [Coven]s in the game.


var covens:Dictionary
var regex:RegEx


func _ready():
	GameInfo.game_started.connect(func():
		regex = RegEx.new()
		regex.compile("([^\\/\n\\r]+)\\.t?res")
		_cache_covens(ProjectSettings.get_setting("skelerealms/covens_path"))
		)


## Gets a [Coven] if it exists.
func get_coven(coven:StringName) -> Coven:
	return covens[coven] if covens.has(coven) else null


## Caches all covens in the project.
func _cache_covens(path:String):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if '.remap' in file_name:
				file_name = file_name.trim_suffix('.remap')
			if dir.current_is_dir(): # if is directory, cache subdirectory
				_cache_covens("%s/%s" % [path, file_name])
			else: # if filename, cache
				var result = regex.search(file_name)
				if result:
					covens[result.get_string(1) as StringName] = load("%s/%s" % [path, file_name])
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("An error occurred when trying to access the path.")


## Add coven to system.
func add_coven(c:Coven) -> void:
	covens[c.coven_id] = c


## Remove coven from system.
func remove_coven(id:StringName) -> void:
	covens.erase(id)


## Change the opinion a coven (of) has of another coven (what) by amount.
func change_opinion(of:StringName, what:StringName, amount:int) -> void:
	var c = get_coven(of)
	if not c:
		return
	if c.other_coven_opinions.has(what):
		c.other_coven_opinions[what] = c.other_coven_opinions[what] + amount
	else:
		c.other_coven_opinions[what] = amount

```

#### crime

**crime.gd**
```gdscript
class_name Crime
extends Resource
## Crime is a resource used to track crimes.


## Possible crime types and their severity.
## Edit to customize the types of crimes that can be committed.
## I guess I could do this in a config file (YAML?) but I dont want to do that right now.
const CRIMES:Dictionary = {
	&"assault": 2, # Beating someone up
	&"theft": 1, # Stealing, pickpocketing
	&"murder": 5, # Killing someone
	&"tomfoolery":1 # Mischeif
}

## Type of crime. See [constant CRIMES].
var crime_type:StringName
var perpetrator:String
var victim:String
var witnesses:Array[StringName] = []
## Severity of this crime
var severity:int:
	get:
		return CRIMES[crime_type] if CRIMES.has(crime_type) else 0


func _init(crime_type:StringName = &"", perpetrator:String = "", victim:String = "") -> void:
	self.crime_type = crime_type
	self.perpetrator = perpetrator
	self.victim = victim


func serialize() -> Dictionary:
	return {
		"crime_type":crime_type,
		"perpetrator":perpetrator,
		"victim":victim,
	}


func _to_string() -> String:
	return "Type: %s, Perp: %s, Victim: %s, Severity %s, Witnesses %s" % [crime_type, perpetrator, victim, severity, witnesses]

```

**crime_master.gd**
```gdscript
extends Node
## OBEY THE CRIME MASTER[br]
## This keeps track of any crimes committed against various [Coven]s.


## Bounty amounts for various crime severity levels.
const bounty_amount:Dictionary = {
	0 : 0,
	1 : 500,
	2 : 10000,
	5 : 100000,
}


## Tracked crimes.
## [codeblock]
## {
##		coven: {
##			"punished" : []
##			"unpunished": []
##		}
## }
## [/codeblock]
var crimes:Dictionary = {}
## This is a has set. All crimes reported will go into this set to be processed in the next frame.
## This is so that the same crime doesn't get reported over and over again. 
var crime_queue:Dictionary = {}
signal crimes_against_covens_updated(affected:Array[StringName])
signal crime_committed(crime:Crime, position:NavPoint)


func _ready():
	add_to_group("savegame_gameinfo")


## Move all unpunished crimes to punished crimes.
func punish_crimes(coven:StringName):
	crimes[coven]["punished"].append(crimes[coven]["unpunished"])
	crimes[coven]["unpunished"].clear


# TODO: Track crimes against others?
## Report a crime. The caller is also added as a witness.
func add_crime(crime:Crime, witness:StringName):
	crime_queue[crime] = true
	crime.witnesses.append(witness)


func _process(_delta: float) -> void:
	_process_crime_queue()


func _process_crime_queue() -> void:
	if crime_queue.size() > 0:
		for crime in crime_queue:
			if crime.victim == "":
				continue
		# add crime to covens
			var cc = SKEntityManager.instance.get_entity(crime.victim).get_component("CovensComponent")
			if cc:
				for coven in (cc as CovensComponent).covens:
					## Skip if doesn't track crime
					if not CovenSystem.get_coven(coven).track_crime:
						continue

					if crimes.has(coven):
						crimes[coven]["unpunished"].append(crime)
					else: # if coven doesnt have crimes against it, initialize table
						crimes[coven] = {
							"punished" : [],
							"unpunished" : [crime]
						}
				crimes_against_covens_updated.emit((cc as CovensComponent).covens)
		crime_queue.clear()


## Returns the max wanted level for crimes against a Coven.
func max_crime_severity(id:StringName, coven:StringName) -> int:
	if not crimes.has(coven):
		return 0
	var cr = crimes[coven]["unpunished"]\
		.filter(func(x:Crime): return x.perpetrator == id)\
		.map(func(x:Crime): return x.severity)
	return 0 if cr.is_empty() else cr.max()


## Calculate the bounty a Coven has for an entity.
func bounty_for_coven(id:StringName, coven:StringName) -> int:
	if not crimes.has(coven):
		return 0
	return crimes[coven]["unpunished"]\
		.filter(func(x:Crime): return x.perpetrator == id)\
		.reduce(func(sum:int, x:Crime): return sum + bounty_amount[x.severity], 0)


func save() -> Dictionary:
	return {
		"crime" : crimes
	}


func load_data(data:Dictionary) -> void:
	crimes = data["crime"]


func reset_data() -> void:
	crimes = {}

```

#### data

##### ItemDataComponents

**apparel_data_component.gd**
```gdscript
class_name ApparelDataComponent
extends ItemDataComponent
## For clothes.

## Whether this has a custom model.
@export var modelled:bool
## Custom model, if using model.
@export var prefab:PackedScene
## Material, if not using a model.
@export var material:Material


func get_type() -> String:
	return "ApparelDataComponent"

```

**equippable_data_component.gd**
```gdscript
class_name EquippableDataComponent
extends ItemDataComponent


@export var valid_slots:Array[StringName]
@export var override_texture: Texture2D
@export var override_material: Material
@export var override_model: PackedScene


func get_type() -> String:
	return "EquippableDataComponent"

```

**holdable_data_component.gd**
```gdscript
class_name HoldableDataComponent
extends ItemDataComponent


## Whether this is held in both hands.
@export var two_handed:bool


func get_type() -> String:
	return "HoldableDataComponent"

```

**item_data_component.gd**
```gdscript
class_name ItemDataComponent
extends Node
## Base class for item data components that describe the capabilities of an item. See [ItemData]. [br]
## Items are a special case, in that they are built up of components.
## This may seem a bit weird and convoluted, and while it is, this allows for a much more extensible and flexible system.
## For example, you could give a shoe both the "Can equip to character" component, the "Holdable" component, and the "Throwable" component,
## and that would allow the character to wear the shoe, take it off, and huck it at somebody's head.


## Used for getting the component type. Override for each new type.
func get_type() -> String:
	return ""

```

**spell_data_component.gd**
```gdscript
class_name SpellDataComponent
extends ItemDataComponent


@export var spell:Spell


func get_type() -> String:
	return "SpellDataComponent"

```

**throwable_data_component.gd**
```gdscript
class_name ThrowableDataComponent
extends ItemDataComponent


func get_type() -> String:
	return "ThrowableDataComponent"

```

#### effects

**explosion.gd**
```gdscript
extends Area2D
## Eksplozja — zadaje obrażenia w zasięgu przy trafieniu (mod: explosive).

var shooter_name: String = ""

func _ready() -> void:
	# Czekamy jedną klatkę fizyki żeby Area2D zdążyła zarejestrować nakładające się ciała.
	await get_tree().physics_frame

	# Jeśli scena zmieniła się podczas await (np. runda się skończyła),
	# węzeł mógł już zostać zwolniony — is_instance_valid to wyłapuje.
	if not is_instance_valid(self):
		return

	# Zabezpieczenie: jeśli strzelec umarł i reset_all() wyczyścił characters,
	# nie próbuj odczytywać jego statystyk — to by crashowało.
	if not Global.characters.has(shooter_name):
		queue_free()
		return

	var dmg = float(Global.characters[shooter_name]["dmg"]) * 0.5

	for body in get_overlapping_bodies():
		if not is_instance_valid(body):
			continue
		# Używamy receive_damage() zamiast bezpośredniej modyfikacji HP —
		# dzięki temu działają pancerze, woskowa powłoka, lustrzana skórka itp.
		if not body.has_method("receive_damage"):
			continue
		var target_name = body.get("character_name")
		if target_name == null or target_name == shooter_name:
			continue
		if not Global.alive.get(target_name, false):
			continue
		if not Global.characters.has(target_name):
			continue
		var actual = body.receive_damage(dmg, shooter_name)
		if actual > 0.0:
			Global.take_damage(target_name, actual, "💥 Eksplozja od " + shooter_name)

	queue_free()

```

**poison_zone.gd**
```gdscript
extends Area2D
## Strefa trucizny — zadaje obrażenia co sekundę przez 3 sekundy.
## Tworzona przez mod: poison (trail), radioactive_seed (przy trafieniu).

var shooter_name: String = ""
var lifetime:   float = 3.0
var tick_timer: float = 1.0

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return

	tick_timer -= delta
	if tick_timer > 0:
		return
	tick_timer = 1.0

	for body in get_overlapping_bodies():
		if not is_instance_valid(body):
			continue
		# Używamy receive_damage() zamiast bezpośredniego hp -= X,
		# żeby pancerze i inne mody obronne działały poprawnie.
		if not body.has_method("receive_damage"):
			continue
		var target_name = body.get("character_name")
		if target_name == null or target_name == shooter_name:
			continue
		if not Global.alive.get(target_name, false):
			continue
		if not Global.characters.has(target_name):
			continue
		var actual = body.receive_damage(8.0, shooter_name)
		if actual > 0.0:
			Global.take_damage(target_name, actual, "☠️ Trucizna")

```

#### entities

**entity.gd**
```gdscript
@tool
class_name SKEntity
extends Node
## An entity for the pseudo-ecs. Contains [SKEntityComponent]s.
## These allow constructs such as NPCs and Items to persist even when not in the scene.


@export var form_id: StringName ## This is what [i]kind[/i] of entity it is. For example, Item "awesome_sword" has a form ID of "iron_sword".
@export var world: String ## The world this entity is in.
@export var position:Vector3 ## The entity's position in the world it lives within.
@export var rotation: Quaternion = Quaternion.IDENTITY ## The entity's rotation.
@export var unique:bool = true ## Whether this is the only entity of this setup. Usually used for named NPCs and the like.
## An internal timer of how long this entity has gone without being modified or referenced.
## One it's beyond a certain point, the [SKEntityManager] will mark it for cleanup after a save.
var stale_timer:float
## This is used to prevent items from spawning, even if they are supposed to be in scene.
## For example, items in invcentories should not spawn despite technically being "in the scene".
var supress_spawning:bool
## Whether this entity is in the scene or not.
var in_scene: bool:
	get:
		return in_scene
	set(val):
		if in_scene && !val: # if was in scene and now not
			left_scene.emit()
		if !in_scene && val: # if was not in scene and now is
			entered_scene.emit()
		in_scene = val


## Emitted when an entity enters a scene.
signal left_scene
## Emitted when an entity leaves a scene.
signal entered_scene
## This signal is emitted when all components have been added once [SKEntityManager.add_entity] is called.
## Await this when you want to connect with other nodes.
signal instantiated


func _init() -> void:
	# call entity ready
	instantiated.emit()
	for c in get_children():
		c._entity_ready()


func _ready():
	if Engine.is_editor_hint():
		return
	add_to_group("savegame_entity")


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		print(scene_file_path)
		return
	if not get_parent() is SKEntityManager:
		queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Engine.is_editor_hint():
		return
	_should_be_in_scene()
	# If we aren't in the scene, start counting up. Otherwise, we are still in the scene with the player and shouldn't depsawn.
	if not in_scene:
		stale_timer += delta
	else:
		stale_timer = 0


## Determine that this entity should be in scene
func _should_be_in_scene():
	if supress_spawning:
		in_scene = false
		return
	# if not in correct world
	if GameInfo.world != world:
		in_scene = false
		return
	# if we are outside of actor fade distance
	if position.distance_squared_to(GameInfo.world_origin.global_position) > ProjectSettings.get_setting("skelerealms/actor_fade_distance") ** 2:
		in_scene = false
		return
	in_scene = true


func _on_set_position(p:Vector3):
	position = p


func _on_set_rotation(q:Quaternion) -> void:
	rotation = q


## Gets a component by the string name.
## Example: [codeblock]
## (e.get_component("NPCComponent") as NPCComponent).kill()
## [/codeblock]
func get_component(type:String) -> SKEntityComponent:
	var n = get_node_or_null(type)
	return n


## Whether it has a component type or not. Useful for checking the capabilities of an entity.
func has_component(type:String) -> bool:
	var x = get_component(type)
	return not x == null


func add_component(c:SKEntityComponent) -> void:
	add_child(c)


func save() -> Dictionary: # TODO: Determine if instance is saved to disk. If not, save that as well. This will Theoretically allow for dynamic instances.
	var data:Dictionary = {
		"entity_data": {
			"world" = world,
			"position" = position,
			"unique" = unique
		}
	}
	for c in get_children().filter(func(x:SKEntityComponent): return x.dirty): # filter to get dirty acomponents
		data["components"][c.name] = ((c as SKEntityComponent).save())
	return data


func load_data(data:Dictionary) -> void:
	world = data["entity_data"]["world"]
	position = JSON.parse_string(data["entity_data"]["position"])
	unique = JSON.parse_string(data["entity_data"]["unique"])

	# loop through all saved components and call load
	for d in data["components"]:
		(get_node(d) as SKEntityComponent).load_data(data[d])
	pass


func reset_data() -> void:
	# TODO: Figure out how to reset entities that are generated at runtime. oh boy that's gonna be fun.
	var i = SKEntityManager.instance.get_disk_data_for_entity(name)
	if i:
		_init()


func reset_stale_timer() -> void:
	stale_timer = 0


func broadcast_message(msg:String, args:Array = []) -> void:
	for c in get_children():
		if c.has_method(msg):
			c.call(msg, args)


func dialogue_command(command:String, args:Array) -> void:
	for c in get_children():
		c._try_dialogue_command(command, args)


## Get a preview scene tree from this entity, if applicable. This is used for getting previews for [class SKWorldEntity].
func get_world_entity_preview() -> Node:
	for c:Node in get_children():
		if c.has_method(&"get_world_entity_preview"):
			return c.get_world_entity_preview()
	return null


## Call this when an entity is generated for the first time; eg. a non-unique Spider enemy is spawned.
func generate() -> void:
	for c:Node in get_children():
		c.on_generate()


func gather_debug_info() -> PackedStringArray:
	var info := PackedStringArray()
	info.push_back("""
[b]SKEntity[/b]
	RefID: %s
	FormID: %s
	World: %s
	Position: x%s y%s z%s
	Rotation: x%s y%s z%s
	In scene: %s
""" % [
	name,
	form_id,
	world,
	position.x,
	position.y,
	position.z,
	rotation.x,
	rotation.y,
	rotation.z,
	in_scene
])
	
	for c in get_children():
		var i:String = (c as SKEntityComponent).gather_debug_info()
		if not i.is_empty():
			info.push_back(i)
	
	return info


func _to_string() -> String:
	return "\n".join(gather_debug_info())


## Prints a rich text message to the console prepended with the entity name. Used for easier debugging. 
func printe(text:String, show_stack:bool = true) -> void:
	print_rich("[b]%s[/b]: %s\n%s" % [name, text, _format_stack_trace() if show_stack else ""])


func _format_stack_trace() -> String:
	var trace:Array = get_stack()
	var output := "[indent]"
	for d:Dictionary in trace:
		output += "%s: [url]%s:%d[/url]\n" % [d.function, d.source, d.line]
	return output

```

**entity_component.gd**
```gdscript
class_name SKEntityComponent 
extends Node
## A component that is within an [SKEntity].
## Extend these to add functionality to an entity.
## When inheriting, make sure to call super._ready() if overriding.


## Parent entity of this component.
@onready var parent_entity:SKEntity = get_parent() as SKEntity
## Whether this component should be saved.
var dirty:bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	if Engine.is_editor_hint():
		return 
	
	parent_entity = get_parent() as SKEntity
	if not parent_entity.left_scene.is_connected(_on_exit_scene.bind()):
		parent_entity.left_scene.connect(_on_exit_scene.bind())
	if not parent_entity.entered_scene.is_connected(_on_enter_scene.bind()):
		parent_entity.entered_scene.connect(_on_enter_scene.bind())


func _entity_ready() -> void:
	pass


## Called when the parent entity enters a scene. See [signal SKEntity.entered_scene].
func _on_enter_scene():
	pass


## Called when the parent entity exits a scene. See [signal SKEntity.left_scene].
func _on_exit_scene():
	pass


## Process a dialogue command given to the entity.
func _try_dialogue_command(command:String, args:Array) -> void:
	pass


## Gather data to save.
func save() -> Dictionary:
	return {}


## Load a data blob from the savegame system.
func load_data(data:Dictionary):
	pass


## Gather and format any relevant info for a debug console or some other debugger.
func gather_debug_info() -> String:
	return ""


func _to_string() -> String:
	return gather_debug_info()


## Prints a rich text message to the console prepended with the entity name. Used for easier debugging. 
func printe(text:String, show_stack:bool = true) -> void:
	if parent_entity:
		parent_entity.printe(text, show_stack)
	else:
		(get_parent() as SKEntity).printe(text, show_stack)


## Get the dependencies for this node, for error warnings. Dependencies are the class name as a string.
func get_dependencies() -> Array[String]:
	return []


## Do any first-time setup needed for this component. For example, roll a loot table, randomize facial attributes, etc.
func on_generate() -> void:
	pass


func _get_configuration_warnings() -> PackedStringArray:
	var output := PackedStringArray()
	
	if not (get_parent() is SKEntity or get_parent() is SKElementGroup):
		output.push_back("Component should be the child of an SKEntity or an SKElementGroup.")
	
	for dep:String in get_dependencies():
		if not get_parent().has_node(dep):
			output.push_back("This component needs %s" % dep)
	
	return output

```

**entity_manager.gd**
```gdscript
class_name SKEntityManager
extends Node
## Manages entities in the game.

## The instance of the entity manager.
static var instance: SKEntityManager

var entities: Dictionary = {}
var disk_assets: Dictionary = {}  # TODO: Figure out an alternative that isn't so memory heavy
var regex: RegEx


func _init() -> void:
	instance = self


func _ready():
	regex = RegEx.new()
	regex.compile("([^\\/\n\\r]+)\\.t?scn")
	_cache_entities(ProjectSettings.get_setting("skelerealms/entities_path"))
	SkeleRealmsGlobal.entity_manager_loaded.emit()


## Gets an entity in the game. [br]
## This system follows a cascading pattern, and attempts to get entities by following the following steps. It will execute each step, and if it fails to get an entity, it will move onto the next one. [br]
## 1. Tries to get the entity from its internal hash table of entities. [br]
## 2. Scans its children entities to see if it missed any (this step may be removed in the future) [br]
## 3. Attempts to load the entity from disk. [br]
## Failing all of these, it will return [code]none[/code].
func get_entity(id: StringName) -> SKEntity:
	# stage 1: attempt find in cache
	if entities.has(id):
		(entities[id] as SKEntity).reset_stale_timer()  # FIXME: If another entity is carrying a reference to this entity, then we might break stuff by cleaning it up in this way?
		return entities[id]
	# stage 2: Check in save file
	var potential_data = SaveSystem.entity_in_save(id)  # chedk the save system
	if potential_data.some():  # if found:
		var e:SKEntity = add_entity_from_scene(ResourceLoader.load(disk_assets[id]))  # load default from disk
		e.load_data(potential_data.unwrap())  # and then load using the data blob we got from the save file
		e.reset_stale_timer()
		return e
	# stage 3: check on disk
	if disk_assets.has(id):
		var e:SKEntity = add_entity_from_scene(ResourceLoader.load(disk_assets[id]))
		e.generate() # generate, because the entity has never been seen before
		e.reset_stale_timer()
		return e 

	# Other than that, we've failed. Attempt to find the entity in the child count as a failsave, then return none.
	return get_node_or_null(id as String)


func _cache_entities(path: String):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():  # if is directory, cache subdirectory
				_cache_entities("%s/%s" % [path, file_name])
			else:  # if filename, cache filename
				if ".remap" in file_name:
					file_name = file_name.trim_suffix(".remap")
				var result = regex.search(file_name)
				if result:
					disk_assets[result.get_string(1)] = "%s/%s" % [path, file_name]  # TODO: Check if it's actually an InstanceData
			file_name = dir.get_next()
		dir.list_dir_end()

	else:
		print("An error occurred when trying to access the path.")


# add a new entity.
#func add_entity(res: InstanceData) -> SKEntity:
	#var new_entity = SKEntity.new(res)  # make a new entity
	# add new entity to self, and the dictionary
	#entities[res.ref_id] = new_entity
	#add_child(new_entity)
	#return new_entity


func _add_entity_raw(e: SKEntity) -> SKEntity:
	entities[e.name] = e
	add_child(e)
	return e


## ONLY call after save!!!
func _cleanup_stale_entities():
	# Get all children
	for c in get_children():
		if (
			(c as SKEntity).stale_timer
			>= ProjectSettings.get_setting("skelerealms/entity_cleanup_timer")
		):  # If stale timer is beyond threshold
			remove_entity(c.name)  # remove


## Remove entity from the game.
func remove_entity(rid: StringName) -> void:
	if entities.has(rid):
		entities[rid].queue_free()
		entities.erase(rid)


func add_entity_from_scene(scene:PackedScene) -> SKEntity:
	var e:SKEntity = scene.instantiate()
	if not e:
		push_error("Scene at path %s isn't a valid entity." % scene.resource_path)
	
	if not e.unique:
		var valid: bool = false 
		var new_id: String = ""
		while not valid:
			new_id = SKIDGenerator.generate_id()
			valid = not entities.has(new_id)
			e.generate.call_deferred()
		e.name = new_id
	return _add_entity_raw(e)

```

#### fsm

**fsm_machine.gd**
```gdscript
class_name FSMMachine
extends Node
## Finite State Machine manager.


## The entry node's name.
var initial_state:String
## The current state of the machine.
var state:FSMState


## Emit when it has made a transition. String is the new state name.
signal transitioned(state_name:String)


## Set this FSM up with a list of state nodes.
func setup(states:Array[FSMState]) -> void:
	# add all children
	for s in states:
		s.state_machine = self
		add_child(s)
	owner = get_parent()
	# call on ready
	for c in get_children():
		c.owner = get_parent()
		(c as FSMState).on_ready()
	# transition to initial states
	transition(initial_state)


func _process(delta: float) -> void:
	state.update(delta)


## Transition to a new state by state name. DOes nothing if no state with name found.
func transition(state_name:String, msg:Dictionary = {}) -> void:
	#print("transitioning from %s state to %s" % [state.name if state else "None", state_name])
	if not has_node(state_name):
		return
	
	if state:
		state.exit()
	
	state = get_node(state_name)
	state.enter(msg)
	
	transitioned.emit(state_name)

```

**fsm_state.gd**
```gdscript
class_name FSMState
extends Node
## Abstract class for states for the [FSMMachine].


## Parent state machine.
var state_machine:FSMMachine = null


func _init() -> void:
	name = _get_state_name()


## get this state node's name. Override to work properly.
func _get_state_name() -> String:
	return "State"


## Called when the state machine finishes adding its nodes in [method FSMMachine.setup].
func on_ready() -> void:
	pass


## Same as _process(), but controlled by the machine.
func update(delta:float) -> void:
	pass


## Called when the node is entered. Message can pass some data to this state.
func enter(msg:Dictionary) -> void:
	pass


## Called when this node is exited.
func exit() -> void:
	pass

```

#### granular_navigation

**nav_point.gd**
```gdscript
class_name NavPoint
extends RefCounted
## Point in a world.


var position:Vector3
var world:String


func _init(w:String, pos:Vector3) -> void:
	world = w
	position = pos

```

**navigation_master.gd**
```gdscript
class_name NavMaster
extends Node
## This is the manager for the [b]Granular Navigation System[/b].
## This is a singleton-like object that will find a path through the game's worlds. [br]
## [b]Granular navigation System[/b][br]
## This system is essentially a low-resolution navmesh that allows actors outside of the scene to continue walking around the worlds, so they will be where the player expects them to be.[br]
## The granular navigation system is split up into "worlds", corresponding to the "worlds" of the game. These are roughly analagous to "cells" in Bethesda games.
## Each [NavWorld] contains [NavNode]s as children that are laid out to match the physical space of a world.
## When NPCs are offscreen, instead of using a navmesh, they will attempt to go to their destination by following these nodes.
## This is done to improve performance. However, be sure not to have [i]too[/i] many entities using this at once, otherwise performance may suffer. 
## See project setting [code]skelerelams/granular_navigation_sim_distance[/code] to adjust how far away the actors have to be before they stop using this system and just stay idle.


static var instance:NavMaster
## Dictionary of references to the roots of KD trees.
var worlds:Dictionary = {}


func _ready() -> void:
	GameInfo.game_started.connect(load_all_networks.bind())
	instance = self


func calculate_path(start:NavPoint, end:NavPoint) -> Array[NavPoint]:
	var start_node:NavNode = nearest_point(start)
	var end_node:NavNode = nearest_point(end)
	
	var open_list:Array[NavNode] = [start_node]
	var closed_list:Array[NavNode] = []
	
	var g_score:Dictionary = {start_node:0}
	var f_score:Dictionary = {start_node:_heuristic(start_node, end_node)}
	var came_from:Dictionary = {}
	
	while not open_list.is_empty():
		# sort to find lowest f score descending, pushing the lowest score to the end of the list.
		# sorting descending is an optimization: popping from the front of a large array is slower, since it has to reindex everything.
		open_list.sort_custom(func(a:NavNode, b:NavNode): 
			# Lazy add heuristics to f_score
			if not f_score.has(a):
				f_score[a] = _heuristic(a, end_node) + g_score[a]
			if not f_score.has(b):
				f_score[b] = _heuristic(b, end_node) + g_score[b]
				
			if f_score[a] == f_score[b]:
				return g_score[a] > g_score[b]
			else:
				return f_score[a] > f_score[b]
		)
		var current:NavNode = open_list.pop_back() # pop from end of list to get lowest f value
		
		for c in current.connections:
			# if connection already closed, skip
			if closed_list.has(c):
				continue
			
			came_from[c] = current # set path parent
			
			# If connection is the end node, we found a path.
			if c == end_node:
				return _reconstruct_path(came_from, c)
			
			open_list.append(c) # add to current
			
			# update G score from previosu to 
			g_score[c] = g_score[current] + current.connections[c]
		
		closed_list.append(current)
	
	return []


func _reconstruct_path(came_from:Dictionary, current:NavNode) -> Array[NavPoint]:
	# potential optimization: Push back and then reverse?
	var path:Array[NavPoint] = [current.nav_point]
	while current in came_from:
		path.push_front(came_from[current].nav_point)
		current = came_from[current]
	return path


func _heuristic(a: NavNode, end:NavNode) -> float:
	# doing the heuristic in this way turns the AStar into Dijkstra unless the nodes are in the same world.
	# this is because, since the worlds are not really euclidean in relation to eachother, it's impossible to find accurate heuristic distances. So we just don't.
	# if we find this too inaccurate, we could keep track of connections between worlds and calculate out heuristics by measuring from door to door. But that's hard.
	if not a.world == end.world:
		return 1000
	else:
		# use squared as a small optimization
		return a.position.distance_squared_to(end.position)


# TODO: load and apply connections
func _load():
	pass


## Recursive descent for the nearest point algorithm.
func _walk_down(n:NavNode, goal:NavPoint, current_closest:NavNode) -> NavNode:
	# set current closest to this if the distance to goal is smaller
	if  n.position.distance_squared_to(goal.position) < current_closest.position.distance_squared_to(goal.position):
		current_closest = n
	# if no children, return current closest
	if not n.left_child and not n.right_child:
		return current_closest
	# make binary decision
	var is_left:bool = goal.position[n.dimension] < n.position[n.dimension]
	if is_left and n.left_child:
		return _walk_down(n.left_child, goal, current_closest)
	elif not is_left and n.right_child:
		return _walk_down(n.right_child, goal, current_closest)
	# if there's no child in the selected direction, return current closest
	else:
		return current_closest



## Find the nav node closest to a given point.
func nearest_point(pt:NavPoint) -> NavNode:
	if not worlds.has(pt.world):
		return null
	
	var root = worlds[pt.world].get_child(0)
	var current_closest:NavNode = root # root by default
	# walk down initially
	current_closest = _walk_down(root, pt, current_closest) # walk down the tree initially
	#walk back up the tree, searching other branches if necessary
	var walking_node:NavNode = current_closest
	while walking_node.get_parent() is NavNode:
		var p = walking_node.get_parent() as NavNode
		# Recursively search the other side of the splitting hyperplane if the distance between the query point and the splitting hyperplane is less than the distance between the query point and the closest node found so far
		if abs(p.position[p.dimension] - pt.position[p.dimension]) < walking_node.position.distance_to(current_closest.position):
			if p.left_child == walking_node and p.right_child:
				current_closest = _walk_down(p.right_child, pt, current_closest)
			elif p.right_child == walking_node and p.left_child:
				current_closest = _walk_down(p.left_child, pt, current_closest)
		walking_node = p
	
	return current_closest


func construct_tree(points:Array[NavPoint]):
	# this constructs a KD tree.
	
	# 1) sort into worlds
	var sorted_points:Dictionary = {}
	for n in points:
		# if point world not already created:
		if not sorted_points.has(n.world):
			# create sort array
			sorted_points[n.world] = []
		sorted_points[n.world].append(n) # then append
		
	# 2) for each world, select median point from random selection of nodes and add to tree.
	# the median is semi-important to try to make sure the tree isn't lopsided for faster and more accurate lookups.
	for w in sorted_points:
		var median:NavPoint
		# if >= 5 nodes in world, select random and find median
		if sorted_points[w].size() >= 5:
			# select 5 random points
			var selected:Array[NavPoint] = (func():
				var arr: Array[NavPoint] = []
				for i in range(5):
					arr.append(sorted_points[w].pick_random())
				return arr
			).call()
			# Find median point
			var middle_coords:Vector3 = selected.reduce(func(accum:Array, pt:NavPoint): # first we sum up the point coordinates
				accum[0] += pt.position.x
				accum[1] += pt.position.y
				accum[2] += pt.position.z
			).reduce(func(accum:Vector3, num:float): # then we divide each component
				accum[0] = num / 5
				accum[1] = num / 5
				accum[2] = num / 5
			)
			# then we sort by distance to center point. using quared to avoid a sqrt. Sort descending.
			selected.sort_custom(func(a:NavPoint, b:NavPoint): return middle_coords.distance_squared_to(a.position) > middle_coords.distance_squared_to(b.position))
			median = selected.pop_back()
		else: # else, accumulate all of them
			var arr_size = sorted_points[w].size()
			var middle_coords:Vector3 = sorted_points[w].reduce(func(accum:Array, pt:NavPoint): # first we sum up the point coordinates
				accum[0] += pt.position.x
				accum[1] += pt.position.y
				accum[2] += pt.position.z
			).reduce(func(accum:Vector3, num:float): # then we divide each component
				accum[0] = num / arr_size
				accum[1] = num / arr_size
				accum[2] = num / arr_size
			)
			# then we sort by distance to center point. using quared to avoid a sqrt. Sort descending.
			sorted_points[w].sort_custom(func(a:NavPoint, b:NavPoint): return middle_coords.distance_squared_to(a.position) > middle_coords.distance_squared_to(b.position))
			median = sorted_points[w].pop_back()
		# add median
		add_point(median.world, median.position)
	
	# 3) for each world, add all the rest of the points, going by the median.
	# A bit wasteful, maybe, As before, we want to keep the tree balanced.
	for w in sorted_points:
		var median:NavPoint
		while not sorted_points[w].size() == 0: # while loop here, because 1) gdscript doesnt like you editing an array while looping through it, and we want to empty the array anyway
			var arr_size = sorted_points[w].size()
			var middle_coords:Vector3 = sorted_points[w].reduce(func(accum:Array, pt:NavPoint): # first we sum up the point coordinates
				accum[0] += pt.position.x
				accum[1] += pt.position.y
				accum[2] += pt.position.z
			).reduce(func(accum:Vector3, num:float): # then we divide each component
				accum[0] = num / arr_size
				accum[1] = num / arr_size
				accum[2] = num / arr_size
			)
			# then we sort by distance to center point. using quared to avoid a sqrt. Sort descending.
			sorted_points[w].sort_custom(func(a:NavPoint, b:NavPoint): return middle_coords.distance_squared_to(a.position) > middle_coords.distance_squared_to(b.position))
			median = sorted_points[w].pop_back()
			# add median
			add_point(median.world, median.position)
	
	# Cache references to trees
	for c in get_children():
		worlds[c.name] = c as NavWorld


## Add a point to the tree
func add_point(world:String, pos:Vector3) -> NavNode:
	print("Adding a point at %s in world %s" % [pos, world])
	var world_node: NavWorld = get_node_or_null(world)
	# Add world if it doesnt already exist
	if not world_node:
		world_node = NavWorld.new()
		world_node.world = world
		world_node.name = world
		worlds[world] = world_node
		add_child(world_node)
	
	return world_node.add_point(pos)


func connect_nodes(a:NavNode, b:NavNode, cost:float) -> void:
	a.connect_nodes(b, cost)
	b.connect_nodes(a, cost)


## Build a series of KD Trees from [Netowrk]s. Dictionary assumes the key is the world name, and the value is the network.
func _load_from_networks(data:Dictionary):
	# thank god we use RC instead of GC but this is still memory heavy
	# TODO: COnvert to a system using packed arrays and indices. Will be *far* more memory efficient, but a bit difficult to reason about, which is why I did it this way first.
	# use dictionary to hold the point and the new node it contains, to avoid duplicates and to have lookups later
	var added_nodes = {}
	var edges = []
	var portals = []
	var portal_edges = []
	# add each point from each network
	for world in data:
		print("loading world network %s" % world)
		edges.append_array(data[world].edges)
		portals.append_array(data[world].portals)
		portal_edges.append(data[world].portal_edges)
		
		for point in data[world].points + data[world].portals:
			added_nodes[point] = add_point(world, point.position)
	# then go back and connect edges and portals, using the dictionary as a lookup
	for edge in edges:
		connect_nodes(added_nodes[edge.point_a], added_nodes[edge.point_b], edge.cost)
	for edge in portal_edges:
		if added_nodes.has(edge.portal_from) and added_nodes.has(edge.portal_to):
			connect_nodes(added_nodes[edge.portal_from], added_nodes[edge.portal_to], 0)
		else:
			print("Unable to make portal connection. Ensure that connecting world is loaded.")


func _load_from_disk(path:String, networks:Dictionary, regex:RegEx) -> void:
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if '.tres.remap' in file_name:
				file_name = file_name.trim_suffix('.remap')
			if dir.current_is_dir(): # if is directory, cache subdirectory
				_load_from_disk(file_name, networks, regex)
			else: # if filename, cache filename
				var result = regex.search(file_name)
				if result:
					print("%s/%s" % [path, file_name])
					networks[result.get_string(1) as StringName] = load("%s/%s" % [path, file_name])
			file_name = dir.get_next()
		dir.list_dir_end()


func load_all_networks() -> void:
	print("Loading all networks...")
	var networks = {}
	var path = ProjectSettings.get_setting("skelerealms/networks_path")
	var regex = RegEx.new()
	regex.compile("([^\\/\n\\r]+).tres")
	
	print("Loading from disk...")
	_load_from_disk(path, networks, regex)
	print("Compiling networks...")
	_load_from_networks(networks)
	
	print_tree_pretty()


static func format_point_name(pt:Vector3, world:StringName) -> String:
	return ("%s-%s" % [world, pt]).replace(".", "_")

```

**navigation_node.gd**
```gdscript
class_name NavNode
extends Node3D
## A single navigation node in the granular navigation system.


## The connections/edges this node has to other nodes. [br]
## The structure of this dictionary is: [br]
## [Codeblock]
## connected_node:NavNode, cost:float
## [/Codeblock]
var connections: Dictionary = {}
var dimension:int
var world:String
var left_child:NavNode
var right_child:NavNode
var nav_point:NavPoint:
	get:
		return NavPoint.new(world, position)


# TODO: Figure out connections
func add_nav_node(pos:Vector3) -> NavNode:
	# figure out if the dimension is less or greater than ourselves.
	# equal is treated as greater.
	var is_left:bool = pos[dimension] < position[dimension]
	if is_left:
		# if our left child exists, tell it to add the node.
		if left_child:
			return left_child.add_nav_node(pos)
		else:
			var new_n = NavNode.new()
			new_n.position = pos # set position
			new_n.dimension = (dimension + 1) % 3 # set dimension and wrap to 3 dimensions
			new_n.world = world
			new_n.name = NavMaster.format_point_name(pos, world)
			add_child(new_n)
			left_child = new_n
			return new_n
	else:
		if right_child:
			return right_child.add_nav_node(pos)
		else:
			var new_n = NavNode.new()
			new_n.position = pos
			new_n.dimension = (dimension + 1) % 3
			new_n.world = world
			new_n.name = NavMaster.format_point_name(pos, world)
			add_child(new_n)
			right_child = new_n
			return new_n


func get_closest_point(pos:Vector3) -> NavNode:
	var is_left:bool = pos[get_parent().dimension] < position[get_parent().dimension]
	
	if is_left:
		if left_child: # if we have a left child, call it instead, 
			return left_child.get_closest_point(pos)
		else: # else it's this
			return self
	else:
		if right_child:
			return right_child.get_closest_point(pos)
		else:
			return self


func connect_nodes(other:NavNode, cost:float) -> void:
	connections[other] = cost

```

**navigation_world.gd**
```gdscript
class_name NavWorld
extends Node
## A world of the granular navigation system. [br]


const dimension = 0

@export var world:String


func add_point(pos:Vector3) -> NavNode:
	# if we have no childrenm, add one
	if get_child_count() == 0:
		var new_n = NavNode.new()
		new_n.position = pos # set position
		new_n.dimension = 0
		new_n.world = world
		new_n.name = NavMaster.format_point_name(pos, world)
		add_child(new_n)
		return new_n
	#else, tell that child to add one
	return (get_child(0) as NavNode).add_nav_node(pos)


## Gets closest point in world to a position.
func get_closest_point(pos:Vector3) -> NavNode:
	if get_child_count() == 0:
		return null
	else:
		return (get_child(0) as NavNode).get_closest_point(pos)

```

#### instance_data

**door_instance.gd**
```gdscript
class_name DoorInstance
extends Resource


@export var world:StringName
@export var position:Vector3
@export var rotation:Vector3

```

#### loottable

##### items

**lt_item.gd**
```gdscript
class_name SKLTItem
extends SKLootTableItem


@export var data:PackedScene


func resolve() -> SKLootTable.LootTableResult:
	return SKLootTable.LootTableResult.new([data], {})

```

**lt_item_entity.gd**
```gdscript
class_name SKLTItemEntity
extends SKLootTableItem


## The unique entity to put in the inventory.
@export var item:PackedScene


func resolve() -> SKLootTable.LootTableResult:
	var id:StringName = item._bundled.names[0]
	return SKLootTable.LootTableResult.new([], {}, [id])

```

**lt_itemchance.gd**
```gdscript
class_name SKLTItemChance
extends SKLootTableItem


@export var item:PackedScene
@export_range(0.0, 1.0) var chance:float = 1.0


func resolve() -> SKLootTable.LootTableResult:
	if randf() > chance:
		return SKLootTable.LootTableResult.new([item], {})
	else:
		return SKLootTable.LootTableResult.new()

```

**lt_itementry.gd**
```gdscript
class_name SKLTItemEntry
extends SKLootTableItem


@export var item:PackedScene


func resolve() -> SKLootTable.LootTableResult:
	return SKLootTable.LootTableResult.new([item], {})

```

**lt_loottablecurrency.gd**
```gdscript
class_name SKLTCurrency
extends SKLootTableItem


@export var currency:StringName = &""
@export_range(0, 100, 1, "or_greater") var amount_min:int = 0
@export_range(0, 100, 1, "or_greater") var amount_max:int = 10


func resolve() -> SKLootTable.LootTableResult:
	return SKLootTable.LootTableResult.new([], {currency: amount_min if amount_max <= amount_min else randi_range(amount_min, amount_max)})

```

**lt_on_condition.gd**
```gdscript
class_name SKLTOnCondition
extends SKLootTableItem


@export_multiline var condition:String = ""
var items:SKLootTable


func _ready() -> void:
	items = get_child(0)


func resolve() -> SKLootTable.LootTableResult:
	if not _check_condition():
		return SKLootTable.LootTableResult.new()
	
	var o:SKLootTable.LootTableResult = SKLootTable.LootTableResult.new()
	for i:SKLootTableItem in items.items:
		o.concat(i.resolve())
	return o


func _check_condition() -> bool:
	if condition == "":
		return false
	
	var e:Expression = Expression.new()
	
	var err:int = e.parse(condition)
	if not err == 0:
		print("Loot table script error: %s" % e.get_error_text())
		return false
	
	var res = e.execute()
	
	if e.has_execute_failed():
		print("Loot table script execution failed.")
		return false
	if res == null:
		return false
	if res is bool:
		return res
	else:
		print("Loot table script warning: Expression should return boolean value.")
		return true

```

**lt_xofitems.gd**
```gdscript
class_name SKLTXOfItem
extends SKLootTableItem


@export_range(0, 100, 1, "or_greater") var x_min:int = 1
@export_range(0, 100, 1, "or_greater") var x_max:int = 0
var items: SKLootTable


func _ready() -> void:
	items = get_child(0)


func resolve() -> SKLootTable.LootTableResult:
	var x = randi_range(x_min, x_min if x_max <= x_min else x_max)
	if items.size() == 0 or x == 0:
		return SKLootTable.LootTableResult.new()
	
	var output:SKLootTable.LootTableResult = SKLootTable.LootTableResult.new()
	var i:int = 0
	while output.size() < x:
		output.concat(items.items[i].resolve())
		i += 1
		if i >= items.size():
			i = 0
	output.items = output.items.slice(0, x)
	return output

```

#### loottable

**skloottable.gd**
```gdscript
class_name SKLootTable
extends Node


## This is a loot table. It can resolve into a collection of items and currencies.


var items:Array[SKLootTableItem] = []


func _ready() -> void:
	items.resize(get_child_count())
	for c:Node in get_children():
		items.append(c)


## Generate all members of the loot table. Returns a dictionary shaped like {&"items":Array[ItemData], &"currencies":{name:amount,...}}
func resolve() -> Dictionary:
	var output:LootTableResult = LootTableResult.new()
	for i:SKLootTableItem in items:
		output.concat(i.resolve())
	return output.to_dict()


class LootTableResult:
	extends RefCounted
	
	
	var items: Array[PackedScene] = []
	var currencies: Dictionary = {}
	var entities: Array[StringName] = []
	
	
	func _init(i:Array[PackedScene] = [], c:Dictionary = {}, e:Array[StringName] = []) -> void:
		items = i
		currencies = c
		entities = e
	
	
	func concat(other:LootTableResult) -> void:
		items.append_array(other.items)
		for c:StringName in other.currencies:
			if currencies.has(c):
				currencies[c] += other.currencies[c]
			else:
				currencies[c] = other.currencies[c]
		for id:StringName in other.entities:
			if not entities.has(id):
				entities.append(id)
	
	
	func to_dict() -> Dictionary:
		return {
			&"items": items,
			&"currencies": currencies,
			&"entities": entities,
		}

```

**skloottableitem.gd**
```gdscript
class_name SKLootTableItem
extends Node


func resolve() -> SKLootTable.LootTableResult:
	return SKLootTable.LootTableResult.new()

```

#### map

**map_drawer.gd**
```gdscript
extends Node2D
## Rysuje tło i dekoracje mapy.

func _draw():
	# Tło — gradient niebo
	var sky_top = Color(0.4, 0.7, 1.0)
	var sky_bottom = Color(0.7, 0.85, 1.0)
	for y in range(-120, 100, 2):
		var t = inverse_lerp(-120, 100, y)
		var col = sky_top.lerp(sky_bottom, t)
		draw_line(Vector2(-220, y), Vector2(220, y), col, 2.0)

	# Chmurki
	_draw_cloud(Vector2(-140, -90), 0.8)
	_draw_cloud(Vector2(80, -100), 1.0)
	_draw_cloud(Vector2(-30, -80), 0.6)
	_draw_cloud(Vector2(160, -85), 0.7)

	# Trawa na ziemi
	var grass_color = Color(0.3, 0.7, 0.2)
	draw_rect(Rect2(-192, 84, 384, 6), grass_color)

	# Krzewy dekoracyjne
	_draw_bush(Vector2(-150, 82))
	_draw_bush(Vector2(-50, 82))
	_draw_bush(Vector2(100, 82))
	_draw_bush(Vector2(160, 82))

func _draw_cloud(pos: Vector2, size: float):
	var col = Color(1, 1, 1, 0.7)
	draw_circle(pos, 8 * size, col)
	draw_circle(pos + Vector2(-6, 2) * size, 6 * size, col)
	draw_circle(pos + Vector2(6, 2) * size, 6 * size, col)
	draw_circle(pos + Vector2(0, 4) * size, 5 * size, col)

func _draw_bush(pos: Vector2):
	var col = Color(0.2, 0.55, 0.15, 0.8)
	draw_circle(pos, 5, col)
	draw_circle(pos + Vector2(-4, 1), 4, col)
	draw_circle(pos + Vector2(4, 1), 4, col)

```

#### misc

**animation_controller.gd**
```gdscript
class_name AnimationController
extends Node

## This is a basic abstraction layer for animations. Use of this is purely optional.
## Place this node just under a puppet node, and connect various other nodes meant to control different aspects of animation somewhere beneath it in the tree,
## And have them subscribe to the signals here to receive animation events from the puppet.


signal value_set(key:StringName, value:Variant)
signal triggered(key:StringName)
signal swapped(now_true:StringName, now_false:StringName)


var root_motion_callback:Callable = func(): return Vector3(0,0,0)
var root_rotation_callback:Callable = func(): return Vector3(0,0,0)
var root_scale_callback:Callable = func(): return Vector3(0,0,0)


func set_value(key:StringName, value:Variant) -> void:
	value_set.emit(key, value)


func trigger(key:StringName) -> void:
	triggered.emit(key)


func swap(now_true:StringName, now_false:StringName) -> void:
	swapped.emit(now_true, now_false)


## Use this to find the controller in the tree.
static func get_animator(n: Node) -> AnimationController:
	if n.get_parent() == null:
		return null
	
	for x in n.get_parent().get_children():
		if x is AnimationController:
			return x
	
	return get_animator(n.get_parent())

```

**audio_emitter.gd**
```gdscript
class_name AudioEventEmitter
extends Node3D
## Used to emit sounds that should have an effect on other things, like alerting NPCs.
## Put this beneath some sort of audio emitter, and link signals.


@export var ignore_self:bool = false


## Finds every node of group "audio_listener" in a radius of unit_size using a physics shape cast, and attempts to call method "heard_audio" on it, passing self as an argument.
func send_play_event(range:float):
	# TODO: Make it less physics based?
	var space_state = get_world_3d().direct_space_state # get space state
	# create query
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = SphereShape3D.new()
	# create query position
	var t = Transform3D()
	t.origin = position
	t.scaled(Vector3(range, range, range)) # scale to match radius
	query.transform = t
	# make query
	var res = space_state.intersect_shape(query)
	# if ignoring self, filter out all nodes part of this tree
	if ignore_self:
		res = res.filter(func(x:Dictionary):
			return not (x["collider"] as Node).is_ancestor_of(self) and not (x["collider"] as Node).find_child(self.name)
		)
	res.filter(func(x:Node): return x.is_in_group("audio_listener"))
	# return results, where all colliders are selected from it.
	for n in  res.map(func(x:Dictionary): return x["collider"] as Node)\
			.filter(func(x:Node): return x.has_method("heard_audio")):
		n.heard_audio(self)

```

**damage_info.gd**
```gdscript
class_name DamageInfo
extends RefCounted
## The effects of a damage event.
## Read the tutorial for how to use these.
## @tutorial(Damage Effects): https://github.com/SlashScreen/skelerealms/wiki/Damage-Effects


## Who caused the damage?
var offender:String
## The different kinds of damage.
var damage_effects:Dictionary
## Optional spell effects.
var spell_effects:Array[StringName] = []
## Optional extra info.
var info:Dictionary = {}


func _init(offender:String, damage_effects:Dictionary, spell_effects:Array[StringName] = [], info:Dictionary = {}) -> void:
	self.offender = offender
	self.damage_effects = damage_effects
	self.spell_effects = spell_effects
	self.info = info

```

**device_emitter.gd**
```gdscript
class_name DeviceEmitter
extends Node


@export var device_name:StringName


func emit_state(state:Variant) -> void:
	DeviceNetwork.update_device_state(device_name, state)

```

**device_listener.gd**
```gdscript
extends Node


@export var device_name:StringName

```

**device_network.gd**
```gdscript
extends Node
## Singleton used for coordinating dungeon puzzle elements.


## Signal called when a device is updated. See [method update_device_state].
signal device_state_changed(device:StringName, value:Variant)


## Signal a device being updated. See [signal device_state_changed].
func update_device_state(device:StringName, value:Variant) -> void:
	device_state_changed.emit(device, value)

```

**element_group.gd**
```gdscript
class_name SKElementGroup
extends Node


func _enter_tree() -> void:
	while get_child_count() > 0:
		get_child(0).reparent(get_parent())
	queue_free()

```

**hit_detector.gd**
```gdscript
class_name HitDetector
extends Area3D
## Hit detector used for melee weapons.


var active:bool ## Whether this should listen for collisions
var collision_callback:Callable ## A callable this should use to pass information back.


func _ready() -> void:
	body_entered.connect(func(body:Node3D) -> void:
		if active:
			collision_callback.call(body)
		)


func activate(cback:Callable) -> void:
	collision_callback = cback
	active = true


func deactivate() -> void:
	active = false

```

**id_generator.gd**
```gdscript
@tool
class_name SKIDGenerator
extends RefCounted


const CHARACTERS: String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_"


static func generate_id(length:int = 10) -> String:
	var output := ""
	
	for _i:int in length:
		output += CHARACTERS[randi_range(0, CHARACTERS.length() - 1)]
	
	return output

```

**npc_template_option.gd**
```gdscript
class_name NPCTemplateOption
extends Resource


@export var template:PackedScene
@export_range(0, 1) var chance:float = 1


func resolve() -> bool:
	return randf() <= chance

```

**option.gd**
```gdscript
class_name Option
extends RefCounted
## A crude implementation of an option/maybe type.
## May get rid of this, because it adds complexity to replicate features that nullability kind of already does...


var _data:Variant


## Make a new option containing data.
static func from(d:Variant) -> Option:
	var op: Option = Option.new()
	op._data = d
	return op


## Make a new Option containing nothing.
static func none() -> Option:
	var op: Option = Option.new()
	op._data = null
	return op


## Wrap any value as an option. If it's null, it's none.
static func wrap(data:Variant) -> Option:
	if data:
		return from(data)
	else:
		return none()


## Whether it has something in it.
func some() -> bool:
	return _data != null


## Get the data from within. May be null.
func unwrap() -> Variant:
	return _data


## Call a function on this option if it contains a value. The argument is the unwrapped contents. 
func bind(fn:Callable) -> Variant:
	if some():
		return fn.call(unwrap())
	else:
		return Option.none()


## Return a specified value if the option is none.
func orelse(v:Variant) -> Variant:
	if some():
		return _data
	else:
		return v

```

**skconfig.gd**
```gdscript
@tool
class_name SKConfig
extends Resource


## This resource is needed to configure some Skelerealms behavior without changing code in the addon scripts itself.
## This should be given to an [class SKEntityManager] to be used.


## The equipment slots available to the equipment.
@export var equipment_slots:Array[StringName]
## Default skills for [class SkillsComponent]s.
@export var skills:Dictionary = {}
## Default attributes for [class AttributesComponent]s.
@export var attributes:Dictionary = {}
## Status effects that will be registered when the game starts.
@export var status_effects:Array[StatusEffect] = []
## The formula for determining the amount of XP needed for a skill to level up, in GDScript. The given skill level is the current skill level, 
## and the formula's result (int) is the XP needed to raise to the next level.
## Inputs: skill_level (int)
## Outputs: int
@export_multiline var skill_xp_formula:String
## The formula for determining the amount of XP needed for a character to level up, in GDScript. The given character level is the current character level, 
## and the formula's result (int) is the XP needed to raise to the next level
## Inputs: character_level (int)
## Outputs: int
@export_multiline var character_xp_formula:String
## The compiled skill xp check expression.
var compiled_skill:Expression
## The compiles character xp check expression.
var compiled_character:Expression


func compile() -> void:
	compiled_skill = Expression.new()
	var err:Error = compiled_skill.parse(skill_xp_formula, PackedStringArray(["skill_level"]))
	if not err == 0:
		push_error("Skill level expression compilation failed: ", compiled_skill.get_error_text(), " - Check your SKConfig resource.")
		return
	
	compiled_character = Expression.new() 
	err = compiled_character.parse(character_xp_formula, PackedStringArray(["character_level"]))
	if not err == 0:
		push_error("Character level expression compilation failed: ", compiled_character.get_error_text(), " - Check your SKConfig resource.")


## Compute the skill xp needed to level up.
func compute_skill(level: int) -> int:
	var res:Variant = compiled_skill.execute([level])
	if compiled_skill.has_execute_failed():
		push_error("Skill level expression execution failed: ", compiled_skill.get_error_text(), " - Check your SKConfig resource.")
		return -1
	if not res is int:
		push_error("Skill level expression did not return an integer.")
		return -1
	return res as int


## Compute the character xp needed to level up.
func compute_character(level: int) -> int:
	var res:Variant = compiled_character.execute([level])
	if compiled_character.has_execute_failed():
		push_error("Character level expression execution failed: ", compiled_character.get_error_text(), " - Check your SKConfig resource.")
		return -1
	if not res is int:
		push_error("Character level expression did not return an integer.")
		return -1
	return res as int

```

**skelesave.gd**
```gdscript
class_name Skelesave


const CLASS_LOOKUP = [
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
	3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
	4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
	4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
	0, 0, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
	5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
	6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 8, 7, 7,
	9, 10, 10, 10, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
]
const TRANSITION_LOOKUP = [
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 1, 0, 0, 0, 2, 3, 5, 4, 6, 7, 8,
	0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 5, 5, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 5, 5, 5, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0
]
const ARR_DELIM = 0xFF
const NULL_DELIM = 0xFE
const VALUE_DELIM = 0xFD
const KEY_DELIM = 0xFC
const ARR_START = 0xFB


static func is_valid_utf8(bytes:PackedByteArray) -> bool:
	var last_state:int = 1
	for byte:int in bytes:
		var current_byte_class:int = CLASS_LOOKUP[byte]
		var new_lookup_index:int = last_state * 12 + current_byte_class
		last_state = TRANSITION_LOOKUP[new_lookup_index]
		if last_state == 0:
			return false
	return last_state == 1


static func serialize(data:Dictionary) -> PackedByteArray:
	var output:PackedByteArray = PackedByteArray()
	for d:Variant in data:
		output.append_array(_stringify_value(d))
		output.append(KEY_DELIM)
		output.append_array(_stringify_value(data[d]))
		output.append(VALUE_DELIM)
	return output


static func _stringify_value(data:Variant) -> PackedByteArray:
	if data == null:
		return PackedByteArray([NULL_DELIM])
	elif data is Dictionary:
		return serialize(data)
	elif data is bool:
		return ("true" if data else "false").to_utf8_buffer()
	elif data is int:
		return ("%d" % data).to_utf8_buffer()
	elif data is float:
		return ("%f" % data).to_utf8_buffer()
	elif data is Array:
		var output:PackedByteArray = PackedByteArray()
		for i:Variant in data:
			output.append_array(_stringify_value(i))
			output.append(ARR_DELIM)
		return output
	else:
		return (data as Object).to_string().to_utf8_buffer()


static func deserialize(data:PackedByteArray) -> Dictionary:
	var output:Dictionary = {}
	var pos:int = 0
	var current_phrase:PackedByteArray = PackedByteArray()
	var current_array:Array = []
	var current_key:String = ""
	var current_value:Variant = null

	while pos < data.size():
		match data[pos]:
			KEY_DELIM:
				current_key = current_phrase.get_string_from_utf8()
				current_phrase.clear()
			VALUE_DELIM:
				current_value = _decode_value(current_phrase)
				current_phrase.clear()
			_:
				current_phrase.append(data[pos])
	return output


static func _decode_value(data:PackedByteArray) -> Variant:
	if data[0] == NULL_DELIM:
		return null
	if data.has(KEY_DELIM):
		return deserialize(data)
	if data.has(ARR_DELIM):
		var output = []
		var current_member:PackedByteArray = PackedByteArray()
		# TODO: array
		for i:int in range(data.size()):
			match data[i]:
				ARR_DELIM:
					output.append(_decode_value(current_member))
					current_member.clear()
				_:
					current_member.append(data[i])
		return output # TODO
	var stringified:String = data.get_string_from_utf8()
	if stringified == "true":
		return true
	if stringified == "false":
		return false
	if stringified.is_valid_int():
		return stringified.to_int()
	if stringified.is_valid_float():
		return stringified.to_float()
	return stringified

```

**status_effect.gd**
```gdscript
class_name StatusEffect
extends Resource


## Base class for all status effects.


## The name of this effect.
@export var name:StringName
## The tags this status effect has.
@export var tags:Array[StringName] = []
## Status effects that this status effect will remove when applied to an entity.
## For example, the "wet" effect will negate the "burning" effect.
@export var negates:Array[StringName] = []
## Status effects with these tags will be removed when this status effect is applied.
## For example, the "muddy" and "slimy" effects may have a "dirty" tag. The "wet" effect
## would remove the "dirty" tag.
@export var negates_tags:Array[StringName] = []
## If an entity has an effect on this list, this effect will not be applied.
@export var incompatible:Array[StringName] = []
## If there are any effects with this tag on the entity, this status effect will not be applied.
@export var imcompatible_tags:Array[StringName] = []


## Called every frame as the effect is active.
func on_update(delta:float, target: StatusEffectHost) -> void:
	pass


## Called when the effect first begins.
func on_start_effect(target: StatusEffectHost) -> void:
	pass


## Called when the effect ends.
func on_end_effect(target: StatusEffectHost) -> void:
	pass

```

**status_effect_host.gd**
```gdscript
class_name StatusEffectHost
extends Node


## This class holds and processes [class StatusEffect]s - Updating them, resolivng tag comflicts, so on. It can work by itself, but it's intended to be the child
## of some kind of "vessel", which can handle [signal message_broadcast] to carry out the will of status effects. That sounds philosophical, but it isn't (unless you want it to be).


## The effects applied to this host. Shape is {StringName:[class StatusEffect]}.
var effects:Dictionary = {}
## The effects are also organized by tag, for optimization purposes. The shape is {StringName:Array\[[class StatusEffect]\]}.
var tag_map:Dictionary = {}
## This signal is listened to by a host's vessel (by default, [class EffectsComponent] and [class EffectsObject]), which will relay the message to other nodes.
## THis is called from the effects if they want to make changes to the object they are attached to.
signal message_broadcast(what:StringName, args:Array)


func _process(delta: float) -> void:
	for e:StatusEffect in effects.values():
		e.on_update(delta, self)


## Add an effect to this host. It will scan the registered effects (See [member SkeleRealmsGlobal.status_effects]) and add the registered effect.
## It will also resolve all tag conflicts as well. If it cannot add the effect due to a tag conflict, or if it already has that effect, it will silently fail. If no effect is found in the database,
## it will push an error.
func add_effect(what:StringName) -> void:
	# check if has already
	if effects.has(what):
		return
	
	if SkeleRealmsGlobal.status_effects.has(what):
		var ne:StatusEffect = (SkeleRealmsGlobal.status_effects[what] as StatusEffect).duplicate()
		# Check incompatibilities
		for x:StringName in ne.incompatible:
			if effects.has(x):
				return
		for x:StringName in ne.incompatible_tags:
			if tag_map.has(x) and not tag_map[x].is_empty():
				return
		# Check negates
		for x:StringName in ne.negates:
			if effects.has(x):
				remove_effect(x)
		for x:StringName in ne.negates_tags:
			var to_remove:Array = tag_map[x].map(func(e:StatusEffect) -> StringName: return e.name)
			for i:StringName in to_remove:
				remove_effect(i)
		# Add effect
		effects[what] = ne
		ne.on_start_effect(self)
	else:
		push_error("No status effect \"%s\" registered." % what)


## Remove an effect by its name. If there is no effect by this name, it will silently fail.
func remove_effect(e:StringName) -> void:
	if not effects.has(e):
		return
	var to_remove:StatusEffect = effects[e]
	to_remove.on_end_effect(self)
	for t:StringName in to_remove.tags:
		tag_map[t].erase(to_remove)
	effects.erase(e)


## Used by status effects to broadcast messages to a hosts' node tree.
## For example, broadcasting "damage" from a host attached to an entity could cause it to be damaged,
## if it has a [class DamageableComponent].
func send_message(what:StringName, args:Array) -> void:
	message_broadcast.emit(what, args)


func has_effect_with_tag(tag:StringName) -> bool: 
	if not effects.has(tag):
		return false 
	if effects[tag].is_empty():
		return false
	return true


func has_effect(effect:StringName) -> bool:
	return effects.has(effect)

```

#### multiplayer

**multiplayermanager.gd**
```gdscript
# =====================================================================
# Tabliczka Znamionowa Skryptu
# Data: 2026-04-07
# Opis: Skrypt zarządzający trybem wieloosobowym (ENet)
# Gdzie uruchomić: Silnik Godot 4
# Docelowa maszyna: Dowolny OS / Serwer dedykowany
# Wymagane uprawnienia: Brak (standardowe prawa aplikacji)
# =====================================================================

extends Node

signal connected
signal disconnected
signal message_received(message: String, sender_peer_id: int)
signal player_joined(peer_id: int)
signal player_left(peer_id: int)

const MAX_PLAYERS: int = 4
enum Mode { SINGLE_PLAYER, SERVER, CLIENT }

var current_mode: Mode = Mode.SINGLE_PLAYER
var peer_id: int = 0
var multiplayer_peer: ENetMultiplayerPeer
var connected_players: Dictionary = {}

@export var host_address: String = "127.0.0.1"
@export var port: int = 7777

func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func start_single_player() -> void:
	disconnect_network()
	current_mode = Mode.SINGLE_PLAYER
	peer_id = 1
	connected_players = {peer_id: "Gracz Lokalny"}
	connected.emit()
	player_joined.emit(peer_id)

func start_server() -> void:
	disconnect_network()
	multiplayer_peer = ENetMultiplayerPeer.new()
	var error: Error = multiplayer_peer.create_server(port, MAX_PLAYERS)
	if error != OK:
		printerr("Błąd przy tworzeniu serwera: ", error)
		return

	multiplayer.multiplayer_peer = multiplayer_peer
	multiplayer_peer.peer_connected.connect(_on_peer_connected)
	multiplayer_peer.peer_disconnected.connect(_on_peer_disconnected)
	
	peer_id = 1
	current_mode = Mode.SERVER
	connected_players = {peer_id: "Serwer"}
	
	connected.emit()
	player_joined.emit(peer_id)

func start_client(address: String = host_address, server_port: int = port) -> void:
	disconnect_network()
	multiplayer_peer = ENetMultiplayerPeer.new()
	var error: Error = multiplayer_peer.create_client(address, server_port)
	if error != OK:
		printerr("Błąd przy tworzeniu klienta: ", error)
		return
		
	multiplayer.multiplayer_peer = multiplayer_peer
	multiplayer_peer.peer_disconnected.connect(_on_peer_disconnected)

func disconnect_network() -> void:
	if multiplayer_peer != null:
		multiplayer_peer.close()
		multiplayer_peer = null
		multiplayer.multiplayer_peer = null
		
	current_mode = Mode.SINGLE_PLAYER
	peer_id = 0
	connected_players.clear()
	disconnected.emit()

func broadcast(message: String) -> void:
	if current_mode == Mode.SINGLE_PLAYER:
		receive_message(message)
	elif multiplayer_peer != null:
		rpc("receive_message", message)

@rpc("any_peer", "call_local", "reliable")
func receive_message(message: String) -> void:
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = peer_id
	message_received.emit(message, sender_id)

func send_to_player(player_id: int, message: String) -> void:
	if multiplayer_peer != null:
		rpc_id(player_id, "receive_message", message)

func _on_peer_connected(new_peer_id: int) -> void:
	connected_players[new_peer_id] = "Gracz %d" % new_peer_id
	player_joined.emit(new_peer_id)

func _on_peer_disconnected(disconnected_peer_id: int) -> void:
	if connected_players.has(disconnected_peer_id):
		connected_players.erase(disconnected_peer_id)
		player_left.emit(disconnected_peer_id)

func _on_connection_failed() -> void:
	disconnect_network()

func _on_server_disconnected() -> void:
	disconnect_network()

func _on_connected_to_server() -> void:
	peer_id = multiplayer.get_unique_id()
	current_mode = Mode.CLIENT
	connected_players = {peer_id: "Ty (Klient)"}
	connected.emit()

```

#### network

##### Editor

**cost_popup.gd**
```gdscript
@tool
extends ConfirmationDialog


signal popup_accepted(text:String)


func _ready() -> void:
	get_ok_button().button_up.connect(_accept.bind())
	($LineEdit as LineEdit).text_changed.connect(_check_text.bind())
	

func _accept() -> void:
	popup_accepted.emit(($LineEdit as LineEdit).text)


func _check_text(new_text:String) -> void:
	get_ok_button().disabled = not new_text.is_valid_float()

```

**network_editor_utility.gd**
```gdscript
@tool
class_name NetworkEditorUtility
extends Control


var add_mode:bool
var portal_mode:bool


signal dissolve
signal merge
signal remove
signal link
signal subdivide
signal unlink
signal change_cost_accepted(text:String)


func _ready() -> void:
	$CostWindow.popup_accepted.connect(_on_change_cost_accepted.bind())


func _on_add_toggled(button_pressed:bool) -> void:
	add_mode = button_pressed


func _on_dissolve_pressed() -> void:
	dissolve.emit()


func _on_merge_pressed() -> void:
	merge.emit()


func _on_remove_pressed() -> void:
	remove.emit()


func _on_link_pressed() -> void:
	link.emit()


func _on_subdivide_pressed() -> void:
	subdivide.emit()


func _on_portal_toggled(button_pressed:bool) -> void:
	portal_mode = button_pressed


func reset_portal_mode() -> void:
	($"Box/Portal" as Button).button_pressed = false # will call signal automatically


func _on_unlink_pressed() -> void:
	unlink.emit()


func _on_change_cost_pressed() -> void:
	$CostWindow.popup_centered()


func _on_change_cost_accepted(text:String) -> void:
	change_cost_accepted.emit(text)

```

**network_gizmo.gd**
```gdscript
class_name NetworkGizmo
extends EditorNode3DGizmoPlugin


const RAY_LENGTH:float = 500

## Association of handle index to associated point.
var handle_associations:Array[NetworkPoint] = []
## The most recent selected point.
var last_modified:NetworkPoint:
	get:
		return last_modified
	set(val):
		# Prevent spam by checking if val is different
		if last_modified == val:
			return
		second_last_modified = last_modified # move value to the second last modified
		last_modified = val
## Second last point that was selected.
var second_last_modified:NetworkPoint

var _plugin:EditorPlugin


func _init() -> void:
	create_material("edge", Color(0, 1, 0)) # Edge color
	create_material("point_unselected", Color(0, 0, 1)) # Color for normal points
	create_material("point_select0", Color(1, 0, 0)) # Color for recently selected points
	create_material("point_select1", Color(1, 1, 0)) # Color for second most recently selected points
	create_handle_material("handles")


func _get_gizmo_name() -> String:
	return "Network"


func _has_gizmo(for_node_3d: Node3D) -> bool:
	return for_node_3d is NetworkInstance


func _redraw(gizmo: EditorNode3DGizmo) -> void:
	gizmo.clear()

	if gizmo.get_node_3d().network.points.size() == 0:
		return

	# For each node:
	var mesh = SphereMesh.new()

	# Handle stuff
	var handle_pts = PackedVector3Array()
	handle_associations.clear() # Clear the array
	handle_associations.resize(gizmo.get_node_3d().network.points.size()) # Set associations size so we can just set indexes
	var handle_idx:Array[int] = [] # We use these to assign indexes when adding the handles. Theoretically it would be fine without this but we want to be sure
	var idx:int = 0

	for n in gizmo.get_node_3d().network.points:
		# set transform
		var t = Transform3D()
		t = t.scaled(Vector3(0.1, 0.1, 0.1))
		t.origin = n.position
		# Draw node sphere and handle
		handle_pts.append(n.position)
		gizmo.add_mesh(CylinderMesh.new() if n is NetworkPortal else mesh, _get_material_for_point(n, gizmo), t)
		# Handle indexes
		handle_associations[idx] = n
		handle_idx.append(idx)
		idx += 1
	
	# Then for each edge:
	var pts = PackedVector3Array()
	for e in gizmo.get_node_3d().network.edges:
		# Add line points
		pts.append(e.point_a.position)
		pts.append(e.point_b.position)
	
	# Then draw lines
	gizmo.add_lines(pts, get_material("edge", gizmo))

	# Add handles
	gizmo.add_handles(handle_pts, get_material("handles", gizmo), handle_idx)


func _set_handle(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool, camera: Camera3D, screen_pos: Vector2) -> void:
	# get associated point
	var pt = handle_associations[handle_id]
	# Create ray
	var from = camera.project_ray_origin(screen_pos)
	var to = from + (camera.project_ray_normal(screen_pos) * RAY_LENGTH)
	var ray = PhysicsRayQueryParameters3D.create(from, to)
	# Wait to be able to get physics info
	await gizmo.get_node_3d().get_tree().physics_frame
	# Cast ray
	var hits = gizmo.get_node_3d().get_world_3d().direct_space_state.intersect_ray(ray)
	if hits:
		pt.position = hits["position"] as Vector3 # Set point position to handle
		last_modified = pt # set last modified
		_redraw(gizmo) # TODO: Don't update the whole thing (?)


func _commit_handle(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool, restore, cancel: bool) -> void:
	# print("Commit handle %s that has restore %s " % [handle_id, restore])
	# get associated point
	var pt = handle_associations[handle_id]
	# restore if cancel
	if cancel:
		#pt.position = restore
		return
	

	""" var ur = _plugin.get_undo_redo()
	ur.create_action("Move Network Point")
	ur.add_do_property(pt, "position", pt.position)
	ur.add_undo_property(pt, "position", restore)
	ur.commit_action() """


## Get the material for the point. This changed the material based on how recently it was selected.
func _get_material_for_point(pt:NetworkPoint, gizmo: EditorNode3DGizmo) -> Material:
	# If last modified
	if last_modified == pt:
		return get_material("point_select0", gizmo)
	# If second last modified
	if second_last_modified == pt:
		return get_material("point_select1", gizmo)
	# Else unselected
	return get_material("point_unselected", gizmo)

```

##### Scripts

**network.gd**
```gdscript
@tool
class_name Network
extends Resource
## This is the network graph itself, containing nodes and edges.


## The points in this network.
@export var points:Array[NetworkPoint] = []
## The edges in this network.
@export var edges:Array[NetworkEdge] = []
## This dictionary contains an array (value) of edges that involve a point (key).
@export var edge_map:Dictionary = {}
## The portals this network has.
@export var portals:Array[NetworkPortal] = []
## Connections between worlds
@export var portal_edges:Array[PortalEdge] = []

signal redraw


## Add a point to this network.
func add_point(pt:Vector3, portal:bool = false) -> NetworkPoint:
	# Create edge
	var new_point = NetworkPortal.new(pt) if portal else NetworkPoint.new(pt)
	# Initialize map entry
	edge_map[new_point] = []
	# Add to points
	points.append(new_point)
	if portal:
		portals.append(new_point)

	redraw.emit()
	return new_point


## Remove a point from the network and all associated connections. See [method dissolve_point].
func remove_point(pt:NetworkPoint) -> void:
	points.erase(pt)
	if pt is NetworkPortal:
		portals.erase(pt)
	
	var edges = edge_map[pt].duplicate()
	# Remove all edges involving this node
	for edge in edges:
		remove_edge(edge)
	# Erase all entries in edge map.
	edge_map.erase(pt)
	edges.clear()

	redraw.emit()


## Dissolve a point in the network, connecting all nodes it was connected to together. See [method remove_point].
func dissolve_point(pt:NetworkPoint) -> void:
	# TODO: Cost?
	# Just delete the node if there is 0 or 1 connections, since there's nothing to dissolve
	if edge_map[pt].size() <= 1:
		remove_point(pt)
		return
	# The nodes this point was connected to, so we can connect them to eachother.
	var to_connect = []
	# Loop through edges and get the other point.
	for edge in edge_map[pt]:
		to_connect.append(edge.point_a if edge.point_b == pt else edge.point_b)
	# Remove the point and associated connections
	remove_point(pt)
	# For unique pairs of to connect, connect edge
	for pair in _find_unique_pairs(to_connect):
		add_edge(pair[0], pair[1])
	
	redraw.emit()


## Merge two points together and reconnect all connections.
func merge_points(a:NetworkPoint, b:NetworkPoint) -> NetworkPoint:
	# Create a new node from the average of 2 points
	var new_node = add_point((a.position + b.position)/2)
	# Track other edges to reconnect to the new node
	var to_connect = []

	# Add other side of edges for a
	for edge in edge_map[a]:
		var other = edge.point_a if edge.point_b == a else edge.point_b
		# Skip connections to other node we are merging
		if other == b:
			continue
		
		to_connect.append(other)
	# Add other side of edges for b
	for edge in edge_map[b]:
		var other = edge.point_a if edge.point_b == b else edge.point_b
		# Skip connections to other node we are merging
		if other == a:
			continue
		
		to_connect.append(other)
	
	remove_point(a)
	remove_point(b)

	# Reconnect everything
	for other in to_connect:
		add_edge(new_node, other)

	redraw.emit()
	return new_node


## Add an edge to this network.
func add_edge(a:NetworkPoint, b:NetworkPoint, cost:float = 1, bidirectional:bool = true) -> NetworkEdge:
	# return if it's bidirectional and an edge already exists connecting these nodes
	if bidirectional and find_edge(a, b):
		return null
	# Create edge
	var edge = NetworkEdge.new(a, b, cost, bidirectional)
	# Add this edge to the edge map

	# Add edge maps if they dont exist
	if not edge_map.has(a):
		edge_map[a] = []

	edge_map[a].append(edge)

	if not edge_map.has(b):
		edge_map[b] = []

	edge_map[b].append(edge)
	# Add to edges
	edges.append(edge)

	redraw.emit()
	return edge


## Remove an edge from the network.
func remove_edge(edge:NetworkEdge) -> void:
	# Erase edge map entry on both sides
	edge_map[edge.point_a].erase(edge)
	edge_map[edge.point_b].erase(edge)
	# Erase from edge database
	edges.erase(edge)

	redraw.emit()


## Find an edge that contains both points. Returns null if none found.
func find_edge(a:NetworkPoint, b:NetworkPoint) -> NetworkEdge:
	for edge in edge_map[a]:
		if edge.point_a == a and edge.point_b == b:
			return edge
		if edge.point_a == b and edge.point_b == a:
			return edge

	return null


# Subdivide an edge into a node in the middle of two points, with two edges connecting all 3 nodes.
func subdivide_edge(edge:NetworkEdge) -> NetworkPoint:
	# Add a new node in between them
	var new_node = add_point((edge.point_a.position + edge.point_b.position)/2)

	# Get other connections
	var to_connect = [edge.point_a, edge.point_b]
	
	remove_edge(edge) # remove the bubdivided edge

	# Reconnect everything
	for other in to_connect:
		add_edge(new_node, other)

	redraw.emit()
	return new_node


## Find all unique pairs of an array
func _find_unique_pairs(arr:Array):
	# this sucks lol
	var pairs = {}

	for i in range(arr.size() - 1):
		for j in range(i + 1, arr.size()):
			var pair = [arr[i], arr[j]]
			pair.sort_custom(func(a:NetworkPoint, b:NetworkPoint): return a.position.distance_squared_to(Vector3()) > b.position.distance_squared_to(Vector3())) # make sure [a, b] and [b, a] is the same thing
			pairs[pair] = 1
	
	return pairs.keys()

```

**network_edge.gd**
```gdscript
class_name NetworkEdge
extends Resource


@export var point_a:NetworkPoint
@export var point_b:NetworkPoint
@export var cost:float = 1
@export var bidirectional:bool = true


func _init(a:NetworkPoint = null, b:NetworkPoint = null, cost:float = 1, bidirectional:bool = true) -> void:
	self.point_a = a
	self.point_b = b
	self.cost = cost
	self.bidirectional = bidirectional

```

**network_instance.gd**
```gdscript
@tool
class_name NetworkInstance
extends Node3D


@export var network:Network = Network.new()


func _ready() -> void:
	if not Engine.is_editor_hint():
		queue_free()

```

**network_point.gd**
```gdscript
class_name NetworkPoint
extends Resource


@export var position:Vector3


func _init(pt:Vector3 = Vector3()) -> void:
	position = pt

```

**network_portal.gd**
```gdscript
class_name NetworkPortal
extends NetworkPoint
## A special point that allows you to connect two networks.

```

**portal_edge.gd**
```gdscript
class_name PortalEdge
extends Resource


@export var portal_from:NetworkPortal
@export var portal_to:NetworkPortal

```

#### points

**furniture.gd**
```gdscript
class_name Furniture
extends IdlePoint
## A special IdlePoint abstract class that allows for animastions to be played when occupied.
## Add an [InteractiveObject] node somewhere.
## Does not enable crafting or anything by default, but you can extend it to do that if you want.


## Animation that plays on an actor when furniture is occupied.
@export var animation:Animation

# TODO: Animate the actors
# TODO: Allow for multiple users (use sub points? allow for nested furniture?)

```

**idle_point.gd**
```gdscript
class_name IdlePoint
extends Marker3D


@export var owning_entity:String

var is_occupied:bool:
	get:
		return is_occupied
	set(val):
		if val and not is_occupied:
			occupied.emit()
		elif not val and is_occupied:
			unoccupied.emit()
		is_occupied = val

signal occupied
signal unoccupied


func _ready() -> void:
	add_to_group("idle_points")


func occupy(who:String) -> void:
	is_occupied = true
	owning_entity = who


func unoccupy() -> void:
	is_occupied = false

```

**spawn_point.gd**
```gdscript
class_name NPCSpawnPoint
extends Node3D


## This is used for one-shot spawners; the unique ID of the spawner will be stored in here if it
## spawned its NPC. This is a hash set.
static var spawn_tracker: Dictionary # TODO: Save this
@export var templates: Array[NPCTemplateOption]
@export_enum("One Shot", "Every Time", "Must Be Triggered") var mode:int
@export var despawn_when_exit_scene:bool ## Whether this entity should despawn when it leaves the scene.


func _ready() -> void:
	if is_visible_in_tree():
		_roll()
	else:
		visibility_changed.connect(func(s:bool)->void: if s: _roll())


func _roll() -> void:
	match mode:
		0:
			if not spawn_tracker.has(generate_id()):
				spawn()
		1:
			spawn()


func spawn() -> void:
	# set up entity
	var t := resolve_templates()
	if t == null:
		return
	
	# add that shiz
	spawn_tracker[generate_id()] = true
	var e := SKEntityManager.instance.add_entity_from_scene(t)
	e.rotation = quaternion
	e.generated = true
	if despawn_when_exit_scene:
		e.left_scene.connect(func() -> void: SKEntityManager.instance.remove_entity(e.name))
	
	# resolve loot table
	if t.loot_table:
		for i in t.loot_table.resolve_table_to_instances():
			var ie = SKEntityManager.instance.add_entity(i) # Add entity
			(e.get_component("ItemComponent") as ItemComponent).contained_inventory = e.name # set contained inventory


func reset_spawner() -> void:
	spawn_tracker.erase(generate_id())


## Get a deterministic ID for this spawner.
func generate_id() -> int:
	return get_path().hash()


## Roll and select a template
func resolve_templates() -> PackedScene:
	if templates.size() == 0:
		push_warning("No templates to spawn from.")
		return null
	
	while true:
		for t in templates:
			var res = t.resolve()
			if res:
				return t.template
	return null

```

#### puppets

**item_puppet.gd**
```gdscript
class_name ItemPuppet
extends RigidBody3D


## The puppeteer of this item.
var puppeteer:PuppetSpawnerComponent
## When this is true, the puppet will not sync its position with the puppeteer.
## This is intended to be used for when an item is in an NPCs hand.
## This will turn on by default if the node at "../../" relative to this one is not an entity, although this may change in the future.
## When true, all [CollisionShape3D]s beneath in the heirarchy will be turned off to prevent collisions with whoever is holding it. 
var inactive:bool:
	get:
		return inactive
	set(val):
		inactive = val
		set_collision_state(self, not val)

signal change_position(Vector3)
signal change_rotation(Quaternion)


func _ready():
	if not $"../../" is SKEntity: # TODO: Less brute force method
		inactive = true
		return
	
	puppeteer = $"../../".get_component("PuppetSpawnerComponent")
	change_position.connect((get_parent().get_parent() as SKEntity)._on_set_position.bind())
	change_rotation.connect((get_parent().get_parent() as SKEntity)._on_set_rotation.bind())


func _process(delta):
	if not inactive:
		change_position.emit(position)
		change_rotation.emit(quaternion)


func get_puppeteer() -> PuppetSpawnerComponent:
	if inactive:
		return null
	return puppeteer


func set_collision_state(n:Node, state:bool) -> void:
	if n is CollisionShape3D and not n.get_parent() is HitDetector:
		(n as CollisionShape3D).disabled = not state
	for c in n.get_children():
		set_collision_state(c, state)

```

**npc_puppet.gd**
```gdscript
class_name NPCPuppet
extends CharacterBody3D
## Puppet "brain" for an NPC.


@onready var movement_target_position: Vector3 = position # No world because this agent only works in the scene.
## This is a stealth provider. See the "Sealth Provider" article i nthe documentation for details.
@export var eyes:Node 
var npc_component:NPCComponent
var puppeteer:PuppetSpawnerComponent
var view_dir:ViewDirectionComponent
var movement_speed: float = 1.0
var target_reached:bool:
	get:
		return navigation_agent.is_navigation_finished()

## Called every frame to update the entity's position.
signal change_position(Vector3)

var movement_paused:bool = false
## The navigation agent.
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	call_deferred("_actor_setup")
	add_to_group("perception_target")
	change_position.connect((get_parent().get_parent() as SKEntity)._on_set_position.bind())
	puppeteer = $"../../".get_component("PuppetSpawnerComponent")
	npc_component = $"../../".get_component("NPCComponent")
	view_dir = $"../../".get_component("ViewDirectionComponent")
	if npc_component:
		puppeteer.printe("Connecting percieved event")
		
		npc_component.entered_combat.connect(draw_weapons.bind())
		npc_component.left_combat.connect(lower_weapons.bind())

	else:
		push_warning("NPC Puppet not a child of an entity with an NPCComponent. Perception turned off.")


func get_puppeteer() -> PuppetSpawnerComponent:
	return puppeteer


## Finds the closest point to this puppet, and jumps to it. 
## This is to avoid getting stuck in things that it may have phased into while navigating out-of-scene.
func snap_to_navmesh() -> void:
	position = NavigationServer3D.map_get_closest_point(NavigationServer3D.get_maps()[0], position)


## Set up navigation.
func _actor_setup()  -> void:
	# Wait for the first physics frame so the NavigationServer can sync.
	await get_tree().physics_frame
	snap_to_navmesh() # snap to mesh
	# Now that the navigation map is no longer empty, set the movement target.
	set_movement_target(movement_target_position)


## Set the target for the NPC.
func set_movement_target(movement_target: Vector3) -> void:
	navigation_agent.set_target_position(movement_target)


func pause_nav() -> void:
	movement_paused = true


func continue_nav() -> void:
	movement_paused = false


func _physics_process(delta) -> void:
	npc_component.puppet_request_move.emit(self)


func _process(delta) -> void:
	change_position.emit(position)
	view_dir.view_rot = rotation


func draw_weapons() -> void:
	npc_component.puppet_request_raise_weapons.emit(self)


func lower_weapons() -> void:
	npc_component.puppet_request_lower_weapons.emit(self)

```

#### relationships

**relationship.gd**
```gdscript
class_name Relationship
extends Resource


@export var other_person:String
@export var level:RelationshipLevel = RelationshipLevel.ACQUAINTANCE
@export_category("Optional")
@export var relationship_type:RelationshipAssociation
@export var role:String # gotta figure out how to make it dynamic enum


## Level determining how close the two NPCs are.
enum RelationshipLevel {
	NEMESIS, ## NPC Will always engage on sight.
	ENEMY, ## Depending on combat settings, NPC may engage this level and below on sight.
	FOE, ## Dislike eachother a lot.
	RIVAL, ## Homestuck tells me these also smooch.
	ACQUAINTANCE, ## No real relationship to speak of.
	FRIEND, ## Friendly.
	BFF, ## Closer friend.
	ALLY, ## Depending on NPC behavior settings, may assist this level and above in combat.
	LOVER, ## smouch
}

```

**relationship_association.gd**
```gdscript
class_name RelationshipAssociation
extends Resource


@export var relationship_key:String
@export var relationship_roles:Array[String] = []

```

#### schedules

**continuity_condition.gd**
```gdscript
class_name ContinuityCondition
extends ScheduleCondition

@export var flag:String
@export var value:float

func evaluate() -> bool:
	# return false if doesn't have flag
	if not GameInfo.continuity_flags.has(flag):
		return false
	# return false if values don't match up
	if not GameInfo.continuity_flags[flag] == value:
		return false
	# else return true
	return true

```

**sandbox_schedule.gd**
```gdscript
class_name SandboxSchedule
extends ScheduleEvent
## A "Sandbox" procedure is a term borrowed from Creation Kit games. This is essentially letting the NPC mill about with nothing more important to do.


## Influences how long an NPC will do an activity for. Represents the midpoint of a random range time duration in seconds.
@export var energy:float
@export var can_swim:bool = false
@export var can_sit:bool = true
@export var can_eat:bool = true
@export var can_sleep:bool = true
## Whether this entity can engage in conversdation while idling.
@export var can_engage_conversation:bool = true
@export var use_idle_points:bool = true
@export_category("Location")
## Whether this NPC must be at a certain location to idle. For example: town square, inn.
@export var be_at_location:bool = true
@export var location_position:Vector3
@export var location_world:String
@export var target_radius:float = 25
var _npc:NPCComponent


func get_event_location() -> NavPoint:
	# Idle points found from goap action 
	return NavPoint.new(location_world, location_position)


func satisfied_at_location(e:SKEntity) -> bool:
	# if we dont need to be at location, return true by default
	if not be_at_location:
		return true
	# if world not the same
	if not e.world == location_world:
		return false	
	# if too far away
	if e.position.distance_to(location_position) > target_radius:
		return false
	# else, we passed
	return true


func on_event_started() -> void:
	_npc.add_objective({"perform_idle_point":true}, false, 0)
	_npc.goap_memory["sandbox_schedule"] = self


func on_event_ended() -> void:
	_npc.remove_objective_by_goals({"perform_idle_point":true})
	_npc.goap_memory.erase("sandbox_schedule")


func attach_npc(n:NPCComponent) -> void:
	_npc = n

```

**schedule.gd**
```gdscript
class_name Schedule
extends Node


## Keeps track of the schedule.
## Schedules are roughly analagous to Creation Kit's "AI packages", although limited to time slots.
## It is made up of [ScheduleEvent]s.
## To adjust NPC behavior under circumastances outside of keeping a schedule, see [GOAPComponent] and [ScheduleCondition].


var events:Array[ScheduleEvent]


func _ready() -> void:
	var es:Array[ScheduleEvent] = []
	for n:Node in get_children():
		if n is ScheduleEvent:
			es.append(n)
	events = es 


func find_schedule_activity_for_current_time() -> Option:
	# Scan events
	var valid_events = events.filter(func(ev:ScheduleEvent): return Timestamp.build_from_world_timestamp().is_in_between(ev.from, ev.to)) # get those that are in the time space
	valid_events.sort_custom(func(a:ScheduleEvent, b:ScheduleEvent): return a.priority > b.priority ) # sort descending by priority
	# find first one that is valid
	for ev in valid_events:
		if (ev as ScheduleEvent).condition == null or (ev as ScheduleEvent).condition.evaluate():
			return Option.from(ev)
	# If we make it this far, we didn't find any, return none.
	return Option.none()

```

**schedule_condition.gd**
```gdscript
class_name ScheduleCondition
extends Resource
## base class for schedule conditions that involve finer control.

func evaluate() -> bool:
	return false

```

**schedule_event.gd**
```gdscript
class_name ScheduleEvent
extends Node


## These are the different schedule events that can occupy a schedule.


## From what time?
@export var from:Timestamp
## To what time?
@export var to:Timestamp
## Anmy condition that needs be checked first.
@export var condition:ScheduleCondition
## Schedule priotity.
@export var priority:float


## Get the location this event is at.
func get_event_location() -> NavPoint:
	return null


## Wthether this entity is "at" the event.
func satisfied_at_location(e:SKEntity) -> bool:
	return true


## What to do when the event has begun.
func on_event_started() -> void:
	return


## What to do when the event has ended.
func on_event_ended() -> void:
	return

```

### scripts

**sk_global.gd**
```gdscript
@tool
extends Node
## A singleton that allows any script to access various important nodes without having to deal with scene scope.
## It also has some important utility functions for working with entities.


## World states for the GOAP system.
var world_states:Dictionary
## Status effects registered in the game.
var status_effects:Dictionary = {}
## The SKConfig resource. 
var config:SKConfig 

## Called when the [SKEntityManager] has finished loading.
signal entity_manager_loaded
## When a chest (or other inventory) is opened.
signal inventory_opened(id:StringName)


func _ready() -> void:
	ProjectSettings.settings_changed.connect(_reload_config.bind())
	_reload_config()


func _reload_config() -> void:
	var path:Variant = ProjectSettings.get_setting("skelerealms/config_path")
	
	if path == null:
		return
	if not path is String:
		return
	
	if not ResourceLoader.exists(path):
		config = null
		return 
	
	config = ResourceLoader.load(path)
	
	if Engine.is_editor_hint():
		return
	
	config.compile()
	for se:StatusEffect in config.status_effects:
		SkeleRealmsGlobal.register_effect(se.name, se)


## Attempts to find an entity in the tree above a node. Returns null if none found. Automatically takes account of reparented puppets.
func get_entity_in_tree(child:Node) -> SKEntity:
	var checking = child
	while not checking.get_parent() == null:
		if checking is SKEntity:
			return checking
		
		# Check if puppet and getting puppeteer
		if checking.has_method("get_puppeteer"):
			if checking.get_puppeteer():
				checking = checking.get_puppeteer()
				continue
		
		checking = checking.get_parent()
	
	return null


## Recursively get [RID]s of all children below this node if it is a [CollisionObject3D].
func get_child_rids(child:Node) -> Array:
	var output = []
	
	for c in child.get_children():
		if c is CollisionObject3D:
			output.append(c.get_rid())
		output.append_array(get_child_rids(c))
	
	return output


## Get any damageable node in parent chain or children 1 layer deep; either [DamageableObject] or [DamageableComponent]. Null if none found.
func get_damageable_node(n:Node) -> Node:
	return _walk_for_component(n, "DamageableComponent", func(x:Node): return x is DamageableObject)


## Get any interactible node in parent chain or children 1 layer deep; either [InteractiveObject] or [InteractiveComponent]. Null if none found.
func get_interactive_node(n:Node) -> Node:
	return _walk_for_component(n, "InteractiveComponent", func(x:Node): return x is InteractiveObject)


## Get any spell target node in parent chain or children 1 layer deep; either [SpellTargetObject] or [SpellTargetComponent]. Null if none found.
func get_spell_target_component(n:Node) -> Node:
	return _walk_for_component(n, "SpellTargetComponent", func(x:Node): return x is SpellTargetObject)


## Walks the tree in parent chain above or 1 layer of children below for a node that satisfies one of the following condition:
## - Is an entity with a component of type component_type, returning the component
## - Makes callable wo_check return true
## See [method get_damageable_node] for a use case.
func _walk_for_component(n:Node, component_type:String, wo_check:Callable) -> Node:
	# Check children
	for c in n.get_children():
		if wo_check.call(c):
			return c
	
	# Check for world object in parents
	var checking = n
	while not checking.get_parent() == null:
		if wo_check.call(checking):
			return checking
		
		# Check if puppet and getting puppeteer
		if checking.has_method("get_puppeteer"):
			if checking.get_puppeteer():
				checking = checking.get_puppeteer()
				continue
		
		checking = checking.get_parent()
	
	# Check for entity component
	var e = get_entity_in_tree(n)
	if e:
		var dc = e.get_component(component_type)
		return dc
	
	return null


func register_effect(what:String, eff:StatusEffect) -> void:
	status_effects[what] = eff

```

#### spell_casting

**spell.gd**
```gdscript
class_name Spell
extends Resource
## This the base class for any spell that NPCs can cast.
## This essentially a blank slate, and as this is a GDScript file, a spell can do literally anything, sky is the limit.
## However, with great control comes great responsibility, my uncle once told me. This means you need to deal with basic stuff, like willpower drain, yourself.
## Despite that, it includes a number of helper methods to do the simple stuff. See [method _find_spell_targets_in_range].


## Spell's ID for translation.
@export var spell_name:String
## Custom assets for this spell; particles, floating hand models, whatever.
## You can pack it all in here so you don't have to use load(), but you can still do that if you want to.
@export var spell_assets:Dictionary
## An array of spell effects we can apply to something we hit.
@export var spell_effects:Array[StringName]
## Whether being hit by this spell is to be considered an attack.
@export var aggressive:bool = false
## The spell caster.
var _caster:SpellHand


## When the spell is first cast.
func on_spell_cast():
	pass


## Called every frame as the spell is being held by the player; eg. as the button is being held to blast flames.
## You can use the delta to drain willpower, or whatever.
func on_spell_held(delta):
	pass


## When the spell is released; eg. when the button is released.
## This doesn't just have to cancel the spell, though; perhaps the player needs to hold a spell to choose a target or charge a kamehameha, and then release to cast.
func on_spell_released():
	pass


## Called when the spell needs to be reset to cast again, and also when it is loaded for the first time; so this is also like a _ready() function.
## Only reset your own variables; the variables defined in this parent class will not be re-initialized.
func reset():
	pass


func process(delta:float) -> void:
	pass


func physics_process(delta:float) -> void:
	pass


## Find all nodes in a range of a point, with the results in a dictionary matching a physics query (like raycasting). 
## You can use this for an AOE attack.
## Using ignore_self assumes that the caster's origin defines the root of the actor casting it.
## Only returns 32 results max.
func _find_spell_targets_in_range(pos:Vector3, radius:float, ignore_self:bool = false) -> Dictionary:
	var space_state = _caster.get_world_3d().direct_space_state # get space state
	# create query
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = SphereShape3D.new()
	# create query position
	var t = Transform3D()
	t.origin = pos
	t.scaled(Vector3(radius, radius, radius)) # scale to match radius
	query.transform = t
	# make query
	await _caster.get_tree().physics_frame
	var res = space_state.intersect_shape(query)
	# if ignoring self, filter out all nodes part of this tree
	if ignore_self:
		res = res.filter(func(x:Dictionary):
			return not (x["collider"] as Node).is_ancestor_of(_caster) and not (x["collider"] as Node).find_child(_caster.name)
		)
	# return results, where all colliders are selected from it.
	return res


## Apply a spell effect to an object.
## Only works if target is of type [SpellTargetComponent] or [SpellTargetObject].
func _apply_spell_effect_to(target, effect:StringName):
	# return early if invalid object
	if not target is SpellTargetComponent and not target is SpellTargetObject:
		return
	target.add_effect(effect)


## Casts a ray, and returns anything it hits, with the results in a dictionary matching a physics query (like raycasting). The dictionary is empty if it hits nothing.
## Using ignore_self assumes that the caster's origin defines the root of the actor casting it.
func _raycast(from:Vector3, direction:Vector3, distance:float, ignore_self:bool = false) -> Dictionary:
	var to = from + (direction * distance)
	var ray = PhysicsRayQueryParameters3D.create(from, to)
	var space_state = _caster.get_world_3d().direct_space_state # get space state
	await _caster.get_tree().physics_frame
	var res = space_state.intersect_ray(ray)
	if res.is_empty():
		return {}
	if not res.collider.is_ancestor_of(_caster) and not res.collider.find_child(_caster.name):
		return res
	return {}

```

**spell_effect.gd**
```gdscript
class_name SpellEffect
extends Resource
## Base class for spell effects.


## The target of this spell effect.
var target:SpellTargetComponent


func apply(stc:SpellTargetComponent) -> void:
	target = stc


## Called every frame as the spell is active.
func on_update(delta:float) -> void:
	pass


## Called when the spell first begins.
func on_start_effect() -> void:
	pass


## Called when the spell ends.
func on_end_effect() -> void:
	pass

```

**spell_hand.gd**
```gdscript
class_name SpellHand
extends Node3D
## Spell casting origin. This is a Node3D, and in general, it should be placed underneath a hand bone, or the top of a staff, or something like that.
## You gotta connect these to inputs yourself.


## What spell is active right now.
var _active_spell:Spell
## The SKEntity this hand is attached to.
var entity:SKEntity


func cast_spell():
	if not _active_spell:
		return
	_active_spell.reset()
	_active_spell.on_spell_cast()


func hold_spell(delta):
	if not _active_spell:
		return
	_active_spell.on_spell_held(delta)


func release_spell():
	if not _active_spell:
		return
	_active_spell.on_spell_released()


func load_spell(sp:Spell):
	_active_spell = sp
	sp._caster = self
	sp.reset()

```

**spell_item.gd**
```gdscript
class_name SpellItem
extends Resource

```

**spell_projectile.gd**
```gdscript
class_name SpellProjectile
extends RigidBody3D
## A special script for projectiles: provides a callback when it hits an object.


## Callback when something is hit.
signal hit_target(target:Node3D)


func _ready():
	body_entered.connect(func(x:Node3D):
		hit_target.emit(x)
	)

```

#### system

**game_info.gd**
```gdscript
extends Node
## holds Current game state.


## What world the player is in.
@export var world: StringName = &"init"

var is_loading:bool = false
var paused:bool = false
var game_running:bool = true :
	get:
		return game_running
	set(val):
		if val:
			$Timer.paused = false
			game_running = val # does this call Set again?
		else:
			$Timer.paused = true
			game_running = val

var world_time:Dictionary = {
	&"world_time" : 0,
	&"minute" : 0,
	&"hour" : 0,
	&"day" : 0,
	&"week" : 0,
	&"month" : 0,
	&"year" : 0,
}
## Continuity flags are values that can be set that allow for dialogue and the world to match up with that the player has done.
## for example, dialogue could set [code]met_alice:true[/code] if the Player meets the character Alice. Then, if the player meets Alice elsewhere, Alice can read this value and respond as though she as a character already knows the player.
var continuity_flags:Dictionary = {}
var minute:int:
	get:
		return world_time[&"minute"]
var hour:int:
	get:
		return world_time[&"hour"]
var day:int:
	get:
		return world_time[&"day"]
var week:int:
	get:
		return world_time[&"week"]
var month:int:
	get:
		return world_time[&"month"]
var year:int:
	get:
		return world_time[&"year"]
var is_game_started:bool
var command_paused:bool
## This is the point at which all entity loading, chunk loading, etc. is done. Normally, you would want this to be the player.
var world_origin:Node3D:
	get:
		if world_origin == null:
			world_origin = get_viewport().get_camera_3d()
		return world_origin
## The time between minutes, from 0 to 1.
var time_fraction:float:
	get:
		return _internal_seconds / ProjectSettings.get_setting("skelerealms/seconds_per_minute")
var _internal_seconds:float = 0.0

signal pause
signal unpause
signal console_frozen
signal console_unfrozen

signal minute_incremented
signal hour_incremented
signal day_incremented
signal week_incremented
signal month_incremented
signal year_incremented
signal game_started

signal game_loading(wid:String)
signal game_loaded


func _ready():
	set_name.call_deferred("GameInfo")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	var t = Timer.new()
	t.name = "Timer"
	add_child(t)
	
	$Timer.timeout.connect(_on_timer_complete.bind())
	$Timer.one_shot = false
	$Timer.start(1)
	$Timer.paused = not game_running


## Puase the game.
func pause_game(silent:bool = false):
	if command_paused:
		return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	paused = true
	get_tree().paused = true
	$Timer.paused = true
	if not silent:
		pause.emit()


## Unpause the game.
func unpause_game():
	if command_paused:
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	paused = false
	get_tree().paused = false
	$Timer.paused = false
	unpause.emit()


func console_freeze() -> void:
	if paused:
		return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	command_paused = true
	get_tree().paused = true
	$Timer.paused = true
	console_frozen.emit()


func console_unfreeze() -> void:
	if paused:
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	command_paused = false
	get_tree().paused = false
	$Timer.paused = false
	console_unfrozen.emit()


func toggle_console_freeze() -> void:
	if not is_game_started:
		return
	
	if command_paused:
		console_unfreeze()
	else:
		console_freeze()


func toggle_pause():
	if not is_game_started:
		return
	
	if paused:
		unpause_game()
	else:
		pause_game()


func _on_timer_complete():
	# Increment world time
	world_time[&"world_time"] += 1
	# Increment minute
	if world_time[&"world_time"] % roundi(ProjectSettings.get_setting("skelerealms/seconds_per_minute")) == 0:
		world_time[&"minute"] += 1
		_internal_seconds = 0
		minute_incremented.emit()
	# Wrap minutes to hours
	if world_time[&"minute"] > roundi(ProjectSettings.get_setting("skelerealms/minutes_per_hour")):
		world_time[&"minute"] = 0
		world_time[&"hour"] += 1
		hour_incremented.emit()
	# Wrap hours to days
	if world_time[&"hour"] > roundi(ProjectSettings.get_setting("skelerealms/hours_per_day")):
		world_time[&"hour"] = 0
		world_time[&"day"] += 1
		day_incremented.emit()
	# Wrap days to weeks
	if world_time[&"day"] > roundi(ProjectSettings.get_setting("skelerealms/days_per_week")):
		world_time[&"day"] = 0
		world_time[&"week"] += 1
		week_incremented.emit()
	# Wrap weeks to months
	if world_time[&"week"] > roundi(ProjectSettings.get_setting("skelerealms/weeks_in_month")):
		world_time[&"week"] = 0
		world_time[&"month"] += 1
		month_incremented.emit()
	# Wrap months to years
	if world_time[&"month"] > roundi(ProjectSettings.get_setting("skelerealms/months_in_year")):
		world_time[&"month"] = 0
		world_time[&"year"] += 1
		year_incremented.emit()


func save() -> Dictionary:
	return {
		"world" : world,
		&"world_time" : world_time,
		"continuity_flags" : continuity_flags
	}


func load_game(data:Dictionary):
	world = data["world"]
	world_time = data[&"world_time"]
	continuity_flags = data["continuity_flags"]


func reset_data() -> void: # this should never happen but just in case
	world_time = {
		&"world_time" : 0,
		&"minute" : 0,
		&"hour" : 0,
		&"day" : 0,
		&"week" : 0,
		&"month" : 0,
		&"year" : 0,
	}
	continuity_flags = {}
	world = "init"


func start_game() -> void:
	game_started.emit()
	is_game_started = true


func _process(delta: float) -> void:
	if not paused:
		_internal_seconds += delta


func _progress_through_day() -> float:
	var hour_progress = hour / ProjectSettings.get_setting("skelerealms/hours_per_day")
	var minutes_progress = minute / (ProjectSettings.get_setting("skelerealms/minutes_per_hour") * ProjectSettings.get_setting("skelerealms/hours_per_day"))
	var seconds_progress = time_fraction / (ProjectSettings.get_setting("skelerealms/minutes_per_hour") * ProjectSettings.get_setting("skelerealms/hours_per_day"))
	return hour_progress + minutes_progress + seconds_progress

```

**save_system.gd**
```gdscript
extends Node
## The savegame system.
## This should be autoloaded.


## Called when the savegame is complete.
## Use this to, for example, freeze the game until complete, or tell the netity manager to clean up stale entities.
signal save_complete
## Called when the loading process is complete. See [signal save_complete].
signal load_complete


## Save the game and write it to user://saves directory.
func save():
	var save_data = {
		"game_info" : {}, # info about the game, like playtime, quests, etc
		"entity_data" : {}, # savegame info from entities
		"other_data" : {} # anything else
	}

	# collect savegame data from entities
	for sd in get_tree().get_nodes_in_group("savegame_entity"):
		save_data["entity_data"][sd.name] = sd.save()
	# collect savegame data from game info
	for sd in get_tree().get_nodes_in_group("savegame_gameinfo"):
		save_data["game_info"][sd.name] = sd.save()
	# collect anything else
	for sd in get_tree().get_nodes_in_group("savegame_other"):
		save_data["other_data"][sd.name] = sd.save()

	# attempt merge with old data, so we still keep the info about entities that aren't being tracked right now.
	var old_file = _get_most_recent_savegame() # my getting the most recent, which was also merged like this, we accumulate info
	if old_file.some(): # we will only merge if there is something to merge with
		var old_data:Dictionary = _deserialize(FileAccess.open(old_file.unwrap(), FileAccess.READ).get_as_text()) # deserialize old data
		old_data.merge(save_data, true) # merge, taking care to overwrite to keep info up to date
		save_data = old_data # bit funky but I'm lazy

	var save_text:String = _serialize(save_data) # serialize

	DirAccess.make_dir_recursive_absolute("user://saves/")
	# TODO: allow for custom save file names
	# Create savegame file
	var file = FileAccess.open("user://saves/%s.dat" % Time.get_datetime_string_from_system().replace(":", ""), FileAccess.WRITE)
	file.store_string(save_text)
	# I think these two are redundant but I wanna be safe
	file.flush()
	file.close()
	save_complete.emit()


## Load the most recent savegame, if applicable.
func load_most_recent():
	var most_recent = _get_most_recent_savegame()
	# only load most recent if there are some
	if most_recent.some():
		load_game(most_recent.unwrap())


## Load a game from a filepath.
func load_game(path:String):
	var file = FileAccess.open(path, FileAccess.READ) # open file
	var data_blob:String = file.get_as_text() # read file
	var save_data:Dictionary = _deserialize(data_blob) # parse data

	# Reset to default state if it doesn't have an entry in the save data
	for e in SKEntityManager.instance.entities:
		if not save_data["entity_data"].has(e):
			SKEntityManager.instance.entities[e].reset_data()
	# load entity data - loop through all data, get entity (spawning it if it isn't there), call load
	for data in save_data["entity_data"]:
		SKEntityManager.instance.get_entity(data).load_data(save_data["entity_data"][data])

	# load game info data
	for si in get_tree().get_nodes_in_group("savegame_gameinfo"):
		if save_data["game_info"].has(si.name):
			si.load_data(save_data["game_info"][si.name])
		else:
			si.reset_data()

	# load others data
	for so in get_tree().get_nodes_in_group("savegame_other"):
		if save_data["other_data"].has(so.name):
			so.load_data(save_data["other_data"][so.name])
		else:
			so.reset_data()


## Check if an entity is accounted for in the save system. Returns the save data blob if there is, else none.
## Use sparingly; could get memory intensive.
func entity_in_save(ref_id:String) -> Option:
	var most_recent = _get_most_recent_savegame() # get most recent filepath
	# if there was no recent save, it isn't here
	if not most_recent.some():
		return Option.none()
	# deserialize
	var deserialized_data:Dictionary = _deserialize(FileAccess.open(most_recent.unwrap(), FileAccess.READ).get_as_text())
	if deserialized_data["entity_data"].has(ref_id):
		# if the data has it, return the blob
		return Option.from(deserialized_data["entity_data"][ref_id])
	else:
		# else, it's not here.
		return Option.none()


## Gets the filepath for the most recent savegame. It is sorted by file modification time.
func _get_most_recent_savegame() -> Option:
	if not DirAccess.dir_exists_absolute("user://saves/"):
		return Option.none()

	var dir_files:Array[String] = []
	dir_files.append_array(DirAccess.get_files_at("user://saves/"))
	# if no saves, we got none
	if dir_files.is_empty():
		return Option.none()
	# sort by modified time
	dir_files.sort_custom(func(a:String, b:String): return FileAccess.get_modified_time("user://saves/%s" % a) < FileAccess.get_modified_time("user://saves/%s" % b))
	var most_recent_file:String = dir_files.pop_back()
	# format
	return Option.from("user://saves/%s" % most_recent_file)


## Turn the save game blob into a string.
## You can change this to use whatever system you want. By default, it uses JSON because that comes with Godot.
func _serialize(data:Dictionary) -> String:
	return JSON.stringify(data, "\t" if ProjectSettings.get_setting("skelerealms/savegame_indents") else "", true, true)


## Turn a string into a data blob.
## Like with [method _serialize], you can write your own.
func _deserialize(text:String) -> Dictionary:
	return JSON.parse_string(text)

```

**timestamp.gd**
```gdscript
class_name Timestamp
extends Resource


# SO much repetitive code

@export_flags("Minute:1", "Hour:2", "Day:4", "Week:8", "Month:16", "Year:32") var compare:int = 0b00010
var use_minute:bool:
	get:
		return compare & 1 == 1
@export var minute:int
var use_hour:bool:
	get:
		return compare & 2 == 2
@export var hour:int
var use_day:bool:
	get:
		return compare & 4 == 4
@export var day:int
var use_week:bool:
	get:
		return compare & 8 == 8
@export var week:int
var use_month:bool:
	get:
		return compare & 16 == 16
@export var month:int
var use_year:bool:
	get:
		return compare & 32 == 32
@export var year:int


static func build_from_world_timestamp() -> Timestamp:
	var stamp:Timestamp = Timestamp.new()
	
	# Set using
	stamp.use_minute = true
	stamp.use_hour = true
	stamp.use_day = true
	stamp.use_week = true
	stamp.use_month = true
	stamp.use_year = true
	
	# Set times
	stamp.minute = GameInfo.minute
	stamp.hour = GameInfo.hour
	stamp.day = GameInfo.day
	stamp.week = GameInfo.week
	stamp.month = GameInfo.month
	stamp.year = GameInfo.year
	
	return stamp

func is_in_between(from:Timestamp, to:Timestamp) -> bool:
	# if we are using the minute and the minute is not between the other two.
	# Ditto for all fields.
	if use_minute and not (from.minute <= minute and minute < to.minute):
		return false
	if use_hour and not (from.hour <= hour and hour < to.hour):
		return false
	if use_day and not (from.day <= day and day < to.day):
		return false
	if use_week and not (from.week <= week and week < to.week):
		return false
	if use_month and not (from.month <= month and month < to.month):
		return false
	if use_year and not (from.year <= year and year < to.year):
		return false
	
	return true


## If timestamp is less than or equal to
func lte(to:Timestamp) -> bool:
	# if we are using the minute and the minute is less than to.minute
	# Ditto for all fields.
	if use_minute and not (minute <= to.minute):
		return false
	if use_hour and not (hour <= to.hour):
		return false
	if use_day and not (day <= to.day):
		return false
	if use_week and not (week <= to.week):
		return false
	if use_month and not ( month <= to.month):
		return false
	if use_year and not (year <= to.year):
		return false
	
	return true


## If timestamp is greater than or equal to
func gte(to:Timestamp) -> bool:
	# if we are using the minute and the minute is less than to.minute
	# Ditto for all fields.
	if use_minute and not (minute >= to.minute):
		return false
	if use_hour and not (hour >= to.hour):
		return false
	if use_day and not (day >= to.day):
		return false
	if use_week and not (week >= to.week):
		return false
	if use_month and not ( month >= to.month):
		return false
	if use_year and not (year >= to.year):
		return false
	
	return true


func time_since(other:Timestamp) -> Dictionary:
	return {
		&"year": other.year - year,
		&"month": other.month - month,
		&"week": other.week - week,
		&"day": other.day - day,
		&"hour": other.hour - hour,
		&"minute": other.minute - minute
	}


## Convert a dictionary time, like produced by [method time_since], to minutes.
static func dict_to_minutes(t:Dictionary) -> int:
	var my:int = t.year * ProjectSettings.get_setting("skelerealms/months_in_year") # months from years
	var wm: int = (t.month + my) * ProjectSettings.get_setting("skelerealms/weeks_in_month") # weeks from months
	var dw: int = (t.week + wm) * ProjectSettings.get_setting("skelerealms/days_per_week") # days from weeks
	var hd: int = (t.day + dw) * ProjectSettings.get_setting("skelerealms/hours_per_day") # hours from days
	var mh: int = (t.hour + hd) * ProjectSettings.get_setting("skelerealms/minutes_per_hour") # minutes from hours
	return t.minute + mh

```

**world_loader.gd**
```gdscript
class_name WorldLoader
extends Node
## World scene loader


var world_paths:Dictionary = {}
var regex:RegEx
var loading_path:String
var last_load_progress := 0 


## Called when the loading process begins.
## Hook into this to pop up a loading screen.
signal begin_world_loading
## Called when the world has finished loading, and gameplay can resume.
## Use this to either continue gameplay, or pop up a button on the loading screen to continue gameplay.
signal world_loading_ready
## Called while the scene is loading with its progress. Progress from 0 to 1.
signal load_scene_progess_updated(percent:int)


func _enter_tree() -> void:
	if get_child_count() > 0:
		GameInfo.world = get_child(0).name


func _ready():
	regex = RegEx.new()
	regex.compile("([^\\/\n\\r]+)\\.t?scn") 
	_cache_worlds(ProjectSettings.get_setting("skelerealms/worlds_path"))
	GameInfo.is_loading = false


func _process(_delta: float) -> void:
	if not GameInfo.is_loading:
		return 
	
	var prog = []
	match ResourceLoader.load_threaded_get_status(loading_path, prog):
		ResourceLoader.THREAD_LOAD_LOADED:
			print("Finishing up...")
			var ps := ResourceLoader.load_threaded_get(loading_path) as PackedScene
			if not ps:
				push_error("Failed to load world at %s" % loading_path)
				_abort()
			_finish_load.call_deferred(ps)
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("Could not load world due to thread loading error.")
			_abort()
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			if not last_load_progress == prog[0]:
				(func(): load_scene_progess_updated.emit(prog[0])).call_deferred()
				last_load_progress = prog[0]


## Load a new world.
func load_world(wid:String) -> void:
	print("loading world")
	
	if not world_paths.has(wid):
		push_error("World not found: %s" % wid)
		return
	
	GameInfo.console_unfreeze()
	begin_world_loading.emit()
	GameInfo.game_loading.emit(wid)
	await get_tree().process_frame
	print("Processed frame. Continuing...")
	GameInfo.is_loading = true
	#await get_tree().process_frame
	#print("processed frame. Unloading world...")
	var e:Error = ResourceLoader.load_threaded_request(world_paths[wid], "PackedScene", true)
	if not e == OK:
		push_error("Load thread error: %d" % e)
		_abort()
		return
	
	last_load_progress = 0
	loading_path = world_paths[wid]
	
	_unload_world()


func _finish_load(w:PackedScene) -> void:
	print("finished loading world")
	add_child(w.instantiate())
	print("finished loading world. Instantiating...")
	world_loading_ready.emit()
	GameInfo.is_loading = false
	print("World instantiated.")
	GameInfo.game_loaded.emit()


func _unload_world():
	remove_child(get_child(0))


func _abort() -> void:
	# TODO: Crash game? 
	world_loading_ready.emit()
	GameInfo.is_loading = false
	GameInfo.game_loaded.emit()


## Searches the worlds directory and caches filepaths, matching them to their name
func _cache_worlds(path:String):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if '.tscn.remap' in file_name:
				file_name = file_name.trim_suffix('.remap')
			if dir.current_is_dir(): # if is directory, cache subdirectory
				_cache_worlds("%s/%s" % [path, file_name])
			else: # if filename, cache filename
				var result = regex.search(file_name)
				if result:
					world_paths[result.get_string(1)] = "%s/%s" % [path, file_name]
			file_name = dir.get_next()
		dir.list_dir_end()
	
	else:
		print("An error occurred when trying to access the path.")

```

#### ui

**choose_character.gd**
```gdscript
extends Control

@onready var picking_label: Label = $PickingLabel
@onready var buttons = {
	"Strawberry": $Strawberry2,
	"Orange":     $Orange2,
	"Pineapple":  $Pineapple2,
	"Grape":      $Grape2
}

func _ready():
	Global.reset_selection()
	update_ui()

func update_ui():
	picking_label.text = "Gracz " + str(Global.current_picking_player) + " wybiera!"
	for character in buttons:
		buttons[character].disabled = !Global.available_characters.has(character)

func _on_strawberry_2_pressed():
	pick("Strawberry")

func _on_grape_2_pressed():
	pick("Grape")

func _on_orange_2_pressed():
	pick("Orange")

func _on_pineapple_2_pressed():
	pick("Pineapple")

func pick(character_name: String):
	Global.pick_character(character_name)
	if Global.all_picked():
		Global.reset_all()
		get_tree().change_scene_to_file("res://Scenes/main_game.tscn")
	else:
		update_ui()

```

**kill_feed.gd**
```gdscript
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

```

**modifier_select.gd**
```gdscript
extends Control

@onready var picking_label: Label  = $PickingLabel
@onready var card1: Button         = $HBoxContainer/Card1
@onready var card2: Button         = $HBoxContainer/Card2
@onready var card3: Button         = $HBoxContainer/Card3

var pickers:              Array = []  # kto wybiera, np. ["Grape", "Strawberry"]
var current_picker_index: int   = 0   # który picker teraz wybiera
var current_cards:        Array = []  # 3 ID modyfikatorów aktualnie na kartach

# Stary słownik modifier_names USUNIĘTY —
# teraz czytamy z Global.modifier_registry, które ma wszystkie 30+ modów.
# Jeśli dodasz nowy mod do Global.gd, automatycznie pojawi się tutaj.

func _ready() -> void:
	pickers              = Global.modifier_pickers
	current_picker_index = 0
	show_cards_for_current_picker()

func show_cards_for_current_picker() -> void:
	# Wszyscy wybrali — lecimy do gry
	if current_picker_index >= pickers.size():
		call_deferred("_go_to_main_game")
		return

	var picker: String = pickers[current_picker_index]
	picking_label.text = picker + " wybiera modyfikator!"

	# Losuj 3 unikalne mody z puli
	var pool: Array = Global.all_modifiers.duplicate()
	pool.shuffle()
	current_cards = pool.slice(0, 3)

	# Ustaw tekst kart z rejestru — emoji + nazwa + opis
	_set_card_text(card1, current_cards[0])
	_set_card_text(card2, current_cards[1])
	_set_card_text(card3, current_cards[2])

## Buduje tekst przycisku z danych w Global.modifier_registry.
## Dzięki temu dodanie nowego modu w Global.gd wystarczy —
## nie trzeba tu nic zmieniać.
func _set_card_text(card: Button, mod_id: String) -> void:
	# Zabezpieczenie: jeśli mod nie istnieje w rejestrze, pokaż samo ID
	if not Global.modifier_registry.has(mod_id):
		card.text = mod_id
		return

	var entry: Dictionary = Global.modifier_registry[mod_id]
	var emoji: String     = entry.get("emoji", "")
	var name:  String     = entry.get("name",  mod_id)
	var desc:  String     = entry.get("desc",  "")

	# Format: "💥 Shotgun pestek\nWystrzelasz 4 dodatkowe pociski w wachlarzu."
	card.text = emoji + " " + name + "\n" + desc

func _go_to_main_game() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_game.tscn")

func pick(index: int) -> void:
	var picker: String = pickers[current_picker_index]
	var chosen: String = current_cards[index]

	# Dodaj mod do gracza — stackuje się między rundami
	Global.modifiers[picker].append(chosen)

	# Wyświetl w kill feedzie co wybrał
	var entry: Dictionary = Global.modifier_registry.get(chosen, {})
	var msg:   String     = entry.get("emoji", "") + " " + picker + \
							" wybrał: " + entry.get("name", chosen)
	Global.kill_feed_message.emit(msg)  # widoczne jak wejdziesz do gry

	current_picker_index += 1
	show_cards_for_current_picker()

func _on_card_1_pressed() -> void: pick(0)
func _on_card_2_pressed() -> void: pick(1)
func _on_card_3_pressed() -> void: pick(2)

```

**round_ended.gd**
```gdscript
extends Control
@onready var winner_label: Label = $WinnerLabel
@onready var points_label: Label = $PointsLabel

func _ready() -> void:
	if Global.winner == "":
		winner_label.text = "REMIS!"
	else:
		winner_label.text = "Wygrał: " + Global.winner

	var points_text = "Punkty:\n"
	for character in Global.points:
		points_text += character + ": " + str(Global.points[character]) + " pkt\n"
	points_label.text = points_text

func _on_button_pressed() -> void:
	Global.round_number += 1

	# Przy remisoie nikt nie wybiera modyfikatorów — gnicie = wszyscy remisują,
	# więc nikt nie "wygrał" rundy i nie ma kogo nagradzać modem.
	# Bez tego warunku get_modifier_pickers() nadpisałoby puste [] ustawione
	# przez _end_round() i gracze niepotrzebnie wybieraliby mody po remisoie.
	if Global.winner == "":
		Global.modifier_pickers = []
	else:
		Global.modifier_pickers = Global.get_modifier_pickers()

	if Global.modifier_pickers.size() > 0:
		get_tree().change_scene_to_file("res://Scenes/ui/modifier_select.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/main_game.tscn")

```

**set_over.gd**
```gdscript
extends Control

@onready var ranking_label: Label = $RankingLabel  # ← sprawdź nazwę w scenie!

func _ready() -> void:
	var sorted = Global.points.keys()
	sorted.sort_custom(func(a, b): return Global.points[a] > Global.points[b])
	var text = "Wyniki po " + str(Global.round_number) + " rundach:\n\n"
	for i in range(sorted.size()):
		text += str(i + 1) + ". " + sorted[i] + " — " + str(Global.points[sorted[i]]) + " pkt\n"
	ranking_label.text = text

func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/ui/round_ended.tscn")

func _on_reset_pressed() -> void:
	Global.reset_full_game()
	get_tree().change_scene_to_file("res://Scenes/ui/choose_character.tscn")

```

#### world_objects

**damageable_object.gd**
```gdscript
class_name DamageableObject
extends SKWorldObject
## For objects in the world that can be damaged but don't have to be tracked, like training dummies


signal damaged(info:DamageInfo)


func receive_message(msg:StringName, args:Array = []) -> void:
	if msg == &"damage":
		damage(args[0])


func damage(info:DamageInfo):
	damaged.emit(info)


func _init() -> void:
	name = "DamageableObject"

```

**door.gd**
```gdscript
class_name Door
extends InteractiveObject
## Example implementation of an interactive object.
## Interacting with this teleports the interactor.


@export var instance:DoorInstance
@export var destination_instance:DoorInstance
var dest_world:String:
	get:
		return destination_instance.world
var dest_pos:Vector3:
	get:
		return destination_instance.position


func _ready():
	on_interact.connect(_handle_teleport_request.bind())


# You could also override #interact, instead of binding to signal.
func _handle_teleport_request(id:String):
	print("teleporting %s to world %s at position %s" % [id, dest_world, dest_pos])
	var teleportee = SKEntityManager.instance.get_entity(id) # get an entity
	if teleportee: # if there is a valid object
		var tc = teleportee.get_component("TeleportComponent")  # Try to get a teleport component
		if tc:
			(tc as TeleportComponent).teleport(dest_world, dest_pos)

```

**effects_object.gd**
```gdscript
class_name EffectsObject
extends SKWorldObject


## This is a vessel for [class StatusEffectHost], intended to give statuseffects to non-entity objects.
## For example, you could add this and a [class DamageableObject] to a wooden box, and if the box is set
## on fire, it will turn to ash.


var host:StatusEffectHost


func _ready() -> void:
	host = StatusEffectHost.new()
	add_child(host)
	host.message_broadcast.connect(broadcast_message.bind())


func add_effect(what:StringName) -> void:
	host.add_effect(what)


func remove_effect(e:StringName) -> void:
	host.remove_effect(e)


func receive_message(msg:StringName, args:Array = []) -> void:
	match msg:
		&"add_effect":
			add_effect(args[0])
		&"remove_effect":
			remove_effect(args[0])

```

**interactive_object.gd**
```gdscript
class_name InteractiveObject
extends SKWorldObject
## base class for objects in the world that don't need tracking, but can be interacted with, like a sign.
## See [Door] for an example implementation.


signal on_interact(id:String)

## Whether it can be interacted with.
@export var interactible:bool = true
## Verb to use when hovered over.
@export var interact_verb:String = "INTERACT"
## Name of the object.
@export var object_name:String = "THING"


func interact(id:String):
	on_interact.emit(id)


func receive_message(msg:StringName, args:Array = []) -> void:
	if msg == &"interact":
		interact(args[0])

```

**sk_world_object.gd**
```gdscript
class_name SKWorldObject
extends Node3D


## This is the base class for non-entity objects affected by Skelerealms concepts.
## This base class is needed to interact with the message broadcasting system used by [class StatusEffect]s - see [class EffectsObject].
## [b]Please Note:[/b] I am still not 100% sure about this design decision, and this system may change in the future.


## A list of nodes that will have messages broadcast to them.
var _neighbors:Array[SKWorldObject] = []


func _ready() -> void:
	_collect_neighbors()
	get_parent().child_order_changed.connect(_collect_neighbors.bind())


## Broadcast messages to siblings and parent of this node (if they are SKWorldObjects).
func broadcast_message(msg:StringName, args:Array = []) -> void:
	for n:SKWorldObject in _neighbors:
		n.receive_message(msg, args)


## Override this to handle receiving messages.
func receive_message(_msg:StringName, _args:Array = []) -> void:
	return


func _collect_neighbors() -> void:
	if get_parent() == null:
		return
	_neighbors.clear()
	if get_parent() is SKWorldObject:
		_neighbors.append(get_parent())
	for c:Node in get_parent().get_children():
		if c == self:
			continue
		if c is SKWorldObject:
			_neighbors.append(c)

```

**spell_target_object.gd**
```gdscript
class_name SpellTargetObject
extends Node3D

# I wish I had mixins or interfaces. maybe I need to restructure something?
@onready var status_effects:EffectsObject = $EffectsObject


signal hit_with_spell(sp:Spell)


func hit(sp:Spell):
	hit_with_spell.emit(sp)


func apply_effect(eff:StringName):
	status_effects.add_effect(eff)

```

**world_entity.gd**
```gdscript
@tool
class_name SKWorldEntity
extends Marker3D


@export var entity:PackedScene:
	set(val):
		entity = val 
		if Engine.is_editor_hint():
			if get_child_count() > 0:
				get_child(0)
			if val:
				_show_preview()


func _ready() -> void:
	if Engine.is_editor_hint():
		_show_preview()
	else:
		SKEntityManager.instance.get_entity(entity._bundled.names[0])


func _show_preview() -> void:
	if not entity:
		return
	var e:SKEntity = entity.instantiate()
	var n:Node = e.get_world_entity_preview().duplicate()
	e.queue_free()
	if not n:
		return
	add_child(n)


func _sync() -> void:
	if not Engine.is_editor_hint():
		return
	
	if not entity:
		return
	
	var e:SKEntity = entity.instantiate()
	if not e:
		return
	
	e.position = global_position
	e.world = EditorInterface.get_edited_scene_root().name
	
	entity.pack(e)

```

## res://

**skelerealms.gd**
```gdscript
@tool
extends EditorPlugin


const DoorJumpPlugin = preload("res://addons/skelerealms/tools/door_connect.gd")
const WorldEntityPlugin = preload("res://addons/skelerealms/tools/world_entity_plugin.gd")
const PointGizmo = preload("res://addons/skelerealms/tools/point_gizmo.gd")
const ScheduleEditorPlugin = preload("res://addons/skelerealms/tools/schedule_editor_plugin.gd")
const ConfigSyncPlugin = preload("res://addons/skelerealms/tools/config_sync_plugin.gd")

## Container we add the toolbar to
const container = CONTAINER_SPATIAL_EDITOR_MENU
const RAY_LENGTH:float = 500
const SNAP_DISTANCE:float = 0.1

## The active [NetworkEditorUtility].
var utility:NetworkEditorUtility
## Gizmo instance for a [NetworkInstance].
var network_gizmo:NetworkGizmo = NetworkGizmo.new()
## Currently editing network.
var target:Network:
	get:
		return target
	set(val):
		if target == val: # Prevent reinitializing a whole lot. may be redundant.
			return
		if target and target.redraw.is_connected(_redraw_gizmo.bind()):
			# unsubscribe from redraw if we are changing selection
			target.redraw.disconnect(_redraw_gizmo.bind())
		target = val
		if target:
			target.redraw.connect(_redraw_gizmo.bind()) # subscribe to redraw
		_set_toolbar_visibility(not val == null) # set toolbar visibility to true if it isnt null
var _target_node:NetworkInstance


var door_jump_plugin := DoorJumpPlugin.new(self)
var we_plugin := WorldEntityPlugin.new()
var point_gizmo := PointGizmo.new()
var se_plugin := ScheduleEditorPlugin.new()
var cs_plugin := ConfigSyncPlugin.new()

var se_w: Window
var se: Control


func _enter_tree():
	# gizmos
	add_node_3d_gizmo_plugin(point_gizmo)
	add_inspector_plugin(door_jump_plugin)
	add_inspector_plugin(we_plugin)
	add_inspector_plugin(se_plugin)
	add_inspector_plugin(cs_plugin)
	# autoload
	add_autoload_singleton("SkeleRealmsGlobal", "res://addons/skelerealms/scripts/sk_global.gd")
	add_autoload_singleton("CovenSystem", "res://addons/skelerealms/scripts/covens/coven_system.gd")
	add_autoload_singleton("GameInfo", "res://addons/skelerealms/scripts/system/game_info.gd")
	add_autoload_singleton("SaveSystem", "res://addons/skelerealms/scripts/system/save_system.gd")
	add_autoload_singleton("CrimeMaster", "res://addons/skelerealms/scripts/crime/crime_master.gd")
	add_autoload_singleton("DeviceNetwork", "res://addons/skelerealms/scripts/misc/device_network.gd")
	
	se_w = Window.new()
	se = ScheduleEditorPlugin.ScheduleEditor.instantiate()
	se_w.add_child(se)
	EditorInterface.get_base_control().add_child(se_w)
	se_w.hide()
	
	se_plugin.request_open.connect(func(events:Array[ScheduleEvent]) -> void:
		se.edit(events)
		se_w.popup_centered(Vector2i(1920, 1080))
		)
	
	# Initialize utility
	utility = load("res://addons/skelerealms/scripts/network/Editor/editor_toolbar.tscn").instantiate()
	add_control_to_container(container, utility) # add to spatial toolbar
	_set_toolbar_visibility(false) # hide by default
	# Connect the buttons
	utility.link.connect(_on_link.bind())
	utility.merge.connect(_on_merge.bind())
	utility.remove.connect(_on_remove.bind())
	utility.dissolve.connect(_on_dissolve.bind())
	utility.subdivide.connect(_on_subdivide.bind())
	utility.unlink.connect(_on_unlink.bind())
	utility.change_cost_accepted.connect(_change_cost.bind())

	# Selection
	get_editor_interface()\
		.get_selection()\
		.selection_changed\
		.connect(_selection_changed.bind())
	
	# Gizmo
	network_gizmo._plugin = self
	add_node_3d_gizmo_plugin(network_gizmo)


func _exit_tree():
	# gizmos
	remove_node_3d_gizmo_plugin(point_gizmo)
	remove_inspector_plugin(door_jump_plugin)
	remove_inspector_plugin(we_plugin)
	remove_inspector_plugin(se_plugin)
	remove_inspector_plugin(cs_plugin)
	# autoload
	remove_autoload_singleton("SkeleRealmsGlobal")
	remove_autoload_singleton("CovenSystem")
	remove_autoload_singleton("GameInfo")
	remove_autoload_singleton("SaveSystem")
	remove_autoload_singleton("CrimeMaster")
	remove_autoload_singleton("DeviceNetwork")

	remove_control_from_container(container, utility)
	remove_node_3d_gizmo_plugin(network_gizmo)
	
	se_w.queue_free()


func _enable_plugin() -> void:
	# settings
	ProjectSettings.set_setting("skelerealms/actor_fade_distance", 100.0)
	ProjectSettings.set_setting("skelerealms/entity_cleanup_timer", 300.0)
	ProjectSettings.set_setting("skelerealms/granular_navigation_sim_distance", 1000.0)
	ProjectSettings.set_setting("skelerealms/savegame_indents", true)
	
	ProjectSettings.set_setting("skelerealms/seconds_per_minute", 2.0)
	ProjectSettings.set_setting("skelerealms/minutes_per_hour", 31.0)
	ProjectSettings.set_setting("skelerealms/hours_per_day", 15.0)
	ProjectSettings.set_setting("skelerealms/days_per_week", 8)
	ProjectSettings.set_setting("skelerealms/weeks_in_month", 4)
	ProjectSettings.set_setting("skelerealms/months_in_year", 8)
	
	ProjectSettings.set_setting("skelerealms/worlds_path", "res://worlds")
	ProjectSettings.set_setting("skelerealms/entities_path", "res://entities")
	ProjectSettings.set_setting("skelerealms/covens_path", "res://covens")
	ProjectSettings.set_setting("skelerealms/doors_path", "res://doors")
	ProjectSettings.set_setting("skelerealms/networks_path", "res://networks")
	
	ProjectSettings.set_setting("skelerealms/config_path", "res://sk_config.res")
	
	ProjectSettings.set_setting("skelerealms/entity_archetypes", PackedStringArray([
		"res://addons/skelerealms/npc_entity_template.tscn",
		"res://addons/skelerealms/item_entity_template.tscn"
	]))


func _disable_plugin() -> void:
	# settings
	ProjectSettings.set_setting("skelerealms/actor_fade_distance", null)
	ProjectSettings.set_setting("skelerealms/entity_cleanup_timer", null)
	ProjectSettings.set_setting("skelerealms/granular_navigation_sim_distance", null)
	ProjectSettings.set_setting("skelerealms/savegame_indents", null)
	
	ProjectSettings.set_setting("skelerealms/seconds_per_minute", null)
	ProjectSettings.set_setting("skelerealms/minutes_per_hour", null)
	ProjectSettings.set_setting("skelerealms/hours_per_day", null)
	ProjectSettings.set_setting("skelerealms/days_per_week", null)
	ProjectSettings.set_setting("skelerealms/weeks_in_month", null)
	ProjectSettings.set_setting("skelerealms/months_in_year", null)
	
	ProjectSettings.set_setting("skelerealms/worlds_path", null)
	ProjectSettings.set_setting("skelerealms/entities_path", null)
	ProjectSettings.set_setting("skelerealms/covens_path", null)
	ProjectSettings.set_setting("skelerealms/doors_path", null)
	ProjectSettings.set_setting("skelerealms/networks_path", null)
	
	ProjectSettings.set_setting("skelerealms/entity_archetypes", null)
	ProjectSettings.set_setting("skelerealms/config_path", null)


func _handles(object: Object) -> bool:
	return object is NetworkInstance


func _selection_changed() -> void:
	# Get selected nodes
	var selections = get_editor_interface()\
							.get_selection()\
							.get_selected_nodes()
	# Skip if no selections 
	if selections.is_empty():
		target = null
		return
	# Set target if network instance
	if selections[0] is NetworkInstance:
		_target_node = selections[0]
		target = selections[0].network
		return
	target = null


func _forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> int:
	# if no utility, pass
	if not utility:
		return AFTER_GUI_INPUT_PASS
	# if no target, pass
	if target == null:
		return AFTER_GUI_INPUT_PASS
	# if not in add mode, pass
	if not utility.add_mode:
		return AFTER_GUI_INPUT_PASS
	# pass if event isn't a mouse button
	if not event is InputEventMouseButton:
		return AFTER_GUI_INPUT_PASS
	# pass if not mouse right click down
	if not (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT or \
		not (event as InputEventMouseButton).pressed:
			return AFTER_GUI_INPUT_PASS
	# If we passed all failure conditions, we block and add point
	_on_add_point(viewport_camera, event)
	return AFTER_GUI_INPUT_STOP


func _set_toolbar_visibility(state:bool) -> void:
	if utility:
		if state:
			utility.show()
		else:
			utility.hide()


func _on_dissolve() -> void:
	if target and network_gizmo.last_modified:
		# dissolve selected point
		target.dissolve_point(network_gizmo.last_modified)

		network_gizmo.last_modified = null
		network_gizmo.second_last_modified = null


func _on_remove() -> void:
	if target and network_gizmo.last_modified:
		# remove selected point
		target.remove_point(network_gizmo.last_modified)

		network_gizmo.last_modified = null
		network_gizmo.second_last_modified = null


func _on_merge() -> void:
	if target and network_gizmo.last_modified and network_gizmo.second_last_modified:
		# Merge the last two selected points
		target.merge_points(network_gizmo.last_modified, network_gizmo.second_last_modified)

		network_gizmo.last_modified = null
		network_gizmo.second_last_modified = null


func _on_link() -> void:
	if target and network_gizmo.last_modified and network_gizmo.second_last_modified:
		# Add an edge between the two last selected points
		target.add_edge(network_gizmo.last_modified, network_gizmo.second_last_modified)


func _on_subdivide() -> void:
	if target and network_gizmo.last_modified and network_gizmo.second_last_modified:
		var edge = target.find_edge(network_gizmo.last_modified, network_gizmo.second_last_modified)
		if edge:
			var middle_node = target.subdivide_edge(edge)
			network_gizmo.last_modified = middle_node


func _on_unlink() -> void:
	if target and network_gizmo.last_modified and network_gizmo.second_last_modified:
		var edge = target.find_edge(network_gizmo.last_modified, network_gizmo.second_last_modified)
		if edge:
			target.remove_edge(edge)


func _on_add_point(camera: Camera3D, event: InputEventMouseButton) -> void:
	_add_point(camera, event.position, utility.portal_mode)


## Add or link nodes.
func _add_point(camera: Camera3D, position:Vector2, portal:bool = false) -> void:
	# return if no target
	if not _target_node:
		return
	var hit_pos:Vector3

	# Step 1: find hit point
	var from = camera.project_ray_origin(position)
	var to = from + (camera.project_ray_normal(position) * RAY_LENGTH)
	var ray = PhysicsRayQueryParameters3D.create(from, to)
	# wait for physics
	await _target_node.get_tree().physics_frame
	var hits = _target_node.get_world_3d().direct_space_state.intersect_ray(ray)
	if hits:
		hit_pos = hits["position"]
	else:
		return
	
	# Step 2: determine if linking to anything else
	var linking:bool = false
	var link_target:NetworkPoint
	var candidates = target.points.filter(func(x:NetworkPoint): return hit_pos.distance_to(x.position) <= SNAP_DISTANCE) # Get all points within distance
	candidates.sort_custom(func(a:NetworkPoint, b:NetworkPoint): return hit_pos.distance_to(a.position) < hit_pos.distance_to(b.position)) # sort by distance
	# if we have candidates, grab closest one
	if not candidates.is_empty():
		linking = true
		link_target = candidates[0]
	
	# Step 3: perform link or add
	if linking: # we are linking
		target.add_edge(link_target, network_gizmo.last_modified) # add between last selected and this one
		network_gizmo.last_modified = link_target # set last modified to link target for easier chaining
	else: # add new node
		var new_pt = target.add_point(hit_pos, portal)
		# if there is something to link, try linking
		if network_gizmo.last_modified:
			target.add_edge(new_pt, network_gizmo.last_modified)
		
		network_gizmo.last_modified = new_pt # set last modified so we can chain
	
	utility.reset_portal_mode()


func _change_cost(text:String) -> void:
	if target and network_gizmo.last_modified and network_gizmo.second_last_modified:
		var edge = target.find_edge(network_gizmo.last_modified, network_gizmo.second_last_modified)
		if edge:
			edge.cost = text.to_float()
			return
	
	push_warning("must select two connected nodes")


func _redraw_gizmo():
	if _target_node:
		_target_node.update_gizmos()

```

### tools

**config_sync_plugin.gd**
```gdscript
extends EditorInspectorPlugin


## Perhaps unintuitively named, this handles things that need to be synced to the sk config; AttributesComponent, SkillsComponent, Equipment Slots.


const SlotSelector = preload("slot_enum_selector.gd")


func _can_handle(object: Object) -> bool:
	return object is VitalsComponent or object is AttributesComponent or object is SkillsComponent or object is EquippableDataComponent


func _parse_begin(object: Object) -> void:
	if object is AttributesComponent:
		_handle_attributes(object)
	elif object is SkillsComponent:
		_handle_skills(object)


func _parse_property(object: Object, _type: Variant.Type, name: String, _hint_type: PropertyHint, _hint_string: String, _usage_flags: int, _wide: bool) -> bool:
	if object is EquippableDataComponent:
		return _handle_slots(object, name)
	return false


func _handle_attributes(object: AttributesComponent) -> void:
	var b := Button.new()
	b.text = "Sync attributes set"
	b.pressed.connect(func() -> void: object.attributes = SkeleRealmsGlobal.config.attributes.duplicate())
	add_custom_control(b)


func _handle_skills(object: SkillsComponent) -> void:
	var b := Button.new()
	b.text = "Sync skill set"
	b.pressed.connect(func() -> void: object.skills = SkeleRealmsGlobal.config.skills.duplicate())
	add_custom_control(b)


func _handle_slots(object:EquippableDataComponent, n:StringName) -> bool:
	if n == "valid_slots":
		add_property_editor("valid_slots", SlotSelector.new())
		return true 
	return false

```

**door_connect.gd**
```gdscript
extends EditorInspectorPlugin


const NODE_3D_VIEWPORT_CLASS_NAME = "Node3DEditorViewport"

var p:EditorPlugin
var _viewports:Array = []
var _cams:Array[Camera3D] = []


func _can_handle(object):
	return object is Door


func _parse_begin(obj:Object):
	var go_to_button:Button = Button.new()
	go_to_button.text = "Jump to door location"
	go_to_button.pressed.connect(func(): _jump_to_door_location(obj as Door))
	add_custom_control(go_to_button)
	var set_position_button:Button = Button.new()
	set_position_button.text = "Set position data"
	set_position_button.pressed.connect(func(): _set_position(obj as Door))
	add_custom_control(set_position_button)


func _jump_to_door_location(obj:Door):
	var path = ProjectSettings.get_setting("skelerealms/worlds_path")
	var res = _find_world(path, obj.destination_instance.world)
	if res == "":
		return
	print("Jumping to location...")
	# Workaround from https://github.com/godotengine/godot/issues/75669#issuecomment-1621230016
	p.get_editor_interface().open_scene_from_path.call_deferred(res)
	p.get_editor_interface().edit_resource.call_deferred(load(res)) # switch tab
	p.get_editor_interface().set_main_screen_editor.call_deferred("3D")
#	var finish_up = func():
#		print("setting camera position %s" % _cams[0].get_parent().get_parent())
#		print(_cams.map(func(c:Camera3D): return c.global_position))
#		var set_cam_position = func():
#			_cams[0].global_position = obj.destination_instance.position
#		set_cam_position.call_deferred()
#	finish_up.call_deferred()


func _set_position(obj:Door) -> void:
	obj.instance.position = obj.global_position
	obj.instance.world = obj.owner.name


func _find_world(path:String, target:String) -> String:
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir(): # if is directory, search subdirectory
				var res = _find_world(file_name, target)
				if not res == "":
					return res
			else: # if filename, cache filename
				var result = file_name.contains(target)
				if result:
					return "%s/%s" % [path, file_name] 
			file_name = dir.get_next()
		dir.list_dir_end()
	return ""


func _init(plug:EditorPlugin):
	p = plug
	_populate_data()


func _populate_data() -> void:
	_find_viewports(p.get_editor_interface().get_base_control())
	for v in _viewports:
		_find_cameras(v)


func _find_viewports(n:Node) -> void:
	if n.get_class() == NODE_3D_VIEWPORT_CLASS_NAME:
		_viewports.append(n)
		return
	
	for c in n.get_children():
		_find_viewports(c)


func _find_cameras(n:Node) -> void:
	if n is Camera3D:
		_cams.append(n)
		return
	
	for c in n.get_children():
		_find_cameras(c)

```

**point_gizmo.gd**
```gdscript
extends EditorNode3DGizmoPlugin


func _get_gizmo_name() -> String:
	return "SKR Point Gizmos"


func _init() -> void:
	create_material("wm", Color(0,0,1))
	create_material("npc", Color(1,0,1))
	create_material("idle", Color(0,1,1))
	create_handle_material("handles")


func _has_gizmo(for_node_3d) -> bool:
	match for_node_3d.get_script():
		NPCSpawnPoint, IdlePoint:
			return true
		_:
			return false


func _redraw(gizmo: EditorNode3DGizmo) -> void:
	gizmo.clear()
	var mesh = SphereMesh.new()
	mesh.radius = 0.5
	gizmo.add_mesh(mesh, get_material(get_mat_for_node(gizmo.get_node_3d()), gizmo))


func get_mat_for_node(n:Node) -> String:
	match n.get_script():
		NPCSpawnPoint:
			return "npc"
		IdlePoint:
			return "idle"
		_:
			return ""

```

**schedule_box.gd**
```gdscript
@tool
extends PanelContainer


const TRACK_WIDTH = 140
const TRACK_OFFSET = 64

var internal_pos:int
var internal_size:int
var editing:ScheduleEvent
var editor:Control

signal delete_requested


func _ready() -> void:
	internal_pos = position.x
	internal_size = size.x
	if editing == null:
		editing = ScheduleEvent.new()
		editing.from = Timestamp.new()
		editing.to = Timestamp.new()


func _on_beginning_point_dragged(offset: Variant) -> void:
	internal_pos += offset.x
	position.x = editor.snap_to_hour(editor.snap_to_minute(editor.scroll_value + internal_pos))


func _on_end_point_dragged(offset: Variant) -> void:
	internal_size += offset.x
	size.x = editor.snap_to_hour(editor.snap_to_minute(position.x + internal_size)) - position.x


func _process(_delta: float) -> void:
	if editor == null:
		return
	
	position.x = editor.snap_to_hour(editor.snap_to_minute(editor.scroll_value + internal_pos))
	
	var start:Dictionary = editor.get_time_from_position(position.x)
	var end:Dictionary = editor.get_time_from_position(position.x + size.x)
	editing.from.hour = start.hour
	editing.from.minute = start.minute
	editing.to.hour = end.hour
	editing.to.minute = end.minute


func switch_track(to:int) -> void:
	position.y = TRACK_OFFSET + TRACK_WIDTH * to


func edit(s:ScheduleEvent, e:Control) -> void:
	editing = s
	editor = e
	internal_pos = editor.position_from_time({
		&"hour": s.from.hour,
		&"minute": s.from.minute,
	})
	size.x = editor.position_from_time({
		&"hour": s.to.hour,
		&"minute": s.to.minute,
	}) - internal_pos
	$MarginContainer/Controls/LineEdit.text = editing.name


func _on_line_edit_text_submitted(new_text: String) -> void:
	editing.name = new_text


func _on_button_pressed() -> void:
	return #EditorInterface.edit_resource(editing)


func _on_remove_pressed() -> void:
	delete_requested.emit()

```

**schedule_editor.gd**
```gdscript
@tool
extends PanelContainer


const TRACK_COUNT = 3
const Span = preload("span.gd")
const BOX_CONTROL = preload("schedule_box_control.tscn")
const SNAP_DIST = 12

@onready var timeline:Control = $ScrollContainer/HBoxContainer
var scroll_value:int
var tracks:Array[Dictionary] = [] # Dictionaries are Control:Span
var track_index:Dictionary = {}
var timeline_width:int
var editing:Array[ScheduleEvent]

signal update_event_array(arr:Array[ScheduleEvent])


func _ready() -> void:
	tracks.resize(3)
	for i:int in range(TRACK_COUNT):
		tracks[i] = {}
	timeline_width = timeline.size.x
	var op:OptionButton = $VBoxContainer/HBoxContainer/OptionButton
	op.clear()
	var inherited:Array = find_classes_that_inherit(&"ScheduleEvent")
	for d:Dictionary in inherited:
		op.add_item(d.class)
		op.set_item_metadata(op.item_count - 1, d.path)
	$VBoxContainer/HBoxContainer/Button.pressed.connect(func() -> void:
		var n:ScheduleEvent = load(op.get_selected_metadata()).new()
		n.from = Timestamp.new()
		n.to = Timestamp.new()
		editing.append(n)
		add_box(n)
		update_event_array.emit(editing)
		)


func _process(_delta: float) -> void:
	scroll_value = timeline.position.x
	_update_tracks()


func _update_tracks() -> void:
	_update_boxes()
	_squash()
	_promote()


func _update_boxes() -> void:
	var boxes:Array = %Container.get_children().map(func(n:Node) -> Control: return n.get_child(0))
	for b:Control in boxes:
		if track_index.has(b):
			tracks[track_index[b]][b].sync(b.get_global_rect())
		else:
			tracks[0][b] = Span.new(b.get_global_rect())
			track_index[b] = 0
			b.switch_track(0)
	# Cleanup
	for b:Control in track_index:
		if not boxes.has(b) or b == null:
			tracks[track_index[b]].erase(b)
			track_index.erase(b)


func _squash() -> void:
	# stupid way of doing it but i think it will be ok?
	# For every track, check against items on bottom track. If no collisions, move it downwards
	# TODO: Handle Overlaps on bottom level?
	var did_move:int
	for track in range(tracks.size() - 1, 0, -1):
		var cd:Dictionary = tracks[track]
		var bd:Dictionary = tracks[track - 1]
		var to_move:Array = []
		var bdkeys:Array = bd.keys()
		bdkeys.sort_custom(func(a:Control, b:Control) -> bool: 
			return bd[a].center > bd[b].center
			)
		for event in cd:
			var valid:bool = true
			
			for obstacle in bdkeys:
				# if any obstacle on track below blocks this, stop looking
				if cd[event].overlaps(bd[obstacle]):
					valid = false
					break
			if valid:
				to_move.append(event)
		# Finalize movement
		for e in to_move:
			e.switch_track(track - 1)
			track_index[e] = track - 1
			bd[e] = cd[e]
			cd.erase(e)
		did_move = max(did_move, to_move.size())
	# If we moved any, squash again. If not, then we are done quashing
	if did_move > 0:
		_squash()


func _promote() -> void:
	# and "least efficient algorithm" award goes to...
	# For every item in each track, check against other items in track to see if it needs to move
	# If it collides with anything, move it. 
	# TODO: Handle overlaps on top level
	var did_move:int
	for track in range(tracks.size() - 1):
		var cd:Dictionary = tracks[track]
		var ad:Dictionary = tracks[track + 1]
		var to_move:Array = []
		var cdkeys:Array = cd.keys()
		cdkeys.sort_custom(func(a:Control, b:Control) -> bool: 
			return cd[a].center > cd[b].center
			)
		for event in cdkeys:
			var valid:bool = false
			
			for obstacle in cdkeys:
				if obstacle == event:
					continue
				if to_move.has(obstacle): # ignore ones we are already moving
					continue
				# if any overlap, we will move upwards
				if cd[event].overlaps(cd[obstacle]):
					valid = true
					break
			if valid:
				to_move.append(event)
		# Finalize movement
		for e in to_move:
			e.switch_track(track + 1)
			track_index[e] = track + 1 
			ad[e] = cd[e]
			cd.erase(e)
		did_move = max(did_move, to_move.size())
	
	if did_move > 0:
		_promote()


func get_time_from_position(pos:int) -> Dictionary:
	var minute:int = ((pos % timeline.HOUR_SEPARATION) / (timeline.HOUR_SEPARATION as float)) * ProjectSettings.get_setting("skelerealms/minutes_per_hour")
	var hour:int =  floori(pos / (timeline.HOUR_SEPARATION as float))
	return {
		&"hour": hour,
		&"minute": minute
	}


func position_from_time(d:Dictionary) -> int:
	var i:int = d.hour * timeline.HOUR_SEPARATION
	i += floori((d.minute / (ProjectSettings.get_setting("skelerealms/minutes_per_hour") as float)) * timeline.HOUR_SEPARATION)
	return i


func snap_to_minute(pos:int) -> int:
	var fac:int = timeline.size.x / (ProjectSettings.get_setting("skelerealms/minutes_per_hour") * ProjectSettings.get_setting("skelerealms/hours_per_day"))
	return pos


func snap_to_hour(pos:int) -> int:
	var nearest_hour:int = roundi(pos / timeline.HOUR_SEPARATION) * timeline.HOUR_SEPARATION
	var dist:int = abs(nearest_hour - pos)
	if dist <= SNAP_DIST:
		return nearest_hour
	else:
		return pos


func edit(s:Array[ScheduleEvent]) -> void:
	editing = s
	for c:Node in %Container.get_children():
		c.queue_free()
	for e:ScheduleEvent in s:
		add_box(e)


func add_box(e:ScheduleEvent) -> void:
	var b:Control = BOX_CONTROL.instantiate()
	b.get_child(0).delete_requested.connect(func() -> void:
		tracks[track_index[b.get_child(0)]].erase(b.get_child(0))
		track_index.erase(b.get_child(0))
		editing.remove_at(editing.find(e))
		update_event_array.emit(editing)
		b.queue_free()
		)
	%Container.add_child(b)
	b.get_child(0).edit(e, self)


static func find_classes_that_inherit(what:StringName) -> Array:
	return ProjectSettings.get_global_class_list()\
		.filter(func(d:Dictionary)->bool: return d.base == what)

```

**schedule_editor_plugin.gd**
```gdscript
@tool
extends EditorInspectorPlugin


const ScheduleEditor := preload("res://addons/skelerealms/tools/schedule_editor.tscn")

signal request_open(events: Array[ScheduleEvent])


func _can_handle(object: Object) -> bool:
	return object is Schedule


func _parse_begin(object: Object) -> void:
	var b := Button.new()
	b.text = "Open schedule editor"
	b.pressed.connect(func() -> void: request_open.emit((object as Schedule).events))
	add_custom_control(b)

```

**schedule_markers.gd**
```gdscript
@tool
extends HBoxContainer


const HOUR_SEPARATION = 256
const H_LINE_WIDTH = 6
const HH_LINE_WIDTH = 2


@onready var hpd:int = ProjectSettings.get_setting("skelerealms/hours_per_day")
var default_font:Font
var default_font_size:int


func _ready() -> void:
	custom_minimum_size = Vector2((hpd + 1) * HOUR_SEPARATION, 0)
	default_font = ThemeDB.fallback_font
	default_font_size = ThemeDB.fallback_font_size


func _draw() -> void:
	draw_hour_lines()
	draw_half_hour_lines()


func draw_hour_lines() -> void:
	var arr:PackedVector2Array = PackedVector2Array()
	arr.resize((hpd + 1) * 2)
	for i in range(hpd + 1):
		var x:int = HOUR_SEPARATION * i
		arr[i * 2] = Vector2(x, 0)
		arr[i * 2 + 1] = Vector2(x, size.y)
		draw_string(default_font, Vector2(x + 5, size.y - default_font_size - 5), "%dh" % i)
	draw_multiline(arr, Color.DARK_SLATE_GRAY, H_LINE_WIDTH)


func draw_half_hour_lines() -> void:
	var arr:PackedVector2Array = PackedVector2Array()
	arr.resize((hpd + 1) * 2)
	for i in range(hpd + 1):
		var x:int = (HOUR_SEPARATION * i) + (HOUR_SEPARATION / 2)
		arr[i * 2] = Vector2(x, 0)
		arr[i * 2 + 1] = Vector2(x, size.y)
	draw_multiline(arr, Color.hex(0x55_55_55), HH_LINE_WIDTH)

```

**scheduledraghandle.gd**
```gdscript
@tool
extends Control


var dragging:bool
var editing:ScheduleEvent
signal dragged(offset)


func _gui_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if (event as InputEventMouseButton).pressed:
				if _contains(event.global_position):
					dragging = true
			else:
				dragging = false
	elif event is InputEventMouseMotion:
		if dragging:
			dragged.emit(event.relative)


func _contains(pos: Vector2) -> bool:
	return get_global_rect().has_point(pos)

```

**slot_enum_selector.gd**
```gdscript
extends EditorProperty


var option_button: OptionButton = OptionButton.new()
var updating:bool
var current:Array[StringName] = []
var parent_vbox := VBoxContainer.new()
var items_vbox := VBoxContainer.new()


func _init() -> void:
	add_child(parent_vbox)
	parent_vbox.add_child(items_vbox)
	
	var hbox := HBoxContainer.new()
	var b := Button.new()
	b.text = "Add item"
	b.pressed.connect(func() -> void:
		_add_item(option_button.get_item_text(option_button.get_selected_id()))
		_sync()
		)
	hbox.add_child(option_button)
	hbox.add_child(b)
	parent_vbox.add_child(hbox)
	
	add_focusable(option_button)


func _ready() -> void:
	for i:StringName in SkeleRealmsGlobal.config.equipment_slots:
		option_button.add_item(i)
		var n_i:int = option_button.item_count - 1


func _sync() -> void:
	var values:Array[StringName] = _get_values()
	if not values == get_edited_object()[get_edited_property()]:
		current = values
		emit_changed(get_edited_property(), values)
		return


func _update_property() -> void:
	var new_value:Array[StringName] = get_edited_object()[get_edited_property()]
	
	if (new_value == current):
		return
	
	updating = true 
	current = new_value
	
	for n:Node in items_vbox.get_children():
		n.queue_free()
	for i:StringName in new_value:
		_add_item(i)
	updating = false


func _add_item(kind:StringName = &"") -> void:
	if (not kind.is_empty()) and _get_values().has(kind):
		return
	var hbox := HBoxContainer.new()
	
	var o:OptionButton = option_button.duplicate()
	if not kind.is_empty():
		for i:int in o.item_count:
			if o.get_item_text(i) == kind:
				o.select(i)
				break
	o.item_selected.connect(func(_i:int) -> void: _sync())
	hbox.add_child(o)
	
	var b := Button.new()
	b.text = "Delete"
	b.pressed.connect(func() -> void: 
		hbox.queue_free()
		_sync()
		)
	hbox.add_child(b)
	
	items_vbox.add_child(hbox)


func _get_values() -> Array[StringName]:
	var output:Array[StringName] = []
	
	for n:Node in items_vbox.get_children():
		var o:OptionButton = ((n as HBoxContainer).get_child(0) as OptionButton)
		output.append(o.get_item_text(o.get_selected_id()))
	
	return output

```

**span.gd**
```gdscript
@tool
extends RefCounted


var start: float
var end: float 
var size:
	get:
		return end - start
var center:int:
	get:
		return roundi((start + end) / 2)


func overlaps(other: Object) -> bool: 
	return contains_point(other.start) or contains_point(other.end) or encloses(other) or other.encloses(self)


func contains_point(pt:float) -> bool:
	return start <= pt and pt <= end


func encloses(other: Object) -> bool:
	return start <= other.start and end >= other.end


func sync(r:Rect2) -> void:
	start = r.position.x
	end = r.end.x


func _init(r:Rect2):
	sync(r)

```

**template_selector.gd**
```gdscript
@tool
extends PanelContainer


const FILE_INHERIT = 1

@onready var option_button: OptionButton = $VBoxContainer/HBoxContainer/OptionButton
@onready var file_dialog: FileDialog = $FileDialog

var editing:SKWorldEntity


# life will be pain until this gets merged https://github.com/godotengine/godot/pull/90057


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var templates:PackedStringArray = ProjectSettings.get_setting("skelerealms/entity_archetypes")
	option_button.clear()
	for t:String in templates:
		option_button.add_item(t)


func edit(what:SKWorldEntity) -> void:
	editing = what


func _on_button_pressed() -> void:
	file_dialog.popup_centered()
	#_create_using_editor()


func _grab_uid(path:String) -> String:
	return ResourceUID.id_to_text(ResourceLoader.get_resource_uid(path))


func _generate_inherited_scene_id() -> String:
	return "1_%s" % SKIDGenerator.generate_id(5).to_lower()


func _format_scene(from:String, entity_name:String) -> String:
	var id:String = _generate_inherited_scene_id()
	var uid:String = ResourceUID.id_to_text(ResourceUID.create_id())
	return """
[gd_scene load_steps=2 format=3 uid=\"%s\"]

[ext_resource type=\"PackedScene\" uid=\"%s\" path=\"%s\" id=\"%s\"]

[node name=\"%s\" instance=ExtResource(\"%s\")]
""" % [
	uid,
	_grab_uid(from),
	from,
	id,
	entity_name,
	id
]


func _on_file_dialog_file_selected(path: String) -> void:
	_make_manually(path)
	#_create_using_instantiation(path)


func _make_manually(path:String) -> void:
	var p:String = option_button.get_item_text(option_button.selected)
	var contents:String = _format_scene(p, "test_entity")
	var fh := FileAccess.open(path, FileAccess.WRITE)
	fh.store_string(contents)
	fh.close()
	EditorInterface.get_resource_filesystem().scan()
	EditorInterface.get_resource_filesystem().update_file(path)
	EditorInterface.get_resource_previewer().queue_resource_preview(path, self, &"receive_thumbnail", null)
	editing.entity = ResourceLoader.load(path)


func _create_using_editor() -> void:
	EditorInterface.get_file_system_dock().navigate_to_path(option_button.get_item_text(option_button.selected))
	
	var popup:PopupMenu = EditorInterface.get_file_system_dock().get_children()\
		.filter(func(n:Node)->bool:return n is PopupMenu)\
		.filter(func(p:PopupMenu) -> bool: return p.item_count > 0)\
		.filter(func(p:PopupMenu) -> bool: return p.get_item_text(0) == "Open Scene")\
		[0]
	
	if popup:
		popup.id_pressed.emit(FILE_INHERIT)


func _create_using_instantiation(path:String) -> void:
	var p:String = option_button.get_item_text(option_button.selected)
	var new_scene:Node = (ResourceLoader.load(p) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_MAIN_INHERITED)
	new_scene.scene_file_path = p
	print(new_scene.scene_file_path)
	var new_ps := PackedScene.new()
	new_ps.pack(new_scene)
	ResourceSaver.save(new_ps, path)


func receive_thumbnail(_path:String, _preview:Texture2D, _thumbnail_preview:Texture2D, _userdata:Variant) -> void:
	return

```

**world_entity_plugin.gd**
```gdscript
extends EditorInspectorPlugin


const TemplateSelector = preload("res://addons/skelerealms/tools/template_selector.tscn")


func _can_handle(object: Object) -> bool:
	return object is SKWorldEntity


func _parse_begin(object: Object) -> void:
	var b := Button.new()
	b.text = "Sync position with entity"
	b.pressed.connect(object._sync.bind())
	
	var t := TemplateSelector.instantiate()
	t.edit(object)
	
	var vbox := VBoxContainer.new()
	vbox.add_child(b)
	vbox.add_child(t)
	
	add_custom_control(vbox)

```

