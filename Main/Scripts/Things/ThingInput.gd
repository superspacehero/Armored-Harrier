extends UnsavedThing
class_name ThingInput

var device_type: String = ""
var device_id: int = 0

var is_player = true

# AI Variables
var action_coroutine = null
var targets = [] # This should be an array of GameThing nodes
var current_target_index = 0
var can_control = false
enum AIState { CHOOSING_ACTION, IDLING, MOVING, ATTACKING, HEALING, FLEEING, ENDING_TURN }
var action_delay = 1.0

var move_action: Vector2 = Vector2.ZERO:
	set(value):
		if value != move_action:
			for game_thing in inventory:
				game_thing.move(value)
	get:
		return move_action

var aim_action: Vector2 = Vector2.ZERO:
	set(value):
		if value != aim_action:
			for game_thing in inventory:
				game_thing.aim(value)
	get:
		return aim_action

var left_trigger_action: bool = false:
	set(value):
		if value != left_trigger_action:
			for game_thing in inventory:
				game_thing.left_trigger(value)

var right_trigger_action: bool = false:
	set(value):
		if value != right_trigger_action:
			for game_thing in inventory:
				game_thing.right_trigger(value)

var primary_action: bool = false:
	set(value):
		if value != primary_action:
			for game_thing in inventory:
				game_thing.primary(value)

var secondary_action: bool = false:
	set(value):
		if value != secondary_action:
			for game_thing in inventory:
				game_thing.secondary(value)

var tertiary_action: bool = false:
	set(value):
		if value != tertiary_action:
			for game_thing in inventory:
				game_thing.tertiary(value)

var quaternary_action: bool = false:
	set(value):
		if value != quaternary_action:
			for game_thing in inventory:
				game_thing.quaternary(value)

var pause_action: bool = false:
	set(value):
		if value != pause_action:
			for game_thing in inventory:
				game_thing.pause(value)

func process_input_event(action: String, value):
	match action:
		"move_up":
			move_action.y = -value
			move_action = move_action
		"move_down":
			move_action.y = value
			move_action = move_action
		"move_left":
			move_action.x = -value
			move_action = move_action
		"move_right":
			move_action.x = value
			move_action = move_action

		"mouse_motion":
			aim_action = Vector2(value.y, value.x)
		"aim_up":
			aim_action.x = -value
			aim_action = aim_action
		"aim_down":
			aim_action.x = value
			aim_action = aim_action
		"aim_left":
			aim_action.y = -value
			aim_action = aim_action
		"aim_right":
			aim_action.y = value
			aim_action = aim_action

		"left_trigger":
			left_trigger_action = value > 0.5 # if value is more than halfway pressed, assume true
		"right_trigger":
			right_trigger_action = value > 0.5
		"primary":
			primary_action = value > 0.5
		"secondary":
			secondary_action = value > 0.5
		"tertiary":
			tertiary_action = value > 0.5
		"quaternary":
			quaternary_action = value > 0.5
		"pause":
			pause_action = value > 0.5

	# print(action, ": ", value)
