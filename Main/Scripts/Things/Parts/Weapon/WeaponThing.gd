extends CharacterPartThing
class_name WeaponThing

func _init():
	thing_type = "Weapon"

var _attacking : bool = false
var _secondary_attacking : bool = false

func _get_damage_amount() -> int:
	return 0

func attack(attacking : bool):
	_attacking = attacking
	
	character.aiming += 1 if attacking else -1

func secondary_attack(attacking : bool):
	_secondary_attacking = attacking

	character.aiming += 1 if attacking else -1

func _process(_delta):
	if _attacking or _secondary_attacking:
		character.rotate_base(-character.aimer.basis.z)
