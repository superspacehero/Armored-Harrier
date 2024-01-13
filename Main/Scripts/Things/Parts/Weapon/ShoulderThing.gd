extends WeaponThing
class_name ShoulderThing

func _init():
	thing_subtype = "Shoulder"

func left_bumper(pressed):
	match side:
		"Left":
			attack(pressed)
		"Both":
			secondary_attack(pressed)

func right_bumper(pressed):
	match side:
		"Right":
			attack(pressed)
		"Both":
			attack(pressed)
