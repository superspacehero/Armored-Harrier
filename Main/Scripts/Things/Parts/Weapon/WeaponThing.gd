extends CharacterPartThing
class_name WeaponThing

func _init():
	thing_type = "Weapon"

var _attacking : bool = false
var _secondary_attacking : bool = false

func attack(attacking : bool):
	# print(("Attacking" if attacking else "Not attacking") + " with " + name)
	_attacking = attacking

func secondary_attack(attacking : bool):
	# print(("Attacking" if attacking else "Not attacking") + " with " + name)
	_secondary_attacking = attacking

func _process(_delta):
	if _attacking or _secondary_attacking:
		character.rotate_base(-character.gameplay_camera.basis.z)