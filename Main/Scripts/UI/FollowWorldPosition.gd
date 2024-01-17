extends Control
class_name FollowWorldPosition

static var instance

@export var target: GameThing
@export_range(0.0, 1.0) var follow_height: float = 0.5

var camera: GameplayCamera

func _ready():
	move()

	var chara = get_parent()

	while chara:
		if chara is CharacterThing:
			camera = (chara as CharacterThing).aimer
			break
		chara = chara.get_parent()

func _process(_delta):
	move()

func move():
	if is_instance_valid(target) and camera:
		if target.health > 0:
			position = camera.camera.unproject_position(target.thing_position(follow_height))
		else:
			target = null
	elif camera:
		print("FollowWorldPosition: No target")
	elif target:
		print("FollowWorldPosition: No camera")
	else:
		print("FollowWorldPosition: No target or camera")
