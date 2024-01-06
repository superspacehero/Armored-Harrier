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
	if target and camera:
		position = camera.camera.unproject_position(target.position.lerp(target.thing_top.position, follow_height))
