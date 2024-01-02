extends WeaponThing
class_name HandheldThing

func _init():
	thing_subtype = "Handheld"

func left_trigger(pressed):
	match side:
		"Left":
			attack(pressed)
		"Both":
			secondary_attack(pressed)

func right_trigger(pressed):
	match side:
		"Right":
			attack(pressed)
		"Both":
			attack(pressed)
