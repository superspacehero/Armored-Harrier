extends UnsavedThing
class_name CharacterThing

# 1. Member Variables/Properties

@export var character_body : CharacterBody3D = null
@export var gameplay_camera : GameplayCamera
@export var character_base : ThingSlot = null

@export_category("Movement")
@export var character_speed : float = 8  # The speed at which the character moves.
@export var jump_height: float = 1  # The height of the character's jump.
@export var jump_offset: float = 0.15  # The offset of the character's jump.
@export var gravity: float = 100  # The gravity of the character.

@onready var jump_full_height: float = jump_height + jump_offset
@onready var jump_velocity: float = sqrt(2 * gravity * jump_full_height)

enum control_level { NONE, MOVEMENT_ONLY, FULL }
@export var can_control: control_level = control_level.FULL
@export var can_move: bool = true
@export var can_jump: bool = true
# @onready var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

enum movement_rotation_behavior { NONE, FULL_ROTATION, LEFT_RIGHT_ROTATION, TOWARDS_CAMERA }
@export var rotation_behavior = movement_rotation_behavior.TOWARDS_CAMERA

@export_category("Energy")
@export var max_energy : float = 100.0
@export var energy_bar : ProgressBar
@export var energy_recovery_rate : float = 20.0

var energy_consumption_rate : float
var can_use_energy : bool = true

var target_movement : Vector2 = Vector2.ZERO
var current_movement : Vector2 = Vector2.ZERO

@export_category("Control Smoothing")
@export var ground_control_smoothness : float = 0.1  # Control how smoothly the character changes direction on the ground
@export var air_control_smoothness : float = 0.05  # Control how smoothly the character changes direction in the air
@export var anti_gravity_smoothness : float = 0.1  # Control how smoothly the character changes direction in the air

var jump_input: bool = false
var is_jumping: bool = false

var thrust_amount : Vector2 = Vector2(0, 0)

var velocity : Vector3 = Vector3.ZERO
var goto_rotation: float
var rotation_time: float = 0.25

var rotation_direction: Vector3 = Vector3.FORWARD

var energy : float:
	set(value):
		_energy = value
		if _energy <= 0:
			_energy = 0
			can_use_energy = false
		elif _energy >= max_energy:
			_energy = max_energy
			can_use_energy = true

		energy_bar.value = _energy
	get:
		return _energy
var _energy : float

# 2. Built-in Functions

func _init():
	thing_type = "Character"

func _ready():
	super()

	assemble_character()
	gameplay_camera.set_camera_object(self, 1, true)
	character_body.velocity = Vector3.ZERO
	energy = max_energy
	
	rotate_base(Vector3.FORWARD if rotation_behavior != movement_rotation_behavior.LEFT_RIGHT_ROTATION else Vector3.RIGHT)

func _physics_process(delta):
	# Lerp the current movement towards the target movement
	if is_in_air():
		current_movement = current_movement.lerp(target_movement, air_control_smoothness)
	else:
		current_movement = current_movement.lerp(target_movement, ground_control_smoothness)

	var movement_vector = calculate_movement_direction(current_movement)

	velocity.x = movement_vector.x * character_speed
	velocity.z = movement_vector.z * character_speed

	if character_body.is_on_floor():
		if thrust_amount.y == 0 and not jump_input:
			is_jumping = false

		if can_control != control_level.NONE and can_jump and jump_input and not is_jumping:
			velocity.y = jump_velocity
			is_jumping = true
		elif velocity.y < 0:
			velocity.y = 0
	else:
		velocity.y -= gravity * delta

		if not is_jumping:
			is_jumping = true

	if is_jumping or thrust_amount.y != 0:
		velocity.y += thrust_amount.y * delta

	# Apply horizontal thrust
	if thrust_amount.x != 0:
		var thrust_direction = Vector3.ZERO
		if current_movement.length() == 0:
			# Default forward direction when there's no movement input
			thrust_direction = -character_base.basis.z.normalized()
		else:
			# Use the movement vector for thrust direction when there is input
			thrust_direction = calculate_movement_direction(current_movement)

		velocity += thrust_direction * thrust_amount.x * delta
		if is_in_air() and velocity.y < 0:
			velocity.y = lerp(velocity.y, 0.0, anti_gravity_smoothness)

	character_body.move_and_slide()
	character_body.velocity = velocity

func is_in_air() -> bool:
	return !character_body.is_on_floor() and is_jumping

func _process(delta):
	if can_use_energy:
		if energy_consumption_rate > 0:
			energy -= energy_consumption_rate * delta
		else:
			energy += energy_recovery_rate * delta
	elif energy < max_energy:
		energy += energy_recovery_rate * delta
		
	rotate_towards_goto_rotation(delta)

# 3. Movement Functions

func calculate_movement_direction(input_direction: Vector2) -> Vector3:
	# Extract the horizontal components of the camera's orientation
	var forward_horizontal = Vector3(gameplay_camera.global_transform.basis.z.x, 0, gameplay_camera.global_transform.basis.z.z).normalized()
	var right_horizontal = Vector3(gameplay_camera.global_transform.basis.x.x, 0, gameplay_camera.global_transform.basis.x.z).normalized()

	# Calculate the movement direction based on the horizontal components
	var direction = forward_horizontal * input_direction.y + right_horizontal * input_direction.x

	# Maintain the length of the input vector for smoothness
	# Normalize only if the length is greater than 1 to maintain the original scale of input_direction
	if direction.length() > 1:
		direction = direction.normalized()

	if direction.length() > 0.01:
		rotate_base(direction)

	return direction

func rotate_base(direction: Vector3):

	match rotation_behavior:
		movement_rotation_behavior.NONE:
			pass
		movement_rotation_behavior.FULL_ROTATION:
			# Do nothing. The character will rotate in the direction of target_movement.
			pass
		movement_rotation_behavior.LEFT_RIGHT_ROTATION:
			if direction.x != 0:
				direction.x = sign(direction.x)

			direction = round(direction)
			
			if direction.x == 0:
				direction.x = rotation_direction.x
			
			direction.z *= 0.5
		movement_rotation_behavior.TOWARDS_CAMERA:
			direction = -gameplay_camera.basis.z

	rotation_direction = direction
	goto_rotation = atan2(rotation_direction.x, rotation_direction.z)
	# print("goto_rotation: " + str(rad_to_deg(goto_rotation)))
	
func rotate_towards_goto_rotation(delta):
	character_base.rotation.y = lerp_angle(character_base.rotation.y, Vector2(-rotation_direction.z, -rotation_direction.x).angle(), delta / rotation_time)

# 4. Event Handling Functions

func move(direction):
	# Normalize the direction to ensure constant speed.
	if direction.length() > 1:
		direction = direction.normalized()

	target_movement = direction
	
	# print("move: " + str(direction))

func aim(direction):
	gameplay_camera.camera_rotation_amount = direction
	
func primary(pressed):
	for part in parts:
		if part is CharacterPartThing:
			part.primary(pressed)

func secondary(pressed):
	for part in parts:
		if part is CharacterPartThing:
			part.secondary(pressed)

func tertiary(pressed):
	for part in parts:
		if part is CharacterPartThing:
			part.tertiary(pressed)

func quaternary(pressed):
	for part in parts:
		if part is CharacterPartThing:
			part.quaternary(pressed)

func left_trigger(pressed):
	for part in parts:
		if part is CharacterPartThing:
			part.left_trigger(pressed)

func right_trigger(pressed):
	for part in parts:
		if part is CharacterPartThing:
			part.right_trigger(pressed)

func pause(_pressed):
	pass

# 5. Character Assembly Variables

@export_category("Character Assembly")

@export_file("*.tres") var character_info_path
var parts: Array = [CharacterPartThing]
var added_parts: Array = [CharacterPartThing]

# 6. Character Assembly Functions

func assemble_character(path: String = ""):
	clear_previous_parts()
	if path == "":
		path = character_info_path
	var character_info_resource = load(path)
	
	if character_info_resource:
		thing_name = character_info_resource.name
		thing_description = character_info_resource.description
		thing_value = character_info_resource.value

		# print("Assembling character: " + thing_name)

		for part in character_info_resource.character_parts:
			var part_instance = part.instantiate()
			if part_instance is HeadThing:
				thing_top = part_instance.thing_top
			parts.append(part_instance)
			# Set any properties on the part, such as color.
			part_instance.character = self

		# Attach parts to other parts.
		attach_part_to_slot(character_base)

	thing_top = thing_top

func clear_previous_parts() -> void:
	# Clear children from the base.
	for child in character_base.get_children():
		child.queue_free()

	parts.clear()
	added_parts.clear()

func attach_part(part: CharacterPartThing, parent: ThingSlot):
	if !added_parts.has(part):
		parent.add_thing(part)
		added_parts.append(part)

		part.position = Vector3.ZERO
		# part.rotation = Vector3.ZERO
		part.scale = Vector3.ONE

		# Add the weight of the part to the character.
		thing_weight += part.thing_weight

		# Merge the variables of the part with the character.
		variables.merge(part.variables)

		attach_parts_to_part(part)

		# print("Attached part: " + part.name + " to " + parent.name)

func attach_parts_to_part(part: CharacterPartThing):
	for slot in part.inventory:
		if slot is ThingSlot:
			attach_part_to_slot(slot)

func attach_part_to_slot(slot: ThingSlot):
	var attached_part_success: bool = false
	for part in parts:
		if (part.thing_type == slot.thing_type or part.thing_subtype == slot.thing_type) and !added_parts.has(part):
			attach_part(part, slot)
			attached_part_success = true
			break
	if !attached_part_success:
		print("No part to attach to slot: " + slot.name)
