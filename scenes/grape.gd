extends CharacterBody2D


@onready var CoyoteTimer: Timer = $Coyote
@onready var JumpBufferTimer: Timer = $JumpBufferTimer

var coyote_time_activated: bool = false

const jump_height: float = -230
var gravity: float = 12
const max_gravity: float = 14.5

const max_speed: float = 80
const acceleration: float = 8
const friction: float = 10

func _physics_process(delta: float) -> void:
	var x_input: float = Input.get_action_strength("move_right2") - Input.get_action_strength("move_left2")
	var velocity_wieght: float = delta * (acceleration if x_input else friction)
	velocity.x = lerp(velocity.x, x_input * max_speed, velocity_wieght)

	if is_on_floor():
		coyote_time_activated = false
		gravity = lerp(gravity, 12.0, 12.0 * delta)
	else:
		if CoyoteTimer.is_stopped() and !coyote_time_activated:
			CoyoteTimer.start()
			coyote_time_activated = true
			
		if Input.is_action_just_released("move_up2") or is_on_ceiling():
			velocity.y *= 0.5
	
		gravity = lerp(gravity, max_gravity, 12.0 * delta)
	
	if Input.is_action_just_pressed("move_up2"):
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
			if head_collision[0]:
				global_position.x += 1.75
			if head_collision[2]:
				global_position.x -= 1.75
	
	if velocity.y > -30 and velocity.y < -5 and abs(velocity.x) > 3:
		if $RayCast2D3.is_colliding() and !$RayCast2D4.is_colliding() and velocity.x < 0:
			velocity.y += jump_height/3.25
		if $RayCast2D.is_colliding() and !$RayCast2D2.is_colliding() and velocity.x > 0:
			velocity.y += jump_height/3.25
	
	velocity.y += gravity
	
	move_and_slide()
