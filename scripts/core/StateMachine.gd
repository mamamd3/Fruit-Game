extends Node
class_name StateMachine
# StateMachine.gd v3 — IDLE/MOVE/SHOOT/HIT/DEAD

signal state_changed(from: State, to: State)

enum State { IDLE, MOVE, SHOOT, HIT, DEAD }

var current: State = State.IDLE

func transition(new_state: State) -> void:
	if new_state == current: return
	if current == State.DEAD: return
	if current == State.HIT and new_state not in [State.IDLE, State.DEAD]: return
	var prev := current
	current = new_state
	emit_signal("state_changed", prev, current)

func can_move()  -> bool: return current in [State.IDLE, State.MOVE]
func can_shoot() -> bool: return current in [State.IDLE, State.MOVE]
func is_alive()  -> bool: return current != State.DEAD
