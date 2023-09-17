extends Node
class_name InputManager

static var instance: InputManager = null

# This dictionary will store ThingInput nodes by device type and device_id
var registered_inputs: Dictionary = {
	"Keyboard": {},
	"Gamepad": {}
}

# Resource to instantiate when a new device is detected
@export var thing_input_prefab: PackedScene = null

# List of actions you want to explicitly process (whitelist)
var allowed_actions: Array = [
	"move_up", "move_down", "move_left", "move_right",
	"aim_up", "aim_down", "aim_left", "aim_right",
	"left_trigger", "right_trigger",
	"primary", "secondary", "tertiary", "quaternary", 
	"pause"
]

func _ready():
	if not instance:
		instance = self

func _input(event):
	var device_type = ""
	var device_id = 0

	# Check if the event corresponds to any of our defined actions
	var matched_action = ""
	for action in allowed_actions:
		if event.is_action(action):
			matched_action = action
			break

	if event is InputEventMouseMotion:
		matched_action = "mouse_motion"

	# If no action matches, exit early
	if matched_action == "":
		return

	if event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		device_type = "Keyboard"
		device_id = 0 # Let's assume all keyboards are 0, as typically you don't have multiple keyboards

	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		device_type = "Gamepad"
		device_id = event.device

	if device_type in registered_inputs:
		if device_id in registered_inputs[device_type]:
			var target_thing_input = registered_inputs[device_type][device_id]

			var value = 0
			if event is InputEventMouseMotion:  # Checking if the event is a mouse motion event
				value = event.relative  # For mouse motion inputs
			elif event.is_action_pressed(matched_action):
				value = 1
			elif event is InputEventJoypadMotion:  # Checking if the event is an analog motion event
				if event.is_action(matched_action):
					value = event.axis_value  # For analog joystick inputs
			
			target_thing_input.process_input_event(matched_action, value)
		else:
			# New device detected! Instantiate and register.
			if thing_input_prefab:
				var new_instance = thing_input_prefab.instantiate() 
				self.add_child(new_instance)

				# Search for ThingInput in the children
				var new_thing_input = new_instance.find_child("Input", true, false)
				if new_thing_input:
					new_thing_input.device_type = device_type
					new_thing_input.device_id = device_id
					register_thing_input(new_thing_input, device_type, device_id)

func register_thing_input(thing_input, device_type: String, device_id: int = 0):
	if device_type not in registered_inputs:
		registered_inputs[device_type] = {}
	
	registered_inputs[device_type][device_id] = thing_input

func unregister_thing_input(device_type: String, device_id: int = 0):
	if device_type in registered_inputs and device_id in registered_inputs[device_type]:
		registered_inputs[device_type].erase(device_id)
