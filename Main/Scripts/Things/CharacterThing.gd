extends UnsavedThing
class_name CharacterThing

# Called when the node enters the scene tree for the first time.
func _ready():
	super()

	energy = max_energy
	gameplay_camera.set_camera_object(self, 1, true)
	character_body.velocity = Vector3.ZERO
	
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

@export var character_body : CharacterBody3D = null
@export var character_speed : float = 5.0  # The speed at which the character moves.

@export var max_energy : float = 100
var can_use_energy : bool = true
var energy_consumption_rate : float
@export var energy_bar : ProgressBar

@export var gameplay_camera : GameplayCamera

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta):
	character_body.velocity.y -= gravity * delta
	character_body.move_and_slide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if can_use_energy:
		if energy_consumption_rate > 0:
			energy -= energy_consumption_rate * delta
	elif energy < max_energy:
		energy += energy_consumption_rate * delta

func move(direction):
	# Normalize the direction to ensure constant speed.
	direction = direction.normalized()
	
	character_body.velocity.x = direction * character_speed
	character_body.velocity.z = direction * character_speed
	
	print("move: " + str(direction))

func aim(direction):
	gameplay_camera.rotate_camera(direction)
	
func primary(pressed):
	pass

func secondary(pressed):
	pass

func tertiary(pressed):
	pass

func quaternary(pressed):
	pass

func left_trigger(pressed):
	pass

func right_trigger(pressed):
	pass

func pause(pressed):
	pass
