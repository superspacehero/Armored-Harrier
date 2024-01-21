extends CharacterPartThing
class_name WeaponThing

func _init():
	thing_type = "Weapon"

@export var weapon_range : float = 1.0

var _attacking : bool = false
var _secondary_attacking : bool = false

var ready_to_use : bool = true

func _get_damage_amount() -> int:
	return 0

func attack(is_attacking : bool):
	_attacking = is_attacking
	
	character.attacking += 1 if is_attacking else -1
	character.aiming += 1 if is_attacking else -1

func secondary_attack(is_attacking : bool):
	_secondary_attacking = is_attacking

	character.attacking += 1 if is_attacking else -1
	character.aiming += 1 if is_attacking else -1

func _process(_delta):
	if _attacking or _secondary_attacking:
		character.rotate_base(-character.aimer.basis.z)
