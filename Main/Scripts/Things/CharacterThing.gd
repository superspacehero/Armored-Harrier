extends TargetableThing
class_name CharacterThing

# 1. Member Variables/Properties

@export var character_body : CharacterBody3D = null
@export var character_collision : CollisionShape3D = null
@export var aimer : Node3D = null
@export var character_base : ThingSlot = null

@export_category("Movement")
@export var move_speed : float = 8  # The speed at which the character moves.
@export var jump_height: float = 8  # The height of the character's jump.
@export var jump_offset: float = 0.15  # The offset of the character's jump.
@export var gravity: float = 50  # The gravity of the character.

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

@export_category("Targeting")
@export_range(0.0, 1.0) var target_hostility_threshold : float = 0.0

var targets: Array = []
var target: TargetableThing = null

func sort_targets():
	for _target in targets:
		if _target is Target:
			continue
		else:
			return  # Don't sort if there are any non-Target objects in the array

	targets.sort_custom(_sort_targets_left_to_right)

func _sort_targets_left_to_right(a: Target, b: Target) -> int:
	return int(a.position.x < b.position.x)

func cycle_target(direction: int):
	if targets.size() == 0:
		return

	# Ensure targets are sorted before cycling
	sort_targets()

	# Check if the current target is still valid
	if is_instance_valid(target):
		var index = find_target_index(target)
		# Calculate new index, making sure it's within the array bounds
		index = (index + direction + targets.size()) % targets.size()
		set_target(targets[index].target)
	else:
		# If current target is not valid, select a new target if available
		if targets.size() > 0:
			set_target(targets[0].target)
		else:
			target = null

func find_target(target_object: TargetableThing) -> Node:
	for _target in targets:
		if _target is Target and _target.target == target_object:
			return _target
		elif _target == target_object:
			return _target
	return null

func find_target_index(target_object: TargetableThing) -> int:
	if not is_instance_valid(target_object):
		return -1

	for i in range(targets.size()):
		if targets[i].target == target_object:
			return i
	return -1

func set_target(new_target: TargetableThing):
	target = new_target
	set_targets_selected()

func set_targets_selected():
	for _target in targets:
		if _target is Target:
			(_target as Target).selected = _target.target == target

func is_ally(target_object: TargetableThing) -> bool:
	if target_object == null:
		return false
	return target_object.thing_team == thing_team

func damage(amount : int, attacker : GameThing = null):
	health -= amount
	add_target(attacker, true)

func add_target(target_object: TargetableThing, override_target_requirements: bool = false):
	if target_object == null or find_target(target_object) != null:
		return  # Exit if target is null or already in the list

	var should_add_target = override_target_requirements or not is_ally(target_object) and target_object.thing_hostility >= target_hostility_threshold
	if not should_add_target:
		return  # Exit if we should not add this target

	var new_target
	if aimer is GameplayCamera:
		new_target = GameManager.instance.target_pool.get_object_from_pool(position)
		new_target.camera = aimer as GameplayCamera
		new_target.target = target_object
		new_target.get_parent().remove_child(new_target)
		aimer.add_child(new_target)
	else:
		new_target = target_object

	targets.append(new_target)

	if target == null:
		set_target(target_object)

	set_targets_selected()
	sort_targets()

func remove_target(target_object: TargetableThing):
	if not is_instance_valid(target_object) or not find_target(target_object):
		return

	var removed_target_index = -1

	if aimer is GameplayCamera:
		var index = find_target_index(target_object)
		var _target = targets[index]
		targets.erase(_target)
		GameManager.instance.target_pool.return_object_to_pool(_target)
		removed_target_index = index
	else:
		removed_target_index = targets.find(target_object)

	if target == target_object:
		target = null  # Clear the current target as it's being removed

	targets.erase(find_target(target_object))
	set_targets_selected()
	sort_targets()

	# Set to next nearest target if the current target was removed
	if removed_target_index != -1:
		set_to_nearest_target(removed_target_index)

func set_to_nearest_target(removed_index: int):
	if targets.size() == 0:
		return  # No targets to set

	if removed_index >= targets.size():
		# If the removed target was the last in the list
		set_target(targets[targets.size() - 1].target)
	else:
		# Otherwise, set to the target at the current index
		set_target(targets[removed_index].target)

var torsos : Array = []

var energy_consumption_rate : float
var can_use_energy : bool = true

var target_movement : Vector2 = Vector2.ZERO
var override_target_movement : Vector2 = Vector2.ZERO

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
@export_category("Rotation")
@export var rotation_time: float = 0.25

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

		if energy_bar:
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

	if aimer is GameplayCamera:
		aimer.set_camera_object(self, 1, true)
	character_body.velocity = Vector3.ZERO
	energy = max_energy
	
	rotate_base(Vector3.FORWARD if rotation_behavior != movement_rotation_behavior.LEFT_RIGHT_ROTATION else Vector3.RIGHT)

func _physics_process(delta):
	# Lerp the current movement towards the target movement
	if is_in_air():
		current_movement = current_movement.lerp(target_movement if override_target_movement.length() == 0 else override_target_movement, air_control_smoothness)
	else:
		current_movement = current_movement.lerp(target_movement if override_target_movement.length() == 0 else override_target_movement, ground_control_smoothness)

	override_target_movement = Vector2.ZERO

	var movement_vector = calculate_movement_direction(current_movement)

	velocity.x = movement_vector.x * move_speed
	velocity.z = movement_vector.z * move_speed

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
		# Use the movement vector for thrust direction when there is input
		thrust_direction = calculate_movement_direction(current_movement)

		velocity += thrust_direction * thrust_amount.x * delta
		if is_in_air() and velocity.y < 0:
			velocity.y = lerp(velocity.y, 0.0, anti_gravity_smoothness)

	character_body.move_and_slide()
	character_body.velocity = velocity

	rotate_torsos(delta)
	rotate_towards_goto_rotation(delta)

func is_in_air() -> bool:
	return !character_body.is_on_floor() and is_jumping

func _process(delta):
	validate_targets()  # Validate targets each frame

	if can_use_energy:
		if energy_consumption_rate > 0:
			energy -= energy_consumption_rate * delta
		else:
			energy += energy_recovery_rate * delta
	elif energy < max_energy:
		energy += energy_recovery_rate * delta

func validate_targets():
	# Check if the current target is still valid
	if not is_instance_valid(target):
		target = null
		if targets.size() > 0:
			set_target(targets[0].target)
		return

	var current_target_index = find_target_index(target)
	var target_removed = false

	for i in range(targets.size() - 1, -1, -1):
		var _target = targets[i]
		if not is_instance_valid(_target.target):
			GameManager.instance.target_pool.return_object_to_pool(_target)
			targets.pop_at(i)
			if i == current_target_index:
				target_removed = true

	if target_removed:
		switch_to_next_target(current_target_index)

func switch_to_next_target(removed_index: int):
	if targets.size() == 0:
		target = null
		return

	var new_target_index = removed_index % targets.size()  # Ensure index is within bounds
	set_target(targets[new_target_index].target)

# 3. Movement Functions

func calculate_movement_direction(input_direction: Vector2) -> Vector3:
	# Extract the horizontal components of the camera's orientation
	var forward_horizontal = Vector3(aimer.global_transform.basis.z.x, 0, aimer.global_transform.basis.z.z).normalized()
	var right_horizontal = Vector3(aimer.global_transform.basis.x.x, 0, aimer.global_transform.basis.x.z).normalized()

	# Calculate the movement direction based on the horizontal components
	var direction = forward_horizontal * input_direction.y + right_horizontal * input_direction.x

	# Maintain the length of the input vector for smoothness
	# Normalize only if the length is greater than 1 to maintain the original scale of input_direction
	if direction.length() > 1:
		direction = direction.normalized()

	if not target and (direction.length() > 0.01 or aiming > 0):
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
			direction = aimer.basis.z

	rotation_direction = direction
	goto_rotation = atan2(rotation_direction.x, rotation_direction.z)
	# print("goto_rotation: " + str(rad_to_deg(goto_rotation)))

var aiming : int = 1:
	set(new_value):
		aiming = max(new_value, aiming)  # Ensure aiming does not go below the minimum
var aiming_minimum : int = 1

func rotate_torsos(delta):
	for torso in torsos:
		if not torso:
			continue

		var target_angle = 0.0
		if target and is_instance_valid(target):
			# Calculate the direction to the target in the torso's local space
			var local_target_pos = -character_base.to_local((target.thing_position(0.5)) + (character_base.global_position - torso.global_position))
			target_angle = atan2(local_target_pos.y, local_target_pos.z)
		elif aiming > 0:
			if aimer is GameplayCamera:
				target_angle = -aimer.rotation.x
				
		target_angle = clamp(target_angle, -PI/2, PI/2)

		# Apply the rotation
		if rotation_time > 0:
			torso.rotation.x = lerp_angle(torso.rotation.x, target_angle, delta / rotation_time)
		else:
			torso.rotation.x = target_angle
	
@export var aiming_angle_threshold : float = 60.0  # Degrees

func rotate_towards_goto_rotation(delta):
	if target and is_instance_valid(target):
		rotate_towards_target()

	character_base.rotation.y = lerp_angle(character_base.rotation.y, goto_rotation, delta / rotation_time)

func rotate_towards_target():
	var torso_forward = character_base.global_transform.basis.z.normalized()
	var camera_forward = aimer.global_transform.basis.z.normalized()

	var dot_product = torso_forward.dot(camera_forward)
	var angle_diff_rad = acos(clamp(dot_product, -1.0, 1.0))
	var angle_diff_deg = rad_to_deg(angle_diff_rad)

	if angle_diff_deg <= aiming_angle_threshold:
		var target_direction = (character_base.global_position - (target.global_position if not target is CharacterThing else target.character_base.global_position)).normalized()
		goto_rotation = atan2(target_direction.x, target_direction.z)
	else:
		remove_target(target)

# 4. Event Handling Functions

func move(direction):
	# Normalize the direction to ensure constant speed.
	if direction.length() > 1:
		direction = direction.normalized()

	target_movement = direction
	
	# print("move: " + str(direction))

func aim(direction):
	aimer.camera_rotation_amount = direction
	
func primary(pressed):
	for part in parts:
		if is_instance_valid(part) and part is CharacterPartThing:
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

func left_bumper(pressed):
	for part in parts:
		if part is CharacterPartThing:
			part.left_bumper(pressed)

func right_bumper(pressed):
	for part in parts:
		if part is CharacterPartThing:
			part.right_bumper(pressed)

func previous_target(pressed):
	if pressed:
		cycle_target(-1)

func next_target(pressed):
	if pressed:
		cycle_target(1)

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
				# if not aimer is GameplayCamera:
				# 	# Reparent the aimer to the head.
				# 	aimer.get_parent().remove_child(aimer)
				# 	part_instance.add_child(aimer)
				# 	aimer.position = Vector3.ZERO
			parts.append(part_instance)
			# Set any properties on the part, such as color.
			part_instance.character = self

		# Attach parts to other parts.
		attach_part_to_slot(character_base)

	thing_top = thing_top

	var _legs : int = 0
	var _move_speed : float = 0
	var _jump_height : float = 0
	var _thing_bottoms : Array = []

	for part in parts:
		if part is LegThing:
			_legs += 1
			_move_speed += part.move_speed
			_jump_height += part.jump_height
			
			_thing_bottoms.append(part.thing_bottom)

		if part is TorsoThing:
			torsos.append(part)

		if part is TargeterThing:
			part.visible = (aimer is GameplayCamera)

	if _legs > 0:
		_move_speed /= _legs
		_jump_height /= _legs

		move_speed = _move_speed
		jump_height = _jump_height

		var average_thing_bottom : Vector3 = Vector3.ZERO
		# Get the average position of all the thing bottoms.
		for _thing_bottom in _thing_bottoms:
			average_thing_bottom += _thing_bottom.global_position
		average_thing_bottom /= _thing_bottoms.size()

		# Set the position of the thing bottom to the average position.
		thing_bottom.global_position = average_thing_bottom

	# Set the height of the character's collision shape to match the height between the thing top and thing bottom.
	var height = thing_top.global_position.y - thing_bottom.global_position.y
	print("height: " + str(height))
	character_collision.position.y = thing_top.global_position.y - height / 2
	(character_collision.shape as CapsuleShape3D).height = height

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

		if part.side != "Both":
			part.side = parent.side

			for slot in part.inventory:
				if slot is ThingSlot and slot.side == "None":
					slot.side = parent.side

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

func get_parts_by_type(type: String) -> Array:
	var parts_by_type: Array = []
	for part in parts:
		if part is CharacterPartThing and (part.thing_type == type or part.thing_subtype == type):
			parts_by_type.append(part)
	return parts_by_type
