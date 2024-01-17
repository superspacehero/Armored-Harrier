extends Node
class_name AIInput

enum AIStates { NONE, ROAMING, SEARCHING, ATTACKING, DEFENDING, RETREATING }
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
@export var move_distance_threshold = 1.0:
	set(threshold):
		move_distance_threshold = max(threshold, 0.0)
@export var vertical_boost_threshold = 5.0:
	set(threshold):
		vertical_boost_threshold = max(threshold, 0.0)

# Roaming behavior parameters
@export_category("Roaming Behavior Parameters")
@export var roam_radius = 20.0  # Radius within which the AI will roam
@export var min_wait_time = 2.0  # Minimum time to wait at a point
@export var max_wait_time = 5.0  # Maximum time to wait at a point
var wait_timer = 0.0

var current_state = AIStates.NONE
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

	initialize_weapon_references()

# Main Process Loop
func _process(_delta):
	sense_environment()
	decide_next_action()
	execute_current_action()

# Environment Sensing
func sense_environment():
	search_for_targets()
	check_energy_levels()

func search_for_targets():
	var best_target = choose_best_target(character.targets)
	if best_target:
		character.set_target(best_target)

func choose_best_target(visible_targets):
	# Choose the closest visible target
	var best_target = null
	var best_distance = INF
	for target in visible_targets:
		var distance = character.character_base.global_position.distance_to(target.global_transform.origin)
		if distance < best_distance:
			best_target = target
			best_distance = distance
	return best_target

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
		AIStates.SEARCHING:
			handle_searching_state()
		AIStates.ATTACKING:
			handle_attacking_state()
		AIStates.DEFENDING:
			handle_defending_state()
		AIStates.RETREATING:
			handle_retreating_state()

	if current_state != previousState:
		previousState = current_state
		match current_state:
			AIStates.SEARCHING:
				print("SEARCHING")
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
	if not is_under_threat():
		roam_around()
	else:
		current_state = AIStates.SEARCHING

func roam_around():
	if get_target_position_distance(false) > move_distance_threshold and previous_target_position != target_position:
		return

	if wait_timer > 0.0:
		wait_timer -= get_physics_process_delta_time()
	else:
		target_position = select_random_point()
		wait_timer = randf_range(min_wait_time, max_wait_time)

func handle_searching_state():
	if is_under_threat():
		if is_aggressive():
			current_state = AIStates.ATTACKING
		elif is_defensive():
			current_state = AIStates.DEFENDING
		else:
			current_state = AIStates.RETREATING
	else:
		current_state = AIStates.SEARCHING

func handle_attacking_state():
	if not is_under_threat() or is_health_low():
		current_state = AIStates.RETREATING
	elif is_under_threat():
		if not is_aggressive():
			current_state = AIStates.DEFENDING
		else:
			engage_target(get_highest_priority_target())

func handle_defending_state():
	if is_aggressive() and is_under_threat():
		counterattack_if_possible()
	elif not is_under_threat() or is_health_low():
		current_state = AIStates.SEARCHING

func handle_retreating_state():
	if not is_under_threat() and is_energy_high() and is_health_high():
		current_state = AIStates.SEARCHING

# Helper Methods
func is_aggressive() -> bool:
	return aggression_factor >= 0.5

func is_defensive() -> bool:
	return defensiveness_factor >= 0.5

func is_under_threat() -> bool:
	return character.targets.size() > 0

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
	return get_target_position(target) if not target is CharacterThing else target.character_base.global_position

func get_target_position_distance(use_y: bool = true):
	return character.character_base.global_position.distance_to(target_position if use_y else Vector3(target_position.x, character.character_base.global_position.y, target_position.z))

func get_closest_target():
	var closest_target = null
	var closest_distance = INF
	for target in character.targets:
		var distance = character.character_base.global_position.distance_to(get_target_position(target))
		if distance < closest_distance:
			closest_target = target
			closest_distance = distance
	return closest_target

func get_weakest_target():
	var weakest_target = null
	var lowest_health = INF
	for target in character.targets:
		if target.health < lowest_health:
			weakest_target = target
			lowest_health = target.health
	return weakest_target

func get_strongest_target():
	var strongest_target = null
	var highest_health = 0
	for target in character.targets:
		if target.health > highest_health:
			strongest_target = target
			highest_health = target.health
	return strongest_target

func get_most_dangerous_target():
	var most_dangerous_target = null
	var highest_threat = 0
	for target in character.targets:
		var threat = target.get_threat_level()
		if threat > highest_threat:
			most_dangerous_target = target
			highest_threat = threat
	return most_dangerous_target

func get_least_dangerous_target():
	var least_dangerous_target = null
	var lowest_threat = INF
	for target in character.targets:
		var threat = target.get_threat_level()
		if threat < lowest_threat:
			least_dangerous_target = target
			lowest_threat = threat
	return least_dangerous_target

# Engagement and Movement
func engage_target(target : TargetableThing):
	character.target = target
	target = character.target
	manage_vertical_movement()
	select_and_use_weapon()

func counterattack_if_possible():
	# Logic to counterattack if certain conditions are met
	# Example: Counterattack when attacked or when an enemy is within a certain range
	if character.target and character.target.thing_is_attacking() or character.character_base.global_position.distance_to(get_target_position(character.target)) < 5.0:
		engage_target(character.target)

# Weapon Management
func initialize_weapon_references():
	weapons.append_array(character.get_parts_by_type("Handheld"))
	weapons.append_array(character.get_parts_by_type("Shoulder"))

func select_and_use_weapon():
	var selected_weapon = select_best_weapon()
	if selected_weapon and character.target:
		var distance_to_target = character.character_base.global_position.distance_to(get_target_position(character.target))
		if distance_to_target <= selected_weapon.range:
			trigger_weapon_attack(selected_weapon)

func select_best_weapon() -> WeaponThing:
	var best_weapon = null
	var highest_suitability_score = 0.0
	for weapon in weapons:
		if weapon.is_ready_to_use():
			var suitability = evaluate_weapon_suitability(weapon)
			if suitability > highest_suitability_score:
				highest_suitability_score = suitability
				best_weapon = weapon
	return best_weapon

func trigger_weapon_attack(weapon: WeaponThing):
	match weapon.side:
		"Left":
			character.left_trigger(true) if weapon is HandheldThing else character.left_bumper(true)
		"Right":
			character.right_trigger(true) if weapon is HandheldThing else character.right_bumper(true)
		"Both":
			character.right_trigger(true) if weapon is HandheldThing else character.right_bumper(true)

func evaluate_weapon_suitability(weapon: WeaponThing) -> float:
	return weapon._get_damage_amount()  # Example: based on damage

# Movement and Positioning
func move_character():
	if get_target_position_distance() <= move_distance_threshold:
		return

	# Calculate the horizontal movement vector
	var horizontal_movement = (target_position - character.character_base.global_position).normalized()
	character.move(Vector2(horizontal_movement.x, horizontal_movement.z))
	character.aimer.look_at(target_position, Vector3.UP, true)

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
		if target != character.target:
			defensive_position += (get_target_position(target) - character.character_base.global_position)
	defensive_position /= character.targets.size()
	target_position = character.character_base.global_position + defensive_position

func move_to_safe_location():
	# Move to a location that is far away from all targets
	var safe_location = Vector3(0, 0, 0)
	for target in character.targets:
		safe_location -= (get_target_position(target) - character.character_base.global_position)
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
	# Determine if horizontal boosting is needed
	if character.target:
		var distance_to_target = character.character_base.global_position.distance_to(get_target_position(character.target))
		var selected_weapon = select_best_weapon()
		var is_weapon_short_range = selected_weapon and not selected_weapon is GunThing

		# Use horizontal boost for evasion or closing distance for short-range attacks
		return (current_state == AIStates.ATTACKING and is_weapon_short_range and distance_to_target > selected_weapon.range) or (current_state == AIStates.DEFENDING and should_evade())
	else:
		return false

func should_evade() -> bool:
	# Example: Evade if health is low or under heavy attack
	return is_health_low() and is_under_threat()

func trigger_vertical_boost(boost: bool):
	character.primary(boost)  # Triggering or stopping vertical boost

func trigger_horizontal_boost(boost: bool):
	character.secondary(boost)  # Triggering or stopping horizontal boost

