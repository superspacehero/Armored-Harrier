extends CharacterPartThing
class_name LegThing

func _init():
	thing_subtype = "Leg"

@export var move_speed : float = 8  # The speed at which the character moves.
@export var jump_height: float = 8  # The height of the character's jump.

func primary(pressed):
	character.jump_input = pressed
	
