extends Node
class_name AIInput

enum AIStates { NONE, ROAMING, ATTACKING, DEFENDING, RETREATING }
enum TargetPriorities { CLOSEST, WEAKEST, STRONGEST, MOST_DANGEROUS, LEAST_DANGEROUS }

# AI controlled character references
@export var character: CharacterThing

# Adjustable behavior parameters
@export_category("Behavior Parameters")
@export var target_priority = TargetPriorities.CLOSEST
@export_range(0.0, 1.0) var aggression_factor = 0.5
@export_range(0.0, 1.0) var defensiveness_factor = 0.5
@export_range(0.0, 1.0) var energy_conservation_factor = 0.5

# Movement parameters
@export_category("Movement Parameters")
@export_range(0.0, 20.0) var default_move_threshold = 1.0

var movement_threshold : float = 0.0:
	get:
		return movement_threshold if movement_threshold > 0.0 else default_move_threshold
	set(value):
		if movement_threshold == value:
			return

		movement_threshold = value
		# print("Movement Threshold: " + str(movement_threshold))

@export_range(0.0, 20.0) var vertical_boost_threshold = 5.0

# Roaming behavior parameters
@export_category("Roaming Behavior Parameters")
@export var roam_radius = 20.0  # Radius within which the AI will roam
@export var min_wait_time = 2.0  # Minimum time to wait at a point
@export var max_wait_time = 5.0  # Maximum time to wait at a point
var wait_timer = 0.0

@export var current_state = AIStates.NONE
var previousState = AIStates.NONE

var target_position : Vector3 = Vector3(0, 0, 0):
	set(position):
		previous_target_position = target_position
		target_position = position
var previous_target_position : Vector3 = target_position

# Weapon references
var weapons: Array = []

# Initialization
func _ready():
	character.thing_hostility = aggression_factor
	character.target_hostility_threshold = defensiveness_factor

	await initialize_weapon_references()

# Main Process Loop
func _physics_process(_delta):
	sense_environment()
	decide_next_action()
	execute_current_action()

# Environment Sensing
func sense_environment():
	search_for_targets()
	check_energy_levels()

func search_for_targets():
	var best_target_wrapper = choose_best_target()
	if best_target_wrapper:
		character.set_target(best_target_wrapper.target_node)

func choose_best_target():
	# Choose the closest visible target
	var best_target_wrapper = null
	var best_distance = INF
	for target_wrapper in character.targets:
		if not is_instance_valid(target_wrapper.target_node):
			continue

		var target_node = target_wrapper.target_node
		var distance = character.character_base.global_position.distance_to(target_node.global_transform.origin)
		if distance < best_distance:
			best_target_wrapper = target_wrapper
			best_distance = distance
	return best_target_wrapper

func check_energy_levels():
	# Monitor the character's energy levels for decision-making
	# Example: Check if the energy is below a certain threshold
	if character.energy < energy_conservation_factor * character.max_energy and is_defensive():
		if current_state != AIStates.DEFENDING:
			current_state = AIStates.DEFENDING

# Decision Making
func decide_next_action():
	match current_state:
		AIStates.NONE:
			current_state = AIStates.ROAMING
		AIStates.ROAMING:
			handle_roaming_state()
		AIStates.ATTACKING:
			handle_attacking_state()
		AIStates.DEFENDING:
			handle_defending_state()
		AIStates.RETREATING:
			handle_retreating_state()

	if current_state != previousState:
		previousState = current_state
		match current_state:
			AIStates.ROAMING:
				print("ROAMING")
			AIStates.ATTACKING:
				print("ATTACKING")
			AIStates.DEFENDING:
				print("DEFENDING")
			AIStates.RETREATING:
				print("RETREATING")


# Action Execution
func execute_current_action():
	move_character()

# State Handlers

func handle_roaming_state():
	if is_under_threat():
		if is_aggressive():
			current_state = AIStates.ATTACKING
		elif is_health_low():
			current_state = AIStates.RETREATING
		else:
			current_state = AIStates.DEFENDING
	elif is_instance_valid(character.target):
		if is_aggressive() and defensiveness_factor < character.target.thing_hostility:
			current_state = AIStates.ATTACKING
		elif defensiveness_factor > character.target.thing_hostility:
			current_state = AIStates.DEFENDING
	else:
		roam_around()

func roam_around():
	if get_target_position_distance(false) > movement_threshold and previous_target_position != target_position:
		return

	if wait_timer > 0.0:
		wait_timer -= get_physics_process_delta_time()
	else:
		target_position = select_random_point()
		wait_timer = randf_range(min_wait_time, max_wait_time)

func handle_attacking_state():
	if is_under_threat() and is_health_low():
		current_state = AIStates.RETREATING
	elif is_under_threat():
		if is_aggressive():
			engage_target(get_highest_priority_target())
		else:
			current_state = AIStates.DEFENDING
	else:
		if is_aggressive():
			engage_target(get_highest_priority_target())
		else:
			current_state = AIStates.DEFENDING

func handle_defending_state():
	if is_under_threat() and is_aggressive():
		counterattack_if_possible()
		take_defensive_position()
	elif is_under_threat() and is_health_low():
		current_state = AIStates.RETREATING

func handle_retreating_state():
	if not is_under_threat() and is_energy_high() and is_health_high():
		current_state = AIStates.ROAMING
	elif not is_under_threat() and is_energy_high():
		current_state = AIStates.ROAMING
	elif not is_under_threat():
		current_state = AIStates.ROAMING
	elif is_under_threat() and is_health_low():
		take_defensive_position()
	elif is_under_threat():
		move_to_safe_location()

# Helper Methods

func is_aggressive() -> bool:
	return aggression_factor >= defensiveness_factor

func is_defensive() -> bool:
	return defensiveness_factor >= aggression_factor

func is_under_threat() -> bool:
	for target in character.targets:
		if is_instance_valid(target) and (target.permanent or target.target_node.thing_is_attacking()):
			return true
	return false

func is_health_low() -> bool:
	return character.health <= (1.0 - aggression_factor) * character.max_health

func is_energy_high() -> bool:
	return character.energy > energy_conservation_factor * character.max_energy

func is_health_high() -> bool:
	return character.health > aggression_factor * character.max_health

# Target Selection

func get_highest_priority_target():
	match target_priority:
		TargetPriorities.CLOSEST:
			return get_closest_target()
		TargetPriorities.WEAKEST:
			return get_weakest_target()
		TargetPriorities.STRONGEST:
			return get_strongest_target()
		TargetPriorities.MOST_DANGEROUS:
			return get_most_dangerous_target()
		TargetPriorities.LEAST_DANGEROUS:
			return get_least_dangerous_target()

func get_target_position(target : Node3D) -> Vector3:
	return target.character_base.global_position if target is CharacterThing else target.global_position 

func get_target_position_distance(use_y: bool = true):
	return character.character_base.global_position.distance_to(target_position if use_y else Vector3(target_position.x, character.character_base.global_position.y, target_position.z))

func get_closest_target():
	var closest_target_wrapper = null
	var closest_distance = INF
	for target_wrapper in character.targets:
		if not is_instance_valid(target_wrapper.target_node):
			continue

		var distance = character.character_base.global_position.distance_to(get_target_position(target_wrapper.target_node))
		if distance < closest_distance:
			closest_target_wrapper = target_wrapper
			closest_distance = distance
	return closest_target_wrapper.target_node if closest_target_wrapper else null

func get_weakest_target():
	var weakest_target = null
	var lowest_health = INF
	for target_wrapper in character.targets:
		if not is_instance_valid(target_wrapper.target_node):
			continue

		var target_node = target_wrapper
		var health = target_node.health
		if health < lowest_health:
			weakest_target = target_node
			lowest_health = health
	return weakest_target.target_node if weakest_target else null

func get_strongest_target():
	var strongest_target = null
	var highest_health = 0
	for target_wrapper in character.targets:
		if not is_instance_valid(target_wrapper.target_node):
			continue

		var target_node = target_wrapper
		var health = target_node.health
		if health > highest_health:
			strongest_target = target_node
			highest_health = health
	return strongest_target.target_node if strongest_target else null 

func get_most_dangerous_target():
	var most_dangerous_target = null
	var highest_threat = 0
	for target_wrapper in character.targets:
		if not is_instance_valid(target_wrapper.target_node):
			continue

		var threat = target_wrapper.get_threat()
		if threat > highest_threat:
			most_dangerous_target = target_wrapper
			highest_threat = threat
	return most_dangerous_target.target_node if most_dangerous_target else null

func get_least_dangerous_target():
	var least_dangerous_target = null
	var lowest_threat = INF
	for target_wrapper in character.targets:
		if not is_instance_valid(target_wrapper.target_node):
			continue

		var threat = target_wrapper.get_threat()
		if threat < lowest_threat:
			least_dangerous_target = target_wrapper
			lowest_threat = threat
	return least_dangerous_target.target_node if least_dangerous_target else null

# Engagement and Movement
func engage_target(target : TargetableThing):
	character.find_target(target).permanent = true
	character.set_target(target)
	manage_vertical_movement()
	select_and_use_weapon()  # This now calls engage_or_disengage_weapon

func counterattack_if_possible():
	if is_instance_valid(character.target) and character.target.thing_is_attacking():
		engage_target(character.target)

# Weapon Management
func initialize_weapon_references():
	while weapons.size() == 0:
		if character.parts.size() > 0:
			weapons.append_array(character.get_parts_by_type("Handheld"))
			weapons.append_array(character.get_parts_by_type("Shoulder"))
		await get_tree().process_frame

func select_and_use_weapon():
	var selected_weapon = select_best_weapon()
	if selected_weapon:
		movement_threshold = selected_weapon.weapon_range
		engage_or_disengage_weapon(selected_weapon)
	else:
		movement_threshold = 0.0

func engage_or_disengage_weapon(weapon: WeaponThing):
	var should_engage = should_engage_weapon(weapon)
	trigger_weapon_attack(weapon, should_engage)

func should_engage_weapon(weapon: WeaponThing) -> bool:
	if current_state == AIStates.ATTACKING and character.target:
		var distance_to_target = character.character_base.global_position.distance_to(get_target_position(character.target))
		return distance_to_target <= weapon.weapon_range
	return false

func select_best_weapon() -> WeaponThing:
	var best_weapon = null
	var highest_suitability_score = 0.0
	for weapon in weapons:
		if weapon.ready_to_use:
			var suitability = evaluate_weapon_suitability(weapon)
			if suitability > highest_suitability_score:
				highest_suitability_score = suitability
				best_weapon = weapon
	return best_weapon

func trigger_weapon_attack(weapon: WeaponThing, trigger: bool = true):
	if character.target:
		match weapon.side:
			"Left":
				character.left_trigger(trigger) if weapon is HandheldThing else character.left_bumper(trigger)
			"Right":
				character.right_trigger(trigger) if weapon is HandheldThing else character.right_bumper(trigger)
			"Both":
				character.right_trigger(trigger) if weapon is HandheldThing else character.right_bumper(trigger)

func evaluate_weapon_suitability(weapon: WeaponThing) -> float:
	return weapon._get_damage_amount()  # Example: based on damage

# Movement and Positioning
func move_character():
	if get_target_position_distance() <= movement_threshold:
		return

	# Calculate the horizontal movement vector
	var horizontal_movement = (target_position - character.character_base.global_position).normalized()
	character.move(Vector2(horizontal_movement.x, horizontal_movement.z))

	var look_at_position = target_position

	if is_instance_valid(character.target):
		# Look at the target
		if character.aimer.global_position != get_target_position(character.target):
			look_at_position = get_target_position(character.target)

	look_at_position = (character.character_base.global_position - look_at_position).normalized()

	character.aimer.global_rotation.y = atan2(look_at_position.x, look_at_position.z) # + PI / 2

	# Check if vertical movement is needed
	var vertical_difference = target_position.y - character.character_base.global_position.y
	if vertical_difference > vertical_boost_threshold:
		character.jump_input = should_jump()
		trigger_vertical_boost(true)
	else:
		character.jump_input = false
		trigger_vertical_boost(false)

func select_random_point() -> Vector3:
	var random_direction = Vector3(randf_range(-1.0, 1.0), randf_range(0.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	var random_distance = randf_range(roam_radius * 0.5, roam_radius)
	var random_position = character.character_base.global_position + random_direction * random_distance
	return random_position

func take_defensive_position():
	# Move to a location that is close to the target but far away from other targets
	var defensive_position = Vector3(0, 0, 0)
	for target in character.targets:
		if target.target_node != character.target:
			defensive_position += (get_target_position(target.target_node) - character.character_base.global_position)
	defensive_position /= character.targets.size()
	target_position = character.character_base.global_position + defensive_position

func move_to_safe_location():
	# Move to a location that is far away from all targets
	var safe_location = Vector3(0, 0, 0)
	for target in character.targets:
		safe_location -= (get_target_position(target.target_node) - character.character_base.global_position)
	safe_location /= character.targets.size()
	target_position = character.character_base.global_position + safe_location

# Vertical and Horizontal Movement Management
func manage_vertical_movement():
	character.jump_input = should_jump()
	if should_vertical_boost():
		trigger_vertical_boost(true)  # Start vertical boost
	else:
		trigger_vertical_boost(false)  # Stop vertical boost

func manage_horizontal_movement():
	if should_horizontal_boost():
		trigger_horizontal_boost(true)  # Start horizontal boost
	else:
		trigger_horizontal_boost(false)  # Stop horizontal boost

func should_jump() -> bool:
	# Logic for determining when to jump
	return !character.is_in_air() # Add additional conditions as needed

func should_vertical_boost() -> bool:
	# Logic for determining when to use vertical boost
	return character.is_in_air() # Add additional conditions as needed

func should_horizontal_boost() -> bool:
	if character.target:
		var distance_to_target = character.character_base.global_position.distance_to(get_target_position(character.target))
		var selected_weapon = select_best_weapon()
		var is_weapon_short_range = selected_weapon and not selected_weapon is GunThing

		# Use horizontal boost for evasion or closing distance for short-range attacks
		return (current_state == AIStates.ATTACKING and is_weapon_short_range and distance_to_target > selected_weapon.weapon_range) or (current_state == AIStates.DEFENDING and should_evade())
	else:
		return false

func should_evade() -> bool:
	# Example: Evade if health is low or under heavy attack
	return is_health_low() and is_under_threat()

func trigger_vertical_boost(boost: bool):
	character.primary(boost)  # Triggering or stopping vertical boost

func trigger_horizontal_boost(boost: bool):
	character.secondary(boost)  # Triggering or stopping horizontal boost

