extends GameThing
class_name AIInput

enum AIStates { SEARCHING, ATTACKING, DEFENDING, RETREATING }

# AI controlled character references
@export var character: CharacterThing

# Adjustable behavior parameters
@export_range(0.0, 1.0) var aggression_factor = 0.5
@export_range(0.0, 1.0) var defensiveness_factor = 0.5
@export_range(0.0, 1.0) var energy_conservation_factor = 0.5

var currentState = AIStates.SEARCHING

# Weapon references
var weapons: Array = []

# Initialization
func _ready():
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
	# Logic to search for targets. It could be based on range, line of sight, etc.
	# Example: Scan the environment to find and add targets to the character's target list
	character.scan_for_targets_within_range()

func check_energy_levels():
	# Monitor the character's energy levels for decision-making
	# Example: Check if the energy is below a certain threshold
	if character.energy < energy_conservation_factor * character.max_energy:
		if currentState != AIStates.RETREATING:
			currentState = AIStates.RETREATING

# Decision Making
func decide_next_action():
	match currentState:
		AIStates.SEARCHING:
			handle_searching_state()
		AIStates.ATTACKING:
			handle_attacking_state()
		AIStates.DEFENDING:
			handle_defending_state()
		AIStates.RETREATING:
			handle_retreating_state()

# Action Execution
func execute_current_action():
	# Implement action execution logic here
	pass

# State Handlers
func handle_searching_state():
	if character.has_target():
		currentState = AIStates.ATTACKING

func handle_attacking_state():
	if not character.has_target():
		currentState = AIStates.SEARCHING
		return
	engage_target(character.get_highest_priority_target())

func handle_defending_state():
	if defensiveness_factor > 0.7:
		take_defensive_position()
	else:
		counterattack_if_possible()

func counterattack_if_possible():
	# Logic to counterattack if certain conditions are met
	# Example: Counterattack when attacked or when an enemy is within a certain range
	if character.can_counterattack():
		character.counterattack()

func handle_retreating_state():
	if character.is_low_on_energy() or character.is_heavily_damaged():
		move_to_safe_location()

# Engagement and Movement
func engage_target(target):
	character.set_target(target)
	move_towards_target(target)
	manage_vertical_movement()
	select_and_use_weapon()

# Weapon Management
func initialize_weapon_references():
	weapons.append_array(character.get_parts_by_type("Handheld"))
	weapons.append_array(character.get_parts_by_type("Shoulder"))

func select_and_use_weapon():
	var selected_weapon = select_best_weapon()
	if selected_weapon:
		trigger_weapon_attack(selected_weapon)

func select_best_weapon() -> WeaponThing:
	var best_weapon = null
	var highest_suitability_score = 0.0
	for weapon in weapons:
		var suitability = evaluate_weapon_suitability(weapon)
		if suitability > highest_suitability_score:
			highest_suitability_score = suitability
			best_weapon = weapon
	return best_weapon

func trigger_weapon_attack(weapon: WeaponThing):
	match weapon.side:
		"Left":
			weapon.left_trigger(true) if weapon is HandheldThing else weapon.left_bumper(true)
		"Right":
			weapon.right_trigger(true) if weapon is HandheldThing else weapon.right_bumper(true)
		"Both":
			weapon.right_trigger(true) if weapon is HandheldThing else weapon.right_bumper(true)

func evaluate_weapon_suitability(weapon: WeaponThing) -> float:
	return weapon._get_damage_amount()  # Example: based on damage

# Movement and Positioning
func move_towards_target(target):
	var direction = (target.global_position - character.global_position).normalized()
	character.move(direction)

func take_defensive_position():
	character.move_to_defensive_position()

func move_to_safe_location():
	character.move_to_safe_location()

# Vertical Movement Management
func manage_vertical_movement():
	character.jump_input = should_jump()
	if should_boost():
		trigger_boost()

func should_jump() -> bool:
	return !character.is_in_air() # and additional jump conditions

func should_boost() -> bool:
	return character.is_in_air() # and additional boost conditions

func trigger_boost():
	for thruster in character.get_parts_by_type("Thruster"):
		if thruster is ThrusterThing:
			thruster.primary(true)  # Assuming primary function triggers the boost
