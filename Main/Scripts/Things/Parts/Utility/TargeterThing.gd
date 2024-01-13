extends CharacterPartThing
class_name TargeterThing

func _init():
	thing_subtype = "Targeter"

func _on_target_body_entered(body):
	if body == character.character_body:
		return
	
	var target = body
	
	while target != null:
		if target is TargetableThing:
			character.add_target(target as TargetableThing)
			break
		else:
			target = target.get_parent()

func _on_target_body_exited(body:Node3D):
	if body == character.character_body:
		return

	var target = body

	while target != null:
		if target is TargetableThing:
			character.remove_target(target as TargetableThing)
			break
		else:
			target = target.get_parent()
