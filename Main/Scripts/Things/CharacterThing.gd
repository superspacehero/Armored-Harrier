extends UnsavedThing
class_name CharacterThing

# 1. Member Variables/Properties

@export var character_body : CharacterBody3D = null
@export var gameplay_camera : GameplayCamera
@export var character_base : Node3D = null

@export var character_speed : float = 4  # The speed at which the character moves.
@export var jump_height: float = 1  # The height of the character's jump.
@export var jump_offset: float = 0.15  # The offset of the character's jump.

enum control_level { NONE, MOVEMENT_ONLY, FULL }
@export var can_control: control_level = control_level.FULL
@export var can_move: bool = true
@export var can_jump: bool = true
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

enum movement_rotation_behavior { NONE, FULL_ROTATION, LEFT_RIGHT_ROTATION, TOWARDS_CAMERA }
@export var rotation_behavior = movement_rotation_behavior.TOWARDS_CAMERA

@export var max_energy : float = 100
@export var energy_bar : ProgressBar

var energy_consumption_rate : float
var can_use_energy : bool = true

var jump_input: bool = false
var is_jumping: bool = false

var velocity : Vector3 = Vector3.ZERO
var goto_rotation: float
var rotation_time: float = 0.25

var rotation_direction: Vector3 = Vector3.FORWARD
var movement: Vector3 = Vector3.ZERO

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

func _ready():
	super()

	energy = max_energy
	gameplay_camera.set_camera_object(self, 1, true)
	character_body.velocity = Vector3.ZERO
	
	rotate_base(Vector3.FORWARD if rotation_behavior != movement_rotation_behavior.LEFT_RIGHT_ROTATION else Vector3.RIGHT)

func _physics_process(_delta):
	velocity = calculate_movement_direction() * character_speed

	if character_body.is_on_floor():
		velocity.y = 0
	else:
		velocity.y -= gravity

	character_body.velocity = velocity
	
	character_body.move_and_slide()
	
	if character_body.is_on_floor() and can_control != control_level.NONE and can_jump and jump_input and !is_jumping:
		velocity.y = sqrt(2 * gravity * (jump_height + jump_offset))
		is_jumping = true
		print("Jumping")

func _process(delta):
	if can_use_energy:
		if energy_consumption_rate > 0:
			energy -= energy_consumption_rate * delta
	elif energy < max_energy:
		energy += energy_consumption_rate * delta
		
	rotate_towards_goto_rotation(delta)

# 3. Custom Functions

func calculate_movement_direction() -> Vector3:
	var direction = Vector3.ZERO

	direction += Plane(gameplay_camera.basis.x,character_body.basis.y.z).normalized().normal * movement.x
	direction += Plane(gameplay_camera.basis.z,character_body.basis.y.z).normalized().normal * movement.z
	direction.y = 0

	direction = direction.normalized()
	
	if direction.length() > 0.01:
		rotate_base(direction)
	
	return direction

func rotate_base(direction: Vector3):

	match rotation_behavior:
		movement_rotation_behavior.NONE:
			pass
		movement_rotation_behavior.FULL_ROTATION:
			# Do nothing. The character will rotate in the direction of movement.
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
	direction = direction.normalized()
	
	movement.x = direction.x
	movement.z = direction.y
	
	# print("move: " + str(direction))

func aim(direction):
	gameplay_camera.camera_rotation_amount = direction
	
func primary(pressed):
	jump_input = pressed

func secondary(_pressed):
	pass

func tertiary(_pressed):
	pass

func quaternary(_pressed):
	pass

func left_trigger(_pressed):
	pass

func right_trigger(_pressed):
	pass

func pause(_pressed):
	pass
