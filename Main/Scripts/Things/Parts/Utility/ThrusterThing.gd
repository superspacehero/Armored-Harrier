extends CharacterPartThing
class_name ThrusterThing

func _init():
	thing_subtype = "Thruster"

@export var intended_weight : float = 70
@export var thrust_power : Vector2 = Vector2(650, 65)
@export var energy_consumption_rate : float = 30.0

var thrust_amount: Vector2 = Vector2(0, 0)

func primary(pressed):
	if pressed and character.is_in_air():
		thrust_amount.y = 1
	else:
		thrust_amount.y = 0

func secondary(pressed):
	thrust_amount.x = 1 if pressed else 0

func _process(_delta):
	var weight_ratio = intended_weight / character.thing_weight
	var adjusted_thrust_power = thrust_power * weight_ratio

	if character.can_use_energy and (character.target_movement.length() > 0 or thrust_amount.y != 0 or character.is_in_air()):
		character.thrust_amount = thrust_amount.normalized() * adjusted_thrust_power
		character.energy_consumption_rate = thrust_amount.normalized().length() * energy_consumption_rate
	else:
		character.thrust_amount = Vector2(0, 0)
		character.energy_consumption_rate = 0
