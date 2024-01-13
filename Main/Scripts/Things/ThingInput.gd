extends GameThing
class_name ThingInput

var input
var device_id: int = 0

@export var is_player = true

var move_action: Vector2 = Vector2.ZERO:
	set(value):
		if value != move_action:
			for game_thing in inventory:
				game_thing.move(value)
			move_action = value
	get:
		return move_action

var aim_action: Vector2 = Vector2.ZERO:
	set(value):
		if value != aim_action:
			for game_thing in inventory:
				game_thing.aim(value)
			aim_action = value
	get:
		return aim_action
				
var mouse_input: Vector2 = Vector2.ZERO:
	set(value):
		if value != mouse_input:
			aim_action = value
			mouse_input = value

var left_trigger_action: bool = false:
	set(value):
		if value != left_trigger_action:
			for game_thing in inventory:
				game_thing.left_trigger(value)
			left_trigger_action = value

var right_trigger_action: bool = false:
	set(value):
		if value != right_trigger_action:
			for game_thing in inventory:
				game_thing.right_trigger(value)
			right_trigger_action = value

var left_bumper_action: bool = false:
	set(value):
		if value != left_bumper_action:
			for game_thing in inventory:
				game_thing.left_bumper(value)
			left_bumper_action = value

var right_bumper_action: bool = false:
	set(value):
		if value != right_bumper_action:
			for game_thing in inventory:
				game_thing.right_bumper(value)
			right_bumper_action = value

var primary_action: bool = false:
	set(value):
		if value != primary_action:
			for game_thing in inventory:
				game_thing.primary(value)
			primary_action = value

var secondary_action: bool = false:
	set(value):
		if value != secondary_action:
			for game_thing in inventory:
				game_thing.secondary(value)
			secondary_action = value

var tertiary_action: bool = false:
	set(value):
		if value != tertiary_action:
			for game_thing in inventory:
				game_thing.tertiary(value)
			tertiary_action = value

var quaternary_action: bool = false:
	set(value):
		if value != quaternary_action:
			for game_thing in inventory:
				game_thing.quaternary(value)
			quaternary_action = value

var previous_target_action: bool = false:
	set(value):
		if value != previous_target_action:
			for game_thing in inventory:
				game_thing.previous_target(value)
			previous_target_action = value

var next_target_action: bool = false:
	set(value):
		if value != next_target_action:
			for game_thing in inventory:
				game_thing.next_target(value)
			next_target_action = value

var pause_action: bool = false:
	set(value):
		if value != pause_action:
			for game_thing in inventory:
				game_thing.pause(value)
			pause_action = value

var aiming_this_frame: bool = false

func _input(event):
	if is_player:
		move_action = input.get_vector("move_left", "move_right", "move_up", "move_down")
		aim_action = input.get_vector("aim_up", "aim_down", "aim_left", "aim_right")
		
		left_trigger_action = input.is_action_pressed("left_trigger")
		right_trigger_action = input.is_action_pressed("right_trigger")

		previous_target_action = input.is_action_pressed("previous_target")
		next_target_action = input.is_action_pressed("next_target")

		primary_action = input.is_action_pressed("primary")
		secondary_action = input.is_action_pressed("secondary")
		tertiary_action = input.is_action_pressed("tertiary")
		quaternary_action = input.is_action_pressed("quaternary")
		pause_action = input.is_action_pressed("pause")
		
		if device_id < 0:
			# Get mouse movement
			if event is InputEventMouseMotion:
				mouse_input = Vector2(event.relative.y, event.relative.x)
				aiming_this_frame = true

func _process(_delta):
	if not aiming_this_frame:
		mouse_input = Vector2.ZERO
	aiming_this_frame = false

# Called when the node is destroyed
func tree_exiting():
	InputManager.instance.unregister_thing_input(device_id)
